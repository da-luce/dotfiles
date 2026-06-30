// Prints the soonest upcoming/in-progress event you have NOT declined, as:
//   <start_epoch>|<end_epoch>|<title>
// Empty output = no qualifying event in the window. Exit 2 = no calendar access.
// All-day events (holidays/birthdays) are excluded so the bar shows real meetings.

import EventKit
import Foundation

let store = EKEventStore()
let sem = DispatchSemaphore(value: 0)
var granted = false

if #available(macOS 14.0, *) {
    store.requestFullAccessToEvents { ok, _ in granted = ok; sem.signal() }
} else {
    store.requestAccess(to: .event) { ok, _ in granted = ok; sem.signal() }
}
sem.wait()
guard granted else { exit(2) }

let now = Date()
guard let end = Calendar.current.date(byAdding: .day, value: 8, to: now) else { exit(0) }
let pred = store.predicateForEvents(withStart: now, end: end,
                                    calendars: store.calendars(for: .event))

let next = store.events(matching: pred)
    .filter { !$0.isAllDay }
    .filter { $0.endDate > now }
    .filter { ev in
        // Drop it only if *I* declined
        if let me = ev.attendees?.first(where: { $0.isCurrentUser }) {
            return me.participantStatus != .declined
        }
        return true
    }
    .sorted { $0.startDate < $1.startDate }
    .first

guard let ev = next else { exit(0) }
let title = (ev.title ?? "").replacingOccurrences(of: "\n", with: " ")
print("\(Int(ev.startDate.timeIntervalSince1970))|\(Int(ev.endDate.timeIntervalSince1970))|\(title)")
