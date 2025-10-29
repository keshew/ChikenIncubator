import SwiftUI
import SwiftUI
import PhotosUI

// MARK: - Модели

struct Egg: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    let incubationDays: Int
    var turnedToday: Bool
    let expectedHatchDate: Date
    var hatched: Bool
}

struct Chick: Identifiable, Codable {
    let id: UUID
    var name: String
    let hatchDate: Date
    var weightHistory: [ChickWeight]
    var healthStatus: String
    var photoName: String?
}

struct ChickWeight: Codable, Identifiable {
    let id: UUID
    let date: Date
    let weight: Double
}

struct Hen: Identifiable, Codable {
    let id: UUID
    var name: String
    var eggCount: Int   // за неделю
    var feedTime: Date?
    var healthStatus: String
    var breed: String
    var photoName: String?
}

struct EnvironmentData: Codable {
    var temperature: Double
    var humidity: Double
}

struct LogEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let description: String
}

struct NotificationTask: Codable, Identifiable {
    let id: UUID
    let title: String
    var date: Date
    var done: Bool
}

class DataManager: ObservableObject {
    static let shared = DataManager()
    private let eggsKey = "eggsKey"
    private let chicksKey = "chicksKey"
    private let hensKey = "hensKey"
    private let envKey = "envKey"
    private let logsKey = "logsKey"
    private let tasksKey = "tasksKey"

    @Published var eggs: [Egg] = [] { didSet { saveEggs() } }
    @Published var chicks: [Chick] = [] { didSet { saveChicks() } }
    @Published var hens: [Hen] = [] { didSet { saveHens() } }
    @Published var environment: EnvironmentData = EnvironmentData(temperature: 37.5, humidity: 55) { didSet { saveEnv() } }
    @Published var logs: [LogEntry] = [] { didSet { saveLogs() } }
    @Published var tasks: [NotificationTask] = [] { didSet { saveTasks() } }

    init() {
        loadAll()
    }

    private func loadAll() {
        eggs = (UserDefaults.standard.codable(forKey: eggsKey) ?? [])
        chicks = (UserDefaults.standard.codable(forKey: chicksKey) ?? [])
        hens = (UserDefaults.standard.codable(forKey: hensKey) ?? [])
        environment = (UserDefaults.standard.codable(forKey: envKey) ?? EnvironmentData(temperature: 37.5, humidity: 55))
        logs = (UserDefaults.standard.codable(forKey: logsKey) ?? [])
        tasks = (UserDefaults.standard.codable(forKey: tasksKey) ?? [])
    }

    private func saveEggs() { UserDefaults.standard.set(value: eggs, forKey: eggsKey) }
    private func saveChicks() { UserDefaults.standard.set(value: chicks, forKey: chicksKey) }
    private func saveHens() { UserDefaults.standard.set(value: hens, forKey: hensKey) }
    private func saveEnv() { UserDefaults.standard.set(value: environment, forKey: envKey) }
    private func saveLogs() { UserDefaults.standard.set(value: logs, forKey: logsKey) }
    private func saveTasks() { UserDefaults.standard.set(value: tasks, forKey: tasksKey) }
}

extension UserDefaults {
    func set<Element: Codable>(value: Element, forKey key: String) {
        let data = try? JSONEncoder().encode(value)
        set(data, forKey: key)
    }
    func codable<Element: Codable>(forKey key: String) -> Element? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Element.self, from: data)
    }
}


struct ContentView: View {
    var body: some View {
        TabView {
            IncubatorScreen()
                .tabItem { Label("Incubator", systemImage: "circle.hexagongrid") }
            ChicksScreen()
                .tabItem { Label("Chicks", systemImage: "bird.fill") }
            HensScreen()
                .tabItem { Label("Hens", systemImage: "rosette") }
            HealthScreen()
                .tabItem { Label("Health", systemImage: "heart.circle.fill") }
            GrowthScreen()
                .tabItem { Label("Growth", systemImage: "chart.line.uptrend.xyaxis") }
            NotificationsScreen()
                .tabItem { Label("Tasks", systemImage: "bell.fill") }
            LogScreen()
                .tabItem { Label("Log", systemImage: "list.bullet.rectangle") }
        }
        .accentColor(.brown)
        .toolbarBackground(Color(red:0.97, green:0.94, blue:0.89), for: .tabBar)
    }
}
#Preview {
    ContentView()
        .environmentObject(DataManager())
}


