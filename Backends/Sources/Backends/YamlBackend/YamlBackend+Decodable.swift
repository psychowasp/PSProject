//
//  YamlBackend+Decodable.swift
//  Backends
//
import Foundation
import ProjectSpec

extension SwiftPackage.VersionRequirement {
    enum RangeCodingKeys: CodingKey {
        case minimumVersion
        case maximumVersion
    }
    init(container: KeyedDecodingContainer<SwiftPackage.CodingKeys>) throws {
        
        if container.contains(.revision) {
            self = .revision(try container.decode(String.self, forKey: .revision))
        } else if container.contains(.branch) {
            self = .branch(try container.decode(String.self, forKey: .branch))
        } else if container.contains(.exactVersion) {
            self = .exact(try container.decode(String.self, forKey: .exactVersion))
        } else if container.contains(.versionRange) {
            let range_c = try container.nestedContainer(keyedBy: RangeCodingKeys.self, forKey: .versionRange)
            self = .range(
                from: try range_c.decode(String.self, forKey: .minimumVersion),
                to: try range_c.decode(String.self, forKey: .maximumVersion)
            )
        } else if container.contains(.upToNextMinorVersion) {
            self = .upToNextMinorVersion(try container.decode(String.self, forKey: .upToNextMinorVersion))
        } else if container.contains(.upToNextMajorVersion) {
            self = .upToNextMajorVersion(try container.decode(String.self, forKey: .upToNextMajorVersion))
        } else {
            fatalError()
        }
        
        
    }
}

extension SwiftPackage: Swift.Decodable {
    
    enum CodingKeys: CodingKey {
        case path
        case group
        case excludeFromProject
        case url
        
        case revision
        case branch
        case exactVersion
        case versionRange
        case upToNextMinorVersion
        case upToNextMajorVersion
    }
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let group = try c.decodeIfPresent(String.self, forKey: .group)
        let excludeFromProject = try c.decodeIfPresent(Bool.self, forKey: .excludeFromProject) ?? false
        if c.contains(.path) {
            self = .local(
                path: try c.decode(String.self, forKey: .path),
                group: group,
                excludeFromProject: excludeFromProject
            )
        } else if c.contains(.url) {
            let version: VersionRequirement = try .init(container: c)
            self = .remote(
                url: try c.decode(String.self, forKey: .url),
                versionRequirement: version
            )
        } else {
            fatalError()
        }
    }
    
}

extension Dependency.PlatformFilter: Swift.Decodable {
    public init(from decoder: any Decoder) throws {
        let c = try decoder.singleValueContainer()
        let string = try c.decode(String.self)
        guard let new = Self(rawValue: string) else {
            throw DecodingError.typeMismatch(
                SupportedDestination.self,
                .init(codingPath: c.codingPath, debugDescription: """
                    wrong filter entry: \(string)
                    supported value is:
                    
                    \(Self.all)
                    \(Self.iOS)
                    \(Self.macOS)
                    """)
            )
        }
        self = new
        
    }
}

extension SupportedDestination: Swift.Decodable {
    public init(from decoder: any Decoder) throws {
        let c = try decoder.singleValueContainer()
        let string = try c.decode(String.self)
        print(Self.self, string)
        guard let new = Self(rawValue: string) else {
            throw DecodingError.typeMismatch(
                SupportedDestination.self,
                .init(codingPath: c.codingPath, debugDescription: """
                    wrong filter entry: \(string)
                    supported value is:
                    
                    \(SupportedDestination.allCases.map(\.rawValue))
                    """)
            )
        }
        self = new
    }
}

extension Dependency: Swift.Decodable {
    
    enum CodingKeys: CodingKey {
        case type
        case reference
        //        case target
        //        case framework
        //        case carthage
        //        case root
        //        case package
        case products
        case embed
        //        case codeSign
        //        case link
        //        case removeHeaders
        //        case implicit
        //        case weak
        case platformFilter
        //        case destinationFilters
        //        case platforms
        //        case copy
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let ref = try container.decode(String.self, forKey: .reference)
        let emb = try container.decodeIfPresent(Bool.self, forKey: .embed) ?? true
        let platformFilter = try container.decodeIfPresent(PlatformFilter.self, forKey: .platformFilter) ?? .all
        switch try container.decode(String.self, forKey: .type) {
            case "framework":
                self.init(
                    type: .framework,
                    reference: ref,
                    embed: emb,
                    platformFilter: platformFilter
                )
            case "package":
                let products = try container.decodeIfPresent([String].self, forKey: .products) ?? []
                self.init(
                    type: .package(products: products),
                    reference: ref,
                    platformFilter: platformFilter
                )
            default: fatalError(container.allKeys.description)
        }
    }
}

