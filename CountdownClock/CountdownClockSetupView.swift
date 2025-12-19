import SwiftUI

struct CountdownClockSetupView: View {
    @State private var eventTitle: String = ""
    @State private var targetDate: Date = Date().addingTimeInterval(3600)
    var onSave: (String, Date) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Countdown Clock Setup")
                .font(.title)
            
            Text("What are you looking forward to?")
                .font(.headline)
            
            TextField("Event name", text: $eventTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Text("When does it happen?")
                .font(.headline)
            
            DatePicker("Target date", selection: $targetDate, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .padding(.horizontal)
            
            Button("OK") {
                onSave(eventTitle, targetDate)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}