struct IncubatorScreen: View {
    @EnvironmentObject var data: DataManager
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    if data.eggs.isEmpty {
                        Spacer()
                        Text("No eggs yet")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(data.eggs) { egg in
                                    EggRow(egg: egg)
                                        .padding()
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(10)
                                        .shadow(radius: 2)
                                }
                            }
                            .padding()
                        }
                    }
                    Button(action: { showAdd = true }) {
                        Label("Add Egg", systemImage: "plus.circle.fill")
                            .font(.title2)
                            .padding()
                    }
                }
                .background(Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea())
                .navigationTitle("Incubator")
                .sheet(isPresented: $showAdd) {
                    AddEggScreen()
                }
            }
        }
    }
}


struct EggRow: View {
    @EnvironmentObject var data: DataManager
    let egg: Egg

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Incubation days left: \(max(0, daysLeft()))")
                Spacer()
                if egg.hatched {
                    Text("Hatched").foregroundColor(.green)
                } else {
                    Button("Turned Today: \(egg.turnedToday ? "Yes" : "No")") {
                        toggleTurned()
                    }
                    .foregroundColor(egg.turnedToday ? .green : .orange)
                }
            }
            Text("Expected: \(egg.expectedHatchDate, formatter: DateFormatter.shortDate)").font(.subheadline)
        }
    }
    private func daysLeft() -> Int {
        let total = egg.incubationDays
        let passed = Calendar.current.dateComponents([.day], from: egg.startDate, to: Date()).day ?? 0
        return max(0, total - passed)
    }
    private func toggleTurned() {
        if let idx = data.eggs.firstIndex(where: { $0.id == egg.id }) {
            data.eggs[idx].turnedToday.toggle()
        }
    }
}

struct AddEggScreen: View {
    @EnvironmentObject var data: DataManager
    @Environment(\.dismiss) var dismiss

    @State private var incubationDays = 21
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        DatePicker("Start Date", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding()
                        
                        Stepper("Incubation Days: \(incubationDays)", value: $incubationDays, in: 18...24)
                            .padding()
                        
                        Spacer()
                        
                        Button("Add Egg") {
                            let egg = Egg(
                                id: UUID(),
                                startDate: date,
                                incubationDays: incubationDays,
                                turnedToday: false,
                                expectedHatchDate: Calendar.current.date(byAdding: .day, value: incubationDays, to: date) ?? Date().addingTimeInterval(Double(incubationDays)*86400),
                                hatched: false)
                            data.eggs.append(egg)
                            data.logs.append(LogEntry(id: UUID(), date: Date(), description: "Egg added, hatch expected \(egg.expectedHatchDate.formatted(date: .numeric, time: .omitted))"))
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom)
                    }
                    .padding()
                    .background(Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea())
                    .navigationTitle("Add Egg")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") { dismiss() }
                        }
                    }
                }
            }
        }
    }
}


struct ChicksScreen: View {
    @EnvironmentObject var data: DataManager
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    if data.chicks.isEmpty {
                        Spacer()
                        Text("No Chicks Yet")
                            .foregroundColor(.gray)
                            .font(.title3)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(data.chicks) { chick in
                                    NavigationLink(destination: ChickDetailScreen(chick: chick)) {
                                        ChickRow(chick: chick)
                                            .padding() // растягиваем по ширине
                                            .background(Color.white.opacity(0.8))
                                            .cornerRadius(10)
                                            .shadow(radius: 2)
                                    }
                                    // отступы слева и справа
                                }
                                
                            }
                            .padding()
                        }
                    }
                    Button(action: { showAdd = true }) {
                        Label("Add Chick", systemImage: "plus.circle.fill")
                            .font(.title2)
                            .padding()
                    }
                }
                .background(Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea())
                .navigationTitle("Chicks")
                .sheet(isPresented: $showAdd) {
                    AddChickScreen()
                }
            }
        }
    }
}

