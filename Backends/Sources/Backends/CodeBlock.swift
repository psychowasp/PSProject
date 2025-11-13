//
//  CodeBlock.swift
//  Backends
//
//  Created by CodeBuilder on 12/11/2025.
//


public final class CodeBlock {
    
    public var code: String
    public var priority: Priority
    
    
    
    init(code: String, priority: Priority) {
        self.code = code
        self.priority = priority
        
        //let a: String = try! PyDict_GetItem<String>(.None, key: "code")
    }
    
}

public extension CodeBlock {
    enum Priority: Int, Comparable {
        public static func < (lhs: CodeBlock.Priority, rhs: CodeBlock.Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        case imports
        case post_imports
        case pre_main
        case main
        case post_main
        case on_exit
    }
}

extension CodeBlock: CustomStringConvertible {
    
    public var description: String {
        code
    }
}
