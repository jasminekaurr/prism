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
    /// Extracts a displayable domain.
    static func domain(from url: URL?) -> String? {
        guard let url else { return nil }
        return url.host
    }

    /// Normalizes pasted text into an http(s) URL, adding `https://` when the scheme is missing.
    static func normalizedURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = validatedHTTPSURL(from: trimmed) {
            return url
        }

        // Common paste: "www.example.com/path" or "example.com/path"
        let withScheme: String
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
            withScheme = trimmed
        } else {
            withScheme = "https://\(trimmed)"
        }
        return validatedHTTPSURL(from: withScheme)
    }

    static func validatedHTTPSURL(from string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = components.host,
              !host.isEmpty else {
            return nil
        }
        components.scheme = scheme
        return components.url
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
