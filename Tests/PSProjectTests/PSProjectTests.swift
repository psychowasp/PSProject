import Testing
@testable import XcodeProjectBuilder
@testable import PyProjectToml
import PathKit
import TOMLKit
import Foundation

let testPath = Path.current + "NewProjectTest"

@Test func test_new_project_kivy() async throws {
    
    setenv("LOGNAME", "Joe", 1)
    
    print("test A")
    if testPath.exists { try testPath.delete() }
    try await PyProjectToml.newToml(path: testPath, uv_name: nil, cythonized: false)
    
    let pyproject_path = testPath + "pyproject.toml"
    #expect(pyproject_path.exists)
    
    let py_src = testPath + "src/newprojecttest"
    #expect(py_src.exists)
    
    let app_file = py_src + "app.py"
    let __main__file = py_src + "__main__.py"
    let __init__file = py_src + "__init__.py"
    
    #expect(app_file.exists)
    #expect(__init__file.exists)
    #expect(__main__file.exists)
    
    let toml = try TOMLTable(string: try pyproject_path.read())
    
    let tool = toml["tool"]
    #expect(tool != nil)
    let psproject_toml = tool!["psproject"]
    #expect(psproject_toml != nil)
    
    let backends = psproject_toml?["backends"]?.array!
    
    backends?.append("kivyschool.kivylauncher")
    
    #expect(toml["tool"]!["psproject"]!["backends"]! == ["kivyschool.kivylauncher"])
    
    try pyproject_path.write(toml.convert())
    print(pyproject_path)
    
    var xcode_build: XcodeProjectBuilder?
    try await testPath.chdir {
        xcode_build = try await XcodeProjectBuilder.create(uv: testPath, targets: [.iOS, .macOS], open: false)
    }
    
    guard let xcode_build  else { throw URLError.init(.badURL) }
    let xcode_path = await xcode_build.workingDir
    
    let sources = xcode_path + "Sources"
    #expect(sources.exists)
    
    let resources = xcode_path + "Resources"
    #expect(resources.exists)
    
    let launch_screen = resources + "Launch Screen.storyboard"
    #expect(launch_screen.exists)
    
    let support = xcode_path + "Support"
    
    let support_files = [
        "dylib-Info-template.plist",
        "ios-arm64",
        "ios-arm64_x86_64-simulator",
        "macos-arm64_x86_64"
    ].map({support + $0})
    
    
    for support_file in support_files {
        #expect(support_file.exists, "\(support_file) missing")
    }
    
    let app_folder = xcode_path + "app"
    #expect(app_folder.exists)
    
    #expect(toml["tool"]!["psproject"]!["copy__main__py"]! == true)
    
    let app_main = app_folder + "__main__.py"
    #expect(app_main.exists)
    
}


