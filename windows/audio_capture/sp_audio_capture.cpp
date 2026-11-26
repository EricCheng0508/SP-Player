// sp_audio_capture.exe — system-audio / microphone capture helper for the
// live-captions feature.
//
// Captures PCM from Windows audio endpoints and writes 16 kHz mono 16-bit
// little-endian PCM to stdout, ready to be piped to the local whisper ASR
// service (which wants exactly that format).
//
// Sources:
//   --source system   Loopback capture of the default render endpoint —
//                     everything Windows is playing (default).
//   --source mic      Default capture endpoint (microphone).
//
// Modes:
//   (no flags)        Stream PCM to stdout until stdout closes or the device
//                     is invalidated. The app kills the process to stop.
//   --wav <file>      Write a proper WAV file instead (self-test).
//   --seconds <n>     Stop after n seconds (self-test; 0 = stream forever).
//
// Exit codes: 0 clean stop, 2 bad arguments, 3 device invalidated (the app
// restarts us), 4 capture error.
//
// Notes on loopback capture: WASAPI loopback does not signal buffer events
// (documented limitation), so we wait on the event with a timeout and drain
// whatever is available — the same wait works for the mic, which does fire.

#include <windows.h>
#include <audioclient.h>
#include <mmdeviceapi.h>
#include <mmsystem.h>
#include <fcntl.h>
#include <io.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <vector>

// Older SDKs may miss these; the values are frozen ABI constants.
#ifndef AUDCLNT_STREAMFLAGS_EVENTDRIVEN
#define AUDCLNT_STREAMFLAGS_EVENTDRIVEN 0x00080000
#endif
#ifndef AUDCLNT_STREAMFLAGS_LOOPBACK
#define AUDCLNT_STREAMFLAGS_LOOPBACK 0x00010000
#endif

namespace {

constexpr REFERENCE_TIME kBufferDuration = 50 /*ms*/ * 10000; // hns
constexpr double kTargetRate = 16000.0;

volatile LONG g_stop = 0;

BOOL WINAPI HandleCtrl(DWORD type) {
  InterlockedExchange(&g_stop, 1);
  return TRUE;
}

void LogLine(const char* msg) {
  std::fprintf(stderr, "sp_audio_capture: %s\n", msg);
  std::fflush(stderr);
}

// Linear-resample mixer: any input format (float32 / int16 / int32, any
// channel count) -> mono float -> 16 kHz s16. Kept deliberately simple;
// ASR is robust to the minor artifacts of linear interpolation.
class Resampler {
 public:
  void Configure(int inRate, int inChannels) {
    rate_ = inRate > 0 ? static_cast<double>(inRate) : 48000.0;
    channels_ = inChannels > 0 ? inChannels : 2;
    step_ = rate_ / kTargetRate;
  }

  // Consumes raw interleaved frames, emits resampled s16 mono into [out].
  void Feed(const BYTE* data, UINT32 bytes, std::vector<short>& out) {
    if (bytes == 0 || channels_ == 0) return;
    const UINT32 frames = bytes / (channels_ * sampleBytes_);
    const size_t before = pending_.size();
    pending_.reserve(before + frames);
    for (UINT32 f = 0; f < frames; ++f) {
      double sum = 0.0;
      for (int c = 0; c < channels_; ++c) {
        sum += SampleAt(data, f * channels_ + c);
      }
      pending_.push_back(static_cast<float>(sum / channels_));
    }

    // Emit while two consecutive frames are available for interpolation;
    // the fractional phase carries across packets.
    while (pos_ + 1.0 < static_cast<double>(pending_.size())) {
      const size_t idx = static_cast<size_t>(pos_);
      const double frac = pos_ - static_cast<double>(idx);
      const float a = pending_[idx];
      const float b = pending_[idx + 1];
      out.push_back(
          static_cast<short>(std::lround((a + (b - a) * frac) * 32767.0)));
      pos_ += step_;
    }
    // Drop consumed frames and rebase the phase onto the new buffer start.
    const size_t consumed = static_cast<size_t>(pos_);
    if (consumed > 0) {
      pending_.erase(pending_.begin(), pending_.begin() + consumed);
      pos_ -= static_cast<double>(consumed);
    }
  }

  int sampleBytes_ = 4;          // per single channel sample
  bool isFloat_ = true;          // format subtype

 private:
  double SampleAt(const BYTE* data, size_t index) const {
    switch (sampleBytes_) {
      case 2: {
        short v;
        std::memcpy(&v, data + index * 2, 2);
        return static_cast<double>(v) / 32768.0;
      }
      case 4: {
        if (isFloat_) {
          float v;
          std::memcpy(&v, data + index * 4, 4);
          return static_cast<double>(v);
        }
        int v;
        std::memcpy(&v, data + index * 4, 4);
        return static_cast<double>(v) / 2147483648.0;
      }
      default:
        return 0.0;
    }
  }

