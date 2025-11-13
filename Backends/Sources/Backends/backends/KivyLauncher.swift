//
//  KivyLauncher.swift
//  Backends
//
import PSTools
import PathKit
import ProjectSpec

fileprivate func pre_main_swift(modules: String) -> String {
    """
    KivyLauncher.pyswiftImports = [
        \(modules)
    ]
    """
}

fileprivate let main_swift = """
let exit_status = KivyLauncher.SDLmain()
"""

fileprivate let on_exit = """
exit(exit_status)
"""


public final class KivyLauncher: SDL2Backend {
    
    public override init() {
        super.init()
    }
    
    public override var name: String { "KivyLauncher" }
    
    public override func packages() async throws -> [String : SwiftPackage] {
        [
            "KivyLauncher": .remote(
                url: "https://github.com/kivy-school/KivyLauncher",
                versionRequirement: .branch("master")
            ),
            "Kivy_iOS_Module": .remote(
                url: "https://github.com/kivy-school/Kivy_iOS_Module",
                versionRequirement: .branch("master")
            )
        ]
    }
    
    public override func target_dependencies(platform: Platform) async throws -> [Dependency] {
        var deps = try await super.target_dependencies(platform: platform)
        
        deps.append(
            .init(
                type: .package(products: ["KivyLauncher"]),
                reference: "KivyLauncher"
            )
        )
        
        deps.append(
            .init(
                type: .package(products: ["Kivy_iOS_Module"]),
                reference: "Kivy_iOS_Module",
                platformFilter: .iOS
            )
        )
        
        return deps
    }
    
    public override func wrapper_imports(platform: Platform) throws -> [WrapperImporter] {
        switch platform {
            case .iOS: [
                .init(
                    libraries: [.init(name: "KivyLauncher"), .init(name: "Kivy_iOS_Module")],
                    modules: [.static_import(".ios")]
                )
            ]
            default: [
                .init(
                    libraries: [.init(name: "KivyLauncher")],
                    modules: []
                )
            ]
        }
    }
    
    public override func will_modify_main_swift() throws -> Bool {
        true
    }
    
    public override func modify_main_swift(libraries: [String], modules: [String], platform: Platform) throws -> [CodeBlock] {
        [
            .init(code: pre_main_swift(modules: modules.joined(separator: "\n\t")), priority: .post_imports),
            .init(code: main_swift, priority: .main),
            .init(code: on_exit, priority: .on_exit)
        ]
    }
    
    
}

