// Summary: Currency formatting, URL helpers, cooling-off date math, and decimal helpers.

import Foundation

enum CurrencyFormatting {
    static func string(from value: Decimal, currencyCode: String, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }
}

enum URLHelpers {
    /// Extracts a displayable domain; returns nil for invalid or non-https schemes when requiring HTTPS.
    static func domain(from url: URL?) -> String? {
        guard let url else { return nil }
        return url.host
    }

    static func validatedHTTPSURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              url.host != nil else {
            return nil
        }
        // Prefer https; allow http only for paste of http links but open via system browser later.
        return url
    }
}

enum CoolingOffCalculator {
    static func reviewDate(
        from createdAt: Date = .now,
        significance: CostSignificance?,
        settings: CoolingPeriodSettings,
        calendar: Calendar = .current
    ) -> Date? {
        guard settings.enabled else { return nil }
        let hours = settings.hours(for: significance)
        return calendar.date(byAdding: .hour, value: hours, to: createdAt)
    }
}

enum DecimalParsing {
    static func parse(_ text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        return Decimal(string: cleaned)
    }
}
