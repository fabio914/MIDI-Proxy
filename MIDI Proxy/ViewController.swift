//
//  ViewController.swift
//  MIDI Proxy
//
//  Created by Fabio de Albuquerque Dela Antonio on 21/08/2021.
//

import UIKit

class ViewController: UIViewController {

    private var midiSender: MidiSender?
    private var midiInput: MidiInput?

    @IBOutlet private weak var label: UILabel!

    init() {
        super.init(nibName: String(describing: type(of: self)), bundle: Bundle(for: type(of: self)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        midiSender = MidiSender(address: "192.168.0.94")
        midiInput = MidiInput(delegate: self)
    }
}

extension ViewController: MidiInputDelegate {

    func midi(_ midiInput: MidiInput, didReceiveEvent event: MidiEvent) {
        label.text = event.debugDescription
        midiSender?.sendEvent(event)
        print("Received: \(event)")
    }
}
