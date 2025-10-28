import Foundation


class EasyPhoneticInputMethod: PhoneticInputMethod {
    override var mappingFileName: String { "easy" }
    override var maxMappingWordSize: Int { 4 }
    
    
    override func toBangla(word: String) -> String {
        return super .toBangla(word: word.lowercased())
    }
    
}
