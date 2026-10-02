import SwiftUI

struct CurrencyPickerView: View {
    @Binding var selectedCurrency: Currency
    let label: String
    var darkMode: Bool = false
    @State private var showingPicker = false

    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            HStack(spacing: 8) {
                Text(selectedCurrency.flag)
                    .font(.app(28, .bold))

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedCurrency.code)
                        .font(.app(17, .semibold))
                        .foregroundColor(darkMode ? .white : AppTheme.primaryText)
                    Text(label)
                        .font(.app(12))
                        .foregroundColor(darkMode ? .white.opacity(0.7) : AppTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.app(12))
                    .foregroundColor(darkMode ? .white.opacity(0.7) : AppTheme.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(darkMode ? Color.white.opacity(0.15) : AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                Rectangle()
                    .stroke(AppTheme.gold.opacity(darkMode ? 0.5 : 0.3), lineWidth: 1)
            )
        }
        .sheet(isPresented: $showingPicker) {
            CurrencyListView(selectedCurrency: $selectedCurrency)
        }
    }
}

struct CurrencyListView: View {
    @Binding var selectedCurrency: Currency
    /// Currencies that need Pro show a lock (picking one still goes through, so
    /// the caller can open the paywall).
    var isLocked: (Currency) -> Bool = { _ in false }
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private static let popularCodes = ["USD", "EUR", "GBP", "JPY", "AUD", "CAD", "MXN", "THB"]

    private var popular: [Currency] {
        Self.popularCodes.compactMap(Currency.currency(for:))
    }

    private var filteredCurrencies: [Currency] {
        guard !searchText.isEmpty else { return Currency.supportedCurrencies }
        return Currency.supportedCurrencies.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.localizedName.localizedCaseInsensitiveContains(searchText) ||
            $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if searchText.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(popular) { currency in
                                    popularChip(currency)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                        }
                    }

                    ForEach(filteredCurrencies) { currency in
                        row(currency)
                    }

                    if filteredCurrencies.isEmpty {
                        Text("No currency matches \u{201C}\(searchText)\u{201D}")
                            .font(.app(15))
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .font(.app(17))
        .background(AppTheme.background)
        .presentationDragIndicator(.visible)
    }

    // MARK: Pieces

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Currency")
                    .font(.app(22, .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.app(14, .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.15), in: Rectangle())
                }
                .accessibilityLabel("Close")
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.secondaryText)
                TextField("Search", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundColor(AppTheme.primaryText)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Color.white, in: Rectangle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(AppTheme.darkBlue)
    }

    private func popularChip(_ currency: Currency) -> some View {
        let palette = FlagPalette.palette(for: currency.flag)
        let isSelected = currency == selectedCurrency
        return Button(action: { select(currency) }) {
            HStack(spacing: 6) {
                Text(currency.flag).font(.app(18))
                Text(currency.code)
                    .font(.app(15, .bold))
                    .foregroundColor(.white)
                if isLocked(currency) {
                    Image(systemName: "lock.fill")
                        .font(.app(10, .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(palette.primary, in: Rectangle())
            .overlay(Rectangle().stroke(AppTheme.gold, lineWidth: isSelected ? 2.5 : 0))
        }
        .accessibilityLabel("\(currency.localizedName)\(isLocked(currency) ? ", Pro" : "")")
    }

    private func row(_ currency: Currency) -> some View {
        let palette = FlagPalette.palette(for: currency.flag)
        let isSelected = currency == selectedCurrency
        return Button(action: { select(currency) }) {
            HStack(spacing: 14) {
                Text(currency.flag)
                    .font(.app(24))
                    .frame(width: 44, height: 44)
                    .background(palette.primary, in: Rectangle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.code)
                        .font(.app(17, .bold))
                        .foregroundColor(AppTheme.primaryText)
                    Text(currency.localizedName)
                        .font(.app(14))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.app(22))
                        .foregroundColor(AppTheme.gold)
                } else if isLocked(currency) {
                    Image(systemName: "lock.fill")
                        .font(.app(13))
                        .foregroundColor(AppTheme.secondaryText.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(isSelected ? AppTheme.lightGold.opacity(0.25) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(currency.localizedName)\(isLocked(currency) ? ", Pro" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func select(_ currency: Currency) {
        selectedCurrency = currency
        dismiss()
    }
}

struct CurrencySwapButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.app(20, .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [AppTheme.gold, AppTheme.darkGold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Rectangle())
                .shadow(color: AppTheme.shadowColor, radius: 4, x: 0, y: 2)
        }
    }
}

struct CurrencySelectionBar: View {
    @EnvironmentObject var currencyManager: CurrencyManager
    var darkMode: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            CurrencyPickerView(
                selectedCurrency: Binding(
                    get: { currencyManager.sourceCurrency },
                    set: { currencyManager.setSourceCurrency($0) }
                ),
                label: "From",
                darkMode: darkMode
            )

            CurrencySwapButton {
                withAnimation(.spring(response: 0.3)) {
                    currencyManager.swapCurrencies()
                }
            }

            CurrencyPickerView(
                selectedCurrency: Binding(
                    get: { currencyManager.destinationCurrency },
                    set: { currencyManager.setDestinationCurrency($0) }
                ),
                label: "To",
                darkMode: darkMode
            )
        }
        .padding(darkMode ? 12 : 0)
        .background(darkMode ? Color.black.opacity(0.6) : Color.clear)
        .cornerRadius(darkMode ? AppTheme.cornerRadius : 0)
    }
}
