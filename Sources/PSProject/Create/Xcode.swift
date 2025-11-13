//
//  Xcode.swift
//  PSProject
//
import ArgumentParser
import PathKit
import PSTools
import Backends
import ProjectSpec
import XcodeProjectBuilder

extension PSProject.Create {
    
    struct Xcode: AsyncParsableCommand {
        
        static var configuration: CommandConfiguration {
            .init(abstract: abstractInfo)
        }
        
        @Option var directory: Path?
        @Flag(name: .long) var ios = false
        @Flag(name: .long) var macos = false
        
        @Flag var forced = false
        
        @Flag var open = false
        
        @MainActor
        func run() async throws {
            
            let root = directory ?? .current
            try Validation.pyprojectExist(root: root)
            if !Validation.hostPython() { return }
            try Validation.backends()
            //let xcode_path = try Validation.xcodeProject(root: root)
            
            var targets: [ProjectSpec.Platform] = []
            
            if !(ios && macos) {
                targets = [.iOS, .macOS]
            } else {
                if ios { targets.append(.iOS) }
                if macos { targets.append(.macOS) }
            }
            
            try await XcodeProjectBuilder.create(uv: root, targets: targets, open: open)
            
        }
        
        
    }
    
}
