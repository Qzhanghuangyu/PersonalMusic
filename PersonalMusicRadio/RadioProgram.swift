import Foundation

enum ListeningScene: String, CaseIterable, Identifiable {
    case morning
    case work
    case lunch
    case nap
    case happy

    var id: String { rawValue }
}

enum HostState: String {
    case tuning = "Tuning"
    case searching = "Searching"
    case speaking = "Speaking"
    case playing = "Playing"
    case paused = "Paused"
    case quiet = "Quiet"
}

struct RadioProgram: Equatable {
    let scene: ListeningScene
    let name: String
    let subtitle: String
    let tone: String
}

struct SceneResolver {
    func resolve(now: Date = Date(), calendar: Calendar = .current) -> ListeningScene {
        let components = calendar.dateComponents([.weekday, .hour, .minute], from: now)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        let weekday = components.weekday ?? 2
        let minutes = hour * 60 + minute
        let isWeekday = (2...6).contains(weekday)

        if (12 * 60)..<(12 * 60 + 30) ~= minutes {
            return .lunch
        }

        if (12 * 60 + 30)..<(14 * 60) ~= minutes {
            return .nap
        }

        if minutes >= 14 * 60 {
            return .happy
        }

        if isWeekday && minutes >= 10 * 60 {
            return .work
        }

        return .morning
    }

    func nextSceneChange(after now: Date = Date(), calendar: Calendar = .current) -> Date {
        for dayOffset in 0...2 {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now

            for time in transitionTimes {
                let candidate = calendar.date(
                    bySettingHour: time.hour,
                    minute: time.minute,
                    second: 0,
                    of: day
                )

                guard let candidate, candidate > now else {
                    continue
                }

                let sceneBefore = resolve(
                    now: candidate.addingTimeInterval(-1),
                    calendar: calendar
                )
                let sceneAfter = resolve(now: candidate, calendar: calendar)

                if sceneBefore != sceneAfter {
                    return candidate
                }
            }
        }

        let nextDay = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        return calendar.startOfDay(for: nextDay)
    }

    func program(for scene: ListeningScene) -> RadioProgram {
        switch scene {
        case .morning:
            return RadioProgram(
                scene: .morning,
                name: "Morning Warmup",
                subtitle: "A gentler set before the work block locks in.",
                tone: "light, clear, unhurried"
            )
        case .work:
            return RadioProgram(
                scene: .work,
                name: "Workday Focus",
                subtitle: "Steady tracks for getting into the day.",
                tone: "calm, clear, lightly focused"
            )
        case .lunch:
            return RadioProgram(
                scene: .lunch,
                name: "Lunch Table",
                subtitle: "A softer station break for the middle of the day.",
                tone: "warm, relaxed, conversational"
            )
        case .nap:
            return RadioProgram(
                scene: .nap,
                name: "Light Nap",
                subtitle: "Low-energy music for a short reset.",
                tone: "quiet, slow, gentle"
            )
        case .happy:
            return RadioProgram(
                scene: .happy,
                name: "Afternoon Lift",
                subtitle: "A brighter set for the second half of the day.",
                tone: "bright, easy, upbeat"
            )
        }
    }

    private var transitionTimes: [(hour: Int, minute: Int)] {
        [
            (0, 0),
            (10, 0),
            (12, 0),
            (12, 30),
            (14, 0)
        ]
    }
}
