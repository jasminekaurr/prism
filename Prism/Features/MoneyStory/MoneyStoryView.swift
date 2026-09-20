// Summary: Money Story dashboard matching recreation screen 16 — demo narrative UI for now.

import SwiftUI

struct MoneyStoryView: View {
    @EnvironmentObject private var router: AppRouter

    @State private var filter: MoneyStoryTimeFilter = .month

    private var demo: MoneyStoryDemoContent {
        MoneyStoryDemoContent.forFilter(filter)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        filterChips
                        introBlock
                        metricsGrid
                        goalProgressSection
                        attentionCard
                        influenceCard
                        attentionVsIntention
                        howYouDecided
                        howSavesFelt
                        tradeoffsSection
                        nextStepCard
                        footerNote
                    }
                    .padding(.horizontal, PrismSpacing.md)
                    .padding(.bottom, 110)
                }
                .prismTransparentBackground()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .background(Color.clear)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                PrismLogoMark()
                Spacer()
            }
            Text("My Money Story")
                .font(PrismTypography.title(32))
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("moneyStory.title")
        }
        .padding(.top, PrismSpacing.sm)
    }

    private var filterChips: some View {
        PrismSegmentedControl(options: MoneyStoryTimeFilter.allCases, selection: $filter) { storyChipTitle($0) }
            .accessibilityIdentifier("moneyStory.filters")
    }

    private var introBlock: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(demo.headline)
                .font(PrismTypography.title(30))
            Text(demo.subtitle)
                .font(PrismTypography.body(14))
                .foregroundStyle(Color.white.opacity(0.88))
            Text(demo.basis)
                .font(PrismTypography.mono)
                .foregroundStyle(Color.white.opacity(0.5))
        }
    }

    // MARK: - Metrics

    private var metricsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ],
            spacing: 8
        ) {
            ForEach(demo.metrics) { metric in
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.value)
                        .font(PrismTypography.number(24))
                        .foregroundStyle(.white)
                    Text(metric.label)
                        .font(PrismTypography.chrome(10.5))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(PrismColors.glassFill)
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(PrismColors.glassStrokeSoft, lineWidth: 1)
                        }
                }
            }
        }
        .accessibilityIdentifier("moneyStory.metrics")
    }

    // MARK: - Goal progress

    private var goalProgressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GOAL PROGRESS · \(storyChipTitle(filter).uppercased())")
                .font(PrismTypography.mono)
                .tracking(0.6)
                .foregroundStyle(Color.white.opacity(0.55))

            ForEach(demo.goals) { goal in
                VStack(alignment: .leading, spacing: 9) {
                    Text(goal.name)
                        .font(PrismTypography.title(22))
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.2))
                            Capsule()
                                .fill(goal.barColor)
                                .frame(width: geo.size.width * goal.fraction)
                        }
                    }
                    .frame(height: 7)
                    HStack {
                        Text("\(goal.contributed) this month")
                        Spacer()
                        Text("\(goal.percentLabel) funded")
                    }
                    .font(PrismTypography.body(12))
                    .foregroundStyle(Color.white.opacity(0.88))
                }
                .padding(.vertical, 4)
                .padding(.bottom, 10)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 1)
                }
            }
        }
        .accessibilityIdentifier("moneyStory.goalProgress")
    }

    // MARK: - Attention

    private var attentionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    SectionMicroLabel(text: "What caught your attention")
                    Text(demo.attentionHeadline)
                        .font(PrismTypography.title(20))
                }
                VStack(spacing: 8) {
                    ForEach(demo.attentionBars) { bar in
                        HStack(spacing: 10) {
                            Text(bar.label)
                                .font(PrismTypography.chrome(12))
                                .frame(width: 88, alignment: .leading)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.2))
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(bar.color)
                                        .frame(width: geo.size.width * bar.fraction)
                                }
                            }
                            .frame(height: 14)
                            Text("\(bar.count)")
                                .font(PrismTypography.body(14))
                                .frame(width: 18, alignment: .trailing)
                        }
                    }
                }
                Text(demo.attentionNote)
                    .font(PrismTypography.body(12))
                    .foregroundStyle(Color.white.opacity(0.88))
                Text(demo.attentionBasis)
                    .font(PrismTypography.mono)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .accessibilityIdentifier("moneyStory.attention")
    }

    // MARK: - Influence

    private var influenceCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    SectionMicroLabel(text: "What influenced you")
                    Text(demo.influenceHeadline)
                        .font(PrismTypography.title(20))
                }
                HStack(spacing: 8) {
                    Text("SOURCE")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("SAVED")
                        .frame(width: 42, alignment: .trailing)
                    Text("STILL LIVE · 14D")
                        .frame(width: 74, alignment: .trailing)
                    Text("GOALS")
                        .frame(width: 44, alignment: .trailing)
                }
                .font(PrismTypography.chrome(9.5))
                .tracking(0.4)
                .foregroundStyle(Color.white.opacity(0.7))

                ForEach(demo.influenceRows) { row in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(row.source)
                                .font(PrismTypography.chrome(13))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(row.saved)")
                                .frame(width: 42, alignment: .trailing)
                            Text(row.stillLiveLabel)
                                .frame(width: 74, alignment: .trailing)
                            Text("\(row.goals)")
                                .frame(width: 44, alignment: .trailing)
                        }
                        .font(PrismTypography.body(14))
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.2))
                                Capsule()
                                    .fill(Color.white.opacity(0.85))
                                    .frame(width: geo.size.width * row.stillLiveFraction)
                            }
                        }
                        .frame(height: 5)
                    }
                }

                Text("Prism can say a platform preceded a decision — not that it caused one.")
                    .font(PrismTypography.body(12))
                    .foregroundStyle(Color.white.opacity(0.88))
            }
        }
        .accessibilityIdentifier("moneyStory.influence")
    }

    // MARK: - Attention vs intention

    private var attentionVsIntention: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attention vs intention")
                .font(PrismTypography.title(22))
            HStack(alignment: .top, spacing: 10) {
                intentionCard(
                    count: demo.attentionCount,
                    label: "ATTENTION",
                    body: "Saved fast · novelty · Curious or Impulse · often removed",
                    emphasized: false
                )
                intentionCard(
                    count: demo.intentionCount,
                    label: "INTENTION",
                    body: "Revisited · tied to a goal · High or Meaningful · planned or funded",
                    emphasized: true
                )
            }
            Text(demo.attentionVsNote)
                .font(PrismTypography.body(12.5))
                .foregroundStyle(Color.white.opacity(0.88))
        }
        .padding(.vertical, 4)
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
        }
        .accessibilityIdentifier("moneyStory.attentionVsIntention")
    }

    private func intentionCard(count: Int, label: String, body: String, emphasized: Bool) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("\(count)")
                .font(PrismTypography.body(26))
            Text(label)
                .font(PrismTypography.chrome(10.5))
                .tracking(0.6)
                .foregroundStyle(Color.white.opacity(emphasized ? 0.8 : 0.7))
            Text(body)
                .font(PrismTypography.body(11.5))
                .foregroundStyle(Color.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(emphasized ? PrismColors.violet.opacity(0.4) : Color.white.opacity(0.07))
                .overlay {
                    if emphasized {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    }
                }
        }
    }

    // MARK: - How you decided

    private var howYouDecided: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How you decided")
                .font(PrismTypography.title(22))
            HStack(alignment: .center, spacing: 8) {
                flowNode(value: "\(demo.savedCount)", label: "saved")
                Text("→").foregroundStyle(Color.white.opacity(0.6))
                flowNode(value: "\(demo.reviewedCount)", label: "reviewed")
                Text("→").foregroundStyle(Color.white.opacity(0.6))
                VStack(spacing: 5) {
                    ForEach(demo.outcomes) { outcome in
                        HStack {
                            Text(outcome.label)
                                .font(PrismTypography.chrome(10.5))
                            Spacer()
                            Text("\(outcome.count)")
                                .font(PrismTypography.body(14))
                        }
                        .foregroundStyle(outcome.foreground)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(outcome.background)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            Text(demo.decisionNote)
                .font(PrismTypography.body(12.5))
                .foregroundStyle(Color.white.opacity(0.88))
        }
        .padding(.vertical, 4)
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
        }
        .accessibilityIdentifier("moneyStory.decisions")
    }

    private func flowNode(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(PrismTypography.body(22))
            Text(label)
                .font(PrismTypography.chrome(9.5))
                .foregroundStyle(Color.white.opacity(0.78))
        }
        .frame(width: 74)
        .padding(.vertical, 10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.07))
        }
    }

    // MARK: - Feelings

    private var howSavesFelt: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("How saves felt")
                .font(PrismTypography.title(22))
            WrappingHStack(spacing: 7) {
                ForEach(demo.feelings) { feeling in
                    HStack(spacing: 7) {
                        Text(feeling.label)
                        Text("\(feeling.count)")
                            .font(PrismTypography.body(13))
                    }
                    .font(PrismTypography.body(12))
                    .foregroundStyle(feeling.tone.foreground)
                    .padding(.horizontal, 11)
                    .frame(height: 28)
                    .background {
                        Capsule()
                            .fill(feeling.tone.background)
                            .overlay {
                                Capsule().stroke(feeling.tone.border, lineWidth: 1)
                            }
                    }
                }
            }
            Text(demo.feelingsNote)
                .font(PrismTypography.body(12.5))
                .foregroundStyle(Color.white.opacity(0.88))
        }
        .padding(.vertical, 4)
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
        }
        .accessibilityIdentifier("moneyStory.feelings")
    }

    // MARK: - Trade-offs

    private var tradeoffsSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("Trade-offs you made")
                .font(PrismTypography.title(22))
            ForEach(demo.tradeoffs) { tradeoff in
                VStack(alignment: .leading, spacing: 5) {
                    Text(tradeoff.decision)
                        .font(PrismTypography.body(13.5))
                    HStack(alignment: .top, spacing: 7) {
                        Text("→")
                            .font(PrismTypography.body(12))
                            .foregroundStyle(Color.white.opacity(0.55))
                        Text(tradeoff.effect)
                            .font(PrismTypography.body(12.5))
                            .foregroundStyle(tradeoff.effectColor)
                    }
                    if let after = tradeoff.after {
                        Text(after)
                            .font(PrismTypography.mono)
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.bottom, 10)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.white.opacity(0.15)).frame(height: 1)
        }
        .accessibilityIdentifier("moneyStory.tradeoffs")
    }

    // MARK: - Next step

    private var nextStepCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            SectionMicroLabel(text: "One next step")
            Text(demo.nextStep)
                .font(PrismTypography.title(24))
            Text(demo.nextWhy)
                .font(PrismTypography.body(12.5))
                .foregroundStyle(Color.white.opacity(0.88))
            Button {
                router.sheet = .review(nil)
            } label: {
                Text(demo.nextCTA)
                    .font(PrismTypography.body(15))
                    .foregroundStyle(PrismColors.buttonInk)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(PrismColors.buttonDark)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("moneyStory.nextStep")
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 69 / 255, green: 29 / 255, blue: 114 / 255).opacity(0.42))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                }
        }
    }

    private var footerNote: some View {
        Text("Built from your Prism activity only — no connected accounts yet. Spending alignment and post-purchase satisfaction unlock once you confirm purchases.")
            .font(PrismTypography.mono)
            .foregroundStyle(Color.white.opacity(0.45))
            .padding(.bottom, 8)
    }

    private func storyChipTitle(_ f: MoneyStoryTimeFilter) -> String {
        switch f {
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .allTime: return "Over time"
        }
    }
}

