// Summary: Multi-step New Goal flow — Paste (when fresh) → Define → Why → Target → Rank/Plan.

import SwiftUI
import UIKit

struct GoalSetupFlowView: View {
    var sourceItem: SavedItem?
    var sourceCollection: PrismCollection?
    var collectionItems: [SavedItem] = []
    @EnvironmentObject private var environment: AppEnvironment
    @EnvironmentObject private var container: DependencyContainer
    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var title = ""
    @State private var goalDescription = ""
    @State private var type: GoalType = .purchase
    @State private var motivation: GoalMotivation = .personalGrowth
    @State private var customMotivation = ""
    @State private var targetAmountText = ""
    @State private var alreadySavedText = ""
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
    @State private var frequency: ContributionFrequency = .monthly
    @State private var priority: GoalPriorityLevel = .active
    @State private var includesBuffer = true
    @State private var errorText: String?
    @State private var previewPace: GoalPaceSnapshot?
    @State private var excludedItemIDs: Set<UUID> = []

    // Paste / define extras (UI + soft prefill; not all persisted on PrismGoal)
    @State private var pasteURLText = ""
    @State private var pasteLinkType = 0
    @State private var whereText = ""
    @State private var relevantDateNote = ""
    @State private var spendingCategory = ""
    @State private var suggestionChips: Set<String> = ["name", "type", "cost", "date"]
    @State private var pasteImageData: Data?
    @State private var pasteLoading = false
    @State private var pastePreviewFailed = false
    @State private var pasteTask: Task<Void, Never>?

    private let linkTypes = ["Product", "Trip", "Event", "Inspiration"]

    private var startsWithPaste: Bool {
        sourceItem == nil && sourceCollection == nil
    }

    private var stepCount: Int { 5 }

