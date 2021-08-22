//
//  MIDISender.swift
//  MIDI Proxy
//
//  Created by Fabio de Albuquerque Dela Antonio on 22/08/2021.
//

import Foundation
import SwiftSocket

final class MidiSender {
    private let port: Int32 = 1337
    private let client: TCPClient

    init?(address: String) {
        let client = TCPClient(address: address, port: port)

        // This is blocking the main thread.
        guard case .success = client.connect(timeout: 10) else {
            return nil
        }

        self.client = client
    }

    func sendEvent(_ event: MidiEvent) {
        _ = client.send(data: MidiEventPayload(event: event).data)
    }

    deinit {
        client.close()
    }
}

struct MidiEventPayload {
    let protocolIdentifier: UInt32 = 13371337
    let type: UInt8
//    let timestamp: UInt64
    let channel: UInt8
    let note: UInt8

    init(event: MidiEvent) {
        self.type = {
            switch event.type {
            case .noteOff:
                return 0
            case .noteOn:
                return 1
            }
        }()

//        self.timestamp = event.timestamp
        self.channel = event.channel
        self.note = event.note.noteNumber
    }

    var data: Data {
        let length = MemoryLayout<MidiEventPayload>.size

        var copy = self
        let data = Data(bytes: &copy, count: length)
        return data
    }
}
