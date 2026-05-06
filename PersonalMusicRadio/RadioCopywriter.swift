import Foundation

struct RadioCopywriter {
    func recommendationReason(
        program: RadioProgram,
        currentTrack: Track?,
        upNextTrack: Track?
    ) -> String {
        guard currentTrack != nil else {
            return "Pick a local music folder first, and the station will queue the first playable file it finds."
        }

        switch program.scene {
        case .morning:
            return "Queued from your authorized folder for a gentler warmup, easing the room in before the heavier work block starts."
        case .work:
            return "Queued from your authorized folder for a \(program.tone) work block, keeping the room steady without touching account-level data."
        case .lunch:
            return "Pulled forward from your local folder for a lighter lunch-table break, with a softer hand into the next song."
        case .nap:
            return "Picked for a low-energy reset from your on-device library, keeping the next move gentle and quiet."
        case .happy:
            if let upNextTrack {
                return "Lined up from your local folder to lift the afternoon a little more, with \(upNextTrack.title) already waiting in the wings."
            }

            return "Lined up from your local folder for a brighter second-half stretch, using only on-device scene cues."
        }
    }

    func djIntro(
        program: RadioProgram,
        currentTrack: Track?,
        upNextTrack: Track?
    ) -> String {
        guard let currentTrack else {
            return "This station is waiting for a local folder before it starts the first set. Once your files are available, the app stays on-device, picks a scene, and eases into the room."
        }

        let handoff = upNextTrack.map { " Up next is \($0.title), ready to keep the set moving." } ?? ""

        switch program.scene {
        case .morning:
            return "\(currentTrack.title) is opening the \(program.name) set with a lighter first stretch, giving the day a softer way to come online.\(handoff)"
        case .work:
            return "\(currentTrack.title) is opening the current \(program.name) hour with a calm, level pulse that helps the day lock in.\(handoff)"
        case .lunch:
            return "\(currentTrack.title) is carrying this \(program.name) break with a warmer table-side tone, giving the day a softer middle turn.\(handoff)"
        case .nap:
            return "\(currentTrack.title) is holding the \(program.name) window low and unhurried, leaving enough air for a proper short reset.\(handoff)"
        case .happy:
            return "\(currentTrack.title) is pushing the \(program.name) set a little brighter now, letting the afternoon come back up with more spring.\(handoff)"
        }
    }

    func upNextCue(program: RadioProgram, upNextTrack: Track?) -> String {
        guard let upNextTrack else {
            return "The next slot will fill from your local folder when the queue refreshes."
        }

        switch program.scene {
        case .morning:
            return "\(upNextTrack.title) stays next to keep the station light before the work block clicks over."
        case .work:
            return "\(upNextTrack.title) stays next because its filename cues fit the current focus block."
        case .lunch:
            return "\(upNextTrack.title) is sitting next as the queue leans softer for the lunch break."
        case .nap:
            return "\(upNextTrack.title) remains next to keep the handoff quieter for the reset window."
        case .happy:
            return "\(upNextTrack.title) is up next to keep the afternoon lift from flattening out."
        }
    }

    func lastFMInsightLines(track: Track, insight: LastFMInsight) -> [String] {
        var lines: [String] = []

        if let listeners = insight.formattedListeners {
            lines.append("\(track.title) is still pulling in around \(listeners) listeners on Last.fm, which makes this set feel a little less solitary.")
            lines.append("Last.fm still shows \(listeners) listeners circling \(track.title), so this one arrives with a wider room already built around it.")
            lines.append("There are roughly \(listeners) listeners holding onto \(track.title) on Last.fm, which gives this moment a little extra social gravity.")
        }

        if let playcount = insight.formattedPlaycount {
            lines.append("\(track.title) has stacked up about \(playcount) plays on Last.fm, so the station can lean on a track that already knows how to travel.")
            lines.append("Last.fm puts \(track.title) near \(playcount) total plays, which helps explain why it settles into the room so quickly.")
            lines.append("With about \(playcount) plays logged on Last.fm, \(track.title) comes in carrying some real mileage.")
        }

        if let primaryTag = insight.primaryTag {
            lines.append("The strongest Last.fm tag around \(track.title) is \(primaryTag), and that shade fits the current set nicely.")
            lines.append("Last.fm listeners keep tagging \(track.title) with \(primaryTag), which lines up neatly with the way this hour is trying to breathe.")
        }

        if let tagSummary = insight.tagSummary {
            lines.append("The Last.fm tag trail on \(track.title) leans \(tagSummary), which gives the station a little more shape than filename cues alone.")
            lines.append("Last.fm keeps describing \(track.title) with tags like \(tagSummary), and that outside read helps sharpen this handoff.")
        }

        return Array(lines.prefix(10))
    }

    func lastFMInsightLine(track: Track, insight: LastFMInsight) -> String? {
        lastFMInsightLines(track: track, insight: insight).randomElement()
    }
}
