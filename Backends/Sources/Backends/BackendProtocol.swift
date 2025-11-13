//
//  BackendProtocol.swift
//  Backends
//
import PathKit
import Foundation
import ProjectSpec
import XcodeGenKit
import PSTools


@MainActor
public protocol BackendProtocol: AnyObject {
    
    var name: String { get }
    
    func url() async throws -> URL?
    
    func frameworks() async throws -> [Path]
    
    func downloads() async throws -> [URL]
    
    func config(root: Path) async throws
    
    func packages() async throws -> [String:SwiftPackage]
    
    func target_dependencies(platform: ProjectSpec.Platform) async throws -> [Dependency]
    
    func wrapper_imports(platform: ProjectSpec.Platform) throws -> [WrapperImporter]
    
    func will_modify_main_swift() throws -> Bool
    
    func modify_main_swift(libraries: [String], modules: [String], platform: ProjectSpec.Platform) throws -> [CodeBlock]
    
    func plist_entries(plist: inout [String:Any], platform: ProjectSpec.Platform) async throws
    
    func install(support: Path, platform: ProjectSpec.Platform) async throws
    
    func copy_to_site_packages(site_path: Path, platform: ProjectSpec.Platform, py_platform: String) async throws
    
    func will_modify_pyproject() throws -> Bool
    
    func modify_pyproject(path: Path) async throws
    
    func exclude_dependencies() throws -> [String]
}


extension BackendProtocol {
    public func do_install(support: Path, platform: ProjectSpec.Platform) async throws {
        try await install(support: .ps_support, platform: platform)
        
        for fw in try await frameworks() {
            let path = fw
            let target = support + path.lastComponent
            print(fw, target)
            if target.exists { continue }
            try path.copy(target)
        }
    }
    
    var pyswift_simple: String {"https://pypi.anaconda.org/pyswift/simple"}
    var kivyschool_simple: String {"https://pypi.anaconda.org/kivyschool/simple"}
    var beeware_simple: String {"https://pypi.anaconda.org/beeware/simple"}
    
    public func pip_install(_ pip: String, _ args: String...) async throws {
        PyTools.pipInstall(pip: pip, args)
    }
}



public extension BackendProtocol {
    
    
    func url() async throws -> URL? {nil}
    
    func frameworks() async throws -> [Path] { [] }
    
    func downloads() async throws -> [URL] { [] }
    
    func config(root: Path) async throws { }
    
    func packages() async throws -> [String:SwiftPackage] {
        [:]
    }
    
    func target_dependencies(platform: ProjectSpec.Platform) async throws -> [Dependency] { [] }
    
    func wrapper_imports(platform: ProjectSpec.Platform) throws -> [WrapperImporter] { [] }
    
    func will_modify_main_swift() throws -> Bool { false }
    
    func modify_main_swift(libraries: [String], modules: [String], platform: ProjectSpec.Platform) throws -> [CodeBlock] { [] }
    
    func plist_entries(plist: inout [String:Any], platform: ProjectSpec.Platform) async throws { }
    
    func install(support: Path, platform: ProjectSpec.Platform) async throws {}
    
    func copy_to_site_packages(site_path: Path, platform: ProjectSpec.Platform, py_platform: String) async throws {}
    
    func will_modify_pyproject() throws -> Bool { false }
    
    func modify_pyproject(path: Path) async throws {}
    
    func exclude_dependencies() throws -> [String] { [] }
}