struct ChickRow: View {
    let chick: Chick
    var body: some View {
        HStack {
            if let photo = chick.photoName, let uiImg = loadImage(name: photo) {
                Image(uiImage: uiImg)
                    .resizable().frame(width:44, height:44).clipShape(Circle())
            }
            VStack(alignment: .leading) {
                Text(chick.name).bold()
                Text("Age: \(daysOld(chick: chick)) days")
                Text("Health: \(chick.healthStatus)")
            }
            .padding(.leading, 10 )
            Spacer()
        }
        
        .frame(maxWidth: .infinity)
    }
    func daysOld(chick: Chick) -> Int {
        Calendar.current.dateComponents([.day], from: chick.hatchDate, to: Date()).day ?? 0
    }
}

func loadImage(name:String) -> UIImage? {
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
    return UIImage(contentsOfFile: url.path)
}

struct AddChickScreen: View {
    @EnvironmentObject var data: DataManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var hatchDate = Date()
    @State private var weight: Double = 0.05
    @State private var healthStatus = "Healthy"
    @State private var photo: UIImage?
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    DatePicker("Hatch Date", selection: $hatchDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding(.horizontal)

                    Stepper("Start Weight: \(weight, specifier: "%.2f") kg", value: $weight, in: 0.01...0.2, step: 0.01)
                        .padding(.horizontal)

                    TextField("Health Status", text: $healthStatus)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    Button("Add Photo") {
                        showPicker = true
                    }
                    .padding(.horizontal)

                    if let photo = photo {
                        Image(uiImage: photo)
                            .resizable()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                            .padding()
                    }

                    Spacer()

                    Button("Add") {
                        let photoName = saveImage(image: photo)
                        let new = Chick(
                            id: UUID(), name: name, hatchDate: hatchDate,
                            weightHistory: [ChickWeight(id: UUID(), date: hatchDate, weight: weight)],
                            healthStatus: healthStatus, photoName: photoName
                        )
                        data.chicks.append(new)
                        data.logs.append(LogEntry(id: UUID(), date: Date(), description: "\(name) chick added"))
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .padding()

                }
            }
            .background(Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea())
            .navigationTitle("Add Chick")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .photosPicker(isPresented: $showPicker, selection: Binding<PhotosPickerItem?>(
                get: { nil },
                set: { item in
                    item?.loadTransferable(type: Data.self) { result in
                        if case let .success(data?) = result,
                           let img = UIImage(data: data) {
                            self.photo = img
                        }
                    }
                })
            )
        }
    }

    func saveImage(image: UIImage?) -> String? {
        guard let img = image,
              let data = img.jpegData(compressionQuality: 0.7) else {
            return nil
        }
        let fileName = UUID().uuidString + ".jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        try? data.write(to: url)
        return fileName
    }
}


struct ChickDetailScreen: View {
    @EnvironmentObject var data: DataManager
    let chick: Chick
    @State private var newWeight: Double = 0
    @State private var healthStatus: String = ""

    var body: some View {
        Form {
            Text(chick.name).font(.largeTitle).bold()
            HStack {
                if let photo = chick.photoName, let img = loadImage(name: photo) {
                    Image(uiImage: img).resizable().frame(width:88, height:88).clipShape(Circle())
                }
                VStack(alignment:.leading) {
                    Text("Age: \(Calendar.current.dateComponents([.day], from: chick.hatchDate, to: Date()).day ?? 0) days")
                    Text("Health: \(chick.healthStatus)")
                }
            }
            Section("History") {
                ForEach(chick.weightHistory) { entry in
                    HStack {
                        Text("\(entry.date, formatter: DateFormatter.shortDate)")
                        Spacer()
                        Text("Weight: \(entry.weight, specifier: "%.2f") kg")
                    }
                }
            }
            Section("Update") {
                Stepper("Weight: \(newWeight, specifier: "%.2f") kg", value: $newWeight, in: 0.01...0.5, step: 0.01)
                TextField("Health Status", text: $healthStatus)
                Button("Save changes") {
                    if let idx = data.chicks.firstIndex(where: { $0.id == chick.id }) {
                        data.chicks[idx].weightHistory.append(ChickWeight(id: UUID(), date: Date(), weight: newWeight))
                        if !healthStatus.isEmpty {
                            data.chicks[idx].healthStatus = healthStatus
                        }
                        data.logs.append(LogEntry(id: UUID(), date: Date(), description: "\(chick.name) status/weight updated"))
                    }
                }
            }
        }
        .onAppear {
            newWeight = chick.weightHistory.last?.weight ?? 0
            healthStatus = chick.healthStatus
        }
    }
}

