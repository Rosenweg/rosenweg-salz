; SPDX-License-Identifier: GPL-3.0-or-later
; Inno-Setup-Skript fuer Rosenweg Salz (Windows-Installer, .exe).
;
;   iscc /DVersion=1.0.0 /DQuelle=build\windows\x64\runner\Release windows\installer\rosenweg-salz.iss
;
; Warum Inno Setup und nicht MSIX: MSIX verlangt ein Signierzertifikat, dem
; der Rechner vertraut (sonst laesst Windows es gar nicht installieren); das
; Haus hat (noch) keines. Ein Inno-Installer laeuft auch unsigniert (SmartScreen
; fragt dann einmal nach), installiert ohne Adminrechte fuer die Person
; (%LOCALAPPDATA%\Programs) und bringt eine saubere Deinstallation mit.
; Mit Zertifikat: SignTool in CI setzen (signtool sign ... $f), sonst nichts.
;
; Ergebnis: build\windows-installer\Rosenweg-Salz-<Version>-Setup.exe

#ifndef Version
  #define Version "0.0.0"
#endif
#ifndef Quelle
  #define Quelle "..\..\build\windows\x64\runner\Release"
#endif

[Setup]
; Feste Kennung: Updates ersetzen die vorhandene Installation.
AppId={{6C1C2E3B-5B0F-4F5A-9E4D-0A7D5A3B5A11}
AppName=Rosenweg Salz
AppVersion={#Version}
AppVerName=Rosenweg Salz {#Version}
AppPublisher=Rosenweg
AppPublisherURL=https://www.rosenweg4303.ch/apps
DefaultDirName={autopf}\Rosenweg Salz
DefaultGroupName=Rosenweg
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\build\windows-installer
OutputBaseFilename=Rosenweg-Salz-{#Version}-Setup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\rosenweg_salz.exe
LicenseFile=..\..\LICENSE
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "de"; MessagesFile: "compiler:Languages\German.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#Quelle}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Rosenweg Salz"; Filename: "{app}\rosenweg_salz.exe"
Name: "{autodesktop}\Rosenweg Salz"; Filename: "{app}\rosenweg_salz.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\rosenweg_salz.exe"; Description: "{cm:LaunchProgram,Rosenweg Salz}"; Flags: nowait postinstall skipifsilent