    private var currentKind: StepKind {
        let kinds: [StepKind] = startsWithPaste
            ? [.paste, .define, .motivation, .target, .plan]
            : [.define, .motivation, .target, .priority, .plan]
        return kinds[min(step, kinds.count - 1)]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PrismAtmosphericBackground()
                VStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 8) {
                        if currentKind == .paste {
                            Text("SHARED TO PRISM")
                                .font(PrismTypography.micro())
                                .tracking(0.8)
                                .foregroundStyle(Color.white.opacity(0.7))
                        } else {
                            Text("NEW GOAL · STEP \(step + 1) OF \(stepCount)")
                                .font(PrismTypography.micro())
                                .tracking(0.8)
                                .foregroundStyle(Color.white.opacity(0.7))
                                .accessibilityIdentifier("goalSetup.title")
                        }

                        Text(stepHeadline)
                            .font(PrismTypography.title(26))

                        if currentKind != .paste {
                            stepTicks
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    GlassCard(padding: 14, cornerRadius: 22) {
                        Group {
                            switch currentKind {
                            case .paste: pasteStep
                            case .define: defineStep
                            case .motivation: motivationStep
                            case .target: targetStep
                            case .priority: priorityStep
                            case .plan: planPreviewStep
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    if let errorText {
                        Text(errorText)
                            .font(PrismTypography.caption())
                            .foregroundStyle(PrismColors.danger)
                    }

                    footerNav
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onDisappear { pasteTask?.cancel() }
        }
        .onAppear {
            if let sourceItem {
                title = sourceItem.title
                goalDescription = sourceItem.reflection ?? sourceItem.notes ?? ""
                if let estimate = sourceItem.estimatedPrice {
                    targetAmountText = "\(estimate)"
                }
                type = inferredType(from: sourceItem)
                if let merchant = sourceItem.merchantName {
                    whereText = "\(merchant) · online"
                }
                if let url = sourceItem.sourceURL?.absoluteString {
                    pasteURLText = url
                    schedulePastePreview(for: url, immediate: true)
                }
            }
            if let sourceCollection {
                title = sourceCollection.name
                goalDescription = sourceCollection.description ?? ""
                type = collectionItems.contains { $0.intent == .dream } ? .experience : .project
                syncTargetFromComponents()
            }
            refreshPreview()
        }
    }

    private var footerNav: some View {
        HStack {
            if step > 0 {
                Button("Back") {
                    withAnimation { step -= 1 }
                }
                .frame(minWidth: 88, minHeight: 44)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .background {
                    RoundedRectangle(cornerRadius: PrismRadius.md, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                }
            }
            Spacer()
            if step < stepCount - 1 {
                PrismPrimaryButton(title: currentKind == .paste ? "Make it a goal" : "Next") {
                    advanceFromCurrentStep()
                }
            } else {
                PrismPrimaryButton(title: "Create goal") {
                    Task { await save() }
                }
                .accessibilityIdentifier("goalSetup.create")
            }
        }
    }

    private func advanceFromCurrentStep() {
        if currentKind == .paste {
            applyPastePrefill()
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || URLHelpers.normalizedURL(from: pasteURLText) != nil else {
                errorText = "Paste a link or add a title to continue."
                return
            }
            errorText = nil
        }
        withAnimation { step += 1 }
        refreshPreview()
    }

    private var stepHeadline: String {
        switch currentKind {
        case .paste: return "Paste anything"
        case .define: return "Define the goal"
        case .motivation: return "Why this matters"
        case .target: return "Set the target"
        case .priority: return "Where it ranks"
        case .plan: return "Your plan"
        }
    }

    private var stepTicks: some View {
        HStack(spacing: 6) {
            ForEach(0..<stepCount, id: \.self) { i in
                Capsule()
                    .fill(i == step ? Color.white : Color.white.opacity(0.28))
                    .frame(height: 3)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Step: Paste

    private var pasteStep: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "link")
                TextField("https://…", text: $pasteURLText)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .autocorrectionDisabled()
                    .font(PrismTypography.mono)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("goalSetup.pasteURL")
                Button(pasteLoading ? "…" : (pasteURLText.isEmpty ? "Paste" : "Clear")) {
                    if pasteURLText.isEmpty {
                        if let clip = UIPasteboard.general.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                           !clip.isEmpty {
                            pasteURLText = clip
                            applyPastePrefill()
                            schedulePastePreview(for: clip, immediate: true)
                        } else {
                            errorText = "Nothing on the clipboard to paste."
                        }
                    } else {
                        pasteURLText = ""
                        title = ""
                        pasteImageData = nil
                        pastePreviewFailed = false
                        errorText = nil
                    }
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .font(PrismTypography.caption())
                .foregroundStyle(.white)
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: PrismRadius.md)
                    .stroke(PrismColors.glassStroke)
            }
            .onChange(of: pasteURLText) { _, newValue in
                applyPastePrefill()
                schedulePastePreview(for: newValue)
            }
            .onSubmit {
                schedulePastePreview(for: pasteURLText, immediate: true)
            }

            pastePreviewBlock

            SectionMicroLabel(text: "TITLE")
            TextField("Goal title", text: $title)
                .font(PrismTypography.body(16, weight: .medium))
                .padding(10)
                .background {
                    RoundedRectangle(cornerRadius: PrismRadius.md)
                        .stroke(PrismColors.glassStroke)
                }
                .accessibilityIdentifier("goalSetup.pasteTitle")

            SectionMicroLabel(text: "TYPE")
            PrismSegmentedControl(options: Array(linkTypes.indices), selection: $pasteLinkType) { linkTypes[$0] }
                .onChange(of: pasteLinkType) { _, i in
                    type = typeFromLinkChip(i)
                }

            Text("Paste a link — Prism fills a title when it can. Nothing is locked.")
                .font(PrismTypography.mono)
                .foregroundStyle(Color.white.opacity(0.45))
        }
    }

    @ViewBuilder
    private var pastePreviewBlock: some View {
        if pasteLoading {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .frame(height: 120)
                .overlay { ProgressView() }
        } else if let pasteImageData, let uiImage = UIImage(data: pasteImageData) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .overlay {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .frame(height: 100)
                .overlay {
                    Text(pastePreviewPlaceholder)
                        .font(PrismTypography.caption())
                        .foregroundStyle(Color.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .padding()
                }
        }
    }

    private var pastePreviewPlaceholder: String {
        if pastePreviewFailed {
            return "No preview image — you can still continue"
        }
        if URLHelpers.normalizedURL(from: pasteURLText) != nil {
            return "Loading cover…"
        }
        return "Paste a product, trip, or event link"
    }

    private func schedulePastePreview(for raw: String, immediate: Bool = false) {
        pasteTask?.cancel()
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URLHelpers.normalizedURL(from: trimmed) else {
            if trimmed.isEmpty {
                pasteImageData = nil
                pastePreviewFailed = false
                pasteLoading = false
            }
            return
        }
        pasteTask = Task {
            if !immediate {
                try? await Task.sleep(nanoseconds: 350_000_000)
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                pasteLoading = true
                pastePreviewFailed = false
            }
            let result = await LinkPreviewFetcher.fetch(for: url)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                pasteLoading = false
                let current = title.trimmingCharacters(in: .whitespacesAndNewlines)
                let placeholder = current.isEmpty
                    || current == url.host?.replacingOccurrences(of: "www.", with: "")
                if placeholder, let previewTitle = result.title, !previewTitle.isEmpty {
                    title = previewTitle
                }
                if let data = result.imageData, UIImage(data: data) != nil {
                    pasteImageData = data
                    pastePreviewFailed = false
                } else {
                    pasteImageData = nil
                    pastePreviewFailed = true
                }
                applyPastePrefill()
            }
        }
    }

    private func applyPastePrefill() {
        let lower = pasteURLText.lowercased()
        if lower.contains("macbook") || lower.contains("apple.com/macbook") {
            if title.isEmpty || title == domainTitleHint {
                title = "MacBook Air 13” M4"
            }
            if targetAmountText.isEmpty { targetAmountText = "1199" }
            if whereText.isEmpty { whereText = "Apple · online" }
            if relevantDateNote.isEmpty { relevantDateNote = "Before spring term" }
            if spendingCategory.isEmpty { spendingCategory = "Tech & equipment" }
            pasteLinkType = 0
            type = .purchase
            suggestionChips = ["name", "type", "cost", "date"]
        } else if title.isEmpty, let hint = domainTitleHint {
            title = hint
        }
    }

    private var domainTitleHint: String? {
        URLHelpers.normalizedURL(from: pasteURLText)
            .flatMap { URLHelpers.domain(from: $0)?.replacingOccurrences(of: "www.", with: "") }
    }

    private func typeFromLinkChip(_ index: Int) -> GoalType {
        switch index {
        case 1: return .travel
        case 2: return .experience
        case 3: return .project
        default: return .purchase
        }
    }

    // MARK: - Step: Define

    private var defineStep: some View {
        VStack(alignment: .leading, spacing: PrismSpacing.sm) {
            if sourceItem != nil || !pasteURLText.isEmpty {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 36, height: 36)
                        .overlay {
                            Text("shot")
                                .font(PrismTypography.mono)
                                .foregroundStyle(Color.white.opacity(0.4))
                        }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FROM YOUR SAVE")
                            .font(PrismTypography.micro())
                            .foregroundStyle(Color.white.opacity(0.5))
                        Text(sourceItem.map { "@\($0.merchantName ?? $0.sourceDomain ?? "save") · \($0.title)" }
                             ?? (title.isEmpty ? pasteURLText : title))
                            .font(PrismTypography.body(14))
                            .lineLimit(2)
                    }
                }
            }

            defineField(
                label: "GOAL NAME",
                text: $title,
                chip: suggestionChips.contains("name") ? "from your save" : nil,
                chipKey: "name",
                identifier: "goalSetup.name"
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    SectionMicroLabel(text: "TYPE")
                    Spacer()
                    if suggestionChips.contains("type") {
                        suggestionChip("suggested", key: "type")
                    }
                }
                Text(typeLine)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: PrismRadius.md)
                            .stroke(PrismColors.glassStroke)
                    }
                Picker("Type", selection: $type) {
                    ForEach(GoalType.allCases) { t in
                        Text(t.displayName).tag(t)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            if sourceCollection != nil {
                componentsPicker
            }

            Text("Prism filled these in from the post. Dismiss anything that isn't right — nothing is locked.")
                .font(PrismTypography.mono)
                .foregroundStyle(Color.white.opacity(0.45))
        }
    }

