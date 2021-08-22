//
//  MIDI.swift
//  MIDI Proxy
//
//  Created by Fabio de Albuquerque Dela Antonio on 21/08/2021.
//

import Foundation
import CoreMIDI

protocol MidiInputDelegate: AnyObject {
    func midi(_ midiInput: MidiInput, didReceiveEvent event: MidiEvent)
}

final class MidiInput {

    private var midiClient = MIDIClientRef()
    private var midiInputPort = MIDIPortRef()

    private weak var delegate: MidiInputDelegate?

    init?(delegate: MidiInputDelegate) {
        self.delegate = delegate

        guard MIDIClientCreate("Midi client" as CFString, nil, nil, &midiClient) == 0 else {
            return nil
        }

        guard MIDIInputPortCreateWithBlock(midiClient, "Midi input" as CFString, &midiInputPort, { [weak self] packetList, sourceConnection in
            self?.receive(packetList)
        }) == 0 else {
            return nil
        }

        let midiSession = MIDINetworkSession.default()
        midiSession.isEnabled = true
        midiSession.connectionPolicy = .anyone

        // Always using the first source
        guard MIDIGetNumberOfSources() > 0 else {
            return nil
        }

        let endpoint = MIDIGetSource(0)
        guard MIDIPortConnectSource(midiInputPort, endpoint, nil) == 0 else {
            return nil
        }
    }

    private func receive(_ packetListPointer: UnsafePointer<MIDIPacketList>) {
        let packetList = packetListPointer.pointee
        var packet = packetList.packet

        for i in 0 ..< packetList.numPackets {

            if let event = MidiEvent(packet: packet) {
                DispatchQueue.main.async {
                    self.delegate?.midi(self, didReceiveEvent: event)
                }
            }

            if i < packetList.numPackets - 1 {
                packet = MIDIPacketNext(&packet).pointee
            }
        }
    }

    deinit {
        MIDIPortDispose(midiInputPort)
        MIDIClientDispose(midiClient)
    }
}

struct MidiEvent {

    enum EventType {
        case noteOn
        case noteOff
    }

    let type: EventType
    let timestamp: UInt64
    let channel: UInt8
    let note: MidiNote

    static func isValid(packet: MIDIPacket) -> Bool {
        packet.length > 2
    }

    static func eventType(from packet: MIDIPacket) -> EventType? {
        let status = packet.data.0
        let data2 = packet.data.2
        let higherNibble = status >> 4

        guard status >= 0x80 && status <= 0xEF else { return nil }

        if higherNibble == 0x8 {
            return .noteOff
        } else if higherNibble == 0x9 {
            if (data2 == 0x0) {
                return .noteOff
            } else {
                return .noteOn
            }
        } else {
            return nil
        }
    }

    // 1 .. 16
    static func channel(from packet: MIDIPacket) -> UInt8 {
        let status = packet.data.0
        let lowerNibble = (status << 4) >> 4
        return lowerNibble + 1
    }

    init?(packet: MIDIPacket) {
        guard Self.isValid(packet: packet) else { return nil }

        guard let eventType = Self.eventType(from: packet),
            let note = MidiNote(noteNumber: packet.data.1)
        else {
            return nil
        }

        self.timestamp = packet.timeStamp
        self.type = eventType
        self.channel = Self.channel(from: packet)
        self.note = note
    }
}

extension MidiEvent: CustomDebugStringConvertible {

    var debugDescription: String {
        "Type: \(type) Channel: \(channel) Note:\(note)"
    }
}

struct MidiNote {
    let noteNumber: UInt8

    init?(noteNumber: UInt8) {
        guard noteNumber >= 0, noteNumber <= 127 else { return nil }
        self.noteNumber = noteNumber
    }

    static let noteStrings = [
        "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
    ]

    var noteString: String {
        Self.noteStrings[Int(noteNumber % 12)]
    }

    var octave: Int {
        // This is not giving the right result for the 9th Octave
        Int((noteNumber / 12)) - 1
    }
}

extension MidiNote: CustomDebugStringConvertible {

    var debugDescription: String {
        "\(noteString)\(octave)"
    }
}
