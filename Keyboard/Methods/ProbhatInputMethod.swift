import Foundation
import Cocoa


class ProbhatInputMethod: JatiyoInputMethod {
    override var mappingFileName: String { "probhat" }
    override var maxMappingWordSize: Int { 1 }
    
    override func createMenu() -> NSMenu? {
        return nil
    }
}
