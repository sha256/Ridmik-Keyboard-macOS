import Foundation

struct MappingConfiguration: Codable {
    let name: String
    let version: String
    let mappings: [String: String]
    let ligatures: [String: String]
    let specialMappings: [String: String]?
    let allowedPattern: String?
}

class MappingLoader {
    private var keyMapping: [String: String] = [:]
    private var ligaturesMapping: [String: String] = [:]
    private var specialMappings: [String: String] = [:]
    private var allowedPatternRegex: NSRegularExpression?

    init(configurationName: String) {
        loadConfiguration(configurationName)
    }

    private func loadConfiguration(_ name: String) {

        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            NSLog("⌨️ MappingLoader: Failed to find \(name).json in bundle")
            keyMapping = [:]
            return
        }

        guard let data = try? Data(contentsOf: url) else {
            NSLog("⌨️ MappingLoader: Failed to load data from \(url)")
            keyMapping = [:]
            return
        }

        do {
            let config = try JSONDecoder().decode(MappingConfiguration.self, from: data)
            keyMapping = config.mappings
            ligaturesMapping = config.ligatures
            specialMappings = config.specialMappings ?? [:]
            
            if let pattern = config.allowedPattern {
                allowedPatternRegex = try? NSRegularExpression(pattern: pattern)
            }
        } catch {
            NSLog("⌨️ MappingLoader: Failed to decode JSON: \(error)")
            keyMapping = [:]
            ligaturesMapping = [:]
            specialMappings = [:]
        }
    }

    func getCharacter(for keySequence: String) -> String? {
        let result = keyMapping[keySequence]
        return result
    }

    func getAllMappings() -> [String: String] {
        return keyMapping
    }

    func getLigatures() -> [String: String] {
        return ligaturesMapping
    }

    func getSpecialMapping(for key: String) -> String? {
        return specialMappings[key]
    }

    func matchesAllowedPattern(_ text: String) -> Bool {
        guard let regex = allowedPatternRegex else {
            return true // No pattern means allow all
        }
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex.firstMatch(in: text, range: range) != nil
    }

}
