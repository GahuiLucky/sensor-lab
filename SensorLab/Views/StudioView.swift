import SwiftUI

struct StudioView: View {
    @EnvironmentObject private var engine: SensorEngine
    @EnvironmentObject private var store: ToolStore

    @State private var runningTool: SensorTool?
    @State private var editorDraft: SensorTool?
    @State private var isCreating = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    introCard

                    if store.tools.isEmpty {
                        emptyState
                    } else {
                        toolGrid
                    }

                    footnote
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
        }
        .sheet(item: $editorDraft) { draft in
            ToolEditorView(tool: draft) { saved in
                if isCreating {
                    store.add(saved)
                } else {
                    store.update(saved)
                }
            }
            .environmentObject(engine)
        }
        .fullScreenCover(item: $runningTool) { tool in
            ToolRunnerView(toolID: tool.id)
                .environmentObject(engine)
                .environmentObject(store)
        }
    }

    // MARK: - Kopf

    private var header: some View {
        HStack(alignment: .center, spacing: 9) {
            ScreenTitle(title: "Studio", subtitle: "Baukasten für Sensortools")
            Spacer(minLength: 4)
            LivePill(isLive: !engine.isPaused)

            Menu {
                Button {
                    isCreating = true
                    editorDraft = SensorTool.blank()
                } label: {
                    Label("Eigenes Tool", systemImage: "plus")
                }
                Button {
                    store.resetPresets()
                } label: {
                    Label("Vorlagen wiederherstellen", systemImage: "arrow.counterclockwise")
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.cyan.opacity(0.20)))
                    .overlay(Circle().strokeBorder(Theme.cyan.opacity(0.45), lineWidth: 1))
            }
        }
    }

    private var introCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Sensordaten zu eigenen Werkzeugen machen")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Quelle wählen, Signal umformen, Darstellung festlegen. Alles läuft live auf dem Gerät und bleibt lokal gespeichert.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 7) {
                    flowTag("Quelle")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.25))
                    flowTag("Form")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.25))
                    flowTag("Darstellung")
                }
            }
        }
    }

    private func flowTag(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.white.opacity(0.65))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.white.opacity(0.07)))
    }

    // MARK: - Tools

    private var toolGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(store.tools) { tool in
                Button {
                    runningTool = tool
                } label: {
                    ToolCardView(tool: tool, engine: engine)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        isCreating = false
                        editorDraft = tool
                    } label: {
                        Label("Bearbeiten", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        store.delete(tool)
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 28))
                .foregroundStyle(Theme.cyan.opacity(0.7))
            Text("Noch kein Tool gebaut")
                .font(.system(size: 14, weight: .semibold))
            Text("Erstelle dein erstes Werkzeug aus einer Sensorquelle.")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
            Button {
                isCreating = true
                editorDraft = SensorTool.blank()
            } label: {
                Text("Tool erstellen")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(red: 0.02, green: 0.06, blue: 0.10))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Theme.cyan))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Theme.cyan.opacity(0.15), lineWidth: 1)
        )
    }

    private var footnote: some View {
        Text("Tipp: Karten lange drücken zum Bearbeiten oder Löschen. Alarm-Tools lösen haptisches Feedback aus, sobald der Wert die Schwelle über- oder unterschreitet.")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.white.opacity(0.3))
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Tool-Karte

struct ToolCardView: View {
    let tool: SensorTool
    let engine: SensorEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle()
                        .fill(tool.color.opacity(0.16))
                        .frame(width: 34, height: 34)
                    Image(systemName: tool.symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tool.color)
                }
                Spacer(minLength: 0)
                Image(systemName: tool.visualization.symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.3))
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(tool.formatted(previewValue))
                    .monoValue(22, weight: .bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                Text(tool.unit)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(1)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tool.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                Text(tool.source.title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.35))
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(tool.color.opacity(0.22), lineWidth: 1)
        )
    }

    private var previewValue: Double {
        var raw = tool.source.value(in: engine)
        if tool.transform == .absolute {
            raw = abs(raw)
        }
        return tool.scaledValue(raw)
    }
}
