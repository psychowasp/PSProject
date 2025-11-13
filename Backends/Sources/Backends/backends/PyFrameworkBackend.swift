
import Foundation
import PathKit
import ProjectSpec
import PSTools

public class PyFrameworkBackend: BackendProtocol {
    
    public var name: String { "PyFrameworkBackend"}
    
    let version = "3.13"
    let sub_version = "b11"

    public init() {}
    
    public func install(support: Path, platform: Platform) async throws {
        
        let support = Path.ps_support
        let py_fw  = support + "Python.xcframework"
        
        if py_fw.exists { return }
        
        let filename = "Python-\(version)-iOS-support.{\(sub_version).tar.gz"
        let py_fw_tar = support + filename
        
        let url: URL = .init(string: "https://github.com/beeware/Python-Apple-support/releases/download/\(version)-\(sub_version)/Python-\(version)-iOS-support.\(sub_version).tar.gz")!
        let (tmp, _) = try await URLSession.download(from: url)
        
        try tmp.move(py_fw_tar)
        try Process.untar(url: py_fw_tar)
        try py_fw_tar.delete()
    }
}





