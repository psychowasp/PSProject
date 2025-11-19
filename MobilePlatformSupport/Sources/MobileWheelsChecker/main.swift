import Foundation
import MobilePlatformSupport

// MARK: - Usage Documentation
func printUsage() {
    print("""
    🔍 Mobile Wheels Checker - Check PyPI packages for iOS/Android support
    
    USAGE:
        mobile-wheels-checker [LIMIT] [OPTIONS]
    
    ARGUMENTS:
        LIMIT           Number of packages to check (default: 1000)
    
    OPTIONS:
        -d, --deps      Enable dependency checking (recursive)
        -a, --all       Use PyPI Simple Index (all packages) instead of top packages
        -h, --help      Show this help message
    
    EXAMPLES:
        # Check top 100 most popular packages
        mobile-wheels-checker 100
        
        # Check top 500 packages with dependency checking
        mobile-wheels-checker 500 --deps
        
        # Check first 1000 packages from PyPI Simple Index
        mobile-wheels-checker 1000 --all
        
        # Check all packages on PyPI (~700k packages - will take hours!)
        mobile-wheels-checker 999999 --all
    
    DATA SOURCES:
        Default:    Top packages from hugovk.github.io (ranked by popularity)
        --all:      All packages from pypi.org/simple (alphabetical order)
    
    OUTPUT:
        - Terminal output with four categorized tables
        - Markdown report: mobile-wheels-results.md
    
    """)
}

struct TopPyPIPackage: Codable {
    let project: String
    let download_count: Int?
}

struct TopPyPIResponse: Codable {
    let last_update: String
    let rows: [TopPyPIPackage]
}

struct MobileWheelsChecker {
    
