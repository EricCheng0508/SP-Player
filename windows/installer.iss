; SP Player installer script (Inno Setup 6)
; Bundles the Flutter Windows Release output into a single setup.exe.

[Setup]
AppName=SP Player
AppVersion=0.10.3
AppPublisher=EricCheng0508
AppPublisherURL=https://github.com/EricCheng0508/SP-Player
DefaultDirName={autopf}\SP Player
DefaultGroupName=SP Player
UninstallDisplayName=SP Player
OutputDir=D:\code\SP-Player\build\installer
OutputBaseFilename=SPPlayer-Setup-0.10.3
Compression=lzma2/normal
SolidCompression=yes
LZMANumBlockThreads=8
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
PrivilegesRequired=admin
SetupIconFile=D:\code\SP-Player\windows\runner\resources\app_icon.ico
WizardStyle=modern
DisableProgramGroupPage=yes

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional:"

[Files]
; App binary only. The local-component models (components\) are NOT bundled —
; they are ~4.7 GB, past GitHub's 2 GiB per-asset limit; the first-run wizard
; downloads them from the `components-v1` release instead.
Source: "D:\code\SP-Player\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Excludes: "components"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
Name: "{group}\SP Player"; Filename: "{app}\sp_player.exe"
Name: "{group}\Uninstall SP Player"; Filename: "{uninstallexe}"
Name: "{autodesktop}\SP Player"; Filename: "{app}\sp_player.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\sp_player.exe"; Description: "Launch SP Player"; Flags: nowait postinstall skipifsilent
