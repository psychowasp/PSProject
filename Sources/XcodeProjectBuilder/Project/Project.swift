//
//  Project.swift
//  PSProject
//
import Foundation
import AppKit
@preconcurrency import ProjectSpec
import PathKit
import PyProjectToml
import Backends
import XcodeGenKit
import XcodeProj
import TOMLKit

extension XcodeProjectBuilder {
    
    @MainActor
    public class Project {
        let name: String// = "MyPySwiftProject"
        var basePath: Path //{ .current + "projects_dist/xcode" }
        let platforms: [ProjectSpec.Platform] //= [.iOS, .macOS]
        
        var project_targets: [ProjectTarget] = []
        
        let toml_psproject: Tool.PSProject
        
        let backends: [any BackendProtocol]
        
        init(name: String, basePath: Path, uv_root: Path, platforms: [ProjectSpec.Platform], toml_psproject: Tool.PSProject, toml: PyProjectToml, toml_table: TOMLTable) throws {
            self.name = name
            self.basePath = basePath
            self.platforms = platforms
            
            let py_src: Path = if uv_root.isRelative, let name = toml.tool?.psproject?.app_name {
                .init("$(dirname $PROJECT_DIR)/\(uv_root.lastComponent)/src/\(name.replacing(try Regex("[ -]"), with: "_"))")
            } else {
                uv_root + "app"
            }
            
            
            self.project_targets = [
                .init(
                    name: name,
                    py_app: py_src,
                    platforms: platforms,
                    toml: toml,
                    toml_table: toml_table,
                    workingDir: basePath
                )
            ]
            self.toml_psproject = toml_psproject
            self.backends = try toml_psproject.loaded_backends()
        }
    }
}

extension XcodeProjectBuilder.Project {
    fileprivate func configs() async throws -> [Config] {
        [.init(name: "Debug", type: .debug),.init(name: "Release", type: .release)]
    }
    
    fileprivate func targets() async throws -> [Target] {
        var output = [Target]()
        for t in project_targets {
            output.append(try await t.export())
        }
        return output
    }
    
    fileprivate func aggregateTargets() async throws -> [AggregateTarget] {
        []
    }
    
    fileprivate func settings() async throws -> Settings {
        .empty
    }
    
    fileprivate func settingGroups() async throws -> [String : Settings] {
        [:]
    }
    
    fileprivate func schemes() async throws -> [Scheme] {
        []
    }
    
    fileprivate func packages(local: Bool = false) async throws -> [String:SwiftPackage] {

        var base: [String:SwiftPackage] = if local {
            [
                "CPython": .local(path: "/Volumes/CodeSSD/GitHub/CPython", group: nil, excludeFromProject: false),
                "PySwiftKit": .local(path: "/Volumes/CodeSSD/PythonSwiftGithub/PySwiftKit", group: nil, excludeFromProject: false),
            ]
        } else {
            [
                "CPython": .remote(url: "https://github.com/py-swift/CPython", versionRequirement: .upToNextMajorVersion("313.0.0")),
                "PySwiftKit": .remote(url: "https://github.com/py-swift/PySwiftKit", versionRequirement: .upToNextMajorVersion("313.0.0")),
            ]
        }
        
        for backend in self.backends {
            for (k, v) in try await backend.packages() {
                base[k] = v
            }
        }
        
        return base
    }
    
    fileprivate func specOptions() async throws -> SpecOptions {
        return .init(bundleIdPrefix: "org.pyswift")
    }
    
    fileprivate func fileGroups() async throws -> [String] {
        []
    }
    
    fileprivate func configFiles() async throws -> [String:String] {
        [:]
    }
    
    fileprivate func attributes() async throws -> [String:Any] {
        [:]
    }
    
    fileprivate func projectReferences() async throws -> [ProjectReference] {
        []
    }
    
    
}

extension XcodeProjectBuilder.Project {
    
    public func project() async throws -> ProjectSpec.Project {
        .init(
            basePath: basePath,
            name: name,
            configs: try await configs(),
            targets: try await targets(),
            aggregateTargets: try await aggregateTargets(),
            settings: try await settings(),
            settingGroups: try await settingGroups(),
            schemes: try await schemes(),
            breakpoints: [],
            packages: try await packages(),
            options: try await specOptions(),
            fileGroups: try await fileGroups(),
            configFiles: try await configFiles(),
            attributes: try await attributes(),
            projectReferences: try await projectReferences()
        )
    }
    
    @MainActor
    public func generate(open: Bool) async throws {
        let project = try! await project()
        let fw = FileWriter(project: project)
        let projectGenerator = ProjectGenerator(project: project)
        
        guard let userName = ProcessInfo.processInfo.environment["LOGNAME"] else {
            fatalError("LOGNAME is missing in environment")
        }
        
        let xcodeProject = try! projectGenerator.generateXcodeProject(in: basePath, userName: userName)
  
        try! fw.writePlists()
        //
        
        try! fw.writeXcodeProject(xcodeProject)
        if open {
            try! await NSWorkspace.shared.open([project.defaultProjectPath.url], withApplicationAt: .applicationDirectory.appendingPathComponent("Xcode.app"), configuration: .init())
        }
    }
}
