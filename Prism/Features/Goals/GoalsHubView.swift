// Summary: Goals hub — primary/active goals and paused/finished (moved off Home for Figma feed).

import SwiftUI

struct GoalsHubView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer

    @State private var goals: [PrismGoal] = []

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismSpacing.lg) {
                        PrismTopBar()
                        HStack {
                            Text("Working toward")
                                .font(PrismTypography.title(22))
                            Spacer()
                            Button("New goal") {
                                router.sheet = .goalSetup(nil)
                            }
                            .font(PrismTypography.caption())
                            .accessibilityIdentifier("home.newGoal")
                        }
                        .padding(.horizontal, PrismSpacing.md)

                        if primaryGoal == nil && activeGoals.isEmpty {
                            GlassCard {
                                EmptyStateView(
                                    title: "Turn inspiration into a goal",
                                    message: "When something matters enough, make it a goal — with a target, a date, and progress you control.",
                                    actionTitle: "Make a goal",
                                    action: { router.sheet = .goalSetup(nil) }
                                )
                            }
                            .padding(.horizontal, PrismSpacing.md)
                            .accessibilityIdentifier("home.goalsEmpty")
                        } else {
                            if let primary = primaryGoal {
                                Button {
                                    router.sheet = .goalDetail(primary.id)
                                } label: {
                                    GoalCardView(goal: primary, pace: container.goalPlanningService.pace(for: primary), isPrimary: true)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, PrismSpacing.md)
                                .accessibilityIdentifier("home.primaryGoal")
                            }
                            ForEach(activeGoals.filter { $0.id != primaryGoal?.id }) { goal in
                                Button {
                                    router.sheet = .goalDetail(goal.id)
                                } label: {
                                    GoalCardView(goal: goal, pace: container.goalPlanningService.pace(for: goal), isPrimary: false)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, PrismSpacing.md)
                            }
                        }

                        let pausedFinished = goals.filter {
                            $0.trackStatus == .paused || $0.trackStatus == .completed || $0.trackStatus == .abandoned
                        }
                        if !pausedFinished.isEmpty {
                            Text("Paused & finished")
                                .font(PrismTypography.headline())
                                .padding(.horizontal, PrismSpacing.md)
                            ForEach(pausedFinished) { goal in
                                Button {
                                    router.sheet = .goalDetail(goal.id)
                                } label: {
                                    GoalCardView(goal: goal, pace: container.goalPlanningService.pace(for: goal), isPrimary: false)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, PrismSpacing.md)
                            }
                        }
                    }
                    .padding(.bottom, PrismSpacing.xl)
                }
                .prismTransparentBackground()
            }
            .prismClearChrome()
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await reload() }
        .onChange(of: router.sheet) { _, new in
            if new == nil { Task { await reload() } }
        }
    }

    private var primaryGoal: PrismGoal? {
        goals.first { $0.priority == .primary && $0.trackStatus != .completed && $0.trackStatus != .abandoned }
    }

    private var activeGoals: [PrismGoal] {
        goals.filter {
            ($0.priority == .active || $0.priority == .primary)
                && $0.trackStatus != .completed
                && $0.trackStatus != .abandoned
                && $0.trackStatus != .paused
        }
    }

    private func reload() async {
        guard let userID = environment.profile?.id else { return }
        goals = (try? await container.goalRepository.fetchAll(userID: userID)) ?? []
    }
}

struct GoalCardView: View {
    let goal: PrismGoal
    let pace: GoalPaceSnapshot
    var isPrimary: Bool

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: PrismSpacing.sm) {
                HStack {
                    if isPrimary {
                        TagPill(text: "Primary", color: PrismColors.tagFashion)
                    }
                    TagPill(text: pace.trackStatus.displayName, color: PrismColors.lavender, filled: false)
                    Spacer()
                }
                Text(goal.title)
                    .font(PrismTypography.title(22))
                    .foregroundStyle(PrismColors.textPrimary)
                if let target = goal.targetAmount {
                    Text("\(CurrencyFormatting.string(from: goal.amountSaved, currencyCode: goal.currencyCode)) of \(CurrencyFormatting.string(from: target, currencyCode: goal.currencyCode))")
                        .font(PrismTypography.headline())
                    ProgressView(value: (pace.percentFunded ?? 0) / 100)
                        .tint(PrismColors.cyan)
                }
                if let required = pace.requiredPerPeriod {
                    Text("\(CurrencyFormatting.string(from: required, currencyCode: goal.currencyCode)) needed this \(pace.periodLabel)")
                        .font(PrismTypography.caption())
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
}
