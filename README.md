# 🎤 WhisperAI

Ein elegantes macOS Menu-Bar-App, das Sprachaufnahmen in Echtzeit mit OpenAI Whisper transkribiert und anschließend mit einem KI-Modell (GPT-4o mini) nachbearbeitet.

**Schnelle Sprachein­gabe für jede App** — mit zwei Hotkeys:
- **Hold-to-Speak** (Standard: Ctrl+Option+R): Taste halten → sprechen → loslassen = Transkription startet
- **FreeHand** (Standard: Ctrl+Option+E): Taste drücken = Aufnahme starten, erneut drücken = stoppen

Der Text wird automatisch in das aktive Fenster eingefügt.

## ✨ Features

- **🌍 Mehrsprachig**: Transkription funktioniert mit Deutsch, Englisch, Französisch und mehr
- **🎯 Drei Modi** (anpassbar):
  - **Übersetzen**: Übersetzt Transkripte in eine frei wählbare Zielsprache
  - **Standard**: Transkript wird grammatikalisch verbessert, Struktur optimiert
  - **Freundlich**: Aggressiver Text wird sachlich und respektvoll umformuliert
- **🔐 Sicher**: API-Keys werden in der macOS Keychain gespeichert, nicht in Plaintext
- **⚡ Schnell**: HUD-Overlay zeigt Echtzeit-Feedback (Verarbeitung → Fertig)
- **🚀 Autostart**: Optional Anmeldeobjekte hinzufügen, damit die App beim Login startet
- **🛠️ Anpassbar**: Hotkeys frei konfigurierbar (inklusive Modifier-Keys für deine Tastaturlayout)
- **🎨 Elegant**: Minimalistisches Design, bleibt unauffällig im Hintergrund

## 📋 Systemanforderungen

- **macOS 13.0+** (Ventura oder neuer)
- **Apple Silicon (M1+) oder Intel** (beide werden unterstützt)
- **OpenAI API-Zugang** (bezahlter Account mit API-Keys)
- **Mikrofonzugriff** + **Bedienungshilfen-Berechtigung** (wird beim Start abgefragt)

## 🚀 Installation

### Option 1: Vorgefertigte App (empfohlen)

