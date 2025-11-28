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
                    .font(.title)

                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedCurrency.code)
                        .font(.headline)
                        .foregroundColor(darkMode ? .white : AppTheme.primaryText)
                    Text(label)
                        .font(.caption)
                        .foregroundColor(darkMode ? .white.opacity(0.7) : AppTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(darkMode ? .white.opacity(0.7) : AppTheme.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(darkMode ? Color.white.opacity(0.15) : AppTheme.cardBackground)
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
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
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredCurrencies: [Currency] {
        if searchText.isEmpty {
            return Currency.supportedCurrencies
        }
        return Currency.supportedCurrencies.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            List(filteredCurrencies) { currency in
                Button(action: {
                    selectedCurrency = currency
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Text(currency.flag)
                            .font(.title)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.code)
                                .font(.headline)
                                .foregroundColor(AppTheme.primaryText)
                            Text(currency.name)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.secondaryText)
                        }

                        Spacer()

                        if currency == selectedCurrency {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.gold)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .searchable(text: $searchText, prompt: "Search currencies")
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.blue)
                }
            }
        }
    }
}

struct CurrencySwapButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [AppTheme.gold, AppTheme.darkGold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
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
