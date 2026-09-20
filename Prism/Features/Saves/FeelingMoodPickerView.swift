// Summary: Apple Journal–style mood picker — morphing orb + valence slider → emotion chips (Prism palette).

import SwiftUI

// MARK: - Valence

enum MoodValence: Int, CaseIterable, Identifiable, Sendable {
    case veryUnpleasant
    case unpleasant
    case neutral
    case pleasant
    case veryPleasant

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .veryUnpleasant: return "Very unpleasant"
        case .unpleasant: return "Unpleasant"
        case .neutral: return "Neutral"
        case .pleasant: return "Pleasant"
        case .veryPleasant: return "Very pleasant"
        }
    }

    /// 0…1 position on the slider.
    var position: Double { Double(rawValue) / Double(MoodValence.allCases.count - 1) }

    static func nearest(to position: Double) -> MoodValence {
        let clamped = min(1, max(0, position))
        let idx = Int((clamped * Double(allCases.count - 1)).rounded())
        return allCases[min(allCases.count - 1, max(0, idx))]
    }

    /// Prism-tinted glow for this valence.
    var palette: MoodPalette {
        switch self {
        case .veryUnpleasant:
            return MoodPalette(core: PrismColors.magenta, mid: PrismColors.danger, glow: PrismColors.violet)
        case .unpleasant:
            return MoodPalette(core: PrismColors.violet, mid: PrismColors.magenta.opacity(0.85), glow: PrismColors.violetSoft)
        case .neutral:
            return MoodPalette(core: PrismColors.cyan, mid: PrismColors.lavender, glow: PrismColors.violetSoft)
        case .pleasant:
            return MoodPalette(core: PrismColors.statusAmber, mid: PrismColors.warmLight, glow: PrismColors.statusAmberSoft)
        case .veryPleasant:
            return MoodPalette(core: PrismColors.statusGreenSoft, mid: PrismColors.cyan, glow: PrismColors.statusGreen)
        }
    }

    /// Soft roundness (0 = circle → higher = rounded petals). Wide range so morph animates clearly.
    var starness: CGFloat {
        switch self {
        case .veryUnpleasant: return 0.22
        case .unpleasant: return 0.18
        case .neutral: return 0.02
        case .pleasant: return 0.42
        case .veryPleasant: return 0.62
        }
    }

    var emotionNames: [String] {
        switch self {
        case .veryUnpleasant, .unpleasant:
            return [
                "Angry", "Anxious", "Ashamed", "Disappointed",
                "Frustrated", "Lonely", "Overwhelmed", "Sad",
                "Scared", "Stressed", "Tired", "Worried"
            ]
        case .neutral:
            return [
                "Calm", "Content", "Curious", "Indifferent",
                "Okay", "Peaceful", "Reflective", "Surprised"
            ]
        case .pleasant, .veryPleasant:
            return [
                "Amazed", "Excited", "Surprised", "Passionate",
                "Happy", "Joyful", "Brave", "Proud",
                "Confident", "Hopeful", "Grateful", "Inspired"
            ]
        }
    }
}

struct MoodPalette: Equatable, Sendable {
    let core: Color
    let mid: Color
    let glow: Color
}

// MARK: - Persistence helper (valence without schema change)

enum MoodValenceStore {
    private static func key(_ itemID: UUID) -> String { "prism.moodValence.\(itemID.uuidString)" }
    private static func versionKey(_ itemID: UUID) -> String { "prism.moodValence.v2.\(itemID.uuidString)" }

    static func load(itemID: UUID) -> MoodValence? {
        guard UserDefaults.standard.object(forKey: key(itemID)) != nil else { return nil }
        let raw = UserDefaults.standard.integer(forKey: key(itemID))
        if UserDefaults.standard.bool(forKey: versionKey(itemID)) {
            return MoodValence(rawValue: raw)
        }
        // Former 7-state scale → 5-state.
        let migrated: MoodValence?
        switch raw {
        case 0: migrated = .veryUnpleasant
        case 1, 2: migrated = .unpleasant
        case 3: migrated = .neutral
        case 4, 5: migrated = .pleasant
        case 6: migrated = .veryPleasant
        default: migrated = MoodValence(rawValue: raw)
        }
        if let migrated {
            save(migrated, itemID: itemID)
        }
        return migrated
    }