    static func downloadTopPackages(limit: Int = 100) async throws -> [String] {
        let url = URL(string: "https://hugovk.github.io/top-pypi-packages/top-pypi-packages-30-days.min.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(TopPyPIResponse.self, from: data)
        
        let packages = response.rows.prefix(limit).map { $0.project }
        print("📥 Downloaded top \(packages.count) packages from PyPI\n")
        return Array(packages)
    }
    
    static func downloadAllPackagesFromSimpleIndex() async throws -> [String] {
        print("📥 Downloading package list from PyPI Simple Index...")
        let url = URL(string: "https://pypi.org/simple/")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "MobileWheelsChecker", code: 1, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to decode HTML"])
        }
        
        // Parse package names from HTML
        // Format: <a href="/simple/package-name/">package-name</a>
        var packages: [String] = []
        let pattern = #"<a href="/simple/[^/]+/">([^<]+)</a>"#
        
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: html, options: [], 
                                       range: NSRange(html.startIndex..., in: html))
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: html) {
                    let packageName = String(html[range])
                    packages.append(packageName)
                }
            }
        }
        
        print("📦 Found \(packages.count) packages on PyPI\n")
        return packages
    }
    
    static func exportMarkdown(
        limit: Int,
        checkDeps: Bool,
        officialBinaryWheels: [PackageInfo],
        pyswiftBinaryWheels: [PackageInfo],
        purePython: [PackageInfo],
        binaryWithoutMobile: [PackageInfo],
        allPackagesWithDeps: [(PackageInfo, [PackageInfo], Bool)],
        timestamp: Date
    ) throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = dateFormatter.string(from: timestamp)
        
        let filename = "mobile-wheels-results.md"
        
        var markdown = """
        # Mobile Platform Support Report
        
        **Generated:** \(dateString)  
        **Packages Checked:** \(limit)  
        **Dependency Checking:** \(checkDeps ? "Enabled" : "Disabled")
        
        ---
        
        ## 🔧 Official Binary Wheels (PyPI)
        
        Packages with official iOS/Android wheels available on PyPI.
        
        | Package | Android | iOS |\(checkDeps ? " Dependencies |" : "")
        |---------|---------|-----|\(checkDeps ? "-------------|" : "")
        
        """
        
        for package in officialBinaryWheels {
            let androidStatus = formatStatusMarkdown(package.android)
            let iosStatus = formatStatusMarkdown(package.ios)
            
            if checkDeps {
                if let depInfo = allPackagesWithDeps.first(where: { $0.0.name == package.name }) {
                    let depsOK = depInfo.2 ? "✅ All supported" : "⚠️ Some unsupported"
                    let depCount = depInfo.1.count
                    markdown += "| `\(package.name)` | \(androidStatus) | \(iosStatus) | \(depsOK) (\(depCount)) |\n"
                }
            } else {
                markdown += "| `\(package.name)` | \(androidStatus) | \(iosStatus) |\n"
            }
        }
        
        if officialBinaryWheels.isEmpty {
            markdown += "\n_No packages found._\n"
        }
        
        markdown += """
        
        
        ## 🔧 PySwift Binary Wheels
        
        Custom iOS/Android builds from [pypi.anaconda.org/pyswift/simple](https://pypi.anaconda.org/pyswift/simple).
        
        | Package | Android | iOS |\(checkDeps ? " Dependencies |" : "")
        |---------|---------|-----|\(checkDeps ? "-------------|" : "")
        
        """
        
        for package in pyswiftBinaryWheels {
            let androidStatus = formatStatusMarkdown(package.android)
            let iosStatus = formatStatusMarkdown(package.ios)
            
            if checkDeps {
                if let depInfo = allPackagesWithDeps.first(where: { $0.0.name == package.name }) {
                    let depsOK = depInfo.2 ? "✅ All supported" : "⚠️ Some unsupported"
                    let depCount = depInfo.1.count
                    markdown += "| `\(package.name)` | \(androidStatus) | \(iosStatus) | \(depsOK) (\(depCount)) |\n"
                }
            } else {
                markdown += "| `\(package.name)` | \(androidStatus) | \(iosStatus) |\n"
            }
        }
        
        if pyswiftBinaryWheels.isEmpty {
            markdown += "\n_No packages found._\n"
        }
        
        markdown += """
        
        
        ## 🐍 Pure Python Packages
        
        Packages that work on all platforms (no binary dependencies).
        
        """
        
        if purePython.count > 100 {
            markdown += "_Showing first 100 packages. Total: \(purePython.count)_\n\n"
        }
        
        markdown += """
        | Package | Android | iOS |\(checkDeps ? " Dependencies |" : "")
        |---------|---------|-----|\(checkDeps ? "-------------|" : "")
        
        """
        
        let maxDisplay = min(100, purePython.count)
        for package in purePython.prefix(maxDisplay) {
            let androidStatus = formatStatusMarkdown(package.android)
            let iosStatus = formatStatusMarkdown(package.ios)
            
            if checkDeps {
                if let depInfo = allPackagesWithDeps.first(where: { $0.0.name == package.name }) {
                    let depsOK = depInfo.2 ? "✅ All supported" : "⚠️ Some unsupported"
                    let depCount = depInfo.1.count
                    markdown += "| `\(package.name)` | \(androidStatus) | \(iosStatus) | \(depsOK) (\(depCount)) |\n"
                }
            } else {
                markdown += "| `\(package.name)` | \(androidStatus) | \(iosStatus) |\n"
            }
        }
        
        if purePython.count > 100 {
            markdown += "\n_... and \(purePython.count - 100) more packages_\n"
        }
        
        markdown += """
        
        
        ## ❌ Binary Packages Without Mobile Support
        
        Packages with binary wheels but no iOS/Android support.
        
        | Package | Android | iOS |\(checkDeps ? " Dependencies |" : "")
        |---------|---------|-----|\(checkDeps ? "-------------|" : "")
        
        """
        
        for package in binaryWithoutMobile {
            let androidStatus = formatStatusMarkdown(package.android)
            let iosStatus = formatStatusMarkdown(package.ios)
            
            if checkDeps {
                if let depInfo = allPackagesWithDeps.first(where: { $0.0.name == package.name }) {
                    let depsOK = depInfo.2 ? "✅ All supported" : "⚠️ Some unsupported"
                    let depCount = depInfo.1.count
                    markdown += "| `\(package.name)` | \(androidStatus) | \(iosStatus) | \(depsOK) (\(depCount)) |\n"
                }
            } else {
                markdown += "| `\(package.name)` | \(androidStatus) | \(iosStatus) |\n"
            }
        }
        
        if binaryWithoutMobile.isEmpty {
            markdown += "\n_No packages found._\n"
        }
        
        // Summary statistics
        let allBinaryWheels = officialBinaryWheels + pyswiftBinaryWheels
        let androidSuccess = allBinaryWheels.filter { $0.android == .success }.count
        let iosSuccess = allBinaryWheels.filter { $0.ios == .success }.count
        let bothSupported = allBinaryWheels.filter { $0.android == .success && $0.ios == .success }.count
        
        markdown += """
        
        
        ## 📈 Summary Statistics
        
        ### Package Distribution
        
        | Category | Count | Percentage |
        |----------|-------|------------|
        | Official Binary Wheels (PyPI) | \(officialBinaryWheels.count) | \(String(format: "%.1f%%", Double(officialBinaryWheels.count) / Double(limit) * 100)) |
        | PySwift Binary Wheels | \(pyswiftBinaryWheels.count) | \(String(format: "%.1f%%", Double(pyswiftBinaryWheels.count) / Double(limit) * 100)) |
        | Pure Python | \(purePython.count) | \(String(format: "%.1f%%", Double(purePython.count) / Double(limit) * 100)) |
        | Binary Without Mobile Support | \(binaryWithoutMobile.count) | \(String(format: "%.1f%%", Double(binaryWithoutMobile.count) / Double(limit) * 100)) |
        | **Total** | **\(limit)** | **100%** |
        
        ### Platform Support (Binary Wheels)
        
        | Platform | Count | Percentage |
        |----------|-------|------------|
        | Android Support | \(androidSuccess) / \(allBinaryWheels.count) | \(String(format: "%.1f%%", allBinaryWheels.isEmpty ? 0 : Double(androidSuccess) / Double(allBinaryWheels.count) * 100)) |
        | iOS Support | \(iosSuccess) / \(allBinaryWheels.count) | \(String(format: "%.1f%%", allBinaryWheels.isEmpty ? 0 : Double(iosSuccess) / Double(allBinaryWheels.count) * 100)) |
        | Both Platforms | \(bothSupported) / \(allBinaryWheels.count) | \(String(format: "%.1f%%", allBinaryWheels.isEmpty ? 0 : Double(bothSupported) / Double(allBinaryWheels.count) * 100)) |
        
        """
        
        if checkDeps {
            let allDepsOK = allPackagesWithDeps.filter { $0.2 }.count
            let totalChecked = allPackagesWithDeps.count
            
            markdown += """
            ### Dependency Analysis
            
            | Status | Count | Percentage |
            |--------|-------|------------|
            | All Dependencies Supported | \(allDepsOK) | \(String(format: "%.1f%%", totalChecked == 0 ? 0 : Double(allDepsOK) / Double(totalChecked) * 100)) |
            | Some Dependencies Unsupported | \(totalChecked - allDepsOK) | \(String(format: "%.1f%%", totalChecked == 0 ? 0 : Double(totalChecked - allDepsOK) / Double(totalChecked) * 100)) |
            | **Total Packages with Dependencies** | **\(totalChecked)** | **100%** |
            
            """
        }
        
        markdown += """
        
        ---
        
        **Generated by:** [MobilePlatformSupport](https://github.com/Py-Swift/PSProject/tree/master/MobilePlatformSupport)  
        **Data Sources:**
        - PyPI: [pypi.org](https://pypi.org)
        - PySwift: [pypi.anaconda.org/pyswift/simple](https://pypi.anaconda.org/pyswift/simple)
        - Top Packages: [hugovk.github.io/top-pypi-packages](https://hugovk.github.io/top-pypi-packages/)
        
        """
        
        // Write to file
        let fileURL = URL(fileURLWithPath: filename)
        try markdown.write(to: fileURL, atomically: true, encoding: .utf8)
        print("\n✅ Markdown report exported to: \(filename)")
    }
    
    static func formatStatusMarkdown(_ status: PlatformSupport?) -> String {
        guard let status = status else {
            return "❓ Unknown"
        }
        
        switch status {
        case .success:
            return "✅ Supported"
        case .purePython:
            return "🐍 Pure Python"
        case .warning:
            return "⚠️ Not available"
        }
    }
    static func main(limit: Int, checkDeps: Bool, useSimpleIndex: Bool) async {
        print("🔍 Mobile Wheels Checker")
        print("========================\n")
        
        let checker = MobilePlatformSupport()
        
        do {
            // Download PySwift index first
            print("📥 Downloading PySwift index...")
            _ = try await checker.fetchPySwiftPackages()
            print()
            
            // Download packages from PyPI
            let testPackages: [String]
            if useSimpleIndex {
                // Get all packages from simple index
                let allPackages = try await downloadAllPackagesFromSimpleIndex()
                // Limit to requested number (or all if limit >= total)
                testPackages = limit >= allPackages.count ? allPackages : Array(allPackages.prefix(limit))
            } else {
                // Get top packages from hugovk
                testPackages = try await downloadTopPackages(limit: limit)
            }
            
            print("Checking \(testPackages.count) \(useSimpleIndex ? "packages" : "popular packages") for mobile support...")
            if checkDeps {
                print("(Dependency checking enabled)")
            }
            print("(Note: Only packages with binary wheels will be shown)\n")
            
            let results = try await checker.getBinaryPackages(from: testPackages)
            
            // If dependency checking is enabled, check each package's dependencies
            var allPackagesWithDeps: [(PackageInfo, [PackageInfo], Bool)] = []  // (package, deps, allDepsSupported)
            
            if checkDeps {
                print("\n🔍 Checking dependencies...\n")
                for package in results {
                    print("  Checking \(package.name)...")
                    var visited = Set<String>()
                    let depResults = try await checker.checkWithDependencies(
                        packageName: package.name,
                        depth: 1,
                        visited: &visited
                    )
                    
                    let dependencies = depResults.filter { $0.key != package.name }.map { $0.value }
                    let allDepsSupported = dependencies.allSatisfy { dep in
                        (dep.android == .success || dep.android == .purePython) &&
                        (dep.ios == .success || dep.ios == .purePython)
                    }
                    
                    allPackagesWithDeps.append((package, dependencies, allDepsSupported))
                }
            }
            
            // Separate results by source and type, sorted alphabetically
            let officialBinaryWheels = results.filter {
                $0.source == .pypi &&
                ($0.android == .success || $0.ios == .success) &&
                !($0.android == .warning && $0.ios == .warning)
            }.sorted { $0.name.lowercased() < $1.name.lowercased() }
            
            let pyswiftBinaryWheels = results.filter {
                $0.source == .pyswift &&
                ($0.android == .success || $0.ios == .success) &&
                !($0.android == .warning && $0.ios == .warning)
            }.sorted { $0.name.lowercased() < $1.name.lowercased() }
            
            let purePython = results.filter { 
                $0.android == .purePython || $0.ios == .purePython
            }.sorted { $0.name.lowercased() < $1.name.lowercased() }
            
            // Binary packages without mobile support (has binary wheels but not for iOS/Android)
            let binaryWithoutMobile = results.filter {
                ($0.android == .warning && $0.ios == .warning) &&
                ($0.android != .purePython && $0.ios != .purePython)
            }.sorted { $0.name.lowercased() < $1.name.lowercased() }
            
            // Display Official Binary Wheels
            print("\n🔧 Official Binary Wheels (PyPI):")
            print(String(repeating: "=", count: 71))
            if checkDeps {
                print("\("Package".padding(toLength: 20, withPad: " ", startingAt: 0)) \("Android".padding(toLength: 20, withPad: " ", startingAt: 0)) \("iOS".padding(toLength: 20, withPad: " ", startingAt: 0)) \("Deps OK".padding(toLength: 10, withPad: " ", startingAt: 0))")
            } else {
                print("\("Package".padding(toLength: 20, withPad: " ", startingAt: 0)) \("Android".padding(toLength: 25, withPad: " ", startingAt: 0)) \("iOS".padding(toLength: 25, withPad: " ", startingAt: 0))")
            }
            print(String(repeating: "-", count: 71))
            
            for package in officialBinaryWheels {
                let androidStatus = formatStatus(package.android)
                let iosStatus = formatStatus(package.ios)
                
                if checkDeps {
                    if let depInfo = allPackagesWithDeps.first(where: { $0.0.name == package.name }) {
                        let depsOK = depInfo.2 ? "✅" : "⚠️"
                        let depCount = depInfo.1.count
                        print("\(package.name.padding(toLength: 20, withPad: " ", startingAt: 0)) \(androidStatus.padding(toLength: 20, withPad: " ", startingAt: 0)) \(iosStatus.padding(toLength: 20, withPad: " ", startingAt: 0)) \(depsOK) (\(depCount))")
                    }
                } else {
                    print("\(package.name.padding(toLength: 20, withPad: " ", startingAt: 0)) \(androidStatus.padding(toLength: 25, withPad: " ", startingAt: 0)) \(iosStatus.padding(toLength: 25, withPad: " ", startingAt: 0))")
                }
            }
            
            // Display PySwift Binary Wheels
            print("\n🔧 PySwift Binary Wheels (pypi.anaconda.org/pyswift/simple):")
            print(String(repeating: "=", count: 71))
            if checkDeps {
                print("\("Package".padding(toLength: 20, withPad: " ", startingAt: 0)) \("Android".padding(toLength: 20, withPad: " ", startingAt: 0)) \("iOS".padding(toLength: 20, withPad: " ", startingAt: 0)) \("Deps OK".padding(toLength: 10, withPad: " ", startingAt: 0))")
            } else {
                print("\("Package".padding(toLength: 20, withPad: " ", startingAt: 0)) \("Android".padding(toLength: 25, withPad: " ", startingAt: 0)) \("iOS".padding(toLength: 25, withPad: " ", startingAt: 0))")
            }
            print(String(repeating: "-", count: 71))
            
            for package in pyswiftBinaryWheels {
                let androidStatus = formatStatus(package.android)
                let iosStatus = formatStatus(package.ios)
                
                if checkDeps {
                    if let depInfo = allPackagesWithDeps.first(where: { $0.0.name == package.name }) {
                        let depsOK = depInfo.2 ? "✅" : "⚠️"
                        let depCount = depInfo.1.count
                        print("\(package.name.padding(toLength: 20, withPad: " ", startingAt: 0)) \(androidStatus.padding(toLength: 20, withPad: " ", startingAt: 0)) \(iosStatus.padding(toLength: 20, withPad: " ", startingAt: 0)) \(depsOK) (\(depCount))")
                    }
                } else {
                    print("\(package.name.padding(toLength: 20, withPad: " ", startingAt: 0)) \(androidStatus.padding(toLength: 25, withPad: " ", startingAt: 0)) \(iosStatus.padding(toLength: 25, withPad: " ", startingAt: 0))")
                }
            }
            
            // Display Pure Python
            print("\n🐍 Pure Python Packages:")
            print(String(repeating: "=", count: 71))
            if checkDeps {
                print("\("Package".padding(toLength: 20, withPad: " ", startingAt: 0)) \("Android".padding(toLength: 20, withPad: " ", startingAt: 0)) \("iOS".padding(toLength: 20, withPad: " ", startingAt: 0)) \("Deps OK".padding(toLength: 10, withPad: " ", startingAt: 0))")
            } else {
                print("\("Package".padding(toLength: 20, withPad: " ", startingAt: 0)) \("Android".padding(toLength: 25, withPad: " ", startingAt: 0)) \("iOS".padding(toLength: 25, withPad: " ", startingAt: 0))")
            }
            print(String(repeating: "-", count: 71))
            
            let maxPurePythonDisplay = 100
            for (index, package) in purePython.enumerated() {
                if index >= maxPurePythonDisplay {
                    let remaining = purePython.count - maxPurePythonDisplay
                    print("... +\(remaining) more")
                    break
                }
                
                let androidStatus = formatStatus(package.android)
                let iosStatus = formatStatus(package.ios)
                
                if checkDeps {
                    if let depInfo = allPackagesWithDeps.first(where: { $0.0.name == package.name }) {
                        let depsOK = depInfo.2 ? "✅" : "⚠️"
                        let depCount = depInfo.1.count
                        print("\(package.name.padding(toLength: 20, withPad: " ", startingAt: 0)) \(androidStatus.padding(toLength: 20, withPad: " ", startingAt: 0)) \(iosStatus.padding(toLength: 20, withPad: " ", startingAt: 0)) \(depsOK) (\(depCount))")
                    }
                } else {
                    print("\(package.name.padding(toLength: 20, withPad: " ", startingAt: 0)) \(androidStatus.padding(toLength: 25, withPad: " ", startingAt: 0)) \(iosStatus.padding(toLength: 25, withPad: " ", startingAt: 0))")
                }
            }
            
            // Display Binary Packages Without Mobile Support
            print("\n❌ Binary Packages Without Mobile Support:")
            print(String(repeating: "=", count: 71))
            if checkDeps {
                print("\("Package".padding(toLength: 20, withPad: " ", startingAt: 0)) \("Android".padding(toLength: 20, withPad: " ", startingAt: 0)) \("iOS".padding(toLength: 20, withPad: " ", startingAt: 0)) \("Deps OK".padding(toLength: 10, withPad: " ", startingAt: 0))")
            } else {
                print("\("Package".padding(toLength: 20, withPad: " ", startingAt: 0)) \("Android".padding(toLength: 25, withPad: " ", startingAt: 0)) \("iOS".padding(toLength: 25, withPad: " ", startingAt: 0))")
            }
            print(String(repeating: "-", count: 71))
            
            for package in binaryWithoutMobile {
                let androidStatus = formatStatus(package.android)
                let iosStatus = formatStatus(package.ios)
                
                if checkDeps {
                    if let depInfo = allPackagesWithDeps.first(where: { $0.0.name == package.name }) {
                        let depsOK = depInfo.2 ? "✅" : "⚠️"
                        let depCount = depInfo.1.count
                        print("\(package.name.padding(toLength: 20, withPad: " ", startingAt: 0)) \(androidStatus.padding(toLength: 20, withPad: " ", startingAt: 0)) \(iosStatus.padding(toLength: 20, withPad: " ", startingAt: 0)) \(depsOK) (\(depCount))")
                    }
                } else {
                    print("\(package.name.padding(toLength: 20, withPad: " ", startingAt: 0)) \(androidStatus.padding(toLength: 25, withPad: " ", startingAt: 0)) \(iosStatus.padding(toLength: 25, withPad: " ", startingAt: 0))")
                }
            }
            
            print("\n📈 Summary:")
            print("- Total packages checked: \(testPackages.count)")
            print("- Official binary wheels (PyPI): \(officialBinaryWheels.count)")
            print("- PySwift binary wheels: \(pyswiftBinaryWheels.count)")
            print("- Pure Python: \(purePython.count)")
            print("- Binary without mobile support: \(binaryWithoutMobile.count)")
            print("")
            
            let allBinaryWheels = officialBinaryWheels + pyswiftBinaryWheels
            let androidSuccess = allBinaryWheels.filter { $0.android == .success }.count
            let iosSuccess = allBinaryWheels.filter { $0.ios == .success }.count
            let bothSupported = allBinaryWheels.filter { $0.android == .success && $0.ios == .success }.count
            
            print("Binary Wheels Platform Support:")
            print("- Android support: \(androidSuccess)/\(allBinaryWheels.count)")
            print("- iOS support: \(iosSuccess)/\(allBinaryWheels.count)")
            print("- Both platforms: \(bothSupported)/\(allBinaryWheels.count)")
            
            if checkDeps {
                let allDepsOK = allPackagesWithDeps.filter { $0.2 }.count
                let totalChecked = allPackagesWithDeps.count
                print("")
                print("Dependency Status:")
                print("- All dependencies supported: \(allDepsOK)/\(totalChecked)")
                if allDepsOK < totalChecked {
                    print("- ⚠️  Some packages have unsupported dependencies")
                }
            }
            
            // Export markdown report
            try exportMarkdown(
                limit: limit,
                checkDeps: checkDeps,
                officialBinaryWheels: officialBinaryWheels,
                pyswiftBinaryWheels: pyswiftBinaryWheels,
                purePython: purePython,
                binaryWithoutMobile: binaryWithoutMobile,
                allPackagesWithDeps: allPackagesWithDeps,
                timestamp: Date()
            )
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
    
    static func formatStatus(_ status: PlatformSupport?) -> String {
        guard let status = status else {
            return "Unknown"
        }
        
        switch status {
        case .success:
            return "✅ Supported"
        case .purePython:
            return "🐍 Pure Python"
        case .warning:
            return "⚠️  Not available"
        }
    }
}
let args = ProcessInfo.processInfo.arguments

// Check for help flag
if args.contains("-h") || args.contains("--help") {
    printUsage()
    exit(0)
}

let limit: Int = if args.count > 1 {
    .init(args[1]) ?? 1000
} else {
    1000
}
let checkDeps: Bool = args.contains("--deps") || args.contains("-d")
let useSimpleIndex: Bool = args.contains("--all") || args.contains("-a")

await MobileWheelsChecker.main(limit: limit, checkDeps: checkDeps, useSimpleIndex: useSimpleIndex)