struct HensScreen: View {
    @EnvironmentObject var data: DataManager
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    if data.hens.isEmpty {
                        Spacer()
                        Text("No Hens Yet")
                            .foregroundColor(.gray)
                            .font(.title3)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(data.hens) { hen in
                                    HStack {
                                        if let photo = hen.photoName, let uiImg = loadImage(name: photo) {
                                            Image(uiImage: uiImg)
                                                .resizable()
                                                .frame(width: 50, height: 50)
                                                .clipShape(Circle())
                                        }
                                        VStack(alignment: .leading) {
                                            Text(hen.name).bold()
                                            Text("Breed: \(hen.breed)")
                                            Text("Eggs this week: \(hen.eggCount)")
                                            Text("Health: \(hen.healthStatus)")
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(10)
                                    .shadow(radius: 2)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                    Button {
                        showAdd = true
                    } label: {
                        Label("Add Hen", systemImage: "plus.circle.fill")
                            .font(.title2)
                            .padding()
                    }
                }
                .background(Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea())
                .navigationTitle("Hens")
                .sheet(isPresented: $showAdd) {
                    AddHenScreen()
                }
            }
        }
    }

    func loadImage(name: String) -> UIImage? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
        return UIImage(contentsOfFile: url.path)
    }
}

struct AddHenScreen: View {
    @EnvironmentObject var data: DataManager
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var breed = ""
    @State private var healthStatus = "Healthy"
    @State private var eggCount = 0
    @State private var photo: UIImage?
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    TextField("Breed", text: $breed)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    TextField("Health Status", text: $healthStatus)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                    Stepper("Egg count this week: \(eggCount)", value: $eggCount, in: 0...50)
                        .padding(.horizontal)

                    Button("Add Photo") {
                        showPicker = true
                    }
                    .padding(.horizontal)

                    if let photo = photo {
                        Image(uiImage: photo)
                            .resizable()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                            .padding()
                    }

                    Spacer()

                    Button("Add") {
                        let photoName = saveImage(image: photo)
                        let newHen = Hen(
                            id: UUID(),
                            name: name,
                            eggCount: eggCount,
                            feedTime: nil,
                            healthStatus: healthStatus,
                            breed: breed,
                            photoName: photoName)
                        data.hens.append(newHen)
                        data.logs.append(LogEntry(id: UUID(), date: Date(), description: "Hen \(name) added"))
                        dismiss()
                    }
                    .disabled(name.isEmpty || breed.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .background(Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea())
            .navigationTitle("Add Hen")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .photosPicker(isPresented: $showPicker, selection: Binding<PhotosPickerItem?>(
                get: { nil },
                set: { item in
                    item?.loadTransferable(type: Data.self) { result in
                        if case let .success(data?) = result, let img = UIImage(data: data) {
                            self.photo = img
                        }
                    }
                })
            )
        }
    }

    func saveImage(image: UIImage?) -> String? {
        guard let img = image, let data = img.jpegData(compressionQuality: 0.7) else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        do {
            try data.write(to: url)
            return fileName
        } catch {
            print("Error saving image:", error)
            return nil
        }
    }
}


struct HealthScreen: View {
    @EnvironmentObject var data: DataManager
    @State private var tempInput = ""
    @State private var humidityInput = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Incubator Environment")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            TextField("Temperature (°C)", text: $tempInput)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)
                            