    static func save(_ valence: MoodValence, itemID: UUID) {
        UserDefaults.standard.set(valence.rawValue, forKey: key(itemID))
        UserDefaults.standard.set(true, forKey: versionKey(itemID))
    }
}

// MARK: - Compact card preview

struct FeelingMoodCardPreview: View {
    var valence: MoodValence?
    var feelings: [Feeling]
    var action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                MoodOrbView(
                    valence: valence ?? .neutral,
                    size: 56,
                    animated: true,
                    pulse: pulse
                )
                .opacity(valence == nil ? 0.45 : 1)

                if let valence {
                    Text(valence.title)
                        .font(PrismTypography.body(12, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                } else {
                    Text("Tap to feel")
                        .font(PrismTypography.display(14, weight: .light))
                        .foregroundStyle(PrismColors.textTertiary)
                }

                if !feelings.isEmpty {
                    Text(feelings.prefix(2).map(\.name).joined(separator: " · "))
                        .font(PrismTypography.chrome(9.5))
                        .foregroundStyle(Color.white.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(valence.map { "Feeling \($0.title)" } ?? "Choose feeling")
        .accessibilityIdentifier("detail.feelingAttached")
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Full picker sheet

struct FeelingMoodPickerView: View {
    let itemID: UUID
    var initialValence: MoodValence
    var initialFeelings: [Feeling]
    var onDone: (MoodValence, [Feeling]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var step: Step = .valence
    @State private var sliderPosition: Double
    @State private var selectedNames: Set<String>
    @State private var pulse = false

    private enum Step { case valence, describe }

    init(
        itemID: UUID,
        initialValence: MoodValence = .neutral,
        initialFeelings: [Feeling] = [],
        onDone: @escaping (MoodValence, [Feeling]) -> Void
    ) {
        self.itemID = itemID
        self.initialValence = initialValence
        self.initialFeelings = initialFeelings
        self.onDone = onDone
        _sliderPosition = State(initialValue: initialValence.position)
        _selectedNames = State(initialValue: Set(initialFeelings.map(\.name)))
    }

    private var valence: MoodValence { MoodValence.nearest(to: sliderPosition) }

    var body: some View {
        ZStack {
            sheetBackground
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)

                // Keep advance controls outside flexible content so they
                // remain visible on the half-height (.medium) detent.
                HStack {
                    if step == .describe {
                        circleChevron(systemName: "chevron.left") {
                            withAnimation(.easeInOut(duration: PrismMotion.standard)) { step = .valence }
                        }
                    } else {
                        Color.clear.frame(width: 36, height: 36)
                    }
                    Spacer()
                    circleChevron(systemName: step == .valence ? "chevron.right" : "checkmark") {
                        advance()
                    }
                    .accessibilityIdentifier(step == .valence ? "mood.next" : "mood.done")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .layoutPriority(2)

                Group {
                    switch step {
                    case .valence: valenceStep
                    case .describe: describeStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .layoutPriority(1)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationContentInteraction(.scrolls)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var sheetBackground: some View {
        let p = valence.palette
        return ZStack {
            Color(red: 0.12, green: 0.11, blue: 0.14)
            RadialGradient(
                colors: [p.glow.opacity(0.35), p.mid.opacity(0.12), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 280
            )
            .animation(.easeInOut(duration: PrismMotion.gentle), value: valence)
        }
        .ignoresSafeArea()
    }

    private var valenceStep: some View {
        VStack(spacing: 12) {
            Text("Choose how you’re feeling about this save")
                .font(PrismTypography.body(16, weight: .medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer(minLength: 4)

            MoodOrbView(valence: valence, size: 132, animated: true, pulse: pulse)
                .animation(.spring(response: 0.45, dampingFraction: 0.78), value: valence)

            Text(valence.title)
                .font(PrismTypography.body(20, weight: .semibold))
                .contentTransition(.opacity)
                .id(valence.title)

            Spacer(minLength: 4)

            MoodValenceSlider(position: $sliderPosition)
                .padding(.horizontal, 28)
                .padding(.bottom, 12)
        }
        .padding(.top, 4)
    }

    private var describeStep: some View {
        VStack(spacing: 14) {
            MoodOrbView(valence: valence, size: 88, animated: true, pulse: pulse)

            Text(valence.title)
                .font(PrismTypography.body(22, weight: .semibold))

            HStack(spacing: 6) {
                Text("What best describes this feeling?")
                    .font(PrismTypography.body(14))
                    .foregroundStyle(Color.white.opacity(0.88))
            }

            ScrollView {
                WrappingHStack(spacing: 8) {
                    ForEach(valence.emotionNames, id: \.self) { name in
                        emotionChip(name)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .padding(.top, 8)
    }

    private func emotionChip(_ name: String) -> some View {
        let selected = selectedNames.contains(name)
        return Button {
            PrismHaptics.soft()
            if selected { selectedNames.remove(name) }
            else { selectedNames.insert(name) }
        } label: {
            Text(name)
                .font(PrismTypography.body(14, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background {
                    Capsule()
                        .fill(selected ? valence.palette.core.opacity(0.85) : Color.black.opacity(0.45))
                        .overlay {
                            Capsule()
                                .stroke(
                                    selected ? Color.white.opacity(0.55) : Color.white.opacity(0.22),
                                    lineWidth: 1
                                )
                        }
                }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("mood.emotion.\(name.lowercased())")
    }

    private func circleChevron(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white.opacity(0.12)))
        }
        .buttonStyle(.plain)
    }

    private func advance() {
        switch step {
        case .valence:
            PrismHaptics.soft()
            // Drop chips that don’t belong to the new valence band.
            let allowed = Set(valence.emotionNames)
            selectedNames = selectedNames.intersection(allowed)
            withAnimation(.easeInOut(duration: PrismMotion.standard)) { step = .describe }
        case .describe:
            let chosen = Feeling.feelings(named: Array(selectedNames))
            MoodValenceStore.save(valence, itemID: itemID)
            onDone(valence, chosen)
            PrismHaptics.save()
            dismiss()
        }
    }
}

// MARK: - Orb

struct MoodOrbView: View {
    var valence: MoodValence
    var size: CGFloat = 140
    var animated: Bool = true
    var pulse: Bool = false
    @State private var spin = false

    var body: some View {
        let p = valence.palette
        let starness = valence.starness
        ZStack {
            Circle()
                .fill(p.glow.opacity(0.4))
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: size * 0.24)
                .scaleEffect(pulse && animated ? 1.12 : 1.0)

            ForEach(0..<3, id: \.self) { i in
                MoodGlyph(starness: starness, points: 5 + i)
                    .stroke(p.mid.opacity(0.4 - Double(i) * 0.1), lineWidth: 1.5)
                    .frame(width: size * (1.08 - CGFloat(i) * 0.12), height: size * (1.08 - CGFloat(i) * 0.12))
                    .rotationEffect(.degrees(Double(i) * 14 + (spin && animated ? 8 : 0)))
                    .blur(radius: CGFloat(i) + 0.5)
            }

            MoodGlyph(starness: starness, points: 5)
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.95), p.core, p.mid.opacity(0.85)],
                        center: .center,
                        startRadius: 2,
                        endRadius: size * 0.45
                    )
                )
                .frame(width: size * 0.74, height: size * 0.74)
                .shadow(color: p.core.opacity(0.75), radius: size * 0.2)
                .scaleEffect(pulse && animated ? 1.04 : 1.0)

            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: size * 0.18, height: size * 0.18)
                .blur(radius: 4)
                .offset(x: -size * 0.08, y: -size * 0.1)
        }
        .frame(width: size * 1.45, height: size * 1.45)
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: valence)
        .animation(.easeInOut(duration: 2.2), value: pulse)
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true)) {
                spin = true
            }
        }
    }
}

/// Morphs between soft circle and rounded petals (quadratic curves — never sharp stars).
private struct MoodGlyph: Shape {
    var starness: CGFloat
    var points: Int

    var animatableData: CGFloat {
        get { starness }
        set { starness = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        // Inner stays relatively close so petals stay rounded even at high starness.
        let inner = outer * (0.58 + (1 - min(starness, 1)) * 0.38)
        let count = max(points, 3) * 2
        var corners: [CGPoint] = []
        for i in 0..<count {
            let angle = (Double(i) / Double(count)) * .pi * 2 - .pi / 2
            let radius = (i % 2 == 0) ? outer : (outer * (1 - starness) + inner * starness)
            corners.append(CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            ))
        }
        guard corners.count > 2 else { return Path(ellipseIn: rect) }
        var path = Path()
        path.move(to: midpoint(corners[corners.count - 1], corners[0]))
        for i in corners.indices {
            let next = corners[(i + 1) % corners.count]
            path.addQuadCurve(to: midpoint(corners[i], next), control: corners[i])
        }
        path.closeSubpath()
        return path
    }

    private func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }
}

// MARK: - Slider

struct MoodValenceSlider: View {
    @Binding var position: Double

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                let w = geo.size.width
                let thumb: CGFloat = 28
                let x = CGFloat(position) * (w - thumb) + thumb / 2

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                        .frame(height: 12)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    PrismColors.magenta.opacity(0.55),
                                    PrismColors.violet.opacity(0.45),
                                    PrismColors.cyan.opacity(0.45),
                                    PrismColors.statusAmber.opacity(0.55)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(thumb, x + thumb / 2), height: 12)
                        .opacity(0.35)

                    Circle()
                        .fill(Color.white)
                        .frame(width: thumb, height: thumb)
                        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
                        .position(x: x, y: geo.size.height / 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let raw = (value.location.x - thumb / 2) / max(w - thumb, 1)
                            let next = min(1, max(0, raw))
                            if MoodValence.nearest(to: next) != MoodValence.nearest(to: position) {
                                PrismHaptics.soft()
                            }
                            position = next
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                position = MoodValence.nearest(to: position).position
                            }
                        }
                )
            }
            .frame(height: 36)

            HStack {
                Text("Very unpleasant")
                Spacer()
                Text("Very pleasant")
            }
            .font(PrismTypography.chrome(9.5))
            .foregroundStyle(Color.white.opacity(0.45))
            .tracking(0.4)
        }
        .accessibilityIdentifier("mood.slider")
    }
}

