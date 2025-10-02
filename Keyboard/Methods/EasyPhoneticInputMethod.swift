import Foundation


class EasyPhoneticInputMethod: PhoneticInputMethod {
    override var mappingFileName: String { "easy" }
    override var maxMappingWordSize: Int { 4 }
}
