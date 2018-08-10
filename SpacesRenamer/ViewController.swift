//
//  ViewController.swift
//  SpacesRenamer
//
//  Created by Alex Beals on 11/15/17.
//  Copyright © 2018 Alex Beals. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var updateButton: NSButton!

    var desktops: [String: NSTextField] = [String: NSTextField]()
    var constraints: [NSLayoutConstraint] = []
    var snippets: [DesktopSnippet] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }

    func teardownViews() {
        NSLayoutConstraint.deactivate(constraints)

        for view in snippets {
            view.removeFromSuperview()
        }

        constraints = []
        snippets = []
        desktops = [String: NSTextField]()
    }

    func setupViews() {
        // Load in a list of all of the spaces
        guard let spacesDict = NSDictionary(contentsOfFile: Utils.listOfSpacesPlist),
            let allMonitors = spacesDict.value(forKeyPath: "Monitors") as? NSArray else { return }

        // Keep reference to previous for constraint
        var prev: NSView?
        var above: NSView?

        let maxSpacesPerMonitor = allMonitors.reduce(Int.min, { max($0, (($1 as? NSDictionary)?.value(forKey: "Spaces") as! NSArray).count) })

        for j in 1...allMonitors.count {
            let allSpaces = (allMonitors[j-1] as? NSDictionary)?.value(forKey: "Spaces") as! NSArray

            let currentSpace = (allMonitors[j-1] as? NSDictionary)?.value(forKeyPath: "Current Space.uuid") as! String

            // Create a label for the monitor (if there is more than one monitor)
            if (allMonitors.count > 1) {
                let monitorLabel = NSTextField(labelWithString: "Monitor \(j)")
                monitorLabel.font = NSFont(name: "HelveticaNeue-Bold", size: 14)
                monitorLabel.translatesAutoresizingMaskIntoConstraints = false

                var topConstraint: NSLayoutConstraint?
                if (above != nil) {
                    topConstraint = NSLayoutConstraint(item: monitorLabel, attribute: .top, relatedBy: .equal, toItem: above, attribute: .bottom, multiplier: 1.0, constant: 10)
                } else {
                    topConstraint = NSLayoutConstraint(item: monitorLabel, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 10)
                }

                let leftConstraint = NSLayoutConstraint(item: monitorLabel, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 10)

                constraints.append(topConstraint!)
                constraints.append(leftConstraint)
                self.view.addSubview(monitorLabel)
                self.view.addConstraints([topConstraint!, leftConstraint])

                above = monitorLabel
            }

            // Create a view for all of the snippets
            let monitorScrollView = NSScrollView()
            monitorScrollView.translatesAutoresizingMaskIntoConstraints = false
            monitorScrollView.verticalScrollElasticity = .none
            monitorScrollView.hasHorizontalScroller = true

            let snippetView = NSView()
            snippetView.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(monitorScrollView)

            var verticalConstraint: NSLayoutConstraint?
            if (above != nil) {
                verticalConstraint = NSLayoutConstraint(item: monitorScrollView, attribute: .top  , relatedBy: .equal, toItem: above, attribute: .bottom, multiplier: 1.0, constant: 10)
            } else {
                verticalConstraint = NSLayoutConstraint(item: monitorScrollView, attribute: .top  , relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1.0, constant: 10)
            }
            var horizontalConstraint = NSLayoutConstraint(item: monitorScrollView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1.0, constant: 10)

            constraints.append(verticalConstraint!)
            constraints.append(horizontalConstraint)
            self.view.addConstraints([verticalConstraint!, horizontalConstraint])

            prev = nil

            // For each space, make a text field
            for i in 1...allSpaces.count {
                let uuid = (allSpaces[i-1] as! [AnyHashable: Any])["uuid"] as! String

                let snippet = DesktopSnippet.instanceFromNib()
                if (uuid == currentSpace) {
                    snippet.monitorImage.image = NSImage(named: NSImage.Name("MonitorSelected"))
                    snippet.isCurrent = true
                }

                snippet.label.stringValue = "\(i)"
                snippet.textField.delegate = self
                snippetView.addSubview(snippet)
                snippets.append(snippet)

                desktops[uuid] = snippet.textField

                var horizontalConstraint: NSLayoutConstraint?
                let verticalConstraint = NSLayoutConstraint(item: snippet, attribute: .top  , relatedBy: .equal, toItem: snippetView, attribute: .top, multiplier: 1.0, constant: 10)

                if (prev == nil) {
                    horizontalConstraint = NSLayoutConstraint(item: snippet, attribute: .leading, relatedBy: .equal, toItem: snippetView, attribute: .leading, multiplier: 1.0, constant: 10)
                } else {
                    horizontalConstraint = NSLayoutConstraint(item: snippet, attribute: .leading, relatedBy: .equal, toItem: prev, attribute: .trailing, multiplier: 1.0, constant: 10)
                }

                constraints.append(verticalConstraint)
                constraints.append(horizontalConstraint!)
                snippetView.addConstraints([verticalConstraint, horizontalConstraint!])
                prev = snippet
            }
            above = prev

            verticalConstraint = NSLayoutConstraint(item: snippetView, attribute: .trailing, relatedBy: .equal, toItem: prev, attribute: .trailing, multiplier: 1.0, constant: 10)
            horizontalConstraint = NSLayoutConstraint(item: snippetView, attribute: .bottom, relatedBy: .equal, toItem: prev, attribute: .bottom, multiplier: 1.0, constant: 10)

            constraints.append(verticalConstraint!)
            constraints.append(horizontalConstraint)
            snippetView.addConstraints([verticalConstraint!, horizontalConstraint])

            monitorScrollView.documentView = snippetView

            let equalHeight = NSLayoutConstraint(item: monitorScrollView, attribute: .height, relatedBy: .equal, toItem: snippetView, attribute: .height, multiplier: 1.0, constant: 0)
            constraints.append(equalHeight)
            self.view.addConstraint(equalHeight)

            let widthConstraint = NSLayoutConstraint(item: monitorScrollView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(min(6.5, Double(allSpaces.count)) * 140.0))
            constraints.append(widthConstraint)
            self.view.addConstraints([widthConstraint])

            prev = monitorScrollView

            if (allSpaces.count == maxSpacesPerMonitor) {
                let horizontalLayout = NSLayoutConstraint(item: self.view, attribute: .trailing, relatedBy: .equal, toItem: prev!, attribute: .trailing, multiplier: 1.0, constant: 10)
                constraints.append(horizontalLayout)
                self.view.addConstraints([horizontalLayout])
            }
        }

        let verticalConstraint = NSLayoutConstraint(item: updateButton, attribute: .top, relatedBy: .equal, toItem: prev!, attribute: .bottom, multiplier: 1.0, constant: 10)
        constraints.append(verticalConstraint)

        self.view.addConstraints([verticalConstraint])
    }

    func refreshViews() {
        teardownViews()
        setupViews()

        var currentMapping = NSMutableDictionary()
        if let preferencesDict = NSMutableDictionary(contentsOfFile: Utils.customNamesPlist),
            let spacesRemaining = preferencesDict.value(forKey: "spaces_renaming") as? NSMutableDictionary {
            currentMapping = spacesRemaining
        }

        // Update with the current names
        for (uuid, textField) in desktops {
            if let newName = currentMapping.value(forKey: uuid) {
                textField.stringValue = newName as! String
            }
        }

        selectCurrent()
    }

    func selectCurrent() {
        for snippet in snippets {
            if snippet.isCurrent {
                snippet.textField.becomeFirstResponder()
                break
            }
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        refreshViews()
    }

    @IBAction func quitMenuApp(_ sender: Any) {
        NSApp.terminate(nil)
    }

    @IBAction func pressChangeName(_ sender: Any) {
        // Load from preferences the current mapping
        let preferencesDict = NSMutableDictionary(contentsOfFile: Utils.customNamesPlist) ?? NSMutableDictionary()
        let currentMapping = (preferencesDict.value(forKey: "spaces_renaming") as? NSMutableDictionary) ?? NSMutableDictionary()

        // Update accordingly
        for (uuid, textField) in desktops {
            currentMapping.setValue(textField.stringValue, forKey: uuid)
        }

        preferencesDict.setValue(currentMapping, forKey: "spaces_renaming")

        // Resave
        preferencesDict.write(toFile: Utils.customNamesPlist, atomically: true)

        // Close the popup
        let delegate = NSApplication.shared.delegate as! AppDelegate
        delegate.closeNameChangeWindow(sender: delegate)
    }
}

extension ViewController: NSTextFieldDelegate {
    override func cancelOperation(_ sender: Any?) {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.closeNameChangeWindow(sender: nil)
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            self.pressChangeName(textView)
            return true
        }
        return false
    }
}

extension ViewController {
    static func freshController() -> ViewController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier(rawValue: "Popup")
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? ViewController else {
            fatalError("Bugged")
        }
        return viewcontroller
    }
}

