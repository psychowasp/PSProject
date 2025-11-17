//
//  YamlBackend.swift
//  Backends
//
import Foundation
import Yams
import ProjectSpec
import PathKit



public final class YamlBackend: Decodable {
    
    let backend: Backend
    
    struct Backend: Decodable {
        let name: String
        let backend_dependencies: [String]?
        let exclude_dependencies: [String]?
        let frameworks: [String]?
        let packages: [String:SwiftPackage]?
        let target_dependencies: [Dependency]?
        let wrapper_imports: WrapperImports?
        let install: [Script]?
        let copy_to_site_packages: [Script]?
        
        enum CodingKeys: CodingKey {
            case name
            case backend_dependencies
            case exclude_dependencies
            case frameworks
            case packages
            case target_dependencies
            case wrapper_imports
            
            
            case install
            case copy_to_site_packages
        }
        
        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
            
            self.name = try container.decode(String.self, forKey: .name)
            self.backend_dependencies = try container.decodeIfPresent([String].self, forKey: .backend_dependencies)
            self.exclude_dependencies = try container.decodeIfPresent([String].self, forKey: .exclude_dependencies)
            self.frameworks = try container.decodeIfPresent([String].self, forKey: .frameworks)?.map({ rawPath in
                switch rawPath {
                    case let ps_supported where ps_supported.hasPrefix("${PS_SUPPORT}"):
                        rawPath.replacing("${PS_SUPPORT}", with: Path.ps_support.string)
                    default:
                        rawPath
                }
            })
            self.packages = try container.decodeIfPresent([String : SwiftPackage].self, forKey: .packages)
            self.target_dependencies = try! container.decodeIfPresent([Dependency].self, forKey: YamlBackend.Backend.CodingKeys.target_dependencies)
            self.wrapper_imports = try! container.decodeIfPresent(WrapperImports.self, forKey: .wrapper_imports)
            self.install = try container.decodeIfPresent([Script].self, forKey: .install)
            self.copy_to_site_packages = try container.decodeIfPresent([Script].self, forKey: .copy_to_site_packages)
        }
    }
    
    enum CodingKeys: CodingKey {
        case backend
    }
    
    public init(from decoder: any Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        self.backend = try container.decode(YamlBackend.Backend.self)
    }
}

extension YamlBackend {
    final class Script: Decodable {
        let type: ScriptType
        let shell: ShellType
        let exec: Execution
        
        enum CodingKeys: CodingKey {
            case type
            case shell
            case file
            case run
        }
        
        public init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<YamlBackend.Script.CodingKeys> = try decoder.container(keyedBy: YamlBackend.Script.CodingKeys.self)
            self.type = try container.decode(YamlBackend.Script.ScriptType.self, forKey: YamlBackend.Script.CodingKeys.type)
            self.shell = try container.decode(YamlBackend.Script.ShellType.self, forKey: YamlBackend.Script.CodingKeys.shell)
            self.exec = if container.contains(.file) {
                .file(try container.decode(String.self, forKey: .file))
            } else if container.contains(.run) {
                .run(try container.decode(String.self, forKey: .run))
            } else {
                fatalError("\(Self.self) key \n\tfile\nor\n\t run is required ")
            }
        }
    }
}

extension YamlBackend {
    struct WrapperImports: Decodable {
        let all: WrapperImporter?
        let iOS: WrapperImporter?
        let macOS: WrapperImporter?
    }
}

extension YamlBackend.Script {
    enum ScriptType: String, Decodable {
        case shell
    }
    enum ShellType: String, Decodable {
        case python
        case sh
        case zsh
        case bash
        case fish
        case ruby
    }
    enum Execution: Decodable {
        case file(String)
        case run(String)
    }
}

extension YamlBackend: BackendProtocol {
    
    public var name: String { backend.name }
    
    public func url() async throws -> URL? {nil}
    
    public func frameworks() async throws -> [Path] { backend.frameworks?.map({.init($0)}) ?? [] }
    
    public func downloads() async throws -> [URL] { [] }
    
    public func config(root: Path) async throws { }
    
    public func packages() async throws -> [String:SwiftPackage] {
        backend.packages ?? [:]
    }
    
    public func target_dependencies(platform: ProjectSpec.Platform) async throws -> [Dependency] {
        backend.target_dependencies ?? []
    }
    
    public func wrapper_imports(platform: ProjectSpec.Platform) throws -> [WrapperImporter] {
        guard let wrapper_imports = backend.wrapper_imports else {
            return []
        }
        
        switch platform {
            case .auto: if let wrappers = wrapper_imports.all {
                return [wrappers]
            }
            case .iOS, .tvOS, .visionOS, .watchOS: if let wrappers = wrapper_imports.iOS {
                return [wrappers]
            }
            case .macOS: if let wrappers = wrapper_imports.macOS {
                return [wrappers]
            }
           
        }
        return []
    }
    
    
    public func will_modify_main_swift() throws -> Bool { false }
    
    public func modify_main_swift(libraries: [String], modules: [String], platform: ProjectSpec.Platform) throws -> [CodeBlock] { [] }
    
    public func plist_entries(plist: inout [String:Any], platform: ProjectSpec.Platform) async throws { }
    
    public func install(support: Path, platform: ProjectSpec.Platform) async throws {
        print(Self.self, "install", name)
        for script in backend.install ?? [] {
            try await script.run()
        }
    }
    
    public func copy_to_site_packages(site_path: Path, platform: ProjectSpec.Platform, py_platform: String) async throws {
        print(Self.self, "copy_to_site_packages", name)
        for script in backend.copy_to_site_packages ?? [] {
            try await script.run()
        }
    }
    
    public func will_modify_pyproject() throws -> Bool { false }
    
    public func modify_pyproject(path: Path) async throws {}
    
    public func exclude_dependencies() throws -> [String] {
        backend.exclude_dependencies ?? []
    }
}
