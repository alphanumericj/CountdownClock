import SwiftUI

/// Full-screen custom notification view shown when an event arrives.
/// Displayed by NotificationController for the "arrival" category.
struct NotificationView: View {
    let eventTitle: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 10) {
                Text("🎉")
                    .font(.system(size: 40))
                Text("WooHoo!!")
                    .font(.headline)
                    .bold()
                    .foregroundStyle(.white)
                Text("\(eventTitle) is here!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Always present so its onAppear fires as soon as this view appears,
            // without waiting for a second render cycle to insert it conditionally.
            ConfettiView()
        }
    }
}

#Preview {
    NotificationView(eventTitle: "Summer Vacation")
}
