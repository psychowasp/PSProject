//
//  MainFiles.swift
//  PSProject
//
import Backends
import Algorithms


@MainActor
func temp_main_file(backends: [any BackendProtocol]) throws -> String {
    let imports = try backends.flatMap { backend in
        try backend.wrapper_imports(platform: .iOS).flatMap { imp in
            imp.libraries.map(\.description)
        }
    }
    let modules = try backends.flatMap { backend in
        try backend.wrapper_imports(platform: .iOS).flatMap { imp in
            imp.modules.map(\.description)
        }
    }
    
    let imports_block = imports.map({"import \($0)"}).joined(separator: "\n")
    
    let main_blocks = try backends.flatMap { backend in
        guard try backend.will_modify_main_swift() else { return  [CodeBlock]() }
        return try backend.modify_main_swift(libraries: imports, modules: modules, platform: .iOS)
    }.chunked(on: \.priority).sorted(by: {$0.0 < $1.0})
    
    
    
    let main_code = main_blocks.flatMap( { priority, blocks in
        var output = [String]()
        output.append("// \(priority.rawValue) - \(priority)")
        for block in blocks {
            output.append(block.code)
        }
        
        return output
    } ).joined(separator: "\n")
    
    //    let pre_lines = try backends.compactMap { backend in
    //        "try backend.pre_main_swift(libraries: imports, modules: modules)"
    //    }
    //    let post_lines = try backends.compactMap { backend in
    //        "try backend.main_swift(libraries: imports, modules: modules)"
    //    }
    //let imports = wrapper_importers.flatMap({$0.libraries.map(\.description)})
    //let modules = wrapper_importers.flatMap({$0.modules.map(\.description)})
    return """
    import Foundation
    import PySwiftKit
    \(imports_block)
    
    \(main_code)
    """
}

