import SwiftUI
import Combine

// KeyboardResponder class to observe keyboard events
class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0
    
    private var keyboardCancellable: AnyCancellable?
    
    init() {
        keyboardCancellable = Publishers.Merge(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
                .map { notification -> CGFloat in
                    let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
                    return keyboardFrame.height
                },
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ -> CGFloat in
                    return 0
                }
        )
        .receive(on: DispatchQueue.main)
        .assign(to: \.currentHeight, on: self)
    }
}

struct CircularProgressBar: View {
    var progress: Double
    var calorieCount: Int
    var totalCalorieTarget: Int
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                .frame(width: 150, height: 150)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(Color(hex: "#ADFF2F"), lineWidth: 20)
                .rotationEffect(Angle(degrees: -90))
                .frame(width: 150, height: 150)
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Calorie count
            Text("\(calorieCount) Cal")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#ADFF2F"))
        }
    }
}

struct ContentView: View {
    @StateObject private var keyboardResponder = KeyboardResponder()
    
    let currentDate = Date()
    let calendar = Calendar.current
    let dateFormatter = DateFormatter()
    
    @State private var highestCalorieIntake: Int = 2500 // Example initial value
    @State private var selectedCalorieTarget: Int = 2000 // Default calorie target
    @State private var showProgressBar: Bool = false
    @State private var currentCalorieCount: Int = 0 // Example current calorie count
    @State private var additionalCalories: String = "" // Text field for adding calories
    @State private var showCongratulationAlert: Bool = false // Alert state variable
    @State private var lastSavedDate: Date = Date.distantPast // Track the last saved date

    let calorieTargets = Array(stride(from: 1000, to: 5000, by: 100)) // Calorie options

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Hello")
                    .foregroundColor(.black)
                    .font(.custom("Avenir Next Medium", size: 28))
                    .offset(y: -10)
                    .fontWeight(.semibold)
                    .padding(.leading, 10)
                
                Text("MUFLI!")
                    .foregroundColor(.black)
                    .font(.custom("Avenir Next Condensed Bold", size: 28))
                    .offset(y: -10)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 15) {
                    Image("Mufli")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))
                        .shadow(radius: 5)
                        .offset(y: -10)
                    
                    Image(systemName: "bell.fill")
                        .foregroundColor(.black)
                        .font(.system(size: 24))
                        .offset(y: -10)
                }
                .padding(.trailing, 10)
            }
            .frame(height: 45)
            .padding(.horizontal)
            .background(Color(hex: "#ADFF2F"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<10) { dayOffset in
                        let date = calendar.date(byAdding: .day, value: dayOffset, to: currentDate) ?? Date()
                        let day = calendar.component(.day, from: date)
                        let month = dateFormatter.monthSymbols[calendar.component(.month, from: date) - 1]

                        VStack {
                            Text("\(day)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#ADFF2F"))
                            Text(month.prefix(3))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60, height: 60)
                        .background(Color(hex: "#333333"))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 10)
            }
            .padding(.vertical, 10)
            .background(Color.black)

            Rectangle()
                .fill(
                    ImagePaint(image: Image(systemName: "circle.fill"), scale: 0.1)
                )
                .frame(height: 8)
                .foregroundColor(Color(hex: "#ADFF2F"))
                .padding(.horizontal, 5)
                .shadow(radius: 10)
                .cornerRadius(10)

            // Organized section for Highest Calorie Intake with everything in one line
            HStack(alignment: .center, spacing: 5) {
                Spacer()
                Text("HIGHEST")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#ADFF2F"))

                Image(systemName: "flame.fill")
                    .foregroundColor(.red)
                
                Text(":  ")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#ADFF2F"))
                
                Text("\(highestCalorieIntake) Cal")
                    .font(.custom("Avenir Next Condensed Bold", size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#ADFF2F"))

                Spacer()
            }
            .padding(.trailing, 20)
            .padding(.vertical, 10)
            .background(Color(hex: "#333333"))
            .cornerRadius(10)
            .padding(.top, 20)
            .padding(.trailing, 10)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Target Calorie Intake: ")
                    .font(.headline)
                    .foregroundColor(Color(hex: "#ADFF2F"))
                
                Picker("Select your target", selection: $selectedCalorieTarget) {
                    ForEach(calorieTargets, id: \.self) { target in
                        Text("\(target) Cal").tag(target)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .font(.custom("Avenir Next Condensed Bold", size: 20))
                .fontWeight(.bold)
                .frame(height: 90)
                .background(Color(hex: "#ADFF2F"))
                .cornerRadius(10)
                .foregroundColor(Color(hex: "#ADFF2F"))
                
                // Button to confirm selection
                Button(action: {
                    currentCalorieCount = 0
                    // Update progress and show progress bar
                    showProgressBar = true
                }) {
                    Text("Set Target")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#333333"))
                        .foregroundColor(Color(hex: "#ADFF2F"))
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 30)
            
            if showProgressBar {
                VStack {
                    CircularProgressBar(
                        progress: min(Double(currentCalorieCount) / Double(selectedCalorieTarget), 1.0),
                        calorieCount: currentCalorieCount,
                        totalCalorieTarget: selectedCalorieTarget
                    )
                    .padding(.top, 80)
                    .frame(width: 200, height: 200)
                    
                    Spacer().frame(height: 50)
                    VStack {
                        HStack(spacing: 10) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 25))
                            
                            TextField("Add Calories", text: $additionalCalories)
                                .keyboardType(.numberPad)
                                .padding(8)
                                .background(Color(hex: "#333333"))
                                .foregroundColor(Color(hex: "#ADFF2F"))
                                .fontWeight(.bold)
                                .font(.system(size: 25))
                                .cornerRadius(8)
                                .frame(width: 260)
                            
                            Button(action: {
                                // Check if the date has changed
                                let currentDay = calendar.startOfDay(for: currentDate)
                                if calendar.compare(lastSavedDate, to: currentDay, toGranularity: .day) == .orderedAscending {
                                    // Reset currentCalorieCount if the date has changed
                                    currentCalorieCount = 0
                                    lastSavedDate = currentDay
                                }
                                
                                // Add calories to the current count
                                if let addedCalories = Int(additionalCalories) {
                                    currentCalorieCount += addedCalories
                                    additionalCalories = ""
                                    
                                    // Check if the new count exceeds the highest intake
                                    if currentCalorieCount > highestCalorieIntake {
                                        highestCalorieIntake = currentCalorieCount
                                    }
                                    
                                    // Check if the target has been reached
                                    if currentCalorieCount >= selectedCalorieTarget {
                                        showCongratulationAlert = true
                                    }
                                }
                            }) {
                                Text("Add")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 20)
                                    .background(Color(hex: "#333333"))
                                    .foregroundColor(Color(hex: "#ADFF2F"))
                                    .cornerRadius(10)
                            }
                            .disabled(additionalCalories.isEmpty) // Disable if no input
                        }
                        .padding(.top, 30)
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            Spacer()
            
            VStack {
                            HStack {
                                Image(systemName: "c.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                                
                                Text("All Rights Reserved")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            .padding(.bottom, 20)
                        }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .alert(isPresented: $showCongratulationAlert) {
            Alert(
                title: Text("Congratulations!"),
                message: Text("You've reached your calorie target!"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// Extension to handle custom colors
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
