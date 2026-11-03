import SwiftUI

// MARK: - Task Status Enum
enum TaskItemStatus: String, CaseIterable {
    case done = "Done"
    case inProgress = "In progress"
    case todo = "To-do"
}

// MARK: - Task Card View (Matching Design)
struct TaskCardView: View {
    let task: TaskItemModel
    var isActiveCard: Bool = false
    let onToggleComplete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        if isActiveCard || (task.priority == .high && !task.isCompleted) {
            // Highlighted Purple Card (Like "Meeting" in the design)
            activePurpleCard
        } else {
            // Standard Dark Row (Like "Competitive Analysis" in the design)
            standardDarkCard
        }
    }

    // MARK: - Highlighted Purple Card
    private var activePurpleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Discuss team tasks for the day")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Text(taskTimeFormatted(task.dueDate))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            HStack {
                // Team Avatars Stack
                avatarStack
                
                Spacer()
                
                // Done Check Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring()) {
                        onToggleComplete()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(task.isCompleted ? Color.green : Color.white.opacity(0.2))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(red: 110/255, green: 40/255, blue: 215/255), Color(red: 88/255, green: 28/255, blue: 180/255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: Color(red: 110/255, green: 40/255, blue: 215/255).opacity(0.35), radius: 8, y: 4)
    }

    // MARK: - Standard Dark Card
    private var standardDarkCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(task.isCompleted ? .gray : .white)
                    .strikethrough(task.isCompleted, color: .gray)
                
                Text("Discuss team tasks for the day")
                    .font(.system(size: 11))
                    .foregroundColor(Color.gray.opacity(0.8))
            }
            
            Spacer()
            
            // Time
            Text(taskTimeFormatted(task.dueDate))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            
            // Status Badge Button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.spring()) {
                    onToggleComplete()
                }
            }) {
                Text(task.isCompleted ? "Done" : (isOverdue(task) ? "In progress" : "To-do"))
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusBadgeBackground)
                    .foregroundColor(statusBadgeTextColor)
                    .clipShape(Capsule())
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Color(red: 22/255, green: 20/255, blue: 30/255))
        .cornerRadius(16)
    }

    // MARK: - Status Badge Styling
    private var statusBadgeBackground: Color {
        if task.isCompleted {
            return Color.green.opacity(0.2)
        } else if isOverdue(task) {
            return Color.orange.opacity(0.2)
        } else {
            return Color(red: 124/255, green: 58/255, blue: 237/255).opacity(0.25)
        }
    }

    private var statusBadgeTextColor: Color {
        if task.isCompleted {
            return Color.green
        } else if isOverdue(task) {
            return Color.orange
        } else {
            return Color(red: 196/255, green: 181/255, blue: 253/255)
        }
    }

    // MARK: - Avatar Stack
    private var avatarStack: some View {
        HStack(spacing: -8) {
            Circle()
                .fill(Color.orange)
                .frame(width: 22, height: 22)
                .overlay(Image(systemName: "person.fill").font(.system(size: 10)).foregroundColor(.white))
                .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
            
            Circle()
                .fill(Color.blue)
                .frame(width: 22, height: 22)
                .overlay(Image(systemName: "person.crop.circle.fill").font(.system(size: 10)).foregroundColor(.white))
                .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
            
            Circle()
                .fill(Color.purple)
                .frame(width: 22, height: 22)
                .overlay(Text("+").font(.system(size: 10, weight: .bold)).foregroundColor(.white))
                .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
        }
    }

    private func taskTimeFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }

    private func isOverdue(_ task: TaskItemModel) -> Bool {
        !task.isCompleted &&
        Calendar.current.startOfDay(for: task.dueDate) < Calendar.current.startOfDay(for: Date())
    }
}