    private var typeLine: String {
        "\(type.displayName) · one-time purchase"
    }

    private func defineField(
        label: String,
        text: Binding<String>,
        chip: String?,
        chipKey: String?,
        keyboard: UIKeyboardType = .default,
        identifier: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                SectionMicroLabel(text: label)
                Spacer()
                if let chip, let chipKey {
                    suggestionChip(chip, key: chipKey)
                }
            }
            TextField(label.capitalized, text: text)
                .keyboardType(keyboard)
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: PrismRadius.md)
                        .stroke(PrismColors.glassStroke)
                }
                .accessibilityIdentifier(identifier ?? "goalSetup.field.\(label)")
        }
    }

    private func suggestionChip(_ label: String, key: String) -> some View {
        Button {
            suggestionChips.remove(key)
            PrismHaptics.soft()
        } label: {
            HStack(spacing: 4) {
                Text(label)
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
            .font(PrismTypography.caption())
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(PrismColors.lavender.opacity(0.85)))
        }
        .buttonStyle(.plain)
    }

    private var componentsPicker: some View {
        VStack(alignment: .leading, spacing: PrismSpacing.xs) {
            SectionMicroLabel(text: "Items in this plan")
            if collectionItems.isEmpty {
                Text("No open saves in this collection yet. You can still create the goal.")
                    .font(PrismTypography.caption())
                    .foregroundStyle(PrismColors.textSecondary)
            }
            ForEach(collectionItems) { item in
                Toggle(isOn: Binding(
                    get: { !excludedItemIDs.contains(item.id) },
                    set: { included in
                        if included { excludedItemIDs.remove(item.id) } else { excludedItemIDs.insert(item.id) }
                        syncTargetFromComponents()
                        refreshPreview()
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                        Text(item.estimatedPrice.map {
                            "Estimated \(CurrencyFormatting.string(from: $0, currencyCode: item.estimatedCurrencyCode ?? currencyCode))"
                        } ?? "No estimate yet")
                            .font(PrismTypography.caption())
                            .foregroundStyle(PrismColors.textSecondary)
                    }
                }
                .accessibilityIdentifier("goalSetup.component.\(item.id.uuidString)")
            }
        }
    }

    private var includedItems: [SavedItem] {
        collectionItems.filter { !excludedItemIDs.contains($0.id) }
    }

    private func syncTargetFromComponents() {
        let total = includedItems.compactMap(\.estimatedPrice).reduce(Decimal(0), +)
        targetAmountText = total > 0 ? "\(total)" : ""
    }

    // MARK: - Step: Motivation

    private var motivationStep: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(motivationPrompt)
                .font(PrismTypography.body(15, weight: .medium))
                .lineLimit(2)
            ForEach(GoalMotivation.allCases) { m in
                Button {
                    motivation = m
                } label: {
                    HStack(spacing: 8) {
                        Text(m.displayName)
                            .font(PrismTypography.body(13))
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                        Spacer(minLength: 0)
                        Image(systemName: motivation == m ? "largecircle.fill.circle" : "circle")
                            .font(.system(size: 14))
                            .foregroundStyle(motivation == m ? Color.white : Color.white.opacity(0.35))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(motivation == m ? Color.white.opacity(0.55) : PrismColors.glassStroke)
                    }
                }
                .buttonStyle(.plain)
            }
            if motivation == .custom {
                TextField("Your reason", text: $customMotivation)
                    .font(PrismTypography.body(13))
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).stroke(PrismColors.glassStroke))
            }
        }
    }

    private var motivationPrompt: String {
        let short = title.isEmpty ? "this" : title.lowercased()
        if short.contains("laptop") || short.contains("macbook") {
            return "Why does a new laptop matter to you?"
        }
        return "Why does \(short) matter to you?"
    }

    // MARK: - Step: Target

    private var targetStep: some View {
        VStack(alignment: .leading, spacing: 8) {
            if type != .lowCost {
                SectionMicroLabel(text: "TARGET AMOUNT")
                TextField("$0", text: $targetAmountText)
                    .keyboardType(.decimalPad)
                    .font(PrismTypography.number(24))
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                    .accessibilityIdentifier("goalSetup.target")

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        SectionMicroLabel(text: "DATE")
                        DatePicker("", selection: $targetDate, displayedComponents: .date)
                            .labelsHidden()
                            .colorScheme(.dark)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))

                    VStack(alignment: .leading, spacing: 4) {
                        SectionMicroLabel(text: "SAVED")
                        TextField("$0", text: $alreadySavedText)
                            .keyboardType(.decimalPad)
                            .font(PrismTypography.body(15))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: PrismRadius.md).stroke(PrismColors.glassStroke))
                }

                SectionMicroLabel(text: "FREQUENCY")
                PrismSegmentedControl(
                    options: ContributionFrequency.allCases,
                    selection: $frequency
                ) { $0.displayName }

                Toggle(isOn: $includesBuffer) {
                    Text("Include 8% buffer")
                        .font(PrismTypography.body(14))
                }
                .tint(PrismColors.statusGreen)

                if includesBuffer, let buffered = bufferedPlanTotal {
                    Text("Plan total \(CurrencyFormatting.string(from: buffered, currencyCode: currencyCode))")
                        .font(PrismTypography.body(14, weight: .medium))
                        .foregroundStyle(PrismColors.lavender)
                        .accessibilityIdentifier("goalSetup.bufferedTotal")
                }
            } else {
                Text("Money is optional for this goal.")
                    .font(PrismTypography.caption())
                    .foregroundStyle(PrismColors.textSecondary)
                DatePicker("Target date", selection: $targetDate, displayedComponents: .date)
            }

            if let pace = previewPace, let required = pace.requiredPerPeriod {
                HStack {
                    Text("THAT WORKS OUT TO")
                        .font(PrismTypography.micro())
                        .foregroundStyle(Color.white.opacity(0.5))
                    Spacer()
                    Text("\(CurrencyFormatting.string(from: required, currencyCode: currencyCode)) / \(pace.periodLabel)")
                        .font(PrismTypography.number(18))
                }
                .padding(10)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.35))
                }
            }
        }
        .onChange(of: targetAmountText) { _, _ in refreshPreview() }
        .onChange(of: alreadySavedText) { _, _ in refreshPreview() }
        .onChange(of: targetDate) { _, _ in refreshPreview() }
        .onChange(of: includesBuffer) { _, _ in refreshPreview() }
        .onChange(of: frequency) { _, _ in refreshPreview() }
    }

    // MARK: - Step: Priority / Plan

    private var priorityStep: some View {
        VStack(alignment: .leading, spacing: PrismSpacing.sm) {
            ForEach(GoalPriorityLevel.allCases) { level in
                Button { priority = level } label: {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(priorityTitle(level)).font(PrismTypography.headline())
                            Text(priorityHint(level))
                                .font(PrismTypography.caption())
                                .foregroundStyle(PrismColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: priority == level ? "largecircle.fill.circle" : "circle")
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: PrismRadius.md)
                            .stroke(priority == level ? Color.white.opacity(0.55) : PrismColors.glassStroke)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var planPreviewStep: some View {
        VStack(alignment: .leading, spacing: PrismSpacing.sm) {
            if startsWithPaste {
                priorityStep
                Divider().overlay(Color.white.opacity(0.15))
            }

            Text("Built from what you entered. Every line stays yours to change.")
                .font(PrismTypography.caption())
                .foregroundStyle(PrismColors.textSecondary)

            planRow(
                label: "CONTRIBUTION",
                value: contributionPlanLine,
                sub: "Auto-transfer on the 1st, adjustable any time"
            )
            planRow(
                label: "TARGET DATE",
                value: targetDate.formatted(.dateTime.day().month().year()),
                sub: relevantDateNote.isEmpty ? nil : relevantDateNote
            )
            if includesBuffer, let buffered = bufferedAmount {
                planRow(
                    label: "BUFFER",
                    value: "8% — \(CurrencyFormatting.string(from: buffered, currencyCode: currencyCode))",
                    sub: "Carried over from your target"
                )
            }
            planRow(
                label: "PROGRESS WITHOUT MONEY",
                value: "Check student pricing · list the old Air",
                sub: "Counts as progress too"
            )

            if sourceCollection != nil && !includedItems.isEmpty {
                SectionMicroLabel(text: "Plan components")
                ForEach(includedItems) { item in
                    Text(item.title).font(PrismTypography.body())
                }
            }

            HStack {
                Text("Every line stays editable")
                    .font(PrismTypography.caption())
                    .foregroundStyle(Color.white.opacity(0.55))
                Spacer()
                if let pace = previewPace, let required = pace.requiredPerPeriod {
                    Text("\(CurrencyFormatting.string(from: required, currencyCode: currencyCode)) / \(pace.periodLabel)")
                        .font(PrismTypography.headline())
                }
            }
            .padding(12)
            .background(Capsule().fill(Color.black.opacity(0.35)))
        }
    }

    private func planRow(label: String, value: String, sub: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(PrismTypography.micro())
                .foregroundStyle(Color.white.opacity(0.5))
            Text(value).font(PrismTypography.headline())
            if let sub {
                Text(sub)
                    .font(PrismTypography.caption())
                    .foregroundStyle(PrismColors.textSecondary)
            }
            Divider().overlay(Color.white.opacity(0.12))
        }
    }

    private var contributionPlanLine: String {
        if let pace = previewPace, let required = pace.requiredPerPeriod {
            return "\(CurrencyFormatting.string(from: required, currencyCode: currencyCode)) every \(pace.periodLabel)"
        }
        return "Set a target to see your pace"
    }

    private var bufferedAmount: Decimal? {
        guard let target = DecimalParsing.parse(targetAmountText) else { return nil }
        return (target * Decimal(8)) / Decimal(100)
    }

    private var bufferedPlanTotal: Decimal? {
        guard let target = DecimalParsing.parse(targetAmountText) else { return nil }
        guard includesBuffer else { return target }
        return (target * Decimal(108)) / Decimal(100)
    }

    private var currencyCode: String {
        environment.profile?.spendingPocket.currencyCode
            ?? Locale.current.currency?.identifier
            ?? "USD"
    }

    private func priorityTitle(_ level: GoalPriorityLevel) -> String {
        switch level {
        case .primary: return "Primary goal (limit 1)"
        case .active: return "Active goal (up to 3)"
        case .flexible: return "Flexible goal (unlimited)"
        case .someday: return "Someday goal (unlimited)"
        }
    }

    private func priorityHint(_ level: GoalPriorityLevel) -> String {
        switch level {
        case .primary: return "Funded before anything else, every month."
        case .active: return "Funded alongside your other active goals."
        case .flexible: return "Tracked and visible, but not funded yet."
        case .someday: return "Parked. No money moves until you say so."
        }
    }

    private func inferredType(from item: SavedItem) -> GoalType {
        switch item.intent {
        case .dream: return .experience
        case .need, .gift, .want: return .purchase
        }
    }

    private func draftGoal() -> PrismGoal? {
        guard let userID = environment.profile?.id else { return nil }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let target = DecimalParsing.parse(targetAmountText)
        let saved = DecimalParsing.parse(alreadySavedText) ?? 0
        var descriptionParts: [String] = []
        if !goalDescription.isEmpty { descriptionParts.append(goalDescription) }
        if !whereText.isEmpty { descriptionParts.append("Where: \(whereText)") }
        if !relevantDateNote.isEmpty { descriptionParts.append(relevantDateNote) }
        if !spendingCategory.isEmpty { descriptionParts.append("Category: \(spendingCategory)") }
        let desc = descriptionParts.isEmpty ? nil : descriptionParts.joined(separator: " · ")
        return PrismGoal(
            id: UUID(),
            userID: userID,
            sourceAspirationID: sourceItem?.id,
            title: trimmed,
            goalDescription: desc,
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
            if sourceCollection != nil {
                try await saveComponents(for: goal)
                container.analytics.track(.goalFromCollectionCreated)
            }
            container.analytics.track(.goalCreated)
            PrismHaptics.save()
            dismiss()
        } catch {
            errorText = "Couldn’t create the goal. Try again."
            container.crashReporter.record(error: error, context: "goal.setup")
        }
    }

    private func saveComponents(for goal: PrismGoal) async throws {
        for (index, item) in includedItems.enumerated() {
            try await container.goalRepository.upsertComponent(
                GoalComponent(
                    id: UUID(),
                    userID: goal.userID,
                    goalID: goal.id,
                    name: item.title,
                    estimatedCost: item.estimatedPrice,
                    currencyCode: item.estimatedPrice == nil ? nil : (item.estimatedCurrencyCode ?? goal.currencyCode),
                    isOptional: false,
                    role: .essential,
                    sortOrder: index,
                    createdAt: .now
                )
            )
            try await container.goalRepository.linkAspiration(
                GoalAspirationLink(
                    id: UUID(),
                    userID: goal.userID,
                    goalID: goal.id,
                    savedItemID: item.id,
                    role: .essential,
                    createdAt: .now
                )
            )
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

private enum StepKind {
    case paste, define, motivation, target, priority, plan
}
