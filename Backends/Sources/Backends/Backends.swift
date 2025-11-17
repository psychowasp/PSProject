// The Swift Programming Language
// https://docs.swift.org/swift-book
import PSTools


public struct WrapperImporter: Decodable {
    
    public let libraries: [Library]
    public let modules: [WrapperImport]
    
    public init(libraries: [Library], modules: [WrapperImport]) {
        self.libraries = libraries
        self.modules = modules
    }
    
    enum CodingKeys: CodingKey {
        case libraries
        case modules
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try! decoder.container(keyedBy: CodingKeys.self)
        self.libraries = try! container.decode([WrapperImporter.Library].self, forKey: .libraries)
        self.modules = try! container.decode([WrapperImporter.WrapperImport].self, forKey: .modules)
    }
   
    
    public struct Library: CustomStringConvertible, Decodable {
        
        public let name: String
        
        public init(name: String) {
            self.name = name
        }
        
        public var description: String {
            name
        }
        
        public init(from decoder: any Decoder) throws {
            let c = try decoder.singleValueContainer()
            name = try c.decode(String.self)
        }
    }
    
    public enum WrapperImport: CustomStringConvertible, Decodable {
        
        case static_import(String)
        case name_import(name: String, module: String)
        
        enum NameImportCodingKeys: CodingKey {
            case name
            case module
        }
        
        public init(from decoder: any Decoder) throws {
            if let c = try? decoder.singleValueContainer() {
                let string = try! c.decode(String.self)
                if string.hasPrefix(".") {
                    self = .static_import(string)
                } else {
                    fatalError("raw strings should contain prefix . and refer to static extension")
                }
            } else {
                let c = try! decoder.container(keyedBy: NameImportCodingKeys.self)
                self = .name_import(
                    name: try c.decode(String.self, forKey: .name),
                    module: try c.decode(String.self, forKey: .module)
                )
            }
        }
        
        
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


