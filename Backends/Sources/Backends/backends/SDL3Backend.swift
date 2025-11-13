//
//  SDL3Backend.swift
//  Backends
//
import Foundation
import PathKit
import ProjectSpec


public class SDL3Backend: BackendProtocol {
    
    public var name: String { "SDL3" }
    
    
    
    public func frameworks() async throws -> [Path] {
        let sdl_fw: Path = .ps_support + "sdl3_frameworks" 
        
        return [
            (sdl_fw + "SDL3.xcframework"),
            (sdl_fw + "SDL3_image.xcframework"),
            (sdl_fw + "SDL3_mixer.xcframework"),
            (sdl_fw + "SDL3_ttf.xcframework"),
            (sdl_fw + "libEGL.xcframework"),
            (sdl_fw + "libGLESv2.xcframework")
        ]
    }
    
    public func target_dependencies(platform: Platform) async throws -> [Dependency] {
        switch platform {
                
            case .iOS:
                [
                    .init(type: .framework, reference: "Support/SDL3.xcframework", platformFilter: .iOS),
                    .init(type: .framework, reference: "Support/SDL3_image.xcframework", platformFilter: .iOS),
                    .init(type: .framework, reference: "Support/SDL3_mixer.xcframework", platformFilter: .iOS),
                    .init(type: .framework, reference: "Support/SDL3_ttf.xcframework", platformFilter: .iOS),
                    .init(type: .framework, reference: "Support/libEGL.xcframework", platformFilter: .iOS),
                    .init(type: .framework, reference: "Support/libGLESv2.xcframework", platformFilter: .iOS)
                ]
            case .watchOS, .visionOS, .tvOS:
                []
            case .auto, .macOS: []
        }
    }
    
    public func install(support: Path, platform: Platform) async throws {
        //if platform == .iOS {
            let sdl2_frameworks: Path = support + "sdl3_frameworks"
            if !sdl2_frameworks.exists {
                try await self.pip_install(
                    "kivy_sdl3_angle",
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

