/// Cloud service profile dialog: pick an existing profile or create/edit one.
///
/// One dialog serves both families (speech / llm). The dialog owns the
/// profile list persistence; API keys are returned to the caller, which
/// stores them through ByokSecretStore per modality.
library;

import 'dart:async';
import 'dart:convert';

import 'package:enjoy_player/core/theme/enjoy_icons.dart';
import 'package:enjoy_player/data/api/api_client_provider.dart';
import 'package:enjoy_player/data/api/byok_secret_store.dart';
import 'package:enjoy_player/features/ai/domain/modality_kind.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enjoy_player/core/theme/enjoy_tokens.dart';
import 'package:enjoy_player/features/ai/data/cloud_profiles_repository.dart';
import 'package:enjoy_player/features/ai/domain/cloud_profile.dart';

/// Result of the picker: the chosen profile and an optionally entered key.
class CloudProfileSelection {
  const CloudProfileSelection({
    this.speech,
    this.llm,
    this.apiKey,
  });

  final CloudSpeechProfile? speech;
  final CloudLlmProfile? llm;

  /// Key typed in the form (null = unchanged / use stored key).
  final String? apiKey;
}

Future<CloudProfileSelection?> showCloudProfileDialog({
  required BuildContext context,
  required WidgetRef ref,
  required bool speech,
  String? selectedId,
}) {
  return showDialog<CloudProfileSelection>(
    context: context,
    builder: (_) => _CloudProfileDialog(
      speakerRef: ref,
      speech: speech,
      selectedId: selectedId,
    ),
  );
}

class _CloudProfileDialog extends StatefulWidget {
  const _CloudProfileDialog({
    required this.speakerRef,
    required this.speech,
    this.selectedId,
  });

  final WidgetRef speakerRef;
  final bool speech;
  final String? selectedId;

  @override
  State<_CloudProfileDialog> createState() => _CloudProfileDialogState();
}

class _CloudProfileDialogState extends State<_CloudProfileDialog> {
  CloudProfiles _profiles = const CloudProfiles();
  CloudSpeechProfile? _editingSpeech;
  CloudLlmProfile? _editingLlm;
  bool _formOpen = false;

  // Form state
  CloudVendor _vendor = CloudVendor.openAiCompatible;
  String? _presetId = 'openai';
  final _endpoint = TextEditingController();
  final _region = TextEditingController();
  final _key = TextEditingController();
  final _asrModel = TextEditingController(text: 'whisper-1');
  final _ttsModel = TextEditingController(text: 'tts-1');
  final _llmModel = TextEditingController(text: 'gpt-4o-mini');
  final _name = TextEditingController();

  // Fetched model list ("拉取模型" against the endpoint's /models).
  bool _fetchingModels = false;
  List<String> _fetchedModels = const [];
  String? _fetchError;

  void _resetModelFetch() {
    _fetchingModels = false;
    _fetchedModels = const [];
    _fetchError = null;
  }

  @override
  void initState() {
    super.initState();
    final loaded = widget.speakerRef.read(cloudProfilesProvider).value;
    if (loaded != null) {
      _profiles = loaded;
    } else {
      unawaited(
        widget.speakerRef.read(cloudProfilesProvider.future).then((p) {
          if (mounted) setState(() => _profiles = p);
        }),
      );
    }
  }

