// Summary: Multi-step Make this a goal flow — define, motivate, target, priority, starter plan.

import SwiftUI

struct GoalSetupFlowView: View {
    var sourceItem: SavedItem?
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var title = ""
    @State private var goalDescription = ""
    @State private var type: GoalType = .experience
    @State private var motivation: GoalMotivation = .joy
    @State private var customMotivation = ""
    @State private var targetAmountText = ""
    @State private var alreadySavedText = ""
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
    @State private var frequency: ContributionFrequency = .monthly
    @State private var priority: GoalPriorityLevel = .active
    @State private var includesBuffer = false
    @State private var errorText: String?
    @State private var previewPace: GoalPaceSnapshot?

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismSpacing.md) {
                        Text("Make this a goal")
                            .font(PrismTypography.title())
                            .accessibilityIdentifier("goalSetup.title")

                        Text(stepSubtitle)
                            .font(PrismTypography.caption())
                            .foregroundStyle(PrismColors.textSecondary)

                        switch step {
                        case 0: defineStep
                        case 1: motivationStep
                        case 2: targetStep
                        case 3: priorityStep
                        default: planPreviewStep
                        }

                        if let errorText {
                            Text(errorText).foregroundStyle(PrismColors.danger)
                        }

                        HStack {
                            if step > 0 {
                                Button("Back") { step -= 1 }
                                    .frame(minHeight: 44)
                            }
                            Spacer()
                            if step < 4 {
                                PrismPrimaryButton(title: "Continue") {
                                    withAnimation { step += 1 }
                                    refreshPreview()
                                }
                            } else {
                                PrismPrimaryButton(title: "Create goal") {
                                    Task { await save() }
                                }
                                .accessibilityIdentifier("goalSetup.create")
                            }
                        }
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear {
            if let sourceItem {
                title = sourceItem.title
                goalDescription = sourceItem.reflection ?? sourceItem.notes ?? ""
                if let estimate = sourceItem.estimatedPrice {
                    targetAmountText = "\(estimate)"
                }
                type = inferredType(from: sourceItem)
            }
            refreshPreview()
        }
    }

    private var stepSubtitle: String {
        switch step {
        case 0: return "Step 1 · Define the goal"
        case 1: return "Step 2 · Why it matters"
        case 2: return "Step 3 · Target"
        case 3: return "Step 4 · Priority"
        default: return "Step 5 · Plan preview"
        }
    }

    private var defineStep: some View {
        VStack(alignment: .leading, spacing: PrismSpacing.sm) {
            SectionMicroLabel(text: "What do you want to achieve?")
            TextField("Goal name", text: $title)
                .padding()
                .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                .accessibilityIdentifier("goalSetup.name")
            TextField("Description (optional)", text: $goalDescription, axis: .vertical)
                .padding()
                .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
            SectionMicroLabel(text: "Type")
            Picker("Type", selection: $type) {
                ForEach(GoalType.allCases) { t in
                    Text(t.displayName).tag(t)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var motivationStep: some View {
        VStack(alignment: .leading, spacing: PrismSpacing.sm) {
            Text("Why does this matter to you?")
                .font(PrismTypography.headline())
            ForEach(GoalMotivation.allCases) { m in
                Button {
                    motivation = m
                } label: {
                    HStack {
                        Text(m.displayName)
                        Spacer()
                        if motivation == m { Image(systemName: "checkmark.circle.fill") }
                    }
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: PrismRadius.md)
                            .stroke(motivation == m ? PrismColors.lavender : PrismColors.glassStroke)
                    }
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            }
            if motivation == .custom {
                TextField("Your reason", text: $customMotivation)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
            }
        }
    }

    private var targetStep: some View {
        VStack(alignment: .leading, spacing: PrismSpacing.sm) {
            if type != .lowCost {
                SectionMicroLabel(text: "How much will it cost?")
                TextField("Target amount", text: $targetAmountText)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                    .accessibilityIdentifier("goalSetup.target")
                SectionMicroLabel(text: "How much have you already saved?")
                TextField("Already saved", text: $alreadySavedText)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                Toggle("Include a flexible buffer in the target", isOn: $includesBuffer)
            } else {
                Text("This goal can progress with milestones — money is optional.")
                    .foregroundStyle(PrismColors.textSecondary)
            }
            SectionMicroLabel(text: "When do you want it?")
            DatePicker("Target date", selection: $targetDate, displayedComponents: .date)
            Picker("Contribution rhythm", selection: $frequency) {
                ForEach(ContributionFrequency.allCases) { f in
                    Text(f.displayName).tag(f)
                }
            }
            .pickerStyle(.segmented)
        }
        .onChange(of: targetAmountText) { _, _ in refreshPreview() }
        .onChange(of: alreadySavedText) { _, _ in refreshPreview() }
        .onChange(of: targetDate) { _, _ in refreshPreview() }
    }

    private var priorityStep: some View {
        VStack(alignment: .leading, spacing: PrismSpacing.sm) {
            Text("How important is this compared with your other goals?")
                .font(PrismTypography.headline())
            ForEach(GoalPriorityLevel.allCases) { level in
                Button { priority = level } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(level.displayName).font(PrismTypography.headline())
                            Text(priorityHint(level))
                                .font(PrismTypography.caption())
                                .foregroundStyle(PrismColors.textSecondary)
                        }
                        Spacer()
                        if priority == level { Image(systemName: "checkmark.circle.fill") }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: PrismRadius.md)
                            .stroke(priority == level ? PrismColors.lavender : PrismColors.glassStroke)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var planPreviewStep: some View {
        VStack(alignment: .leading, spacing: PrismSpacing.sm) {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title.isEmpty ? "Your goal" : title)
                        .font(PrismTypography.title(22))
                    if let pace = previewPace {
                        if let rem = pace.remaining {
                            Text("Remaining \(CurrencyFormatting.string(from: rem, currencyCode: currencyCode))")
                        }
                        if let required = pace.requiredPerPeriod {
                            Text("Required contribution: \(CurrencyFormatting.string(from: required, currencyCode: currencyCode)) per \(pace.periodLabel)")
                                .foregroundStyle(PrismColors.lavender)
                        }
                        Text(pace.trackStatus.displayName)
                            .font(PrismTypography.caption())
                    }
                    Text("You stay in control of every assumption. Prism never decides what you can afford.")
                        .font(PrismTypography.caption())
                        .foregroundStyle(PrismColors.textTertiary)
                }
            }
            Text("Starter milestones will be added. You can edit them anytime.")
                .font(PrismTypography.caption())
                .foregroundStyle(PrismColors.textSecondary)
        }
    }

    private var currencyCode: String {
        environment.profile?.spendingPocket.currencyCode
            ?? Locale.current.currency?.identifier
            ?? "USD"
    }

    private func priorityHint(_ level: GoalPriorityLevel) -> String {
        switch level {
        case .primary: return "Your main focus — only one primary at a time."
        case .active: return "Actively funded — up to a few at once."
        case .flexible: return "Worth keeping, not actively funded right now."
        case .someday: return "Parked for later without pressure."
        }
    }

    private func inferredType(from item: SavedItem) -> GoalType {
        switch item.intent {
        case .dream: return .experience
        case .need: return .purchase
        case .gift: return .purchase
        case .want: return .purchase
        }
    }

    private func draftGoal() -> PrismGoal? {
        guard let userID = environment.profile?.id, !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        let target = DecimalParsing.parse(targetAmountText)
        let saved = DecimalParsing.parse(alreadySavedText) ?? 0
        return PrismGoal(
            id: UUID(),
            userID: userID,
            sourceAspirationID: sourceItem?.id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            goalDescription: goalDescription.isEmpty ? nil : goalDescription,
            type: type,
            motivation: motivation,
            customMotivation: motivation == .custom ? customMotivation : nil,
            targetAmount: type == .lowCost ? nil : target,
            currencyCode: currencyCode,
            amountSaved: saved,
            targetDate: targetDate,
            contributionFrequency: frequency,
            priority: priority,
            includesBuffer: includesBuffer,
            trackStatus: .onTrack,
            createdAt: .now,
            updatedAt: .now,
            completedAt: nil,
            pausedAt: nil
        )
    }

    private func refreshPreview() {
        guard let goal = draftGoal() else {
            previewPace = nil
            return
        }
        previewPace = container.goalPlanningService.pace(for: goal)
    }

    private func save() async {
        guard var goal = draftGoal() else {
            errorText = "Add a goal name to continue."
            return
        }
        let pace = container.goalPlanningService.pace(for: goal)
        goal.trackStatus = pace.trackStatus
        do {
            // Soft limit check for active goals
            if goal.priority == .active || goal.priority == .primary,
               let userID = environment.profile?.id {
                let existing = try await container.goalRepository.fetchAll(userID: userID)
                let activeCount = existing.filter { $0.priority == .active || $0.priority == .primary }.count
                if goal.priority == .active && activeCount >= 3 {
                    errorText = "You already have three active goals. Pause one, choose Flexible, or keep this in Someday."
                    return
                }
            }
            try await container.goalRepository.upsert(goal)
            if let item = sourceItem, let userID = environment.profile?.id {
                try await container.goalRepository.linkAspiration(
                    GoalAspirationLink(
                        id: UUID(),
                        userID: userID,
                        goalID: goal.id,
                        savedItemID: item.id,
                        role: .inspiration,
                        createdAt: .now
                    )
                )
            }
            try await seedMilestones(for: goal)
            container.analytics.track(.goalCreated)
            PrismHaptics.save()
            dismiss()
        } catch {
            errorText = "Couldn’t create the goal. Try again."
            container.crashReporter.record(error: error, context: "goal.setup")
        }
    }

    private func seedMilestones(for goal: PrismGoal) async throws {
        let titles: [String]
        switch goal.type {
        case .purchase:
            titles = ["Compare options", "Choose one", "Reach 50% funded", "Purchase"]
        case .travel, .experience:
            titles = ["Choose dates", "Compare options", "Book essentials", "Go"]
        case .project:
            titles = ["Define scope", "Source key pieces", "Install or assemble", "Complete"]
        case .recurring:
            titles = ["Set cadence", "Complete first cycle", "Complete a month"]
        case .lowCost:
            titles = ["Plan first outing", "Halfway", "Complete the list"]
        }
        for (index, title) in titles.enumerated() {
            try await container.goalRepository.upsertMilestone(
                GoalMilestone(
                    id: UUID(),
                    userID: goal.userID,
                    goalID: goal.id,
                    title: title,
                    targetAmount: nil,
                    isCompleted: false,
                    completedAt: nil,
                    sortOrder: index,
                    createdAt: .now
                )
            )
        }
    }
}
