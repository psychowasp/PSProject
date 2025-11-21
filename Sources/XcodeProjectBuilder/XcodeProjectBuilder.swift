//
//  XcodeProjectBuilder.swift
//  PSProject
//
//  Created by CodeBuilder on 12/11/2025.
//
import ProjectSpec
import PathKit
import XCAssetsProcessor
import CoreGraphics
import Foundation
import TOMLKit
import Backends
import PSTools
import PyProjectToml

@MainActor
public final class XcodeProjectBuilder {
    let workingDir: Path
    
    var project: Project
    let pyproject: PyProjectToml
    
    init(project: Project, pyproject: PyProjectToml) {
        self.project = project
        self.pyproject = pyproject
        workingDir = project.basePath
    }
    
    @discardableResult
    public static func create(uv: Path, targets: [ProjectSpec.Platform], open: Bool) async throws -> Self {
        
        let pyproject_toml: Path = uv + "pyproject.toml"
        let pyproject = try pyproject_toml.loadPyProjectToml()
        
        guard let psproject = pyproject.tool?.psproject else {
            fatalError("[tool.psproject] is missing")
        }
        //let proj_target = ProjectTarget()
        
        let project = try Project(
            name: psproject.app_name ?? pyproject.project.name,
            basePath: uv + "project_dist/xcode",
            uv_root: uv,
            platforms: targets,
            toml_psproject: psproject,
            toml: pyproject,
            toml_table: .init(string: .init(contentsOf: pyproject_toml.url, encoding: .utf8))
        )
        let xcode_proj = Self.init(project: project, pyproject: pyproject)
        
        try await xcode_proj.createStructure()
        try await xcode_proj.project.generate(open: open)
        
        return xcode_proj
    }
    
    public func createStructure() async throws {
        try await createRootFolders()
        
        try await installBackends()
        
        try await copyPythonLibs()
        
        try await copyAppFiles()
        
        try await handleSwiftFiles()
    }
    
    
    
    
}


extension XcodeProjectBuilder {
    
    private func createRootFolders() async throws {
        
        func rootFolders(root: Path, main_target: Bool) async throws {
            
            if main_target {
                try? (root + "app").mkpath(ignore: true)
                let support = root + "Support"
                try support.mkpath(ignore: true)
                
                let dylib_plist = support + "dylib-Info-template.plist"
                try dylib_plist.write(stdlib_plist(), encoding: .utf8)
            } else {
                if !root.exists { try root.mkdir() }
                let dylib_plist = root + "dylib-Info-template.plist"
                try dylib_plist.write(stdlib_plist(), encoding: .utf8)
            }
            
            let sources = root + "Sources"
            
            let ios_sources = sources + "IphoneOS"
            try ios_sources.mkpath(ignore: true)
            
            let macos_sources = sources + "MacOS"
            try macos_sources.mkpath(ignore: true)
            
            if main_target {
                let shared_sources = sources + "Shared"
                try shared_sources.mkpath(ignore: true)
            }
            
            try await createSitePackages(root: root)
        }
        
        try await rootFolders(
            root: workingDir,
            main_target: true
        )
        
        for target in project.project_targets.filter({$0.extra_target != nil}) {
            try await rootFolders(
                root: target.workingDir,
                main_target: false
            )
        }
    }
    
    
    private func createSitePackages(root: Path) async throws {
        let site_root = root + "site_packages"
        try site_root.mkpath(ignore: true)
        try (site_root + "iphoneos").mkdir(ignore: true)
        try (site_root + "iphonesimulator").mkdir(ignore: true)
        try (site_root + "macos").mkdir(ignore: true)
    }
    
    fileprivate func installBackends() async throws {
        let support = workingDir + "Support"
        
        //try Validation.support()
        //try await Validation.supportPythonFramework()
        
        var backends = project.backends
        for extra_target in project.project_targets.compactMap(\.extra_target) {
            backends.append(contentsOf: try extra_target.loaded_backends())
        }
        
        backends = backends.uniqued(on: \.name)
        
        for backend in backends {
            try await backend.do_install(support: support, platform: .auto)
        }
    }
    
    private func copyPythonLibs() async throws {
        let support = workingDir + "Support"
        let python_fw = Path.ps_support + "Python.xcframework"
        
        for target in project.platforms {
            switch target {
                case .iOS:
                    
                    let lib_arm64 = python_fw + "ios-arm64"
                    let lib_sim = python_fw + "ios-arm64_x86_64-simulator"
                    for lib in [ lib_arm64, lib_sim ] {
                        try? lib.copy(support + lib.lastComponent)
                    }
                case .macOS:
                    let mac_support = support + "macos-arm64_x86_64"
                    try? (python_fw + "macos-arm64_x86_64").copy(mac_support)
                    let mac3_13 = mac_support + "Python.framework/Versions/3.13"
                    try? (mac3_13 + "lib").copy(mac_support + "lib")
                    try? (mac3_13 + "include").copy(mac_support + "include")
                default:
                    fatalError("\(target) not implemented")
            }
        }
    }
    
    private func copyAppFiles() async throws {
        let appFiles = try await getKivyAppFiles()
        
        
        for target in project.platforms {
            //let targ_path = target.targetPath(workingDir)
            let resourcesPath = workingDir + "Resources"
            if !resourcesPath.exists { try resourcesPath.mkdir() }
                switch target {
                    case .iOS:
                        try? (appFiles + "Launch Screen.storyboard").copy(resourcesPath + "Launch Screen.storyboard")
                        
                        try await generateIconAsset(resourcesPath: resourcesPath, appFiles: appFiles)
                        
                    case .macOS:
                        break
                    default: break
                }
            
        }
        
        if project.toml_psproject.copy__main__py {
            let app_dir = project.basePath + "app"
            let app_src = pyproject.app_src(root: .current)
            let fn = "__main__.py"
            try! (app_src + fn).copy(app_dir + fn )
        }
    }
    