                            TextField("Humidity (%)", text: $humidityInput)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal)
                            
                            Button("Update") {
                                if let temp = Double(tempInput), let hum = Double(humidityInput) {
                                    data.environment.temperature = temp
                                    data.environment.humidity = hum
                                    data.logs.append(LogEntry(id: UUID(), date: Date(), description: "Environment updated: Temp \(temp)°C, Humidity \(hum)%"))
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.horizontal)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Summary")
                                .font(.headline)
                            //
                            
                            Text("Temperature: \(data.environment.temperature, specifier: "%.1f") °C")
                            
                            
                            Text("Humidity: \(data.environment.humidity, specifier: "%.0f") %")
                            
                            
                            Text("Chicks Health Summary: \(healthSummary())")
                            
                            
                            Text("Hens Health Summary: \(healthSummaryHens())")
                            
                        }
                        .padding(.horizontal)
                        Spacer()
                    }
                    .padding(.vertical)
                }
                .background(Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea())
                .navigationTitle("Health")
                .onAppear {
                    tempInput = "\(data.environment.temperature)"
                    humidityInput = "\(Int(data.environment.humidity))"
                }
            }
        }
    }

    func healthSummary() -> String {
        let statuses = data.chicks.map { $0.healthStatus }
        let unhealthy = statuses.filter { !$0.lowercased().contains("healthy") }
        return unhealthy.isEmpty ? "All healthy" : "\(unhealthy.count) chick(s) need attention"
    }

    func healthSummaryHens() -> String {
        let statuses = data.hens.map { $0.healthStatus }
        let unhealthy = statuses.filter { !$0.lowercased().contains("healthy") }
        return unhealthy.isEmpty ? "All healthy" : "\(unhealthy.count) hen(s) need attention"
    }
}


import Charts
import SwiftUI

struct GrowthScreen: View {
    @EnvironmentObject var data: DataManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(data.chicks) { chick in
                            VStack(alignment: .leading) {
                                Text(chick.name)
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                Chart {
                                    ForEach(chick.weightHistory) { w in
                                        LineMark(
                                            x: .value("Date", w.date),
                                            y: .value("Weight", w.weight)
                                        )
                                        .interpolationMethod(.catmullRom)
                                    }
                                }
                                .frame(height: 150)
                                .padding([.horizontal, .bottom])
                            }
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 2)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea())
                .navigationTitle("Growth")
            }
        }
    }
}


struct NotificationsScreen: View {
    @EnvironmentObject var data: DataManager
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    if data.tasks.isEmpty {
                        Spacer()
                        Text("No Tasks Yet")
                            .foregroundColor(.gray)
                            .font(.title3)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(data.tasks) { task in
                                    HStack {
                                        Text(task.title)
                                        Spacer()
                                        Text(task.date, style: .date)
                                        Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(task.done ? .green : .gray)
                                            .onTapGesture { toggleDone(task) }
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(10)
                                    .shadow(radius: 2)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                    Button {
                        showAdd = true
                    } label: {
                        Label("Add Task", systemImage: "plus.circle.fill")
                            .font(.title2)
                            .padding()
                    }
                }
                .background(Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea())
                .navigationTitle("Tasks")
                .sheet(isPresented: $showAdd) {
                    AddNotificationScreen()
                }
            }
        }
    }

    func toggleDone(_ task: NotificationTask) {
        if let idx = data.tasks.firstIndex(where: { $0.id == task.id }) {
            data.tasks[idx].done.toggle()
        }
    }
}

struct AddNotificationScreen: View {
    @EnvironmentObject var data: DataManager
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        TextField("Title", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                        
                        DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.graphical)
                            .padding(.horizontal)
                        
                        Spacer()
                        
                        Button("Add") {
                            let newTask = NotificationTask(id: UUID(), title: title, date: date, done: false)
                            data.tasks.append(newTask)
                            data.logs.append(LogEntry(id: UUID(), date: Date(), description: "New task added: \(title)"))
                            dismiss()
                        }
                        .disabled(title.isEmpty)
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                    .background(Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea())
                    .navigationTitle("Add Task")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}


struct LogScreen: View {
    @EnvironmentObject var data: DataManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea()
                
                VStack {
                    if data.logs.isEmpty {
                        Spacer()
                        Text("No Logs Yet")
                            .foregroundColor(.gray)
                            .font(.title3)
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(data.logs.sorted(by: { $0.date > $1.date })) { log in
                                    VStack(alignment: .leading) {
                                        Text(log.description)
                                            .font(.body)
                                        Text(log.date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(8)
                                    .shadow(radius: 1)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.97, green: 0.94, blue: 0.89).ignoresSafeArea())
                .navigationTitle("Log")
            }
        }
    }
}



extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}
