//
//  Cache.swift
//  PSProject
//
//  Created by CodeBuilder on 20/11/2025.
//


//
//  Cache.swift
//  PSProjectGenerator
//

import Foundation
import ArgumentParser
import PathKit
import XcodeProjectBuilder
import Backends
import TOMLKit
import PSTools
import PipRepo
import PyProjectToml

extension Path: @unchecked Swift.Sendable {}

extension PSProject.Wheels {
    
    struct Cache: AsyncParsableCommand {
        
        
        static let configuration: CommandConfiguration = .init(subcommands: [
            Download.self,
            Update.self
        ])
        
       
        
        struct Update: AsyncParsableCommand {
            
            @Argument var uv: Path
            
            func run() async throws {
                if !Validation.hostPython() { return }
                try Validation.backends()
                
                //try await launchPython()
                let uv_abs = uv.absolute()
                let toml_path = (uv_abs + "pyproject.toml")
                
                //let toml = try TOMLDecoder().decode(PyProjectToml.self, from: try (toml_path).read())
                let toml = try toml_path.loadPyProjectToml()
                toml.root = uv
                
                guard
                    let pyswift_project = toml.tool?.psproject
                    //let folderName = await pyswift_project.folder_name
                else { return }
                
                let cache_dir = Path((pyswift_project.wheel_cache_dir ?? ".wheels").resolve_path(prefix: uv_abs, file_url: false))
                guard cache_dir.exists else {
                    return
                }
                let repo = try RepoFolder(root: cache_dir)
                try repo.generate_simple(output: cache_dir)
            }
        }
    }
    
    
}
