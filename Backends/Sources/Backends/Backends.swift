// The Swift Programming Language
// https://docs.swift.org/swift-book
import PSTools


public struct WrapperImporter {
    
    public let libraries: [Library]
    public let modules: [WrapperImport]
    
    public init(libraries: [Library], modules: [WrapperImport]) {
        self.libraries = libraries
        self.modules = modules
    }
    
    
    public struct Library: CustomStringConvertible {
        
        public let name: String
        
        public init(name: String) {
            self.name = name
        }
        
        public var description: String {
            name
        }
        
    }
    
    public enum WrapperImport: CustomStringConvertible {
        
        case static_import(String)
        case name_import(name: String, module: String)
        
        
        
        
        public var description: String {
            switch self {
                case .static_import(let string):
                    string
                case .name_import(let name, let module):
                    ".init(name: \(name), module: \(module).py_init )"
            }
        }
    }
}

extension Validation {
    public static func supportPythonFramework() async throws {
        if validateSupportPythonFramework() { return }
        //let gil = PyGILState_Ensure()
        let py_backend = await PyFrameworkBackend()
        
        try await py_backend.do_install(support: .ps_support, platform: .auto)
        
        //PyGILState_Release(gil)
    }
}


