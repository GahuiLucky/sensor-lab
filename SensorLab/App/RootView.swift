import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case studio
    case motion
    case location
    case activity
    case environment

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Übersicht"
        case .studio: return "Studio"
        case .motion: return "Bewegung"
        case .location: return "Standort"
        case .activity: return "Aktivität"
        case .environment: return "Umgebung"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .studio: return "hammer.fill"
        case .motion: return "gyroscope"
        case .location: return "location.fill"
        case .activity: return "figure.walk"
        case .environment: return "gauge"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var engine: SensorEngine
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var showTabs = false
    @State private var tab: AppTab = .dashboard

    var body: some View {
        ZStack {
            if showTabs || hasOnboarded {
                content
            } else {
                WelcomeView { demo in
                    hasOnboarded = true
                    engine.start(demo: demo)
                    showTabs = true
                }
            }
        }
        .onAppear {
            if hasOnboarded {
                showTabs = true
                engine.start()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        Group {
            switch tab {
            case .dashboard:
                DashboardView()
            case .studio:
                StudioView()
            case .motion:
                MotionView()
            case .location:
                LocationView()
            case .activity:
                ActivityView()
            case .environment:
                EnvironmentView()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            tabBar
        }
    }

    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(AppTab.allCases) { item in
                tabButton(item)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.45), radius: 18, x: 0, y: 8)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private func tabButton(_ item: AppTab) -> some View {
        Button {
            tab = item
        } label: {
            VStack(spacing: 4) {
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(height: 19)
                Text(item.title)
                    .font(.system(size: 8, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(tab == item ? Theme.cyan : Color.white.opacity(0.38))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(tab == item ? Theme.cyan.opacity(0.13) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
