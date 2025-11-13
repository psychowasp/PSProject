// The Swift Programming Language
// https://docs.swift.org/swift-book
// 
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import XcodeProjectBuilder
import PathKit
import Backends
import PSTools
import PyProjectToml


@main
struct PSProject: AsyncParsableCommand {
    
    static var configuration: CommandConfiguration {
        .init(
            commandName: "psproject",
            version: LIBRARY_VERSION,
            subcommands: [
                Create.self,
                Init.self,
                Update.self
            ]
        )
    }
    
    
}



extension Path: ArgumentParser.ExpressibleByArgument {
    public init?(argument: String) {
        self.init(argument)
    }
}


