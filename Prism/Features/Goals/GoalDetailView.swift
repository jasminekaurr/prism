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
    @State private var components: [GoalComponent] = []
    @State private var showCompletion = false
    @State private var completionPrompted = false
    @State private var confirmAbandon = false

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

                            if let rating = goal.outcomeRating {
                                GlassCard {
                                    SectionMicroLabel(text: "How it turned out")
                                    Text(rating.displayName)
                                        .font(PrismTypography.headline())
                                    if let note = goal.outcomeNote {
                                        Text(note)
                                            .font(PrismTypography.body())
                                            .foregroundStyle(PrismColors.textSecondary)
                                    }
                                }
                                .accessibilityIdentifier("goalDetail.outcome")
                            }

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

                            if !components.isEmpty {
                                Text("Plan components").font(PrismTypography.headline())
                                ForEach(components) { c in
                                    HStack {
                                        Text(c.name)
                                        Spacer()
                                        if let cost = c.estimatedCost {
                                            Text("Est. \(CurrencyFormatting.string(from: cost, currencyCode: c.currencyCode ?? goal.currencyCode))")
                                                .foregroundStyle(PrismColors.textSecondary)
                                        }
                                    }
                                    .font(PrismTypography.caption())
                                }
                                Text("Component costs are your own estimates, not confirmed prices.")
                                    .font(PrismTypography.caption())
                                    .foregroundStyle(PrismColors.textTertiary)
                            }

                            if !contributions.isEmpty {
                                Text("Recent progress").font(PrismTypography.headline())
                                ForEach(contributions.prefix(5)) { c in
                                    Text(contributionLine(c, currency: goal.currencyCode))
                                        .font(PrismTypography.caption())
                                        .foregroundStyle(PrismColors.textSecondary)
                                }
                            }

                            if goal.trackStatus != .completed && goal.trackStatus != .abandoned {
                                PrismPrimaryButton(title: "Add progress") {
                                    router.sheet = .addProgress(goal.id)
                                }
                                .accessibilityIdentifier("goalDetail.addProgress")
                            }

                            lifecycleActions(goal: goal)
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
        .sheet(isPresented: $showCompletion, onDismiss: { Task { await load() } }) {
            GoalCompletionView(goalID: goalID)
        }
        .confirmationDialog("Abandon this goal?", isPresented: $confirmAbandon, titleVisibility: .visible) {
            Button("Abandon goal", role: .destructive) {
                Task { await abandon() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("It stays in your history. Nothing is deleted.")
        }
    }

    @ViewBuilder
    private func lifecycleActions(goal: PrismGoal) -> some View {
        if goal.trackStatus == .completed {
            if goal.outcomeRating == nil {
                Button("Reflect on this goal") { showCompletion = true }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("goalDetail.reflect")
            }
        } else if goal.trackStatus != .abandoned {
            HStack {
                Button("Mark complete") { Task { await complete() } }
                    .accessibilityIdentifier("goalDetail.complete")
                if goal.trackStatus == .paused {
                    Button("Resume") { Task { await resume() } }
                        .accessibilityIdentifier("goalDetail.resume")
                } else {
                    Button("Pause") { Task { await pause() } }
                        .accessibilityIdentifier("goalDetail.pause")
                }
                Button("Abandon", role: .destructive) { confirmAbandon = true }
                    .accessibilityIdentifier("goalDetail.abandon")
            }
            .buttonStyle(.bordered)
            .font(PrismTypography.caption())
        }
    }

    private func complete() async {
        guard let goal else { return }
        try? await container.goalRepository.upsert(container.goalPlanningService.markComplete(goal))
        container.analytics.track(.goalCompleted)
        PrismHaptics.save()
        await load()
    }

    private func pause() async {
        guard let goal else { return }
        try? await container.goalRepository.upsert(container.goalPlanningService.pause(goal))
        await load()
    }

    private func resume() async {
        guard let goal else { return }
        try? await container.goalRepository.upsert(container.goalPlanningService.resume(goal))
        await load()
    }

    private func abandon() async {
        guard let goal else { return }
        try? await container.goalRepository.upsert(container.goalPlanningService.abandon(goal))
        await load()
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
            components = (try? await container.goalRepository.fetchComponents(goalID: goal.id)) ?? []
            if goal.trackStatus == .completed && goal.outcomeRating == nil && !completionPrompted {
                completionPrompted = true
                showCompletion = true
            }
        }
    }
}

/// Celebration plus one gentle question. Skippable; the outcome stays on the device.
struct GoalCompletionView: View {
    let goalID: UUID
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var goal: PrismGoal?
    @State private var rating: GoalOutcomeRating?
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(spacing: PrismSpacing.md) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 44))
                            .foregroundStyle(PrismColors.warmLight)
                        Text("You made it happen")
                            .font(PrismTypography.title())
                            .accessibilityIdentifier("goalCompletion.title")
                        if let goal {
                            Text(goal.title)
                                .font(PrismTypography.headline())
                                .multilineTextAlignment(.center)
                            if let reason = goal.customMotivation ?? goal.motivation?.displayName {
                                Text("You started this because: \(reason)")
                                    .font(PrismTypography.caption())
                                    .foregroundStyle(PrismColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        Text("Was it worth it?")
                            .font(PrismTypography.title(22))
                            .padding(.top, PrismSpacing.sm)
                        ForEach(GoalOutcomeRating.allCases) { option in
                            Button {
                                rating = option
                            } label: {
                                HStack {
                                    Text(option.displayName)
                                    Spacer()
                                    if rating == option { Image(systemName: "checkmark.circle.fill") }
                                }
                                .padding(12)
                                .background {
                                    RoundedRectangle(cornerRadius: PrismRadius.md)
                                        .stroke(rating == option ? PrismColors.lavender : PrismColors.glassStroke)
                                }
                            }
                            .buttonStyle(.plain)
                            .frame(minHeight: 44)
                            .accessibilityIdentifier("goalCompletion.\(option.rawValue)")
                        }
                        TextField("Anything you learned? (optional)", text: $note, axis: .vertical)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))

                        PrismPrimaryButton(title: "Save reflection") {
                            Task { await save() }
                        }
                        .disabled(rating == nil)
                        .accessibilityIdentifier("goalCompletion.save")

                        Button("Skip for now") { dismiss() }
                            .foregroundStyle(PrismColors.textSecondary)
                            .frame(minHeight: 44)
                    }
                    .padding()
                }
            }
        }
        .task {
            goal = try? await container.goalRepository.fetch(id: goalID)
            rating = goal?.outcomeRating
            note = goal?.outcomeNote ?? ""
        }
    }

    private func save() async {
        guard let goal, let rating else { return }
        let updated = container.goalPlanningService.recordOutcome(goal, rating: rating, note: note)
        try? await container.goalRepository.upsert(updated)
        container.analytics.track(.goalOutcomeRecorded)
        PrismHaptics.save()
        dismiss()
    }
}