  double rate_ = 48000.0;
  int channels_ = 2;
  double step_ = 3.0;
  double pos_ = 0.0;            // read position within pending_
  std::vector<float> pending_;  // unconsumed mono frames
};

void WriteWavHeader(FILE* f, UINT32 dataBytes, UINT32 rate) {
  const UINT32 byteRate = rate * 2; // mono s16
  struct {
    char riff[4]; UINT32 riffSize; char wave[4];
    char fmtHdr[4]; UINT32 fmtSize; UINT16 fmtTag; UINT16 ch; UINT32 rateU;
    UINT32 byteRateU; UINT16 block; UINT16 bits;
    char dataHdr[4]; UINT32 dataSize;
  } h = {
      {'R','I','F','F'}, 36 + dataBytes, {'W','A','V','E'},
      {'f','m','t',' '}, 16, 1, 1, rate, byteRate, 2, 16,
      {'d','a','t','a'}, dataBytes};
  std::fwrite(&h, sizeof(h), 1, f);
}

bool ParseArgs(int argc, wchar_t** argv, bool* mic, const wchar_t** wavPath,
               double* seconds) {
  *mic = false;
  *wavPath = nullptr;
  *seconds = 0.0;
  for (int i = 1; i < argc; ++i) {
    const wchar_t* a = argv[i];
    if (std::wcscmp(a, L"--source") == 0 && i + 1 < argc) {
      ++i;
      if (std::wcscmp(argv[i], L"mic") == 0) {
        *mic = true;
      } else if (std::wcscmp(argv[i], L"system") != 0) {
        return false;
      }
    } else if (std::wcscmp(a, L"--wav") == 0 && i + 1 < argc) {
      *wavPath = argv[++i];
    } else if (std::wcscmp(a, L"--seconds") == 0 && i + 1 < argc) {
      *seconds = std::wcstod(argv[++i], nullptr);
    } else {
      return false;
    }
  }
  return true;
}

int Run(bool mic, const wchar_t* wavPath, double seconds) {
  HRESULT hr = CoInitializeEx(nullptr, COINIT_MULTITHREADED);
  if (FAILED(hr)) {
    LogLine("CoInitializeEx failed");
    return 4;
  }

  IMMDeviceEnumerator* enumerator = nullptr;
  IAudioClient* client = nullptr;
  IAudioCaptureClient* capture = nullptr;
  FILE* out = stdout;
  bool stdoutBinary = false;
  int exitCode = 0;
  WAVEFORMATEX* format = nullptr;

  do {
    hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                          __uuidof(IMMDeviceEnumerator),
                          reinterpret_cast<void**>(&enumerator));
    if (FAILED(hr)) { LogLine("no device enumerator"); exitCode = 4; break; }

    IMMDevice* device = nullptr;
    hr = enumerator->GetDefaultAudioEndpoint(
        mic ? eCapture : eRender, eConsole, &device);
    if (FAILED(hr)) { LogLine(mic ? "no default mic" : "no default render device"); exitCode = 4; break; }
    hr = device->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr,
                          reinterpret_cast<void**>(&client));
    device->Release();
    if (FAILED(hr)) { LogLine("device activate failed"); exitCode = 4; break; }

    hr = client->GetMixFormat(&format);
    if (FAILED(hr) || format == nullptr) { LogLine("no mix format"); exitCode = 4; break; }

    // Loopback capture does not support event-driven buffering on Windows
    // (SetEventHandle rejects it), so both sources use plain polling.
    const DWORD flags = mic ? 0 : AUDCLNT_STREAMFLAGS_LOOPBACK;
    hr = client->Initialize(AUDCLNT_SHAREMODE_SHARED, flags,
                            kBufferDuration, 0, format, nullptr);
    if (FAILED(hr)) { LogLine("audio client init failed"); exitCode = 4; break; }

    hr = client->GetService(__uuidof(IAudioCaptureClient),
                            reinterpret_cast<void**>(&capture));
    if (FAILED(hr)) { LogLine("capture service failed"); exitCode = 4; break; }

