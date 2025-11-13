//
//  Create.swift
//  PSProject
//
//  Created by CodeBuilder on 13/11/2025.
//
import ArgumentParser

extension PSProject {
    struct Create: AsyncParsableCommand {
        
        static var configuration: CommandConfiguration {
            .init(
                abstract: abstractInfo,
                subcommands: [
                    Xcode.self
                ]
            )
        }
        
        
    }
    
}

