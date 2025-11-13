//
//  SDL2Backend.swift
//  Backends
//
import Foundation
import PathKit
import ProjectSpec
import PSTools

public class SDL2Backend: BackendProtocol {
    
    public var name: String { "SDL2" }
    
    
    
    public func frameworks() async throws -> [Path] {
        let sdl2_fw: Path = .ps_support + "sdl2_frameworks"
        return [
            (sdl2_fw + "SDL2.xcframework"),
            (sdl2_fw + "SDL2_image.xcframework"),
            (sdl2_fw + "SDL2_mixer.xcframework"),
            (sdl2_fw + "SDL2_ttf.xcframework")
        ]
    }
    
    public func target_dependencies(platform: Platform) async throws -> [Dependency] {
        switch platform {
            case .iOS:
                [
                    .init(type: .framework, reference: "Support/SDL2.xcframework", platformFilter: .iOS),
                    .init(type: .framework, reference: "Support/SDL2_image.xcframework", platformFilter: .iOS),
                    .init(type: .framework, reference: "Support/SDL2_mixer.xcframework", platformFilter: .iOS),
                    .init(type: .framework, reference: "Support/SDL2_ttf.xcframework", platformFilter: .iOS),
                ]
            case .watchOS, .visionOS, .tvOS:
                []
            case .auto, .macOS: []
        }
    }
    
    public func install(support: Path, platform: Platform) async throws {
        //if platform == .auto {
            let sdl2_frameworks: Path = support + "sdl2_frameworks"
            if !sdl2_frameworks.exists {
                try await self.pip_install(
                    "kivy_sdl2",
                    "--extra-index-url", self.kivyschool_simple,
                    "-t", sdl2_frameworks.string
                )
            }
        //}
    }
    
    
    public func url() async throws -> URL? {nil}
        
    public func downloads() async throws -> [URL] { [] }
    
    public func config(root: Path) async throws { }
    
    public func packages() async throws -> [String:SwiftPackage] {
        [:]
    }
        
    public func wrapper_imports(platform: ProjectSpec.Platform) throws -> [WrapperImporter] { [] }
    
    public func will_modify_main_swift() throws -> Bool { false }
    
    public func modify_main_swift(libraries: [String], modules: [String], platform: ProjectSpec.Platform) throws -> [CodeBlock] { [] }
    
    public func plist_entries(plist: inout [String:Any], platform: ProjectSpec.Platform) async throws { }
        
    public func copy_to_site_packages(site_path: Path, platform: ProjectSpec.Platform, py_platform: String) async throws {}
    
    public func will_modify_pyproject() throws -> Bool { false }
    
    public func modify_pyproject(path: Path) async throws {}
    
    public func exclude_dependencies() throws -> [String] { [] }
}