    // Identify the sample format for the resampler. For WAVEFORMATEXTENSIBLE
    // the SubFormat GUID's Data1 equals the legacy format tag (1 = PCM,
    // 3 = float), so no ksmedia GUID instances are needed.
    Resampler res;
    WAVEFORMATEXTENSIBLE* ext = reinterpret_cast<WAVEFORMATEXTENSIBLE*>(format);
    const bool extensible = format->wFormatTag == WAVE_FORMAT_EXTENSIBLE &&
                            format->cbSize >= sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX);
    const WORD fmtTag = extensible
        ? static_cast<WORD>(ext->SubFormat.Data1)
        : format->wFormatTag;
    if (fmtTag == WAVE_FORMAT_IEEE_FLOAT) {
      res.isFloat_ = true;
      res.sampleBytes_ = format->wBitsPerSample / 8;
      if (res.sampleBytes_ != 4) {
        LogLine("unsupported float bit depth");
        exitCode = 4;
        break;
      }
    } else if (fmtTag == WAVE_FORMAT_PCM) {
      res.isFloat_ = false;
      res.sampleBytes_ = format->wBitsPerSample / 8;
      if (res.sampleBytes_ != 2 && res.sampleBytes_ != 4) {
        LogLine("unsupported pcm bit depth");
        exitCode = 4;
        break;
      }
    } else {
      LogLine("unsupported mix format");
      exitCode = 4;
      break;
    }
    res.Configure(format->nSamplesPerSec, format->nChannels);

    if (wavPath != nullptr) {
      out = nullptr;
      if (_wfopen_s(&out, wavPath, L"wb") != 0 || out == nullptr) {
        LogLine("cannot open wav file");
        exitCode = 4;
        break;
      }
      WriteWavHeader(out, 0, static_cast<UINT32>(kTargetRate));
    } else {
      _setmode(_fileno(stdout), _O_BINARY);
      stdoutBinary = true;
    }

    hr = client->Start();
    if (FAILED(hr)) { LogLine("start failed"); exitCode = 4; break; }

    LogLine(mic ? "capturing mic" : "capturing system audio");

    std::vector<short> pcm;
    std::vector<BYTE> sink;
    UINT32 writtenBytes = 0;
    const ULONGLONG deadline = seconds > 0.0
        ? (GetTickCount64() +
           static_cast<ULONGLONG>(seconds * 1000.0))
        : 0;

    while (!InterlockedCompareExchange(&g_stop, 0, 0)) {
      if (deadline != 0 && GetTickCount64() >= deadline) break;

      // Polling cadence: ~15 ms, well inside the 50 ms buffer.
      Sleep(15);

      BYTE* data = nullptr;
      UINT32 frames = 0;
      DWORD flagsRaw = 0;
      UINT64 devPos = 0, qpcPos = 0;
      while (capture->GetNextPacketSize(&frames) == S_OK && frames > 0) {
        if (capture->GetBuffer(&data, &frames, &flagsRaw, &devPos, &qpcPos) != S_OK) break;
        const UINT32 bytes = frames * format->nChannels * res.sampleBytes_;
        if ((flagsRaw & AUDCLNT_BUFFERFLAGS_SILENT) == 0 && data != nullptr) {
          pcm.clear();
          res.Feed(data, bytes, pcm);
        } else {
          // Silence: emit zeros at the expected output rate so the timeline
          // stays continuous.
          const UINT32 skipIn = frames;
          const double outFrames =
              static_cast<double>(skipIn) * kTargetRate / format->nSamplesPerSec;
          pcm.assign(static_cast<size_t>(outFrames) + 1, 0);
        }
        capture->ReleaseBuffer(frames);
        if (!pcm.empty()) {
          const size_t want = pcm.size() * 2;
          const size_t got = wavPath != nullptr
              ? std::fwrite(pcm.data(), 2, pcm.size(), out) * 2
              : std::fwrite(pcm.data(), 2, pcm.size(), stdout) * 2;
          if (got != want) {
            // stdout closed / file error: parent is gone; stop quietly.
            InterlockedExchange(&g_stop, 1);
            break;
          }
          writtenBytes += static_cast<UINT32>(want);
          if (wavPath == nullptr) {
            std::fflush(stdout);
          }
        }
      }
    }

    client->Stop();

    if (wavPath != nullptr && out != nullptr) {
      // Patch RIFF/data sizes with the real byte counts.
      std::fseek(out, 0, SEEK_SET);
      WriteWavHeader(out, writtenBytes, static_cast<UINT32>(kTargetRate));
      std::fclose(out);
      out = nullptr;
      wchar_t msg[128];
      swprintf_s(msg, L"wrote %lu bytes to %s\n", writtenBytes, wavPath);
      // _cwprintf for wide output; keep it simple on stderr narrow.
      char narrow[128];
      WideCharToMultiByte(CP_ACP, 0, msg, -1, narrow, sizeof(narrow), nullptr, nullptr);
      LogLine(narrow);
    }
  } while (false);

  if (format != nullptr) CoTaskMemFree(format);
  if (capture != nullptr) capture->Release();
  if (client != nullptr) client->Release();
  if (enumerator != nullptr) enumerator->Release();
  if (out != nullptr && out != stdout) std::fclose(out);
  (void)stdoutBinary;
  CoUninitialize();
  return exitCode;
}

} // namespace

int wmain(int argc, wchar_t** argv) {
  bool mic = false;
  const wchar_t* wavPath = nullptr;
  double seconds = 0.0;
  if (!ParseArgs(argc, argv, &mic, &wavPath, &seconds)) {
    LogLine("usage: sp_audio_capture [--source system|mic] [--wav file] [--seconds n]");
    return 2;
  }
  SetConsoleCtrlHandler(HandleCtrl, TRUE);
  const int code = Run(mic, wavPath, seconds);
  return code;
}