// MARK: - Feeling name helpers

extension Feeling {
    /// Resolve emotion chip names to Feeling records (creates stable system IDs when known).
    static func feelings(named names: [String]) -> [Feeling] {
        let catalog = Feeling.moodCatalog
        return names.compactMap { name in
            catalog.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
                ?? Feeling(id: UUID(), name: name, isSystem: false)
        }
    }

    /// Journal-style emotion vocabulary used by the mood picker (includes legacy system feelings).
    static var moodCatalog: [Feeling] {
        var seen = Set<String>()
        var result: [Feeling] = []
        for feeling in systemFeelings + journalEmotions {
            let key = feeling.name.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(feeling)
        }
        return result
    }

    private static let journalEmotions: [Feeling] = {
        let names = [
            "Angry", "Anxious", "Ashamed", "Disappointed", "Frustrated", "Lonely",
            "Overwhelmed", "Sad", "Scared", "Stressed", "Tired", "Worried",
            "Calm", "Content", "Curious", "Indifferent", "Okay", "Peaceful",
            "Reflective", "Surprised",
            "Amazed", "Excited", "Passionate", "Happy", "Joyful", "Brave",
            "Proud", "Confident", "Hopeful", "Grateful", "Inspired"
        ]
        return names.enumerated().map { index, name in
            // Stable UUIDs in a reserved namespace so re-saves match.
            let hex = String(format: "%012X", 0x100 + index)
            let id = UUID(uuidString: "00000000-0000-0000-0001-\(hex)")!
            return Feeling(id: id, name: name, isSystem: true)
        }
    }()
}
