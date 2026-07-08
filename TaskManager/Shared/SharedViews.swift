import SwiftUI

#if os(iOS)
import UIKit
#endif

struct EmptyStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct AppEditButton: View {
    var body: some View {
        #if os(iOS)
        EditButton()
        #else
        EmptyView()
        #endif
    }
}

struct AddTextItemView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let placeholder: String
    let onSave: (String) -> Void

    @State private var value = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(placeholder, text: $value)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        onSave(value.trimmedOrFallback("Без названия"))
                        dismiss()
                    }
                }
            }
        }
    }
}

extension Double {
    var moneyString: String {
        formatted(.currency(code: "RUB").precision(.fractionLength(0)))
    }
}

extension String {
    func trimmedOrFallback(_ fallback: String) -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

extension Calendar {
    static var app: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        return calendar
    }

    func startOfWeek(containing date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}

extension Date {
    static func time(from value: String) -> Date? {
        let components = value.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else {
            return nil
        }

        var dateComponents = Calendar.app.dateComponents([.year, .month, .day], from: Date())
        dateComponents.hour = components[0]
        dateComponents.minute = components[1]
        return Calendar.app.date(from: dateComponents)
    }

    var shortDateString: String {
        formatted(.dateTime.day().month(.twoDigits).year(.twoDigits))
    }

    var dayMonthString: String {
        formatted(.dateTime.day().month(.wide))
    }

    var weekdayString: String {
        formatted(.dateTime.weekday(.wide))
    }

    var timeString: String {
        formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }
}

struct PlannerDate: Identifiable {
    let date: Date

    var id: TimeInterval {
        date.timeIntervalSinceReferenceDate
    }
}

enum AppColor {
    static var groupedBackground: Color {
        #if os(iOS)
        Color(.systemGroupedBackground)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    static var secondaryGroupedBackground: Color {
        #if os(iOS)
        Color(.secondarySystemGroupedBackground)
        #else
        Color(nsColor: .controlBackgroundColor)
        #endif
    }

    static var systemBackground: Color {
        #if os(iOS)
        Color(.systemBackground)
        #else
        Color(nsColor: .textBackgroundColor)
        #endif
    }
}

extension View {
    @ViewBuilder
    func appDismissKeyboardOnTap() -> some View {
        #if os(iOS)
        overlay(KeyboardDismissTapLayer().allowsHitTesting(false))
        #else
        self
        #endif
    }

    @ViewBuilder
    func appDecimalKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    @ViewBuilder
    func appNumbersAndPunctuationKeyboard() -> some View {
        #if os(iOS)
        keyboardType(.numbersAndPunctuation)
        #else
        self
        #endif
    }

    @ViewBuilder
    func appLowercaseInput() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    @ViewBuilder
    func appInlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func appAlwaysEditMode() -> some View {
        #if os(iOS)
        environment(\.editMode, .constant(.active))
        #else
        self
        #endif
    }
}

#if os(iOS)
private struct KeyboardDismissTapLayer: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async {
            context.coordinator.installIfNeeded(from: view)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.installIfNeeded(from: uiView)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var window: UIWindow?
        private weak var recognizer: UITapGestureRecognizer?

        deinit {
            if let recognizer {
                window?.removeGestureRecognizer(recognizer)
            }
        }

        func installIfNeeded(from view: UIView) {
            guard let window = view.window, self.window !== window else {
                return
            }

            if let recognizer {
                self.window?.removeGestureRecognizer(recognizer)
            }

            let recognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            window.addGestureRecognizer(recognizer)

            self.window = window
            self.recognizer = recognizer
        }

        @objc private func dismissKeyboard() {
            window?.endEditing(true)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard let view = touch.view else {
                return true
            }

            return !view.hasKeyboardInputOrControlAncestor
        }
    }
}

private extension UIView {
    var hasKeyboardInputOrControlAncestor: Bool {
        var currentView: UIView? = self

        while let view = currentView {
            if view is UITextField || view is UITextView || view is UIControl {
                return true
            }

            currentView = view.superview
        }

        return false
    }
}
#endif
