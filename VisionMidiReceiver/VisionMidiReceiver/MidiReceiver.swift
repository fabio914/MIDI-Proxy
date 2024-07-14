//
//  MidiReceiver.swift
//  VisionMidiReceiver
//
//  Created by Fabio Dela Antonio on 14/07/2024.
//

import Foundation
import SwiftSocket

protocol MidiReceiverDelegate: AnyObject {
    func didReceive(payload: MidiEventPayload)
}

final class MidiReceiver {
    private weak var delegate: MidiReceiverDelegate?
    private let port: Int32 = 13370
    private var server: TCPServer?
    private var serverThread: Thread?

    func terminate() {
        serverThread?.cancel()
        serverThread = nil
        server = nil
    }

    func startServer() {
        terminate()

        let server = TCPServer(address: "0.0.0.0", port: port)
        self.server = server

        let serverThread = Thread(block: { [weak self] in
            switch server.listen() {
            case .success: 
                if let client = server.accept() {
                    while !Thread.current.isCancelled {
                        let length = MemoryLayout<MidiEventPayload>.size

                        if let message = client.read(length) {
                            let data = Data(bytes: message, count: length)
                            let payload = data.withUnsafeBytes({ $0.load(as: MidiEventPayload.self) })

                            DispatchQueue.main.async {
                                self?.delegate?.didReceive(payload: payload)
                            }
                        }
                    }

                    client.close()
                } else {
                    print("accept error")
                }
            case .failure(let error):
                print(error)
            }
        })

        serverThread.start()
        self.serverThread = serverThread
    }

    init(delegate: MidiReceiverDelegate) {
        self.delegate = delegate
    }


    deinit {
        terminate()
    }
}

struct MidiEventPayload {
    let protocolIdentifier: UInt32 = 13371337
    let type: UInt8
//    let timestamp: UInt64
    let channel: UInt8
    let note: UInt8



    var data: Data {
        let length = MemoryLayout<MidiEventPayload>.size

        var copy = self
        let data = Data(bytes: &copy, count: length)
        return data
    }
}
