import Foundation
import Cocoa


class JatiyoInputMethod: InputMethodProtocol {
    var mappingFileName: String { "jatiyo" }
    var maxMappingWordSize: Int { 2 }

    private static let oldStyleKarsKey = "JatiyoInputMethod.shouldFixOldStyleInput"

    var shouldFixOldStyleInput: Bool {
        get {
            UserDefaults.standard.object(forKey: JatiyoInputMethod.oldStyleKarsKey) as? Bool ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: JatiyoInputMethod.oldStyleKarsKey)
        }
    }

    private lazy var inputMapper: MappingLoader = {
        return MappingLoader(configurationName: mappingFileName)
    }()


    func toBangla(word: String) -> String {
        var result = ""
        var i = 0
        let wordArray = Array(shouldFixOldStyleInput ? fixOldStyleInput(word) : word)
        let length = wordArray.count

        while i < length {
            var found = false
            let maxJ = min(maxMappingWordSize, length - i)

            for j in stride(from: maxJ, through: 1, by: -1) {
                guard i + j <= length else { continue }

                let keyArray = Array(wordArray[i..<(i + j)])
                let key = String(keyArray)

                if let value = inputMapper.getCharacter(for: key) {
                    result += value
                    i += j
                    found = true
                    break
                }
            }

            if !found {
                i += 1
            }
        }

        return result
    }

    private func fixOldStyleInput(_ input: String) -> String {
        
        var chars = Array(input)
        var i = 0
        
        while i < chars.count {
            // Rule 1: c ? f -> ? (
            if i + 2 < chars.count, chars[i] == "c", chars[i+2] == "f" {
                let mid = chars[i+1]
                chars.replaceSubrange(i...i+2, with: [mid, "("])
                i += 2
                continue
            }
            
            // Rule 2: c ? X -> ? X
            if i + 2 < chars.count, chars[i] == "c", chars[i+2] == "X" {
                let mid = chars[i+1]
                chars.replaceSubrange(i...i+2, with: [mid, "X"])
                i += 2
                continue
            }
            
            // Rule 3: swap if c, d, or C
            if i + 1 < chars.count, ["c", "d", "C"].contains(chars[i]) {
                chars.swapAt(i, i+1)
                i += 2
                continue
            }
            
            i += 1
        }
        
        return String(chars)
    }

    func matchesAllowedPattern(_ text: String) -> Bool {
        return inputMapper.matchesAllowedPattern(text)
    }

    func getSpecialMapping(for key: String) -> String? {
        return inputMapper.getSpecialMapping(for: key)
    }

    func createMenu() -> NSMenu? {
        let menu = NSMenu()
        let oldStyleKarsMenuItem = NSMenuItem(
            title: NSLocalizedString("Use old style kars", comment: ""),
            action: #selector(InputMethodController.handleMenuAction(_:)),
            keyEquivalent: ""
        )
        oldStyleKarsMenuItem.tag = 100
        oldStyleKarsMenuItem.state = shouldFixOldStyleInput ? .on : .off
        oldStyleKarsMenuItem.keyEquivalentModifierMask = [.control, .option]

        menu.addItem(oldStyleKarsMenuItem)
        return menu
    }

    func handleMenuAction(_ menuItem: NSMenuItem) {
        switch menuItem.tag {
        case 100:
            shouldFixOldStyleInput.toggle()
            menuItem.state = shouldFixOldStyleInput ? .on : .off
        default:
            break
        }
    }
}
