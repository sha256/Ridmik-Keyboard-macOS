import Foundation
import Cocoa

/// Protocol defining the interface for input method implementations
protocol InputMethodProtocol {

    /// The name of the mapping configuration file (without extension)
    var mappingFileName: String { get }

    /// Maximum number of characters to look back for key sequence matching
    var maxMappingWordSize: Int { get }

    /// Convert a key sequence to its corresponding output text
    func toBangla(word: String) -> String

    /// Check if a character matches the allowed pattern
    func matchesAllowedPattern(_ text: String) -> Bool

    /// Get the special mapping for a key
    func getSpecialMapping(for key: String) -> String?

    /// Create a menu for input method specific settings (optional)
    func createMenu() -> NSMenu?

    /// Handle menu action when a menu item is selected
    func handleMenuAction(_ menuItem: NSMenuItem)
}


extension InputMethodProtocol {
    
    func createMenu() -> NSMenu? {
        return nil
    }

    func handleMenuAction(_ menuItem: NSMenuItem) {
        
    }
}