  @override
  void dispose() {
    _endpoint.dispose();
    _region.dispose();
    _key.dispose();
    _asrModel.dispose();
    _ttsModel.dispose();
    _llmModel.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _persist(CloudProfiles next) async {
    await writeCloudProfiles(widget.speakerRef, next);
    if (mounted) setState(() => _profiles = next);
  }

  void _openNew() {
    setState(() {
      _formOpen = true;
      _editingSpeech = null;
      _editingLlm = null;
      _vendor = CloudVendor.openAiCompatible;
      _presetId = 'openai';
      _endpoint.clear();
      _region.clear();
      _key.clear();
      _name.clear();
      _asrModel.text = 'whisper-1';
      _ttsModel.text = 'tts-1';
      _llmModel.text = 'gpt-4o-mini';
      _resetModelFetch();
    });
  }

  void _openEditSpeech(CloudSpeechProfile p) {
    setState(() {
      _formOpen = true;
      _editingSpeech = p;
      _editingLlm = null;
      _vendor = p.vendor;
      _presetId = null;
      _endpoint.text = p.endpoint;
      _region.text = p.region;
      _name.text = p.name;
      _key.clear();
      _asrModel.text = p.asrModel;
      _ttsModel.text = p.ttsModel;
      _resetModelFetch();
    });
  }

  void _openEditLlm(CloudLlmProfile p) {
    setState(() {
      _formOpen = true;
      _editingLlm = p;
      _editingSpeech = null;
      _vendor = p.vendor;
      _presetId = null;
      _endpoint.text = p.endpoint;
      _region.text = p.region;
      _name.text = p.name;
      _key.clear();
      _llmModel.text = p.model;
      _resetModelFetch();
    });
  }

  void _applyPreset(LlmPreset preset) {
    setState(() {
      _presetId = preset.id;
      _endpoint.text = preset.endpoint;
      _llmModel.text = preset.model;
      _vendor = preset.id == 'azureOpenAi'
          ? CloudVendor.azure
          : CloudVendor.openAiCompatible;
      _resetModelFetch();
    });
  }

  /// Queries `{endpoint}/models` (OpenAI-compatible list API) and fills the
  /// suggestion list. Uses the typed key; when empty, falls back to the
  /// stored LLM key so editing an existing profile works without retyping.
  Future<void> _fetchModels() async {
    final endpoint = _endpoint.text.trim().replaceAll(RegExp(r'/+$'), '');
    if (endpoint.isEmpty) {
      setState(() => _fetchError = '请先填写端点地址');
      return;
    }
    var key = _key.text.trim();
    if (key.isEmpty) {
      try {
        key =
            await widget.speakerRef
                .read(byokSecretStoreProvider)
                .readApiKey(ModalityKind.llm) ??
            '';
      } on Object {
        // Secure storage unavailable — proceed without a key.
      }
    }
    setState(() {
      _fetchingModels = true;
      _fetchError = null;
      _fetchedModels = const [];
    });
    try {
      final uri = Uri.parse('$endpoint/models');
      final response = await widget.speakerRef
          .read(httpClientProvider)
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              if (key.isNotEmpty) 'Authorization': 'Bearer $key',
            },
          ).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw 'HTTP ${response.statusCode}';
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      List<String> models = const [];
      if (decoded is Map && decoded['data'] is List) {
        models = [
          for (final item in decoded['data'] as List)
            if (item is Map && item['id'] != null) item['id'].toString(),
        ];
      } else if (decoded is List) {
        // Some gateways return a bare array of ids or objects.
        models = [
          for (final item in decoded)
            if (item is String) item else if (item is Map && item['id'] != null)
              item['id'].toString(),
        ];
      }
      models = [...models.where((m) => m.isNotEmpty)]..sort();
      if (models.isEmpty) {
        throw '端点没有返回模型列表';
      }
      setState(() => _fetchedModels = models);
    } on TimeoutException {
      setState(() => _fetchError = '请求超时，检查端点或网络');
    } on Object catch (e) {
      setState(() => _fetchError = '拉取失败：$e');
    } finally {
      if (mounted) setState(() => _fetchingModels = false);
    }
  }

  Future<void> _deleteSpeech(CloudSpeechProfile p) async {
    await _persist(
      _profiles.copyWith(speech: [..._profiles.speech]..remove(p)),
    );
  }

  Future<void> _deleteLlm(CloudLlmProfile p) async {
    await _persist(_profiles.copyWith(llm: [..._profiles.llm]..remove(p)));
  }

  void _selectExistingSpeech(CloudSpeechProfile p) {
    Navigator.of(context).pop(CloudProfileSelection(speech: p));
  }

  void _selectExistingLlm(CloudLlmProfile p) {
    Navigator.of(context).pop(CloudProfileSelection(llm: p));
  }

  Future<void> _saveForm() async {
    final key = _key.text.trim();
    final name = _name.text.trim();
    final endpoint = _endpoint.text.trim();
    final region = _region.text.trim();
    final isAzure = _vendor == CloudVendor.azure;
    if (!isAzure && endpoint.isEmpty) return;
    if (isAzure && region.isEmpty) return;
    final label = name.isNotEmpty
        ? name
        : isAzure
        ? 'Azure · $region'
        : endpoint.replaceFirst(RegExp(r'^https?://'), '');

    if (widget.speech) {
      final base =
          _editingSpeech ??
          CloudSpeechProfile(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: label,
          );
      final updated = base.copyWith(
        name: label,
        vendor: _vendor,
        endpoint: isAzure ? '' : endpoint,
        region: region,
        asrModel: _asrModel.text.trim().isEmpty
            ? 'whisper-1'
            : _asrModel.text.trim(),
        ttsModel: _ttsModel.text.trim().isEmpty
            ? 'tts-1'
            : _ttsModel.text.trim(),
        hasKey: base.hasKey || key.isNotEmpty,
      );
      final list = [..._profiles.speech];
      final idx = list.indexWhere((p) => p.id == updated.id);
      if (idx >= 0) {
        list[idx] = updated;
      } else {
        list.insert(0, updated);
      }
      await _persist(_profiles.copyWith(speech: list));
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(CloudProfileSelection(speech: updated, apiKey: key.isEmpty ? null : key));
    } else {
      final base =
          _editingLlm ??
          CloudLlmProfile(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: label,
          );
      final updated = base.copyWith(
        name: label,
        vendor: _vendor,
        endpoint: isAzure ? '' : endpoint,
        region: region,
        model: _llmModel.text.trim().isEmpty
            ? 'gpt-4o-mini'
            : _llmModel.text.trim(),
        hasKey: base.hasKey || key.isNotEmpty,
      );
      final list = [..._profiles.llm];
      final idx = list.indexWhere((p) => p.id == updated.id);
      if (idx >= 0) {
        list[idx] = updated;
      } else {
        list.insert(0, updated);
      }
      await _persist(_profiles.copyWith(llm: list));
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(CloudProfileSelection(llm: updated, apiKey: key.isEmpty ? null : key));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final speech = widget.speech;

    return AlertDialog(
      title: Text(speech ? '配置云端语音服务' : '配置云端语言模型'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                speech
                    ? '识别与合成共用同一个端点与密钥，模型分别填写。'
                    : '字幕翻译专用（LLM），云端质量显著高于本地小模型。',
                style: tt.bodySmall?.copyWith(color: t.ink3, height: 1.35),
              ),
              SizedBox(height: t.space12),
              if (!_formOpen) ...[
                Text('已保存的配置', style: tt.labelMedium?.copyWith(color: t.ink3)),
                const SizedBox(height: 4),
                if (speech)
                  for (final p in _profiles.speech)
                    _profileRow(
                      context,
                      title: p.name,
                      subtitle: p.summary,
                      hasKey: p.hasKey,
                      selected: p.id == widget.selectedId,
                      onTap: () => _selectExistingSpeech(p),
                      onEdit: () => _openEditSpeech(p),
                      onDelete: () => _deleteSpeech(p),
                    )
                else
                  for (final p in _profiles.llm)
                    _profileRow(
                      context,
                      title: p.name,
                      subtitle: p.summary,
                      hasKey: p.hasKey,
                      selected: p.id == widget.selectedId,
                      onTap: () => _selectExistingLlm(p),
                      onEdit: () => _openEditLlm(p),
                      onDelete: () => _deleteLlm(p),
                    ),
                if ((speech ? _profiles.speech : _profiles.llm).isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '还没有保存的配置。',
                      style: tt.bodySmall?.copyWith(color: t.ink3),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _openNew,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新建配置'),
                  ),
                ),
              ] else
                _buildForm(context),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        if (_formOpen)
          FilledButton(onPressed: _saveForm, child: const Text('保存并使用')),
      ],
    );
  }

  Widget _profileRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool hasKey,
    required bool selected,
    required VoidCallback onTap,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(EnjoyIcons.cloud, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: hasKey
                              ? cs.primaryContainer.withValues(alpha: .5)
                              : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          hasKey ? '已配置' : '缺密钥',
                          style: tt.labelSmall?.copyWith(
                            fontSize: 10,
                            color: hasKey ? cs.onPrimaryContainer : t.ink3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(color: t.ink3),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onEdit, child: const Text('编辑')),
            TextButton(onPressed: onDelete, child: const Text('删除')),
            if (selected)
              Icon(Icons.check, size: 18, color: cs.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final t = EnjoyThemeTokens.of(context);
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final isAzure = _vendor == CloudVendor.azure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              _editingSpeech != null || _editingLlm != null ? '编辑配置' : '新建配置',
              style: tt.labelMedium?.copyWith(color: t.ink3),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _formOpen = false),
              child: const Text('返回列表'),
            ),
          ],
        ),
        if (widget.speech) ...[
          Text('协议', style: tt.labelMedium?.copyWith(color: t.ink3)),
          const SizedBox(height: 6),
          SegmentedButton<CloudVendor>(
            segments: const [
              ButtonSegment(
                value: CloudVendor.openAiCompatible,
                label: Text('OpenAI 兼容'),
              ),
              ButtonSegment(value: CloudVendor.azure, label: Text('Azure Speech')),
            ],
            selected: {_vendor},
            onSelectionChanged: (s) => setState(() => _vendor = s.first),
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
          const SizedBox(height: 8),
        ] else ...[
          Text('预设', style: tt.labelMedium?.copyWith(color: t.ink3)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in kLlmPresets)
                ChoiceChip(
                  label: Text(preset.label),
                  selected: _presetId == preset.id,
                  onSelected: (_) => _applyPreset(preset),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (!isAzure) ...[
          TextField(
            controller: _endpoint,
            decoration: const InputDecoration(
              labelText: '端点地址',
              hintText: 'https://api.openai.com/v1',
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
          ),
          const SizedBox(height: 10),
        ] else ...[
          TextField(
            controller: _region,
            decoration: const InputDecoration(
              labelText: '区域',
              hintText: 'eastasia',
            ),
            autocorrect: false,
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _key,
          decoration: const InputDecoration(
            labelText: 'API 密钥',
            hintText: '留空 = 沿用原密钥',
          ),
          obscureText: true,
          autocorrect: false,
        ),
        const SizedBox(height: 10),
        if (widget.speech) ...[
          TextField(
            controller: _asrModel,
            decoration: const InputDecoration(
              labelText: '识别模型',
              hintText: 'whisper-1',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ttsModel,
            decoration: const InputDecoration(
              labelText: '合成模型',
              hintText: 'tts-1',
            ),
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _llmModel,
                  decoration: const InputDecoration(
                    labelText: '翻译模型',
                    hintText: 'gpt-4o-mini',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_fetchingModels)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                OutlinedButton(
                  onPressed: isAzure ? null : _fetchModels,
                  child: const Text('拉取模型'),
                ),
            ],
          ),
          if (_fetchError != null) ...[
            const SizedBox(height: 6),
            Text(
              _fetchError!,
              style: tt.bodySmall?.copyWith(color: cs.error),
            ),
          ],
          if (_fetchedModels.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 168),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _fetchedModels.length,
                itemBuilder: (context, index) {
                  final model = _fetchedModels[index];
                  final selected = model == _llmModel.text.trim();
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    title: Text(
                      model,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall,
                    ),
                    trailing: selected
                        ? Icon(Icons.check, size: 16, color: cs.primary)
                        : null,
                    onTap: () => setState(() => _llmModel.text = model),
                  );
                },
              ),
            ),
          ],
        ],
        const SizedBox(height: 10),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: '名称（可选）',
            hintText: '例如：公司代理',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isAzure
              ? 'Azure 用区域 + 密钥定位服务。'
              : '任何 OpenAI 兼容端点均可。',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