    private func handleSwiftFiles() async throws {
        
        func createMain(target: Platform, root: Path, backends: [any BackendProtocol]) throws {
            let sourcesPath = root + "Sources"
            switch target {
                case .iOS:
                    let mainFile = try temp_main_file(
                        backends: backends,
                        platform: .iOS
                    )
                    try (sourcesPath + "IphoneOS/main.swift").write(mainFile)
                case .macOS:
                    let mainFile = try temp_main_file(
                        backends: backends,
                        platform: .macOS
                    )
                    try (sourcesPath + "MacOS/main.swift").write(mainFile)
                default: break
                    
            }
        }
        
        let backends = project.backends
        let extra_targets = project.project_targets.filter({$0.extra_target != nil})
        for target in project.platforms {
            print(Self.self, "handleSwiftFiles", target)
            try createMain(target: target, root: workingDir, backends: backends)
            
            for extra_target in extra_targets {
                print(Self.self, "handleSwiftFiles extra target", target)
                try createMain(target: target, root: extra_target.workingDir, backends: extra_target.extra_target?.loaded_backends() ?? [])
            }
        }
        
        
    }
    
    private func generateIconAsset(resourcesPath: Path, appFiles: Path) async throws {
        let png: Path = appFiles + "icon.png"
        let dest: Path = resourcesPath + "Images.xcassets"
        
        let appiconset = dest + "AppIcon.appiconset"
        try? appiconset.mkpath()
        let iconsData = [IconDataItem].allIcons
        let assetData = iconsData//.filter({$0.idiom != .mac})
        //iconsData.filter({$0.idiom == .mac})
        
        let sizes: [CGFloat] = assetData.compactMap { Double($0.expected_size)! }
        try XCAssetsProcessor(source: png).process(dest: appiconset, sizes: sizes)
        
        
        try JSONEncoder().encode(ContentsJson(images: assetData)).write(to: (appiconset + "Contents.json").url)
    }
    
    private func getKivyAppFiles() async throws -> Path {
        let kivyAppFiles: Path = .ps_support + "KivyAppFiles"
        if !kivyAppFiles.exists {
            //try! kivyAppFiles.delete()
            Path.ps_support.chdir {
                gitClone("https://github.com/py-swift/KivyAppFiles")
            }
        }
        
        return kivyAppFiles
        
    }
    
    @discardableResult
    public  static func copyAndModifyUVProject(_ uv: Path, excludes: [String]) throws -> Path {
        let new = Path.current
        let pyproject = uv + "pyproject.toml"
        let py_new = new + "pyproject.toml"
        
        let modded = try TOMLTable(string: try pyproject.read())
        var deps = (modded["project"]?["dependencies"]?.array ?? []).compactMap(\.string)
        
        deps.removeAll { dep in
            //guard let dep = dep.string else { return false }
            return excludes.contains { exc in
                dep.hasPrefix(exc)
            }
        }
        
//        for ext in excludes {
//            
//            switch ext {
//                case "kivy":
//                    deps.removeAll(where: { dep in
//                        if let dep = dep.string {
//                            switch dep {
//                                case let reloader where reloader.hasPrefix("kivy-reloader"):
//                                    false
//                                default:
//                                    dep.hasPrefix(ext)
//                            }
//                        } else {
//                            false
//                        }
//                    })
//                default:
//                    deps.removeAll(where: { dep in
//                        if let dep = dep.string {
//                            dep.hasPrefix(ext)
//                        } else {
//                            false
//                        }
//                    })
//            }
//            
//        }
        modded["project"]?["dependencies"] = deps.tomlValue
        
        try py_new.write(modded.convert())
        return new
    }
    
    public static func generateReqFromUV(toml: PyProjectToml, uv: Path, backends: [any BackendProtocol]) async throws -> String {
        //var excludes = toml.pyswift.project?.exclude_dependencies ?? []
        
        var excludes = toml.tool?.psproject?.exclude_dependencies ?? []
        
        for backend in backends {
            excludes.append(contentsOf: try backend.exclude_dependencies())
        }
        
        if !excludes.isEmpty {
            var reqs = [String]()
            let uv_abs = uv.absolute()
            try Path.withTemporaryFolder { tmp in
                // loads, modifies and save result as pyproject.toml in temp folder
                // and temp folder now mimics an uv project directory
                let wheels_dir = uv_abs + "wheels"
                if wheels_dir.exists {
                    try (tmp + "wheels").symlink(wheels_dir)
                }
                try Self.copyAndModifyUVProject(uv_abs, excludes: excludes)
                reqs.append(
                    UVTool.export_requirements(uv_root: tmp, group: nil)
                )
                
            }
            if let ios_pips = toml.tool?.psproject?.dependencies?.pips {
                reqs.append(contentsOf: ios_pips)
            }
            
            let req_txt = reqs.joined(separator: "\n")
            print(req_txt)
            return req_txt
        } else {
            // excludes not defined or empty go on like normal
            var reqs = [String]()
            reqs.append(
                UVTool.export_requirements(uv_root: uv, group: nil)
            )
            if let ios_pips = toml.tool?.psproject?.dependencies?.pips {
                reqs.append(contentsOf: ios_pips)
            }
            
            let req_txt = reqs.joined(separator: "\n")
            print(req_txt)
            return req_txt
        }
        
    }

}
