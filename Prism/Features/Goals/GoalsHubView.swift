// Summary: Goals dashboard tab — lead goal card + other goals list (recreation screen 15).

import SwiftUI

struct GoalsHubView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer

    @State private var goals: [PrismGoal] = []
    @State private var leadID: UUID?
    @State private var showAllGoals = false
    @State private var otherGoalsExpanded = true

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismSpacing.md) {
                        HStack {
                            Spacer()
                            PrismLogoMark()
                            Spacer()
                        }
                        .padding(.horizontal, PrismSpacing.md)
                        .padding(.top, PrismSpacing.sm)

                        HStack {
                            Text("Goals")
                                .font(PrismTypography.title(32))
                            Spacer()
                            if !liveGoals.isEmpty {
                                PrismHeaderAction(title: "See all", accessibilityID: "goals.seeAll") {
                                    showAllGoals = true
                                }
                            }
                        }
                        .padding(.horizontal, PrismSpacing.md)

                        Text(hubSummary)
                            .font(PrismTypography.caption())
                            .foregroundStyle(Color.white.opacity(0.65))
                            .padding(.horizontal, PrismSpacing.md)

                        if let lead {
                            Button {
                                router.sheet = .goalDetail(lead.id)
                            } label: {
                                GoalCardView(
                                    goal: lead,
                                    pace: container.goalPlanningService.pace(for: lead),
                                    isPrimary: lead.priority == .primary
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, PrismSpacing.md)
                            .accessibilityIdentifier("goals.lead")

                            if let note = leadNote(for: lead) {
                                Text(note)
                                    .font(PrismTypography.body(14))
                                    .foregroundStyle(PrismColors.textSecondary)
                                    .padding(.horizontal, PrismSpacing.md)
                            }

                            PrismPrimaryButton(title: "Add progress") {
                                router.sheet = .addProgress(lead.id)
                            }
                            .padding(.horizontal, PrismSpacing.md)
                        } else {
                            GlassCard {
                                EmptyStateView(
                                    title: "Turn inspiration into a goal",
                                    message: "When something matters enough, make it a goal — with a target, a date, and progress you control.",
                                    actionTitle: "Make a goal",
                                    action: { router.sheet = .goalSetup(nil) }
                                )
                            }
                            .padding(.horizontal, PrismSpacing.md)
                            .accessibilityIdentifier("goals.empty")
                        }

                        if !otherGoals.isEmpty {
                            Button {
                                withAnimation(.easeInOut(duration: PrismMotion.quick)) {
                                    otherGoalsExpanded.toggle()
                                }
                            } label: {
                                HStack {
                                    Text(otherGoalsExpanded
                                         ? "YOUR OTHER GOALS · TAP TO HIDE"
                                         : "YOUR OTHER GOALS · TAP TO SHOW")
                                        .font(PrismTypography.mono)
                                        .tracking(0.6)
                                        .foregroundStyle(Color.white.opacity(0.55))
                                    Spacer()
                                    Image(systemName: otherGoalsExpanded ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color.white.opacity(0.45))
                                }
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, PrismSpacing.md)
                            .padding(.top, PrismSpacing.sm)
                            .accessibilityIdentifier("goals.otherToggle")

                            if otherGoalsExpanded {
                                VStack(spacing: 8) {
                                    ForEach(otherGoals) { goal in
                                        Button {
                                            router.sheet = .goalDetail(goal.id)
                                        } label: {
                                            otherRow(goal)
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityIdentifier("goals.other.\(goal.id.uuidString)")
                                    }
                                }
                                .padding(.horizontal, PrismSpacing.md)
                            }
                        }

                        Button {
                            router.sheet = .goalSetup(nil)
                        } label: {
                            Text("+ New goal from a save")
                                .font(PrismTypography.headline())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .background {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                                        .foregroundStyle(Color.white.opacity(0.4))
                                }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, PrismSpacing.md)
                        .accessibilityIdentifier("goals.new")
                    }
                    .padding(.bottom, 100)
                }
                .prismTransparentBackground()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await reload() }
        .onChange(of: router.sheet) { _, new in
            if new == nil { Task { await reload() } }
        }
        .sheet(isPresented: $showAllGoals) {
            AllGoalsListSheet(goals: liveGoals)
                .environmentObject(router)
                .environmentObject(container)
        }
    }

    private var liveGoals: [PrismGoal] {
        goals.filter(isLive)
    }

    private var hubSummary: String {
        let live = goals.filter(isLive)
        let primary = live.filter { $0.priority == .primary }.count
        let active = live.filter { $0.priority == .active }.count
        let paused = live.filter { $0.priority == .flexible || $0.priority == .someday || $0.trackStatus == .paused }.count
        let pocket = environment.profile?.spendingPocket.monthlyAmount
        let pocketLine = pocket.map { CurrencyFormatting.string(from: $0, currencyCode: environment.profile?.spendingPocket.currencyCode ?? "USD") + " a month allocated" }
            ?? "Goals across priorities"
        return "\(pocketLine) · \(primary) primary · \(active) active · \(paused) paused"
    }

    private var lead: PrismGoal? {
        if let leadID, let g = goals.first(where: { $0.id == leadID }) { return g }
        return goals.first { $0.priority == .primary && isLive($0) }
            ?? goals.first { $0.priority == .active && isLive($0) }
            ?? goals.first { isLive($0) }
    }

    private var otherGoals: [PrismGoal] {
        goals.filter { $0.id != lead?.id }
    }

    private func isLive(_ g: PrismGoal) -> Bool {
        g.trackStatus != .abandoned
    }

    private func otherRow(_ goal: PrismGoal) -> some View {
        let pace = container.goalPlanningService.pace(for: goal)
        return HStack(spacing: 11) {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.priority.displayName.uppercased())
                    .font(PrismTypography.mono)
                    .foregroundStyle(Color.white.opacity(0.55))
                Text(goal.title)
                    .font(PrismTypography.body(16, weight: .medium))
                    .foregroundStyle(.white)
                if let target = goal.targetAmount {
                    let display = GoalPlanningService().effectiveTarget(for: goal) ?? target
                    Text("\(CurrencyFormatting.string(from: goal.amountSaved, currencyCode: goal.currencyCode)) of \(CurrencyFormatting.string(from: display, currencyCode: goal.currencyCode))")
                        .font(PrismTypography.caption())
                        .foregroundStyle(PrismColors.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(pace.trackStatus.displayName)
                    .font(PrismTypography.caption())
                    .foregroundStyle(PrismColors.statusGreenSoft)
                if let pct = pace.percentFunded {
                    Text("\(Int(pct))%")
                        .font(PrismTypography.number(14))
                        .foregroundStyle(.white)
                }
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.35))
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(PrismColors.glassFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                }
        }
    }

    private func leadNote(for goal: PrismGoal) -> String? {
        let pace = container.goalPlanningService.pace(for: goal)
        switch pace.trackStatus {
        case .aLittleBehind:
            return "One contribution missed. Adding a little this week puts it back on pace — not a failure, just a signal."
        case .ahead:
            return "Funded ahead of schedule. Worth a calendar hold for the next milestone."
        case .onTrack:
            return "You’re on pace. Keep the contribution rhythm you’ve set."
        default:
            return nil
        }
    }

    private func reload() async {
        guard let userID = environment.profile?.id else { return }
        goals = (try? await container.goalRepository.fetchAll(userID: userID)) ?? []
        if leadID == nil {
            leadID = lead?.id
        }
    }
}

/// Full list of live goals so you can open any of them from the hub.
struct AllGoalsListSheet: View {
    let goals: [PrismGoal]
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(goals) { goal in
                            Button {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    router.sheet = .goalDetail(goal.id)
                                }
                            } label: {
                                GoalCardView(
                                    goal: goal,
                                    pace: container.goalPlanningService.pace(for: goal),
                                    isPrimary: goal.priority == .primary
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("All goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