// MARK: - Demo content (recreation screen 16)

private struct MoneyStoryDemoContent {
    let headline: String
    let subtitle: String
    let basis: String
    let metrics: [MoneyStoryMetric]
    let goals: [MoneyStoryGoalProgress]
    let attentionHeadline: String
    let attentionBars: [MoneyStoryBar]
    let attentionNote: String
    let attentionBasis: String
    let influenceHeadline: String
    let influenceRows: [MoneyStoryInfluenceRow]
    let attentionCount: Int
    let intentionCount: Int
    let attentionVsNote: String
    let savedCount: Int
    let reviewedCount: Int
    let outcomes: [MoneyStoryOutcome]
    let decisionNote: String
    let feelings: [MoneyStoryFeeling]
    let feelingsNote: String
    let tradeoffs: [MoneyStoryTradeoff]
    let nextStep: String
    let nextWhy: String
    let nextCTA: String

    static func forFilter(_ filter: MoneyStoryTimeFilter) -> MoneyStoryDemoContent {
        switch filter {
        case .week:
            return base(
                headline: "Three decisions, one contribution.",
                subtitle: "You saved 4 ideas and reviewed 3. The $60 you added kept the laptop goal from slipping further.",
                basis: "Based on 4 saves this week",
                metrics: [
                    .init(value: "4", label: "ideas saved"),
                    .init(value: "3", label: "decisions made"),
                    .init(value: "$60", label: "added to goals"),
                    .init(value: "1", label: "purchase reconsidered"),
                    .init(value: "0", label: "milestones")
                ],
                next: "Decide between your two High-priority saves.",
                why: "Both have been open for nine days. Neither is funded.",
                cta: "Open the two saves"
            )
        case .month:
            return base(
                headline: "You chose the goal over the feed.",
                subtitle: "You saved 18 ideas this month, mostly products. The three you kept were tied to goals, and $190 of what you didn’t spend went to Japan.",
                basis: "Based on 18 saves and 9 decisions",
                metrics: [
                    .init(value: "18", label: "ideas saved"),
                    .init(value: "9", label: "decisions made"),
                    .init(value: "$190", label: "redirected to goals"),
                    .init(value: "7", label: "purchases reconsidered"),
                    .init(value: "2", label: "milestones done")
                ],
                next: "Turn your most revisited save into a goal.",
                why: "The Kyoto ryokan has been opened four times in three weeks and still isn’t attached to anything.",
                cta: "Review that save"
            )
        case .allTime:
            return base(
                headline: "Travel keeps winning your attention back.",
                subtitle: "Across six months, travel saves are revisited three times more often than products — and travel is the only category you have funded every single month.",
                basis: "Based on 112 saves since March",
                metrics: [
                    .init(value: "112", label: "ideas saved"),
                    .init(value: "58", label: "decisions made"),
                    .init(value: "$1,740", label: "redirected to goals"),
                    .init(value: "31", label: "purchases reconsidered"),
                    .init(value: "9", label: "milestones done")
                ],
                next: "Archive 14 Someday saves you haven’t opened since June.",
                why: "None were revisited, and none became goals. Clearing them makes the live ones easier to see.",
                cta: "Review the archive"
            )
        }
    }

