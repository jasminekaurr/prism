// Summary: Review hub, swipe deck, and buy / keep considering / let go decision sheets with undo.

import SwiftUI

struct ReviewHubView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer

    @State private var ready: [SavedItem] = []
    @State private var considering: [SavedItem] = []
    @State private var letGo: [SavedItem] = []
    @State private var purchased: [SavedItem] = []
    @State private var regretDue: [SavedItem] = []
    @State private var showDeck = false
    @State private var undoBanner: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: PrismSpacing.lg) {
                        HStack {
                            Spacer()
                            PrismBrandMark(size: 18)
                            Spacer()
                        }
                        Text("Review")
                            .font(PrismTypography.title())
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("review.title")

                        if let undoBanner {
                            GlassCard {
                                HStack {
                                    Text(undoBanner)
                                    Spacer()
                                    Button("Undo") {
                                        Task { await performUndo() }
                                    }
                                    .accessibilityIdentifier("review.undo")
                                }
                            }
                        }

                        if ready.isEmpty && considering.isEmpty && regretDue.isEmpty {
                            EmptyStateView(
                                title: "Nothing to revisit yet",
                                message: "When a cooling-off period ends, items will appear here. You can also open anything you’re still considering."
                            )
                            .accessibilityIdentifier("review.empty")
                        }

                        if !regretDue.isEmpty {
                            regretSection
                        }

                        if !ready.isEmpty {
                            section(title: "Ready to revisit", items: ready)
                            PrismPrimaryButton(title: "Start review") {
                                showDeck = true
                            }
                            .accessibilityIdentifier("review.start")
                        }

                        if !considering.isEmpty {
                            section(title: "Still considering", items: considering)
                        }

                        if !purchased.isEmpty {
                            section(title: "Purchased", items: purchased)
                        }

                        if !letGo.isEmpty {
                            section(title: "Let go", items: letGo)
                        }
                    }
                    .padding()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showDeck) {
                ReviewDeckView(items: ready.isEmpty ? considering : ready) { message in
                    undoBanner = message
                    Task { await reload() }
                }
            }
        }
        .task { await reload() }
        .onChange(of: router.sheet) { _, new in
            if new == nil { Task { await reload() } }
        }
    }

    private func section(title: String, items: [SavedItem]) -> some View {
        VStack(alignment: .leading, spacing: PrismSpacing.sm) {
            Text(title).font(PrismTypography.headline())
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PrismSpacing.sm) {
                    ForEach(items) { item in
                        Button {
                            router.sheet = .itemDetail(item.id)
                        } label: {
                            SavedItemCard(item: item, collectionName: nil)
                                .frame(width: 178)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var regretSection: some View {
        VStack(alignment: .leading, spacing: PrismSpacing.sm) {
            Text("Check-in").font(PrismTypography.headline())
            ForEach(regretDue) { item in
                GlassCard {
                    VStack(alignment: .leading, spacing: PrismSpacing.sm) {
                        Text("Still glad you bought \u{201C}\(item.title)\u{201D}?")
                            .font(PrismTypography.body())
                        HStack {
                            ForEach(RegretAnswer.allCases) { answer in
                                Button(answer.displayName) {
                                    Task { await answerRegret(item, answer) }
                                }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("regret.\(answer.rawValue)")
                            }
                        }
                    }
                }
            }
            Text("Only you see this. It helps your Money Story show what was worth it.")
                .font(PrismTypography.caption())
                .foregroundStyle(PrismColors.textTertiary)
        }
        .accessibilityIdentifier("review.regretSection")
    }

    private func answerRegret(_ item: SavedItem, _ answer: RegretAnswer) async {
        let updated = RegretCheckIn.answer(answer, for: item)
        try? await container.savedItemRepository.upsert(updated)
        await container.notificationScheduler.cancelRegretCheckIn(itemID: item.id)
        container.analytics.track(.regretCheckInAnswered)
        PrismHaptics.soft()
        await reload()
    }

    private func reload() async {
        guard let userID = environment.profile?.id else { return }
        let all = (try? await container.savedItemRepository.fetchAll(userID: userID)) ?? []
        regretDue = RegretCheckIn.due(items: all)
        let due = (try? await container.savedItemRepository.fetchReadyForReview(userID: userID, asOf: .now)) ?? []
        ready = due
        let dueIDs = Set(due.map(\.id))
        considering = all.filter { item in
            (item.status == .considering || item.status == .readyForReview) && !dueIDs.contains(item.id)
        }
        letGo = all.filter { $0.status == .letGo }
        purchased = all.filter { $0.status == .purchased }
    }

    private func performUndo() async {
        guard let userID = environment.profile?.id,
              let payload = environment.lastUndo,
              let item = try? await container.savedItemRepository.fetch(id: payload.itemID),
              let event = try? await container.decisionRepository.latestActive(for: payload.itemID),
              let result = try? container.decisionService.undo(item: item, lastEvent: event, userID: userID) else {
            return
        }
        try? await container.savedItemRepository.upsert(result.item)
        try? await container.decisionRepository.append(result.event)
        await container.notificationScheduler.cancelReviewReminder(itemID: item.id)
        await container.notificationScheduler.cancelRegretCheckIn(itemID: item.id)
        undoBanner = nil
        environment.lastUndo = nil
        await reload()
    }
}

struct ReviewDeckView: View {
    let items: [SavedItem]
    var onDecision: (String) -> Void

    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var index = 0
    @State private var offset: CGSize = .zero
    @State private var redirectPrompt: RedirectPrompt?

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                if items.isEmpty {
                    EmptyStateView(title: "You’re caught up", message: "No items in this review queue.")
                } else if index < items.count {
                    let item = items[index]
                    VStack(spacing: PrismSpacing.lg) {
                        Text(item.title).font(PrismTypography.title(22))
                        SavedItemCard(item: item, collectionName: nil)
                            .frame(maxWidth: 300)
                            .offset(offset)
                            .gesture(
                                DragGesture()
                                    .onChanged { offset = $0.translation }
                                    .onEnded { value in
                                        if value.translation.width < -120 {
                                            Task { await letGo(item) }
                                        } else if value.translation.width > 120 {
                                            router.sheet = .buyConfirmation(item.id)
                                        } else {
                                            withAnimation { offset = .zero }
                                        }
                                    }
                            )

                        HStack(spacing: PrismSpacing.xl) {
                            Button {
                                Task { await letGo(item) }
                            } label: {
                                Image(systemName: "trash")
                                    .frame(width: 44, height: 44)
                                    .background(Circle().stroke(PrismColors.glassStroke))
                            }
                            .accessibilityLabel("Let go")
                            .accessibilityIdentifier("review.letGo")

                            Button {
                                router.sheet = .keepConsidering(item.id)
                            } label: {
                                Text("Keep considering")
                                    .font(PrismTypography.caption())
                                    .padding()
                                    .background(Capsule().stroke(PrismColors.glassStroke))
                            }
                            .accessibilityIdentifier("review.keep")

                            Button {
                                router.sheet = .buyConfirmation(item.id)
                            } label: {
                                Image(systemName: "heart.fill")
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(PrismColors.violet.opacity(0.6)))
                            }
                            .accessibilityLabel("Buy")
                            .accessibilityIdentifier("review.buy")
                        }
                    }
                    .padding()
                } else {
                    VStack {
                        Text("Decision made. Prism will add this to your story.")
                            .font(PrismTypography.title(22))
                            .multilineTextAlignment(.center)
                        PrismPrimaryButton(title: "Done") { dismiss() }
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $redirectPrompt) { prompt in
                RedirectNudgeView(goal: prompt.goal, itemTitle: prompt.itemTitle)
            }
            .onChange(of: router.sheet) { _, new in
                // After buy/keep sheets dismiss, advance
                if new == nil {
                    Task {
                        await reloadAdvance()
                    }
                }
            }
        }
    }

    private func letGo(_ item: SavedItem) async {
        guard let userID = environment.profile?.id,
              let result = try? container.decisionService.applyLetGo(item: item, userID: userID) else { return }
        try? await container.savedItemRepository.upsert(result.item)
        try? await container.decisionRepository.append(result.event)
        await container.notificationScheduler.cancelReviewReminder(itemID: item.id)
        container.analytics.track(.itemLetGo)
        container.analytics.track(.reviewCompleted)
        PrismHaptics.decision()
        environment.lastUndo = .init(itemID: item.id, message: "You decided this wasn’t for you.")
        onDecision("You decided this wasn’t for you.")
        withAnimation(.easeOut(duration: PrismMotion.archival)) {
            offset = .zero
            index += 1
        }
        let goals = (try? await container.goalRepository.fetchAll(userID: userID)) ?? []
        if let focus = container.goalPlanningService.focusGoal(in: goals) {
            redirectPrompt = RedirectPrompt(goal: focus, itemTitle: item.title)
        }
    }

    private func reloadAdvance() async {
        offset = .zero
        // If current item was decided via sheet, move forward
        if index < items.count {
            let current = items[index]
            if let updated = try? await container.savedItemRepository.fetch(id: current.id),
               updated.status == .purchased || updated.status == .letGo || updated.reviewAt != current.reviewAt {
                index += 1
                onDecision("Decision made. Prism will add this to your story.")
            }
        }
    }
}

struct BuyConfirmationView: View {
    let itemID: UUID
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var didPurchase: Bool?
    @State private var priceText = ""
    @State private var tradeoff: String?
    @State private var motivationReminder: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                VStack(alignment: .leading, spacing: PrismSpacing.md) {
                    Text("Did the purchase happen?")
                        .font(PrismTypography.title(22))
                    if let tradeoff {
                        GlassCard {
                            Text(tradeoff)
                                .font(PrismTypography.body())
                                .foregroundStyle(PrismColors.textSecondary)
                        }
                    }
                    if let motivationReminder {
                        Text(motivationReminder)
                            .font(PrismTypography.caption())
                            .foregroundStyle(PrismColors.textTertiary)
                    }
                    HStack {
                        Button("Yes") { didPurchase = true }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("buy.yes")
                        Button("Not yet") { didPurchase = false }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("buy.no")
                    }
                    if didPurchase == true {
                        Text("Confirmed purchase price (optional)")
                        TextField("Skip if you’d rather not", text: $priceText)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                            .accessibilityIdentifier("buy.price")
                    }
                    PrismPrimaryButton(title: "Confirm") {
                        Task { await confirm() }
                    }
                    .disabled(didPurchase == nil)
                    .accessibilityIdentifier("buy.confirm")
                    Spacer()
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
        .task { await loadTradeoff() }
    }

    private func loadTradeoff() async {
        guard let profile = environment.profile,
              let item = try? await container.savedItemRepository.fetch(id: itemID) else { return }
        let goals = (try? await container.goalRepository.fetchAll(userID: profile.id)) ?? []
        guard let primary = goals.first(where: { $0.priority == .primary && $0.trackStatus != .completed })
                ?? goals.first(where: { $0.priority == .active }) else { return }
        let pace = container.goalPlanningService.pace(for: primary)
        let price = item.estimatedPrice
        tradeoff = container.goalPlanningService.tradeoffCopy(
            itemTitle: item.title,
            estimatedPrice: price,
            against: primary,
            pace: pace
        )
        if let motivation = primary.motivation {
            motivationReminder = "Your goal “\(primary.title)”: \(primary.customMotivation ?? motivation.displayName)"
        }
    }

    private func confirm() async {
        guard let profile = environment.profile,
              let item = try? await container.savedItemRepository.fetch(id: itemID),
              let didPurchase else { return }
        let price = DecimalParsing.parse(priceText)
        guard let result = try? container.decisionService.applyBuy(
            item: item,
            userID: profile.id,
            purchaseConfirmed: didPurchase,
            confirmedPrice: price,
            currencyCode: price == nil ? nil : profile.spendingPocket.currencyCode
        ) else { return }
        try? await container.savedItemRepository.upsert(result.item)
        try? await container.decisionRepository.append(result.event)
        await container.notificationScheduler.cancelReviewReminder(itemID: item.id)
        if didPurchase {
            container.analytics.track(.itemPurchasedConfirmed)
            if let due = result.item.regretCheckInAt, profile.notificationPreferences.isRegretCheckInOn {
                await container.notificationScheduler.scheduleRegretCheckIn(itemID: item.id, at: due)
            }
        }
        container.analytics.track(.reviewCompleted)
        PrismHaptics.decision()
        environment.lastUndo = .init(itemID: item.id, message: "Decision made. Prism will add this to your story.")
        dismiss()
    }
}

struct KeepConsideringView: View {
    let itemID: UUID
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss
    @State private var days = 3

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                VStack(spacing: PrismSpacing.md) {
                    Text("Keep considering")
                        .font(PrismTypography.title(22))
                    Text("Choose another review date. We won’t pressure you.")
                        .foregroundStyle(PrismColors.textSecondary)
                        .multilineTextAlignment(.center)
                    Stepper("In \(days) days", value: $days, in: 1...30)
                        .accessibilityIdentifier("keep.days")
                    PrismPrimaryButton(title: "Save") {
                        Task { await save() }
                    }
                    .accessibilityIdentifier("keep.save")
                    Spacer()
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }

    private func save() async {
        guard let profile = environment.profile,
              let item = try? await container.savedItemRepository.fetch(id: itemID) else { return }
        let newDate = Calendar.current.date(byAdding: .day, value: days, to: .now)
        guard let result = try? container.decisionService.applyKeepConsidering(
            item: item,
            userID: profile.id,
            newReviewAt: newDate
        ) else { return }
        try? await container.savedItemRepository.upsert(result.item)
        try? await container.decisionRepository.append(result.event)
        try? await container.reviewEventRepository.append(
            ReviewEvent(id: UUID(), userID: profile.id, savedItemID: item.id, scheduledAt: newDate ?? .now, completedAt: nil, createdAt: .now)
        )
        await container.notificationScheduler.cancelReviewReminder(itemID: item.id)
        if let newDate, profile.notificationPreferences.coolingOffRemindersEnabled {
            await container.notificationScheduler.scheduleReviewReminder(itemID: item.id, at: newDate)
        }
        PrismHaptics.soft()
        dismiss()
    }
}

struct RedirectPrompt: Identifiable {
    let id = UUID()
    let goal: PrismGoal
    let itemTitle: String
}

/// Shown after letting go of a save while a goal is active. Nothing is added automatically:
/// an estimate is never treated as money saved.
struct RedirectNudgeView: View {
    let goal: PrismGoal
    let itemTitle: String
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                VStack(alignment: .leading, spacing: PrismSpacing.md) {
                    Text("Letting go takes intention")
                        .font(PrismTypography.title(22))
                        .accessibilityIdentifier("redirect.title")
                    Text("You let go of \u{201C}\(itemTitle)\u{201D}. Want to note that as progress on \u{201C}\(goal.title)\u{201D}?")
                        .font(PrismTypography.body())
                        .foregroundStyle(PrismColors.textSecondary)

                    SectionMicroLabel(text: "Money you actually moved to this goal (optional)")
                    TextField("Leave blank to just note it", text: $amountText)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                        .accessibilityIdentifier("redirect.amount")
                    Text("Prism never counts an estimate as savings. Only enter an amount you really set aside.")
                        .font(PrismTypography.caption())
                        .foregroundStyle(PrismColors.textTertiary)

                    if let errorText {
                        Text(errorText).foregroundStyle(PrismColors.danger)
                    }

                    PrismPrimaryButton(title: "Note it as progress") {
                        Task { await accept() }
                    }
                    .accessibilityIdentifier("redirect.accept")

                    Button("Not now") { dismiss() }
                        .foregroundStyle(PrismColors.textSecondary)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("redirect.dismiss")
                    Spacer()
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }

    private func accept() async {
        guard let profile = environment.profile else { return }
        let amount = DecimalParsing.parse(amountText)
        if !amountText.trimmingCharacters(in: .whitespaces).isEmpty && amount == nil {
            errorText = "Enter a number, or leave it blank."
            return
        }
        do {
            try await container.goalRepository.appendContribution(
                GoalContribution(
                    id: UUID(), userID: profile.id, goalID: goal.id, kind: .behavioral,
                    amount: nil, currencyCode: nil,
                    note: "Let go of a lower-priority save", createdAt: .now
                )
            )
            if let amount, amount > 0 {
                try await container.goalRepository.appendContribution(
                    GoalContribution(
                        id: UUID(), userID: profile.id, goalID: goal.id, kind: .financial,
                        amount: amount, currencyCode: goal.currencyCode,
                        note: "Redirected after letting go", createdAt: .now
                    )
                )
                var updated = container.goalPlanningService.applyFinancialContribution(to: goal, amount: amount)
                updated.trackStatus = container.goalPlanningService.pace(for: updated).trackStatus
                try await container.goalRepository.upsert(updated)
            }
            container.analytics.track(.redirectNudgeAccepted)
            PrismHaptics.save()
            dismiss()
        } catch {
            errorText = "Couldn\u{2019}t save that. Try again."
        }
    }
}
