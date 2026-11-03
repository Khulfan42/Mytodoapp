import SwiftUI
import CoreData
import UserNotifications

// MARK: - Enums & Models
enum TaskCategory: String, CaseIterable, Identifiable {
    case work = "Work"
    case study = "Study"
    case personal = "Personal"
    case other = "Other"
    
    var id: String { self.rawValue }
}

enum TaskPriority: String, CaseIterable, Identifiable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var id: String { self.rawValue }
}

struct TaskItemModel: Identifiable {
    let id: UUID
    var title: String
    var category: TaskCategory
    var priority: TaskPriority
    var dueDate: Date
    var isCompleted: Bool
}


// MARK: - App Navigation Tabs
enum AppTab {
    case home
    case calendar
    case activity
    case profile
}

// MARK: - Main Content View
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TodoItem.dueDate, ascending: true)],
        animation: .default
    )
    private var savedTasks: FetchedResults<TodoItem>

    // Navigation & State
    @State private var currentTab: AppTab = .home
    @State private var isShowingAddSheet = false
    @State private var searchText = ""
    @State private var selectedDateIndex = 2 // Aug 30 default

    // Dates for Calendar Strip
    let calendarDays: [(day: String, weekday: String)] = [
        ("28", "Wed"),
        ("29", "Thu"),
        ("30", "Fri"),
        ("31", "Sat"),
        ("01", "Sun")
    ]

    // Computed Tasks from Core Data
    private var tasks: [TaskItemModel] {
        savedTasks.compactMap { item in
            guard
                let id = item.id,
                let title = item.title,
                let category = TaskCategory(rawValue: item.category ?? ""),
                let priority = TaskPriority(rawValue: item.priority ?? ""),
                let dueDate = item.dueDate
            else {
                return nil
            }

            return TaskItemModel(
                id: id,
                title: title,
                category: category,
                priority: priority,
                dueDate: dueDate,
                isCompleted: item.isCompleted
            )
        }
    }

    private var filteredTasks: [TaskItemModel] {
        if searchText.isEmpty {
            return tasks
        }
        return tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Deep Dark Background
            Color(red: 14/255, green: 12/255, blue: 21/255)
                .ignoresSafeArea()

            // Active Tab View
            Group {
                switch currentTab {
                case .home:
                    homeDashboardView
                case .calendar:
                    todayTasksView
                case .activity:
                    activityLogView
                case .profile:
                    welcomeOnboardingView
                }
            }
            .padding(.bottom, 75) // Space for bottom tab bar

            // MARK: - Floating Purple Tab Bar
            customBottomTabBar
        }
        .sheet(isPresented: $isShowingAddSheet) {
            AddTaskSheetView { title, category, priority, dueDate in
                createTask(title: title, category: category, priority: priority, dueDate: dueDate)
            }
        }
        .onAppear {
            requestNotificationPermission()
            seedInitialDemoTasksIfEmpty()
        }
    }

    // MARK: - SCREEN 1: Home Dashboard View
    private var homeDashboardView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Top Header (User profile + Bell)
                HStack(spacing: 12) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(Image(systemName: "person.crop.circle.fill").font(.system(size: 24)).foregroundColor(.white))
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1.5))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hello!")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("Roshitha Krishnamoorthy")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Bell Icon
                    Button(action: {}) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color(red: 24/255, green: 22/255, blue: 34/255))
                                .clipShape(Circle())

                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 2, y: 2)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search", text: $searchText)
                        .foregroundColor(.white)
                    Image(systemName: "mic.fill")
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(red: 24/255, green: 22/255, blue: 34/255))
                .cornerRadius(14)
                .padding(.horizontal)

                // Banner: "Hectic week ahead of you!"
                VStack(alignment: .leading, spacing: 14) {
                    Text("You have a really hectic week\nahead of you!")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .lineSpacing(4)

                    HStack {
                        // Avatar stack with +
                        HStack(spacing: -8) {
                            Circle().fill(Color.orange).frame(width: 26, height: 26)
                                .overlay(Text("👨🏻‍💻").font(.system(size: 12)))
                            Circle().fill(Color.blue).frame(width: 26, height: 26)
                                .overlay(Text("👩🏼‍🎨").font(.system(size: 12)))
                            Circle().fill(Color.purple).frame(width: 26, height: 26)
                                .overlay(Text("🧑🏽‍💼").font(.system(size: 12)))
                            Circle().fill(Color.white.opacity(0.3)).frame(width: 26, height: 26)
                                .overlay(Image(systemName: "plus").font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                        }

                        Spacer()

                        // Progress pill
                        HStack(spacing: 6) {
                            Text("Progress")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.8))
                            Text("65%")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                    }
                }
                .padding(18)
                .background(
                    LinearGradient(
                        colors: [Color(red: 124/255, green: 58/255, blue: 237/255), Color(red: 76/255, green: 29/255, blue: 149/255)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(22)
                .shadow(color: Color(red: 124/255, green: 58/255, blue: 237/255).opacity(0.4), radius: 10, y: 5)
                .padding(.horizontal)

                // Section: In progress
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("In progress")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Circle()
                            .fill(Color(red: 124/255, green: 58/255, blue: 237/255))
                            .frame(width: 20, height: 20)
                            .overlay(Text("2").font(.system(size: 11, weight: .bold)).foregroundColor(.white))
                        Spacer()
                    }
                    .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            inProgressCard(
                                category: "UI/UX Design",
                                priority: "High",
                                title: "Create e-landing page",
                                progress: 0.55,
                                date: "Mon, 1 Sept 2024"
                            )
                            inProgressCard(
                                category: "UI/UX Design",
                                priority: "Medium",
                                title: "Design a website",
                                progress: 0.40,
                                date: "Wed, 3 Sept 2024"
                            )
                        }
                        .padding(.horizontal)
                    }
                }

                // Section: Today Task
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Today Task")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Circle()
                            .fill(Color(red: 124/255, green: 58/255, blue: 237/255))
                            .frame(width: 20, height: 20)
                            .overlay(Text("\(filteredTasks.count)").font(.system(size: 11, weight: .bold)).foregroundColor(.white))
                        Spacer()
                    }
                    .padding(.horizontal)

                    LazyVStack(spacing: 12) {
                        ForEach(filteredTasks) { task in
                            TaskCardView(
                                task: task,
                                isActiveCard: false,
                                onToggleComplete: { toggleComplete(taskID: task.id) },
                                onEdit: {}
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - In Progress Card Component
    private func inProgressCard(category: String, priority: String, title: String, progress: Double, date: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category)
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 124/255, green: 58/255, blue: 237/255).opacity(0.3))
                    .foregroundColor(Color(red: 196/255, green: 181/255, blue: 253/255))
                    .cornerRadius(6)

                Spacer()

                Text(priority)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(6)
            }

            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)

            HStack {
                HStack(spacing: -6) {
                    Circle().fill(Color.orange).frame(width: 20, height: 20)
                    Circle().fill(Color.blue).frame(width: 20, height: 20)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Progress")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            ProgressView(value: progress)
                .accentColor(Color(red: 124/255, green: 58/255, blue: 237/255))

            Text(date)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .padding(14)
        .frame(width: 220)
        .background(Color(red: 22/255, green: 20/255, blue: 30/255))
        .cornerRadius(18)
    }

    // MARK: - SCREEN 2: Today's Tasks / Calendar View
    private var todayTasksView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack {
                    Button(action: { currentTab = .home }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text("Today 's Task")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // Date Strip (Aug 28 Wed, 29 Thu, 30 Fri, 31 Sat, Sept 01 Sun)
                HStack(spacing: 8) {
                    ForEach(0..<calendarDays.count, id: \.self) { index in
                        let item = calendarDays[index]
                        let isSelected = index == selectedDateIndex

                        Button(action: { selectedDateIndex = index }) {
                            VStack(spacing: 4) {
                                Text("Aug")
                                    .font(.system(size: 10))
                                    .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)

                                Text(item.day)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)

                                Text(item.weekday)
                                    .font(.system(size: 10))
                                    .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                isSelected
                                ? Color(red: 124/255, green: 58/255, blue: 237/255)
                                : Color(red: 22/255, green: 20/255, blue: 30/255)
                            )
                            .cornerRadius(14)
                        }
                    }
                }
                .padding(.horizontal)

                // Task Cards List with Times & Badges
                LazyVStack(spacing: 12) {
                    ForEach(Array(filteredTasks.enumerated()), id: \.element.id) { index, task in
                        TaskCardView(
                            task: task,
                            isActiveCard: index == 0, // First item is prominent purple card
                            onToggleComplete: { toggleComplete(taskID: task.id) },
                            onEdit: {}
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - SCREEN 3: Activity Log View
    private var activityLogView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Button(action: { currentTab = .home }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text("Activity log")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 20, height: 20)
                }
                .padding(.horizontal)
                .padding(.top, 10)

                Text("Today")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal)

                LazyVStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { i in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color.purple.opacity(0.4))
                                .frame(width: 36, height: 36)
                                .overlay(Text("🧑🏻‍💻").font(.system(size: 18)))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(i % 2 == 0 ? "You completed a task: Weekly goals" : "You added a task: Design review")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)

                                Text("10:00 AM")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color(red: 22/255, green: 20/255, blue: 30/255))
                        .cornerRadius(14)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 20)
        }
    }

    // MARK: - SCREEN 4: Welcome / Onboarding View
    private var welcomeOnboardingView: some View {
        VStack(spacing: 24) {
            Spacer()

            // 3D Glass Sphere Graphic
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 196/255, green: 181/255, blue: 253/255), Color(red: 124/255, green: 58/255, blue: 237/255), Color(red: 67/255, green: 24/255, blue: 138/255)],
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                    .blur(radius: 4)
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: Color(red: 124/255, green: 58/255, blue: 237/255).opacity(0.6), radius: 30, y: 10)
            }

            VStack(spacing: 10) {
                Text("Task Management App")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text("\"Stay organized, stay focused, and get more done with the right task management app\"")
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 32)
            }

            Button(action: { currentTab = .home }) {
                Text("Welcome")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 124/255, green: 58/255, blue: 237/255), Color(red: 91/255, green: 33/255, blue: 182/255)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }

    // MARK: - Floating Purple Tab Bar (Exact Design Match)
    private var customBottomTabBar: some View {
        HStack {
            // Home Tab
            Button(action: { currentTab = .home }) {
                Image(systemName: "house.fill")
                    .font(.system(size: 18))
                    .foregroundColor(currentTab == .home ? .black : .white.opacity(0.8))
                    .frame(width: 38, height: 38)
                    .background(currentTab == .home ? Color.white : Color.clear)
                    .clipShape(Circle())
            }

            Spacer()

            // Calendar Tab
            Button(action: { currentTab = .calendar }) {
                Image(systemName: "calendar")
                    .font(.system(size: 18))
                    .foregroundColor(currentTab == .calendar ? .black : .white.opacity(0.8))
                    .frame(width: 38, height: 38)
                    .background(currentTab == .calendar ? Color.white : Color.clear)
                    .clipShape(Circle())
            }

            Spacer()

            // Center Elevated Add (+) Button
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                isShowingAddSheet = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.3), radius: 5, y: 3)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(red: 124/255, green: 58/255, blue: 237/255))
                }
            }

            Spacer()

            // Folder / Activity Tab
            Button(action: { currentTab = .activity }) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 18))
                    .foregroundColor(currentTab == .activity ? .black : .white.opacity(0.8))
                    .frame(width: 38, height: 38)
                    .background(currentTab == .activity ? Color.white : Color.clear)
                    .clipShape(Circle())
            }

            Spacer()

            // Profile Tab
            Button(action: { currentTab = .profile }) {
                Image(systemName: "person.fill")
                    .font(.system(size: 18))
                    .foregroundColor(currentTab == .profile ? .black : .white.opacity(0.8))
                    .frame(width: 38, height: 38)
                    .background(currentTab == .profile ? Color.white : Color.clear)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Color(red: 124/255, green: 58/255, blue: 237/255))
        .cornerRadius(32)
        .shadow(color: Color(red: 124/255, green: 58/255, blue: 237/255).opacity(0.5), radius: 15, y: 6)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Actions & Persistence
    private func createTask(title: String, category: TaskCategory, priority: TaskPriority, dueDate: Date) {
        let newItem = TodoItem(context: viewContext)
        let taskID = UUID()

        newItem.id = taskID
        newItem.title = title
        newItem.category = category.rawValue
        newItem.priority = priority.rawValue
        newItem.dueDate = dueDate
        newItem.isCompleted = false

        saveContext()
    }

    private func toggleComplete(taskID: UUID) {
        if let item = savedTasks.first(where: { $0.id == taskID }) {
            item.isCompleted.toggle()
            saveContext()
        }
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
            print("Core Data Error: \(error.localizedDescription)")
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - Initial Demo Data (Matching the Screenshot)
    private func seedInitialDemoTasksIfEmpty() {
        guard savedTasks.isEmpty else { return }

        let sampleTasks: [(title: String, category: TaskCategory, priority: TaskPriority, offsetHours: Int)] = [
            ("Meeting", .work, .high, 0),
            ("Competitive Analysis", .work, .medium, 1),
            ("Create Low-fidelity", .work, .medium, 2),
            ("Landing page", .work, .medium, 3),
            ("Research", .study, .low, 5),
            ("Prototype", .study, .low, 6)
        ]

        for sample in sampleTasks {
            let item = TodoItem(context: viewContext)
            item.id = UUID()
            item.title = sample.title
            item.category = sample.category.rawValue
            item.priority = sample.priority.rawValue
            item.dueDate = Calendar.current.date(byAdding: .hour, value: sample.offsetHours, to: Date()) ?? Date()
            item.isCompleted = false
        }
        saveContext()
    }
}

// MARK: - Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(
                \.managedObjectContext,
                PersistenceController.preview.container.viewContext
            )
            .preferredColorScheme(.dark)
    }
}
