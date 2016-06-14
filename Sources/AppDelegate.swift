//
//  AppDelegate.swift
//  Monolingual
//
//  Created by Ingmar Stein on 14.07.14.
//
//

import Cocoa
import Fabric
import Crashlytics

let ProcessApplicationNotification = "ProcessApplicationNotification"

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
	var preferencesWindowController: NSWindowController?

	// validate values stored in NSUserDefaults and reset to default if necessary
	private func validateDefaults() {
		let defaults = UserDefaults.standard()

		let roots = defaults.array(forKey: "Roots")
		if roots == nil || roots!.index(where: { (root) -> Bool in
			if let rootDictionary = root as? NSDictionary {
				return rootDictionary.object(forKey: "Path") == nil
					|| rootDictionary.object(forKey: "Languages") == nil
					|| rootDictionary.object(forKey: "Architectures") == nil
			} else {
				return true
			}
		}) != nil {
			defaults.set(Root.defaults as NSArray, forKey: "Roots")
		}
	}

	func applicationDidFinishLaunching(_: Notification) {
		let defaultDict: [String: AnyObject]  = [ "Roots" : Root.defaults as AnyObject, "Trash" : false, "Strip" : false, "NSApplicationCrashOnExceptions" : true ]

		UserDefaults.standard().register(defaultDict)

		validateDefaults()

		Fabric.with([Crashlytics()])
	}

	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}

	func application(_ sender: NSApplication, openFile filename: String) -> Bool {
		let dict: [NSObject: AnyObject] = [ "Path": filename as NSString, "Language": true, "Architectures": true ]

		NotificationCenter.default().post(name: NSNotification.Name(rawValue: ProcessApplicationNotification), object: self, userInfo: dict)
		
		return true
	}
	
	//MARK: - Actions
	
	@IBAction func documentationBundler(_ sender : NSMenuItem) {
		let docURL = Bundle.main().urlForResource(sender.title, withExtension:nil)
		NSWorkspace.shared().open(docURL!)
	}
	
	@IBAction func openWebsite(_: AnyObject) {
		NSWorkspace.shared().open(URL(string:"https://ingmarstein.github.io/Monolingual")!)
	}
	
	@IBAction func donate(_: AnyObject) {
		NSWorkspace.shared().open(URL(string:"https://ingmarstein.github.io/Monolingual/donate.html")!)
	}

	@IBAction func showPreferences(_ sender: AnyObject) {
		if preferencesWindowController == nil {
			let storyboard = NSStoryboard(name:"Main", bundle:nil)
			preferencesWindowController = storyboard.instantiateController(withIdentifier: "PreferencesWindow") as? NSWindowController
		}
		preferencesWindowController?.showWindow(sender)
	}
}
