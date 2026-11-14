import Foundation
import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var engine: SensorEngine

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    if !engine.availability.stepCounting && !engine.demoMode {
                        UnavailableBanner(
                            title: "Kein Schrittzähler",
                            message: "Der Simulator unterstützt keine Pedometerdaten. Aktiviere den Demo-Modus in den Einstellungen."
                        )
                    }

                    activityCard
                    stepsCard

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        MetricTile(
                            title: "Kadenz",
                            value: engine.cadence > 0 ? engine.cadence.fixed(0) : "–",
                            unit: "S/min",
                            icon: "figure.walk",
                            tint: Theme.green
                        )
                        MetricTile(
                            title: "Pace",
                            value: paceText,
                            unit: "min/km",
                            icon: "stopwatch",
                            tint: Theme.cyan
                        )
                        MetricTile(
                            title: "Distanz",
                            value: (engine.distance / 1000).fixed(2),
                            unit: "km",
                            icon: "map",
                            tint: Theme.violet
                        )
                        MetricTile(
                            title: "Schritte",
                            value: engine.steps.grouped,
                            unit: "",
                            icon: "shoeprints.fill",
                            tint: Theme.green
                        )
                        MetricTile(
                            title: "Etagen auf",
                            value: "\(engine.floorsUp)",
                            unit: "",
                            icon: "arrow.up",
                            tint: Theme.amber
                        )
                        MetricTile(
                            title: "Etagen ab",
                            value: "\(engine.floorsDown)",
                            unit: "",
                            icon: "arrow.down",
                            tint: Theme.pink
                        )
                    }

                    Text("Schritte und Distanz werden seit Mitternacht gezählt. Kadenz und Pace liefert das Pedometer nur während der Bewegung.")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            ScreenTitle(title: "Aktivität", subtitle: "Pedometer · Bewegungserkennung")
            Spacer()
            LivePill(isLive: !engine.isPaused)
        }
    }

    private var activityCard: some View {
        Card {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(engine.activityKind.tint.opacity(0.15))
                        .frame(width: 76, height: 76)
                    Circle()
                        .strokeBorder(engine.activityKind.tint.opacity(0.35), lineWidth: 1)
                        .frame(width: 76, height: 76)
                    Image(systemName: engine.activityKind.symbol)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(engine.activityKind.tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("AKTUELLE AKTIVITÄT")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(.white.opacity(0.4))
                    Text(engine.activityKind.title)
                        .font(.system(size: 23, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(activityDetail)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var activityDetail: String {
        if engine.demoMode { return "Simulierte Aktivität · Demo-Modus" }
        var parts: [String] = []
        if !engine.activityConfidence.isEmpty {
            parts.append("Konfidenz \(engine.activityConfidence)")
        }
        if let since = engine.activitySince {
            parts.append("seit \(since.formatted(date: .omitted, time: .shortened))")
        }
        if parts.isEmpty { return "Warte auf Bewegung …" }
        return parts.joined(separator: " · ")
    }

    private var stepsCard: some View {
        Card(title: "Heute", icon: "figure.walk", tint: Theme.green) {
            HStack(spacing: 20) {
                ZStack {
                    RingGauge(progress: engine.stepsProgress, color: Theme.green, lineWidth: 12)
                        .frame(width: 120, height: 120)
                    VStack(spacing: 1) {
                        Text(engine.steps.grouped)
                            .monoValue(25, weight: .bold)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text("Schritte")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    ValueRow(label: "Ziel", value: "10.000", tint: Theme.green)
                    ValueRow(label: "Distanz", value: "\((engine.distance / 1000).fixed(2)) km", tint: Theme.cyan)
                    ValueRow(label: "Etagen", value: "\(engine.floorsUp) ↑ · \(engine.floorsDown) ↓")
                    ValueRow(
                        label: "Fortschritt",
                        value: "\(Int(engine.stepsProgress * 100)) %",
                        tint: Theme.violet
                    )
                }
            }
        }
    }

    private var paceText: String {
        guard engine.pace > 0 else { return "–" }
        let secondsPerKilometer = engine.pace * 1000
        let minutes = Int(secondsPerKilometer) / 60
        let seconds = Int(secondsPerKilometer) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
