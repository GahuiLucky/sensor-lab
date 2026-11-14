# Sensor Lab – iOS Sensor-Dashboard

Eine vollständige SwiftUI-App, die alle verfügbaren iPhone-Sensoren live einliest und als animierte, moderne Oberfläche visualisiert. Keine externen Abhängigkeiten, keine Netzwerkverbindung, alle Daten bleiben auf dem Gerät.

![Plattform](https://img.shields.io/badge/iOS-17%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-declarative-green)

## Sensoren & Datenquellen

| Bereich | Sensoren / Frameworks | Anzeige |
|---|---|---|
| Bewegung | Accelerometer, Gyroskop, Device Motion (`CoreMotion`) | Live-Liniendiagramme X/Y/Z, Betrag, Ø/Min/Max, künstlicher Horizont, 3D-Gerätelage |
| Lage | Attitude (Roll/Nick/Gier), Schwerkraftvektor | Horizont, Gradwerte, 3D-Kippansicht |
| Magnetfeld | Magnetometer (`CMDeviceMotion.magneticField`) | Feldstärke in µT, Achsenverlauf, Erdgas-Referenz |
| Standort | GPS (`CoreLocation`) | Koordinaten, Höhe, Tempo, Kurs, Genauigkeiten, Zeitstempel |
| Kompass | `CLHeading` | rotierende Kompassrose, magnetisch/geografisch, Genauigkeit |
| Aktivität | `CMMotionActivityManager`, `CMPedometer` | Gehen/Laufen/Rad/Fahrzeug/Stationär, Konfidenz, Schritte, Distanz, Etagen, Kadenz, Pace |
| Umgebung | Barometer (`CMAltimeter`), Mikrofon (`AVAudioEngine`) | relativer Höhenverlauf, Luftdruck in hPa, Schallpegel in dBFS inkl. Wellenform |
| Gerät | `UIDevice`, `ProcessInfo` | Akkustand/-status, Thermik, Ausrichtung, Helligkeit, Stromsparmodus, Näherungssensor |

## Starten

Voraussetzungen: macOS mit **Xcode 15 oder neuer**, iOS-17-Gerät oder Simulator.

1. `SensorLab.xcodeproj` in Xcode öffnen.
2. Unter **Signing & Capabilities** das eigene Team wählen. Die Bundle-ID `com.sensorlab.app` ggf. anpassen.
3. Ein iPhone als Zielgerät wählen und **Run** (⌘R) drücken.

Auf einem echten iPhone erscheint beim ersten Start ein Onboarding. Dort werden die Berechtigungen für Bewegung, Standort und Mikrofon angefragt. Ohne Hardware (Simulator) lässt sich der **Demo-Modus** starten – er erzeugt realistische, animierte Beispielwerte für alle Bereiche und ist jederzeit in den Einstellungen umschaltbar.

> Der Simulator liefert keine Accelerometer-, Gyroskop-, Magnetometer- oder Barometerdaten. Die App zeigt dort einen Hinweis und schlägt den Demo-Modus vor.

## Aufbau

```
SensorLab.xcodeproj
SensorLab/
├── App/          App-Einstieg und Tab-Navigation
├── Engine/       Sensor-Dienste (CoreMotion, CoreLocation, AVFoundation), SensorEngine, ToolStore
├── Models/       Datenmodelle, Ringpuffer, Formatierung, SensorTool-Baukasten
├── Design/       Theme, Karten, Diagramme, Kompassrose, Horizont
├── Views/        Übersicht, Studio, Bewegung, Standort, Aktivität, Umgebung, Einstellungen, Onboarding
├── Resources/    Asset-Katalog inkl. App-Icon
└── Info.plist    Nutzungsbeschreibungen (Deutsch)
```

Alle Diagramme sind mit `Canvas` und `Path` selbst gezeichnet – ohne Charts-Framework oder Fremdbibliotheken. Die Ringpuffer halten die letzten 180 Messpunkte (ca. 6 Sekunden bei 30 Hz) und werden bei jeder Messung aktualisiert.

## Bedienung

- **Live/Pause** oben rechts friert die Anzeige ein, die Sensoren laufen im Hintergrund weiter.
- **Einstellungen** (Schieberegler-Symbol) zeigen die Verfügbarkeit jedes Sensors, den Berechtigungsstatus und den Demo-Umschalter.
- Die Tab-Leiste führt zu den Detailansichten mit größeren Diagrammen und Statistiken.
- Im **Studio** entstehen eigene Tools aus den Sensordaten (siehe unten).
- Der **Näherungssensor** ist standardmäßig aus und muss in der Umgebungsansicht bewusst aktiviert werden (das Display schaltet sich bei Bedeckung ab).

## Studio – eigene Tools aus Sensordaten

Der Tab **Studio** ist ein Baukasten: Jedes Tool besteht aus Quelle → Umformung → Darstellung und optional einem Alarm. Änderungen sind sofort live, alles wird lokal in `UserDefaults` gespeichert (`sensorlab.tools.v1`).

| Baustein | Möglichkeiten |
|---|---|
| Quelle | 20 Sensoren: Accel X/Y/Z/Betrag, Gyro X/Y/Z/Betrag, Roll/Nick/Gier, Schwerkraft, Magnetfeld, rel. Höhe, Luftdruck, Schallpegel, Tempo, Kompass, Schritte, Kadenz |
| Umformung | Rohwert, Betrag, Geglättet (EMA, Regler 0.02–0.95), dazu Faktor und Offset |
| Darstellung | Zahl, Linienverlauf, Ringanzeige, Balken – jeweils mit Min/Max-Bereich |
| Alarm | über/unter Schwelle, optional haptisches Feedback (Warnung + Impuls alle 1,6 s) |

**Bedienung**

1. Im Studio oben rechts auf **+** tippen → *Eigenes Tool*.
2. Name, Symbol und Farbe wählen, dann Sensorquelle, Signalform, Darstellung und Bereich festlegen.
3. *Sichern* – das Tool erscheint als Live-Karte im Raster.
4. Karte antippen öffnet die Vollbild-Live-Ansicht mit Statistik (Ø/Min/Max) und Konfiguration.
5. Karte lange drücken zum **Bearbeiten** oder **Löschen**; über das **+**-Menü lassen sich die Vorlagen wiederherstellen.

**Vorlagen** beim ersten Start: Wasserwaage, Erschütterung, Lärmampel, Tempo, Schrittziel, Höhenprofil. Geglättete Tools verwenden einen exponentiellen Mittelwert, damit z. B. das Tempo nicht zappelt; Alarme prüfen bei jedem Sample (30 Hz) und lösen nur beim Zustandswechsel ein Haptik-Muster aus.

## Installierbare IPA für das iPhone

iOS-Apps lassen sich nur mit macOS und Xcode kompilieren und nur mit einer Apple-Signatur installieren. Auf diesem Windows-Rechner wurde deshalb **keine IPA erzeugt** – das Projekt ist aber so vorbereitet, dass ein Rechner mit Xcode oder GitHub Actions sie in wenigen Minuten baut.

### Variante A: GitHub Actions (ohne Mac)

1. Projekt in ein GitHub-Repository pushen.
2. Reiter **Actions** → Workflow **iOS IPA bauen** → **Run workflow**. Der Workflow nutzt einen macOS-Runner und `.github/workflows/ios-ipa.yml`.
3. Nach etwa 2–4 Minuten das Artefakt **SensorLab-unsigned-ipa** herunterladen und entpacken.
4. [Sideloadly](https://sideloadly.io) unter Windows starten, iPhone per USB verbinden, `SensorLab-unsigned.ipa` hineinziehen, die eigene **Apple-ID** eintragen und *Start* drücken.
5. Auf dem iPhone: **Einstellungen → Allgemein → VPN & Geräteverwaltung** → Entwicklerprofil vertrauen.

Die IPA ist bewusst **unsigniert** (`CODE_SIGNING_ALLOWED=NO`); die Signatur übernimmt Sideloadly mit der Apple-ID. Mit einer kostenlosen Apple-ID läuft die App **7 Tage**, danach einfach erneut signieren; mit dem Apple Developer Program (99 €/Jahr) ein Jahr. Maximal drei eigene Apps gleichzeitig mit kostenloser ID.

### Variante B: Xcode auf einem Mac

1. `SensorLab.xcodeproj` öffnen, unter *Signing & Capabilities* das eigene Team wählen (Bundle-ID ggf. anpassen).
2. iPhone verbinden und **Run** (⌘R) für den direkten Test.
3. Für eine Datei: **Product → Archive → Distribute App → Development/Ad Hoc** exportieren.

> Ohne Signatur ist keine IPA installierbar – das ist eine Vorgabe von iOS, keine Einschränkung des Projekts. Der CI-Build prüft außerdem, ob der Swift-Code kompiliert; auf Windows ist das nicht möglich.

## Hinweise

- Schrittzähler und Aktivitätserkennung beginnen mit den Werten seit Mitternacht.
- Kadenz und Pace liefert das Pedometer nur während aktiver Bewegung.
- Der Schallpegel ist ein relativer dBFS-Wert (0 dB = Vollaussteuerung), keine kalibrierte Schalldruckmessung. Es werden keine Aufnahmen gespeichert.
- Die App ist für iOS 17+ ausgelegt und nutzt die SwiftUI-App-Lifecycle-Struktur ohne Storyboard.
- Auf diesem Windows-Rechner wurde das Projekt erstellt, aber nicht kompiliert – der erste Build sollte in Xcode oder über den Actions-Workflow erfolgen.