1. Gehe zu [Releases](https://github.com/agentnebel/WhisperAI/releases)
2. Lade die neueste `WhisperAI.app.zip` herunter
3. Entzippe die Datei → `WhisperAI.app` erscheint
4. Verschiebe `WhisperAI.app` in deinen `/Applications`-Ordner
5. Starte die App erstmals (Gatekeeper zeigt "Unbekannter Entwickler" → Rechtsklick → Öffnen)

### Option 2: Aus dem Quellcode bauen

Voraussetzungen:
- Xcode Command Line Tools: `xcode-select --install`
- Swift 5.9+

```bash
git clone https://github.com/agentnebel/WhisperAI.git
cd WhisperAI
./build.sh release
# Fertige App: build/WhisperAI.app
```

## 🔧 Erste Einrichtung

### 1. OpenAI API-Key besorgen

1. Gehe zu [platform.openai.com](https://platform.openai.com/account/api-keys)
2. Melde dich mit deinem OpenAI-Konto an (registrieren falls nötig)
3. Klicke auf **„Create new secret key"**
4. Kopiere den Key (einmalig sichtbar!)
5. Speichere ihn irgendwo sicher (später benötigt)

**Kosten**: Whisper-API kostet ca. **€0,002 pro Minute** Audioinput, GPT-4o mini ca. **€0,00015 pro 1K Input-Tokens**. Eine typische Transkription (30 Sekunden Audio) kostet etwa **€0,005** (~ 0,5 Cent).

### 2. Berechtigungen gewähren

Beim **ersten Start** von WhisperAI zeigt die App Dialoge für:

1. **Mikrofon-Zugriff**: 
   - System fragt → **„Erlauben"** klicken
   - Falls bereits abgelehnt: Systemeinstellungen → Datenschutz & Sicherheit → Mikrofon → WhisperAI aktivieren

2. **Bedienungshilfen-Berechtigung** (für Auto-Paste):
   - App zeigt Anleitung → **„Einstellungen öffnen"** klicken
   - Systemeinstellungen → Datenschutz & Sicherheit → Bedienungshilfen
   - **WhisperAI aktivieren** (den Toggle einschalten)
   - **WhisperAI neu starten** (wichtig!)

### 3. API-Key eingeben

1. Klick aufs 🎤 Icon in der Menu-Bar (oben rechts)
2. Klick auf **„Einstellungen…"** (unten)
3. Reiter **„Allgemein"** → Feld **„API Key"**
4. Klick auf **„Ändern"** → API-Key einfügen (Cmd+V)
5. **„Speichern"** klicken

### 4. (Optional) Autostart aktivieren

Im Onboarding-Panel oder in den Einstellungen:
- Klick auf **„Autostart aktivieren"** → die App trägt sich selbst in „Anmeldeobjekte & Erweiterungen" ein
- Danach startet WhisperAI automatisch beim Mac-Login

## 📖 Bedienung

### Hotkeys

Standardmäßig:
- **Ctrl+Option+R** (Hold-to-Speak): Taste halten → sprechen → loslassen
- **Ctrl+Option+E** (FreeHand): Drücken zum Start, erneut drücken zum Stopp

Die Hotkeys sind **vollständig anpassbar**:
1. Menu-Bar → **„Einstellungen…"**
2. Reiter **„Allgemein"**
3. Bei jedem Hotkey auf **„Aufnehmen"** klicken und neue Tastenkombination drücken
4. **„Speichern"**

> **Tipp für DE-Keyboards**: Die App erkennt automatisch dein Tastaturlayout (QWERTY, QWERTZ, etc.) und zeigt die Tastennamen korrekt an.

### Modus wechseln

1. Klick auf 🎤 in der Menu-Bar
2. **Modus-Buttons** oben: „Standard" oder „Freundlich"
3. Die gewählte Farbe bleibt bis zum Neustart aktiv

### HUD-Overlay

Während du sprichst und die App verarbeitet:
- 🟠 **Verarbeitung...** (orange Pulsing-Icon) → OpenAI-APIs laufen
- ✅ **Text eingefügt** (grünes Checkmark) → fertig, Text wurde in dein aktives Fenster eingefügt

## ⚙️ Konfiguration

### Modi hinzufügen/ändern

1. Menu-Bar → **„Einstellungen…"** → Reiter **„Modus"**
2. **„+"** zum Hinzufügen, bestehende Modi bearbeiten
3. Custom-Prompt eingeben (z.B. „Formuliere als Email")
4. **„Speichern"**

Beispiel-Prompts:
- _„Schreibe einen professionellen Email"_
- _„Zusammenfassung der wichtigsten Punkte"_
- _„Übersetze ins Englische"_

### Übersetzen-Modus: Zielsprache wählen

Der eingebaute **Übersetzen**-Modus unterstützt 19 Sprachen (Englisch, Französisch, Spanisch, Italienisch, Portugiesisch, Niederländisch, Polnisch, Russisch, Chinesisch, Japanisch, Koreanisch, Arabisch, Türkisch, Schwedisch, Norwegisch, Dänisch, Finnisch, Griechisch, Tschechisch).

1. Menu-Bar → **„Einstellungen…"** → Reiter **„Modus"**
2. Modus **„Übersetzen"** auswählen
3. Unter **„Zielsprache"** die gewünschte Sprache wählen
4. **„Speichern"**

Eigene Modi mit dem Platzhalter `{language}` im Prompt werden ebenfalls durch die gewählte Sprache ersetzt.

### Einstellungen (Dateiort)

Deine Konfiguration wird lokal gespeichert:
- **API-Key**: `~/Library/Keychains/` (Keychain — sicher!)
- **Modi**: `~/Library/Application Support/WhisperAI/modes.json`
- **Hotkeys**: `~/Library/Preferences/com.whisperai.app.plist`

Diese Dateien werden **nicht** mit der App verteilt und enthalten keine persönlichen Infos.

## 🐛 Troubleshooting

### „Berechtigung erforderlich" beim Start
- Bedienungshilfen noch nicht gewährt? → **Menü-Panel folgen**
- Noch nicht sichtbar? → App neu starten (wichtig nach Gewährung!)

### Hotkey funktioniert nicht
- Ist die App im Vordergrund? Hotkeys sind **global registriert** und sollten überall funktionieren
- Tastenkombination von anderer App belegt? → Andere Taste wählen (Einstellungen → Allgemein)
- Auf DE-Keyboard Test-Namen überprüfen (z.B. „R" statt „Y")

### Text wird nicht eingefügt
- Ist die aktive App TextField-kompatibel? (funktioniert mit Safari, Mail, VS Code, etc.)
- Bedienungshilfen-Permission nicht aktiv? → Nochmal aktivieren + **Neustart der App**
- Zu lang? (max. ~10.000 Zeichen sicher) → Längere Texte splitten

### API-Key-Fehler
- Key ist falsch/abgelaufen? → Neuer Key bei OpenAI
- Key mit `sk-` Prefix? (sollte immer so beginnen)
- Guthaben aufgebraucht? → Zahlungsinfo bei OpenAI prüfen
- Rate-Limit? → Warte ein paar Sekunden vor nächster Aufnahme

### Performance/Verzögerung
- Erste Aufnahme ist langsam (Netzwerk-Verbindung wird aufgebaut) — später läuft's zügig
- Lange Transkriptionen (>2 min Audio) brauchen entsprechend länger
- Ist dein Internet stabil? → Nutze 5 GHz WiFi oder Ethernet

## 🛠️ Aus dem Quellcode bauen

```bash
git clone https://github.com/agentnebel/WhisperAI.git
cd WhisperAI

# Release-Build
./build.sh release

# Fertige App
open build/WhisperAI.app

# Oder direkt starten
./build.sh release && open build/WhisperAI.app
```

Der Build nutzt **Swift 5** und benötigt die macOS SDK (via Xcode Command Line Tools).

## 📁 Projektstruktur

```
WhisperAI/
├── WhisperAI/
│   ├── main.swift                    # App Entry Point
│   ├── AppDelegate.swift             # Lifecycle + Hotkey-Handling
│   ├── AppState.swift                # Enums (idle, recording, processing)
│   ├── Audio/
│   │   └── AudioRecorder.swift       # Mikrofon-Zugriff (AVFoundation)
│   ├── API/
│   │   ├── WhisperService.swift      # OpenAI Whisper API
│   │   └── LLMService.swift          # OpenAI GPT-4o mini API
│   ├── Services/
│   │   ├── TextInserter.swift        # Keyboard-Paste (Accessibility)
│   │   ├── HotkeyManager.swift       # Carbon-Event Global Hotkeys
│   │   ├── SettingsManager.swift     # UserDefaults + Keychain
│   │   └── KeychainHelper.swift      # Secure API Key Storage
│   ├── Modes/
│   │   ├── Mode.swift                # Mode-Datentyp
│   │   └── ModeManager.swift         # Custom-Modes (JSON-Persistierung)
│   ├── UI/
│   │   ├── WhisperAIModel.swift      # SwiftUI ObservableObject
│   │   ├── MenuBarPopoverView.swift  # SwiftUI Popover
│   │   ├── GeneralSettingsView.swift # Hotkey + API Key Settings
│   │   ├── ModesSettingsView.swift   # Mode Editor
│   │   ├── SettingsWindowController.swift # Settings-Fenster
│   │   ├── StatusBarController.swift # NSStatusBar Icon + Popover
│   │   ├── InsertionHUD.swift        # Toast-Overlay während Verarbeitung
│   │   ├── RecordingHUD.swift        # Mikrofon-Overlay während Aufnahme
│   │   └── AccessibilityOnboarding.swift # First-Run Dialogs
│   ├── Info.plist                    # App Metadata
│   ├── AppIcon.icns                  # App Icon
│   └── WhisperAI.entitlements        # Code-Signing Entitlements
├── build.sh                          # Build-Script (swiftc + Code-Signing)
└── README.md                         # Diese Datei
```

## 🔒 Sicherheit & Datenschutz

- **Keine Datensammlung**: Die App sendet nur Audioinput an OpenAI-APIs. Keine Telemetrie, kein Tracking.
- **Keychain**: API-Keys werden in der macOS Keychain gespeichert (am sichersten)
- **Keine Cloud-Sync**: Modi und Einstellungen bleiben auf deinem Mac
- **Entfernt nach Verarbeitung**: Audiodateien werden nach der Transkription sofort gelöscht
- **Offline-Betrieb nicht möglich**: Erfordert aktive Internet-Verbindung zu OpenAI-APIs

## 📋 Changelog

### v1.4.0 — 2026-04-17
**Aufnahme-Overlay (RecordingHUD)**
- Neues kreisförmiges Mikrofon-Overlay erscheint beim Start einer Aufnahme zentriert auf dem Desktop
- Transparenter Hintergrund (`underWindowBackground`): Desktop bleibt sichtbar
- Pulsierender Ring zeigt aktive Aufnahme an; Icon-Farbe passt sich dem System-Erscheinungsbild an (hell/dunkel)
- Verschwindet automatisch wenn die Aufnahme endet oder abbricht

**Code-Cleanup**
- Ungenutzten `onModeSelected`-Callback aus `StatusBarController` entfernt
- `rebuildMenu()` → `refreshModel()` umbenannt und irreführende „Legacy/No-op"-Kommentare entfernt
- Totes `radius`-Property aus `RecordingHUD` entfernt
- Tote `.tag(0)/.tag(1)`-Modifier auf `TabView` in `SettingsWindowController` entfernt
- Leeren `"Übersetzen": []`-Platzhalter aus `legacyPromptsByName` entfernt
- README-Projektstruktur: doppelter `ModeManager`-Eintrag weg, alle Dateien korrekt gelistet

---

### v1.3.0 — 2026-04-17
**Stabiles Code-Signing (kein Keychain-Spam mehr)**
- Selbst-signiertes lokales Zertifikat „WhisperAI Dev" ersetzt Ad-hoc-Signierung (`--sign -`)
- Zuvor: Jeder Build erzeugte eine neue, zufällige Signatur → macOS fragte bei jedem Start erneut nach Keychain-Zugriff
- Jetzt: Signatur bleibt über alle Builds hinweg gleich → einmalige „Immer erlauben"-Genehmigung reicht dauerhaft
- `build.sh` wechselt automatisch auf Ad-hoc-Fallback, falls das Zertifikat nicht gefunden wird

**Popover-Größe korrigiert**
- `NSHostingController.sizingOptions = [.preferredContentSize]` (macOS 13+) hinzugefügt
- Bisher: NSPopover ignorierte die SwiftUI-Intrinsicsize und schnitt den Inhalt oben ab (Modus-Bereich war nicht sichtbar)
- Jetzt: Popover passt sich automatisch an die tatsächliche Höhe des SwiftUI-Inhalts an

**Modus-Auswahl im Popover neu gestaltet**
- Horizontale Pill-Buttons durch vertikale Zeilen mit Checkmark-Indikator ersetzt
- Löst das Overflow-Problem bei vier oder mehr Modi (Buttons liefen früher aus dem sichtbaren Bereich)
- Hover-Effekt und farbige Hintergrundmarkierung für den aktiven Modus

---

### v1.2.0 — 2026-04-15
**Übersetzen-Modus**
- Neuer eingebauter Modus „Übersetzen" mit konfigurierbarer Zielsprache
- Zielsprache wählbar in Einstellungen → Modus (19 Sprachen verfügbar)
- Prompt-Platzhalter `{language}` wird zur Laufzeit durch die gewählte Sprache ersetzt
- Automatische Migration: Bestehende Installationen erhalten den neuen Modus ohne Datenverlust

**Migrations-Engine erweitert**
- Zweistufige Migration beim App-Start: (1) veraltete Prompts upgraden, (2) fehlende Default-Modi ergänzen
- Neue Defaults erscheinen bei Update automatisch in der Modus-Liste bestehender Nutzer

---

### v1.1.0 — 2026-04-14
**LLM beantwortet keine Fragen mehr**
- Gehärtete System-Prompts für alle Default-Modi mit klaren STRENG-VERBOTEN/NUR-ERLAUBT-Abschnitten
- Transkript wird in `<transcript>`-Tags eingebettet, damit das Modell Nutzerdaten von Anweisungen trennt
- Verhindert, dass transkribierte Fragen (z.B. „Was ist die Hauptstadt von Frankreich?") direkt beantwortet werden
- Konkrete Gegenbeispiele in den Prompts demonstrieren korrektes Verhalten

---

### v1.0.0 — 2026-04-13
**Erstveröffentlichung**
- Hold-to-Speak & FreeHand-Hotkeys (global, Carbon HIToolbox)
- OpenAI Whisper-Transkription
- GPT-4o mini Nachbearbeitung mit konfigurierbaren Modi
- Keychain-Speicherung des API-Keys
- HUD-Overlay mit transparenten Ecken
- Bedienungshilfen-Onboarding
- Autostart via SMAppService (kein Login-Items-Eintrag mehr nötig)
- Einstellungen: Hotkeys, Modelle, API-Key, Modi-Editor

---

## 📜 Lizenz

Dieses Projekt ist Open Source. Siehe [LICENSE](LICENSE) für Details.

## 🙋 Fragen & Support

- **Issue gefunden?** → Erstelle einen [GitHub Issue](https://github.com/agentnebel/WhisperAI/issues)
- **Feedback?** → [GitHub Discussions](https://github.com/agentnebel/WhisperAI/discussions)
- **Beitrag?** → Pull Requests sind willkommen!

## 🙏 Danke

Gebaut mit:
- [OpenAI Whisper API](https://platform.openai.com/docs/guides/speech-to-text)
- [OpenAI GPT-4o mini](https://platform.openai.com/docs/models)
- [macOS AppKit + SwiftUI](https://developer.apple.com/)
- [Carbon.HIToolbox](https://developer.apple.com/) (Global Hotkeys)

---

**Viel Erfolg mit WhisperAI!** 🎙️✨
