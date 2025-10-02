import Foundation


class PhoneticInputMethod: InputMethodProtocol {
    var mappingFileName: String { "phonetic" }
    var maxMappingWordSize: Int { 4 }
    
    private lazy var inputMapper: MappingLoader = {
        return MappingLoader(configurationName: mappingFileName)
    }()

    private func isVowel(_ char: Character) -> Bool {
        let vowels: Set<Character> = ["a", "e", "i", "I", "o", "O", "u", "U"]
        return vowels.contains(char)
    }

    private func areAllVowels(_ string: String) -> Bool {
        return !string.isEmpty && string.allSatisfy { isVowel($0) }
    }
    
    private func lastCharacterStr(from text: String) -> String? {
        guard let scalar = text.unicodeScalars.last else {
            return nil
        }
        return String(scalar)
    }

    func toBangla(word: String) -> String {
        var result = ""
        var i = 0
        let wordArray = Array(word)
        let length = wordArray.count
        var canPossiblyJoin = false

        while i < length {
            let maxJ = min(maxMappingWordSize, length - i)

            for j in stride(from: maxJ, through: 1, by: -1) {
                guard i + j <= length else { continue }

                let keyArray = Array(wordArray[i..<(i + j)])
                var key = String(keyArray)
                let allVowels = areAllVowels(key) || (key == "w" && i == 0) || key == "rri"

                // Handle 'o' logic
                if i > 0 && key == "o" {
                    if isVowel(wordArray[i - 1]) {
                        key = "^O" // আমি'ও' amio
                    } else {
                        i += 1
                        canPossiblyJoin = false
                        break
                    }
                } else if allVowels && (i == 0 || !canPossiblyJoin) {
                    // if at the beginning or after previous vowel
                    key = "^\(key)"
                } else if length >= i + 3 && (i > 0 && isVowel(wordArray[i - 1]) || i == 0) &&
                          wordArray[i] == "r" && wordArray[i + 1] == "r" &&
                          !areAllVowels(String(wordArray[i + 2])) {
                    result += "র্" // রেফ
                    canPossiblyJoin = false
                    i += 2
                    break
                }

                // য-ফলা handling
                if canPossiblyJoin && key == "y" {
                    key = "z"
                }

                if let value = inputMapper.getCharacter(for: key) {
                    if canPossiblyJoin {
                        if let lastCharStr = lastCharacterStr(from: result) {
                            let ligatures = inputMapper.getLigatures()
                            if key == "z" || (ligatures[lastCharStr]?.contains(value.first ?? Character("")) ?? false) {
                                result += "্"
                            }
                        }
                    }
                    canPossiblyJoin = !allVowels
                    result += value
                    i += j
                    break
                } else if j == 1 {
                    i += 1
                    canPossiblyJoin = false
                }
            }
        }

        return result
    }

    func matchesAllowedPattern(_ text: String) -> Bool {
        return inputMapper.matchesAllowedPattern(text)
    }

    func getSpecialMapping(for key: String) -> String? {
        return inputMapper.getSpecialMapping(for: key)
    }
}
