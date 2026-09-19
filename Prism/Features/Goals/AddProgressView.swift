// Summary: Add progress sheet — financial, planning, or behavioral contributions toward a goal.

import SwiftUI

struct AddProgressView: View {
    let goalID: UUID
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var kind: ContributionKind = .financial
    @State private var amountText = ""
    @State private var note = ""
    @State private var errorText: String?

    private let planningPresets = [
        "Chose dates",
        "Compared options",
        "Made a reservation",
        "Completed research",
        "Invited someone"
    ]
    private let behavioralPresets = [
        "Waited through cooling-off",
        "Let go of a lower-priority save",
        "Redirected money to this goal"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismSpacing.md) {
                        Text("Add progress")
                            .font(PrismTypography.title())
                            .accessibilityIdentifier("progress.title")

                        Picker("Kind", selection: $kind) {
                            ForEach(ContributionKind.allCases) { k in
                                Text(k.displayName).tag(k)
                            }
                        }
                        .pickerStyle(.segmented)

                        if kind == .financial {
                            TextField("Amount", text: $amountText)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                                .accessibilityIdentifier("progress.amount")
                        } else {
                            let presets = kind == .planning ? planningPresets : behavioralPresets
                            ForEach(presets, id: \.self) { preset in
                                Button(preset) { note = preset }
                                    .buttonStyle(.bordered)
                            }
                        }

                        TextField("Note (optional)", text: $note, axis: .vertical)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))

                        if let errorText {
                            Text(errorText).foregroundStyle(PrismColors.danger)
                        }

                        PrismPrimaryButton(title: "Save progress") {
                            Task { await save() }
                        }
                        .accessibilityIdentifier("progress.save")
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
    }

    private func save() async {
        guard let profile = environment.profile,
              var goal = try? await container.goalRepository.fetch(id: goalID) else { return }

        let amount = DecimalParsing.parse(amountText)
        if kind == .financial && amount == nil {
            errorText = "Enter an amount, or switch to planning / behavioral progress."
            return
        }

        let contribution = GoalContribution(
            id: UUID(),
            userID: profile.id,
            goalID: goal.id,
            kind: kind,
            amount: kind == .financial ? amount : nil,
            currencyCode: kind == .financial ? goal.currencyCode : nil,
            note: note.isEmpty ? nil : note,
            createdAt: .now
        )

        do {
            try await container.goalRepository.appendContribution(contribution)
            if kind == .financial, let amount {
                goal = container.goalPlanningService.applyFinancialContribution(to: goal, amount: amount)
                let pace = container.goalPlanningService.pace(for: goal)
                goal.trackStatus = pace.trackStatus
                try await container.goalRepository.upsert(goal)
                if goal.trackStatus == .completed {
                    container.analytics.track(.goalCompleted)
                }
            }
            container.analytics.track(.goalContributionAdded)
            PrismHaptics.save()
            dismiss()
        } catch {
            errorText = "Couldn’t save progress."
        }
    }
}