    private static func base(
        headline: String,
        subtitle: String,
        basis: String,
        metrics: [MoneyStoryMetric],
        next: String,
        why: String,
        cta: String
    ) -> MoneyStoryDemoContent {
        MoneyStoryDemoContent(
            headline: headline,
            subtitle: subtitle,
            basis: basis,
            metrics: metrics,
            goals: [
                .init(name: "Japan, Apr 2027", contributed: "$325", percentLabel: "35%", fraction: 0.35, barColor: .white),
                .init(name: "New laptop", contributed: "$60", percentLabel: "12%", fraction: 0.12, barColor: PrismColors.statusAmber)
            ],
            attentionHeadline: "Style caught your attention most.",
            attentionBars: [
                .init(label: "Products", count: 9, fraction: 1.0, color: PrismColors.violet),
                .init(label: "Experiences", count: 5, fraction: 0.56, color: PrismColors.violet.opacity(0.75)),
                .init(label: "Trips", count: 3, fraction: 0.33, color: PrismColors.violet.opacity(0.5)),
                .init(label: "Places", count: 1, fraction: 0.11, color: PrismColors.violet.opacity(0.3))
            ],
            attentionNote: "Products dominated your feed, but experiences were more likely to become goals.",
            attentionBasis: "Based on 18 saves",
            influenceHeadline: "TikTok inspired the most saves. Pinterest ideas lasted longest.",
            influenceRows: [
                .init(source: "TikTok", saved: 9, stillLiveLabel: "30%", stillLiveFraction: 0.30, goals: 1),
                .init(source: "Instagram", saved: 6, stillLiveLabel: "67%", stillLiveFraction: 0.67, goals: 2),
                .init(source: "Pinterest", saved: 3, stillLiveLabel: "100%", stillLiveFraction: 1.0, goals: 1)
            ],
            attentionCount: 11,
            intentionCount: 7,
            attentionVsNote: "You saved fewer travel ideas than products, but revisited them three times more often.",
            savedCount: 18,
            reviewedCount: 9,
            outcomes: [
                .init(label: "became goals", count: 4, background: PrismTone.done.background, foreground: PrismTone.done.foreground),
                .init(label: "deferred", count: 3, background: PrismTone.priority.background, foreground: PrismTone.priority.foreground),
                .init(label: "removed", count: 2, background: PrismTone.off.background, foreground: PrismTone.off.foreground)
            ],
            decisionNote: "Waiting changed your mind on 60% of what you reviewed after seven days.",
            feelings: [
                .init(label: "Joy", count: 6, tone: .intent),
                .init(label: "Impulse", count: 6, tone: .priority),
                .init(label: "Curious", count: 5, tone: .topic),
                .init(label: "Practical", count: 4, tone: .topic),
                .init(label: "Meaningful", count: 3, tone: .intent),
                .init(label: "Someday", count: 2, tone: .off)
            ],
            feelingsNote: "You marked six saves Impulse, compared with three last month.",
            tradeoffs: [
                .init(decision: "You deferred the $140 sneakers", effect: "Japan stayed on track", effectColor: PrismColors.statusGreenSoft, after: nil),
                .init(decision: "You booked the concert", effect: "Laptop goal moved back two weeks", effectColor: PrismColors.statusAmberSoft, after: "You marked it Meaningful afterward."),
                .init(decision: "You chose the refurbished Air", effect: "Laptop target down $180", effectColor: PrismColors.statusGreenSoft, after: nil)
            ],
            nextStep: next,
            nextWhy: why,
            nextCTA: cta
        )
    }
}

private struct MoneyStoryMetric: Identifiable {
    let id = UUID()
    let value: String
    let label: String
}

private struct MoneyStoryGoalProgress: Identifiable {
    let id = UUID()
    let name: String
    let contributed: String
    let percentLabel: String
    let fraction: CGFloat
    let barColor: Color
}

private struct MoneyStoryBar: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let fraction: CGFloat
    let color: Color
}

private struct MoneyStoryInfluenceRow: Identifiable {
    let id = UUID()
    let source: String
    let saved: Int
    let stillLiveLabel: String
    let stillLiveFraction: CGFloat
    let goals: Int
}

private struct MoneyStoryOutcome: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let background: Color
    let foreground: Color
}

private struct MoneyStoryFeeling: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
    let tone: PrismTone
}

private struct MoneyStoryTradeoff: Identifiable {
    let id = UUID()
    let decision: String
    let effect: String
    let effectColor: Color
    let after: String?
}
