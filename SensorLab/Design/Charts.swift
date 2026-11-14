import SwiftUI

// MARK: - Liniendiagramm

struct ChartSeries: Identifiable {
    let id: String
    let label: String
    let color: Color
    let values: [Double]
}

struct LineChart: View {
    let series: [ChartSeries]
    var height: CGFloat = 150
    var fixedRange: ClosedRange<Double>? = nil
    var showFill: Bool = true

    private var domain: ClosedRange<Double> {
        if let fixedRange = fixedRange { return fixedRange }
        let all = series.flatMap { $0.values }
        guard let minValue = all.min(), let maxValue = all.max() else { return -1...1 }
        var span = maxValue - minValue
        if span < 0.0001 { span = 1 }
        let padding = span * 0.18
        return (minValue - padding)...(maxValue + padding)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                grid(size: geo.size)
                ForEach(series) { item in
                    chartShape(for: item, size: geo.size)
                }
            }
        }
        .frame(height: height)
    }

    private func grid(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            for index in 0...4 {
                let y = canvasSize.height * CGFloat(index) / 4
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                context.stroke(path, with: .color(.white.opacity(0.055)), lineWidth: 1)
            }
            if domain.lowerBound < 0 && domain.upperBound > 0 {
                let span = domain.upperBound - domain.lowerBound
                let y = canvasSize.height * CGFloat(domain.upperBound / span)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: canvasSize.width, y: y))
                context.stroke(path, with: .color(.white.opacity(0.14)), lineWidth: 1)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    @ViewBuilder
    private func chartShape(for item: ChartSeries, size: CGSize) -> some View {
        let pts = points(for: item.values, in: size)
        if pts.count > 1 {
            if showFill {
                fillPath(pts, in: size)
                    .fill(
                        LinearGradient(
                            colors: [item.color.opacity(0.28), item.color.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            linePath(pts)
                .stroke(
                    item.color,
                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
                )
                .shadow(color: item.color.opacity(0.5), radius: 3)
        }
    }

    private func points(for values: [Double], in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty else { return [] }
        let range = domain
        let span = max(range.upperBound - range.lowerBound, 0.000001)
        let stepX = values.count > 1 ? size.width / CGFloat(values.count - 1) : size.width
        let insetY: CGFloat = 8
        let usable = max(size.height - insetY * 2, 1)

        var result: [CGPoint] = []
        result.reserveCapacity(values.count)
        for (index, value) in values.enumerated() {
            let ratio = (value - range.lowerBound) / span
            let y = insetY + usable * CGFloat(1 - ratio)
            result.append(CGPoint(x: CGFloat(index) * stepX, y: min(max(y, 0), size.height)))
        }
        return result
    }

    private func linePath(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        guard points.count > 1 else { return path }
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let middle = CGPoint(x: (previous.x + current.x) / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: middle, control: previous)
        }
        if let last = points.last {
            path.addLine(to: last)
        }
        return path
    }

    private func fillPath(_ points: [CGPoint], in size: CGSize) -> Path {
        var path = linePath(points)
        guard let first = points.first, let last = points.last else { return path }
        path.addLine(to: CGPoint(x: last.x, y: size.height))
        path.addLine(to: CGPoint(x: first.x, y: size.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Ring

struct RingGauge: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 9

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            Circle()
                .trim(from: 0, to: min(max(progress, 0.001), 0.999))
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.55), color, color.opacity(0.75)],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.45), radius: 8)
        }
    }
}

// MARK: - Balken

struct MeterBar: View {
    let level: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.07))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.7), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(6, geo.size.width * min(max(level, 0), 1)))
                    .shadow(color: tint.opacity(0.5), radius: 6)
            }
        }
        .frame(height: 10)
    }
}

// MARK: - Wellenform

struct Waveform: View {
    let values: [Double]
    let color: Color

    var body: some View {
        Canvas { context, size in
            guard !values.isEmpty else { return }
            let step = size.width / CGFloat(values.count)
            for (index, value) in values.enumerated() {
                let amplitude = CGFloat(min(max(value, 0), 1))
                let barHeight = max(2, amplitude * size.height)
                let rect = CGRect(
                    x: CGFloat(index) * step,
                    y: (size.height - barHeight) / 2,
                    width: max(step * 0.5, 1),
                    height: barHeight
                )
                let path = Path(roundedRect: rect, cornerRadius: max(step * 0.25, 0.5))
                context.fill(path, with: .color(color.opacity(0.75)))
            }
        }
        .frame(height: 44)
    }
}
