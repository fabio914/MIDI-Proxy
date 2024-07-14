//
//  ContentView.swift
//  VisionMidiReceiver
//
//  Created by Fabio Dela Antonio on 14/07/2024.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @StateObject var viewModel = MidiViewModel()

    var body: some View {
        VStack {
            Text(viewModel.currentText)
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}

final class MidiViewModel: MidiReceiverDelegate, ObservableObject {

    @Published var currentText: String = ""
    lazy var serverReceiver: MidiReceiver = MidiReceiver(delegate: self)

    init() {
        serverReceiver.startServer()
    }

    func didReceive(payload: MidiEventPayload) {
        print("Received: \(payload.note) \(payload.type)")

        // Mapping to characters
        if payload.type == 1 /* note On */ {
            switch payload.note {
            case 45:
                currentText += "a"
            case 47:
                currentText += "b"
            case 48:
                currentText += "c"
            case 50:
                currentText += "d"
            case 52:
                currentText += "e"
            case 53:
                currentText += "f"
            case 55:
                currentText += "g"
            case 57:
                currentText += "h"
            case 59:
                currentText += "i"
            case 60:
                currentText += "j"
            case 62:
                currentText += "k"
            case 64:
                currentText += "l"
            case 65:
                currentText += "m"
            case 67:
                currentText += "n"
            case 69:
                currentText += "o"
            case 71:
                currentText += "p"
            case 72:
                currentText += "q"
            case 74:
                currentText += "r"
            case 76:
                currentText += "s"
            case 77:
                currentText += "t"
            case 79:
                currentText += "u"
            case 81:
                currentText += "v"
            case 83:
                currentText += "w"
            case 84:
                currentText += "x"
            case 86:
                currentText += "y"
            case 88:
                currentText += "z"
            case 61:
                currentText += " "
            case 63:
                currentText += "!"
            case 66:
                currentText += "?"
            case 68:
                currentText += "."
            case 43:
                currentText = String(currentText.dropLast(1))
            default:
                break
            }
        }
    }
}
