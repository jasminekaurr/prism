// Summary: Goal detail — pace, milestones, linked aspirations, add progress.

import SwiftUI

struct GoalDetailView: View {
    let goalID: UUID
    @EnvironmentObject private var container: DependencyContainer
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss

    @State private var goal: PrismGoal?
    @State private var pace: GoalPaceSnapshot?
    @State private var milestones: [GoalMilestone] = []
    @State private var contributions: [GoalContribution] = []

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                if let goal, let pace {
                    ScrollView {
                        VStack(alignment: .leading, spacing: PrismSpacing.md) {
                            Text(goal.title).font(PrismTypography.title())
                            HStack {
                                TagPill(text: goal.priority.displayName, color: PrismColors.tagWant)
                                TagPill(text: pace.trackStatus.displayName, color: PrismColors.lavender, filled: false)
                            }

                            progressBlock(goal: goal, pace: pace)

                            if let motivation = goal.motivation {
                                GlassCard {
                                    SectionMicroLabel(text: "Why it matters")
                                    Text(goal.customMotivation ?? motivation.displayName)
                                        .font(PrismTypography.body())
                                }
                            }

                            if !milestones.isEmpty {
                                Text("Milestones").font(PrismTypography.headline())
                                ForEach(milestones) { m in
                                    HStack {
                                        Image(systemName: m.isCompleted ? "checkmark.circle.fill" : "circle")
                                        Text(m.title)
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                            if !contributions.isEmpty {
                                Text("Recent progress").font(PrismTypography.headline())
                                ForEach(contributions.prefix(5)) { c in
                                    Text(contributionLine(c, currency: goal.currencyCode))
                                        .font(PrismTypography.caption())
                                        .foregroundStyle(PrismColors.textSecondary)
                                }
                            }

                            PrismPrimaryButton(title: "Add progress") {
                                router.sheet = .addProgress(goal.id)
                            }
                            .accessibilityIdentifier("goalDetail.addProgress")
                        }
                        .padding()
                    }
                } else {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task { await load() }
        .onChange(of: router.sheet) { _, new in
            if new == nil { Task { await load() } }
        }
    }

    private func progressBlock(goal: PrismGoal, pace: GoalPaceSnapshot) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                if let target = goal.targetAmount {
                    Text("\(CurrencyFormatting.string(from: goal.amountSaved, currencyCode: goal.currencyCode)) of \(CurrencyFormatting.string(from: target, currencyCode: goal.currencyCode))")
                        .font(PrismTypography.title(22))
                    ProgressView(value: (pace.percentFunded ?? 0) / 100)
                        .tint(PrismColors.lavender)
                }
                if let rem = pace.remaining {
                    Text("Remaining \(CurrencyFormatting.string(from: rem, currencyCode: goal.currencyCode))")
                }
                if let required = pace.requiredPerPeriod {
                    Text("\(CurrencyFormatting.string(from: required, currencyCode: goal.currencyCode)) needed this \(pace.periodLabel)")
                        .foregroundStyle(PrismColors.textSecondary)
                }
                if let date = goal.targetDate {
                    Text(date, style: .date)
                        .font(PrismTypography.caption())
                        .foregroundStyle(PrismColors.textTertiary)
                }
            }
        }
    }

    private func contributionLine(_ c: GoalContribution, currency: String) -> String {
        switch c.kind {
        case .financial:
            if let amount = c.amount {
                return "\(CurrencyFormatting.string(from: amount, currencyCode: currency)) · \(c.note ?? "Contribution")"
            }
            return c.note ?? "Contribution"
        case .planning, .behavioral:
            return "\(c.kind.displayName): \(c.note ?? "Progress")"
        }
    }

    private func load() async {
        goal = try? await container.goalRepository.fetch(id: goalID)
        if let goal {
            pace = container.goalPlanningService.pace(for: goal)
            milestones = (try? await container.goalRepository.fetchMilestones(goalID: goal.id)) ?? []
            contributions = (try? await container.goalRepository.fetchContributions(goalID: goal.id)) ?? []
        }
    }
}
