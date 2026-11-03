import SwiftUI

struct AddTaskSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var taskName = ""
    @State private var selectedCategory = "Design"
    @State private var dueDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
    @State private var taskDescription = ""

    let categories = ["Design", "Development", "Research", "Wireframe"]
    let onSave: (String, TaskCategory, TaskPriority, Date) -> Void

    var body: some View {
        ZStack {
            // Dark Background
            Color(red: 14/255, green: 12/255, blue: 21/255)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Spacer()

                    Text("New Task")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 12)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Task Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task Name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)

                            TextField("e.g. UI Design", text: $taskName)
                                .foregroundColor(.white)
                                .padding(14)
                                .background(Color(red: 24/255, green: 22/255, blue: 34/255))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)

                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { cat in
                                    Button(action: { selectedCategory = cat }) {
                                        Text(cat)
                                            .font(.system(size: 13, weight: .semibold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedCategory == cat
                                                ? Color(red: 124/255, green: 58/255, blue: 237/255)
                                                : Color(red: 24/255, green: 22/255, blue: 34/255)
                                            )
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }

                        // Date & Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date & Time")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)

                            DatePicker("Select Date", selection: $dueDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .padding(10)
                                .background(Color(red: 24/255, green: 22/255, blue: 34/255))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .colorScheme(.dark)
                        }

                        // Start & End Time
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start time")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)

                                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .padding(8)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(red: 24/255, green: 22/255, blue: 34/255))
                                    .cornerRadius(12)
                                    .colorScheme(.dark)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("End time")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)

                                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .padding(8)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(red: 24/255, green: 22/255, blue: 34/255))
                                    .cornerRadius(12)
                                    .colorScheme(.dark)
                            }
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)

                            TextEditor(text: $taskDescription)
                                .frame(height: 90)
                                .padding(8)
                                .background(Color(red: 24/255, green: 22/255, blue: 34/255))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .colorScheme(.dark)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        }

                        // Create Task Button
                        Button(action: {
                            let trimmed = taskName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }

                            let categoryMapped: TaskCategory = {
                                switch selectedCategory {
                                case "Design": return .work
                                case "Development": return .work
                                case "Research": return .study
                                default: return .personal
                                }
                            }()

                            onSave(trimmed, categoryMapped, .high, dueDate)
                            dismiss()
                        }) {
                            Text("Create Task")
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
                                .shadow(color: Color(red: 124/255, green: 58/255, blue: 237/255).opacity(0.4), radius: 10, y: 5)
                        }
                        .disabled(taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.top, 10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}
