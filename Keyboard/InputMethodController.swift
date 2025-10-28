import InputMethodKit

@objc(InputMethodController)
class InputMethodController: IMKInputController {
    
    private var inputMethod: InputMethodProtocol!
    private var inputText: String = ""
    private static var currentInputSourceID: String = ""
    private var notificationObserver: NSObjectProtocol?
    
    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        super.init(server: server, delegate: delegate, client: inputClient)
        
        updateInputMethodIfNeeded()
        
    }
    
    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        updateInputMethodIfNeeded()
    }
    
    private func toBangla(word: String) -> String {
        guard let inputMethod = inputMethod else {
            return word
        }
        return inputMethod.toBangla(word: word)
    }
    
    private func updateComposingText() {

        guard let client = self.client() else {
            NSLog("⌨️ InputMethodController: no client available")
            return
        }
        let banglaText = toBangla(word: inputText)
        
        let cursorPosition = NSRange(location: NSNotFound, length: NSNotFound)
        
        let underline = self.mark(
            forStyle: kTSMHiliteConvertedText,
            at: NSRange(location: NSNotFound, length: 0)
        ) as? [NSAttributedString.Key: Any]
        
        let text = NSMutableAttributedString(string: banglaText, attributes: underline)
        
        client.setMarkedText(
            text,
            selectionRange: cursorPosition,
            replacementRange: cursorPosition
        )
        
    }
    
    private func resetComposingState() {
        inputText = ""
    }
    
    override func commitComposition(_ sender: Any!) {
        commitComposingText()
    }
    
    func handleDeleteBackward() -> Bool {
        
        if !inputText.isEmpty {
            inputText.removeLast()
            updateComposingText()
            
            if inputText.isEmpty {
                cancelComposition()
            }
            return true
        }
        
        // If no composition, let the system handle it
        return false
    }
    
    override func cancelComposition() {
        if !inputText.isEmpty {
            self.commitComposingText()
        }
    }
    
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        //NSLog("🔥 \(Unmanaged.passUnretained(self).toOpaque()): handle event: \(event), lang: \(inputMethod?.mappingFileName ?? "unknown")")
        
        updateInputMethodIfNeeded()
        
        // NSLog("🔥 input method: \(self.inputMethod)")
        
        let modifiers = event.modifierFlags
        
        if event.type != .keyDown || inputMethod == nil || modifiers.contains(.command) {
            return false
        }
        
        let key = event.characters ?? ""
        let keyCode = event.keyCode
        
        // Handle backspace
        if keyCode == 51 {
            return handleDeleteBackward()
        }
        
        // Handle escape - cancel composition
        if keyCode == 53 {
            if !inputText.isEmpty {
                cancelComposition()
                return true
            }
            return false
        }
        
        // Handle arrow keys - finish composition and let system handle navigation
        // Left: 123, Up: 126, Right: 124, Down: 125
        if [123, 124, 125, 126].contains(keyCode) {
            if !inputText.isEmpty {
                commitComposingText()
            }
            return false  // Let system handle arrow key normally
        }
        
        // Handle special mappings
        if let specialOutput = inputMethod.getSpecialMapping(for: key) {
            commitComposingText()
            return commitText(specialOutput)
        }
        
        // Handle digits
        if isEnglishDigit(key) {
            commitComposingText()
            commitText(toBanglaDigit(key.first!))
            return true
        }
        
        // Check if key matches allowed pattern
        if !inputMethod.matchesAllowedPattern(key) {
            commitComposingText()
            return false
        }
        
        inputText += key
        updateComposingText()
        // NSLog("🔥 End of handle event: \(event), lang: \(inputMethod?.mappingFileName ?? "unknown")")
        return true
    }
    
    @discardableResult
    private func commitText(_ text: String) -> Bool {
        guard let client = client() else {
            return false
        }
        client.insertText(text, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
        resetComposingState()
        return true
    }
    
    @discardableResult
    private func commitComposingText() -> Bool {
        let finalBanglaText = toBangla(word: inputText)
        commitText(finalBanglaText)
        return true
    }
    
    private func isEnglishDigit(_ str: String) -> Bool {
        guard let char = str.first, str.count == 1 else { return false }
        return char >= "0" && char <= "9"
    }
    
    private func toBanglaDigit(_ char: Character) -> String {
        if let scalar = char.unicodeScalars.first, scalar.value >= 48 && scalar.value <= 57 { // '0'–'9'
            let banglaScalarValue = 0x09E6 + (scalar.value - 0x30) // ০ + offset
            if let banglaScalar = UnicodeScalar(banglaScalarValue) {
                return String(banglaScalar)
            }
        }
        return String(char)
    }
    
    private func getCurrentInputMethodId() -> String {
        if let currentSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() {
            if let sourceID = TISGetInputSourceProperty(currentSource, kTISPropertyInputSourceID) {
                return Unmanaged<CFString>.fromOpaque(sourceID).takeUnretainedValue() as String
            }
        }
        return ""
    }
    
    private func updateInputMethodIfNeeded() {
        let sourceID = getCurrentInputMethodId()
        
        // NSLog("⌨️ IM from service: \(sourceID), IM using: \(InputMethodController.currentInputSourceID)")
        
        // Don't reinitialize if the source hasn't changed
        if sourceID == InputMethodController.currentInputSourceID && inputMethod != nil  {
            return
        }

        // Only handle our defined input methods
        let newInputMethod: InputMethodProtocol?
        switch sourceID {
        case "com.ridmik.inputmethod.macos.jatiyo":
            newInputMethod = JatiyoInputMethod()
        case "com.ridmik.inputmethod.macos.phonetic":
            newInputMethod = PhoneticInputMethod()
        case "com.ridmik.inputmethod.macos.probhat":
            newInputMethod = ProbhatInputMethod()
        case "com.ridmik.inputmethod.macos.easy":
            newInputMethod = EasyPhoneticInputMethod()
        default:
            // Ignore input source IDs not defined in our Info.plist
            NSLog("⌨️ Ignoring unknown input source ID: \(sourceID)")
            return
        }
        
        if let newInputMethod = newInputMethod {
            inputMethod = newInputMethod
            InputMethodController.currentInputSourceID = sourceID
            // NSLog("⌨️ 🔥 \(Unmanaged.passUnretained(self).toOpaque()): Switched to input method: \(sourceID)")
            commitComposingText()
        } else if (inputMethod == nil) {
            // default value
            inputMethod = PhoneticInputMethod()
            InputMethodController.currentInputSourceID = "com.ridmik.inputmethod.macos.phonetic"
        }
    }
    
    override func menu() -> NSMenu! {
        guard let inputMethod = inputMethod else {
            return NSMenu()
        }
        
        let menu = inputMethod.createMenu() ?? NSMenu()

        if menu.numberOfItems > 0 {
            menu.addItem(NSMenuItem.separator())
        }

        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let versionMenuItem = NSMenuItem(title: "Version \(versionString)", action: nil, keyEquivalent: "")
        versionMenuItem.isEnabled = false
        menu.addItem(versionMenuItem)

        let copyrightMenuItem = NSMenuItem(title: "© 2014-Present, Ridmik Labs", action: nil, keyEquivalent: "")
        copyrightMenuItem.isEnabled = false
        menu.addItem(copyrightMenuItem)

        return menu
    }
    
    @objc func handleMenuAction(_ sender: Any!) {
        guard let menuDict = sender as? Dictionary<String, Any>, let menuItem = menuDict["IMKCommandMenuItem"] as? NSMenuItem else {
            NSLog("⌨️ Failed to extract menu item from sender")
            return
        }
        inputMethod.handleMenuAction(menuItem)
    }

    override func recognizedEvents(_ sender: Any!) -> Int {
        let mask: NSEvent.EventTypeMask = [
            .keyDown,
            .flagsChanged
        ]
        return Int(mask.rawValue)
    }
    
    deinit {
        if let notificationObserver = notificationObserver {
            NotificationCenter.default.removeObserver(notificationObserver)
        }
    }
    
}
