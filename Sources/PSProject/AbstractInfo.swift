//
//  AbstractInfo.swift
//  PSProject
//
//  Created by CodeBuilder on 13/11/2025.
//


extension PSProject.Create {
    static let abstractInfo: String = "Create iOS/macOS project"
}

extension PSProject.Create.Xcode {
    static let abstractInfo: String = "Create Xcode Project Type"
}


extension PSProject.Update {
    static let abstractInfo: String = "Update Xcode Dependecies like site-packages, local index simple ..."
}

extension PSProject.Update.App {
    static let abstractInfo: String = "update app wheel (cythonized mode only)"
}

extension PSProject.Update.Simple {
    static let abstractInfo: String = "update simple index in local wheels folder"
}

extension PSProject.Update.SitePackages {
    static let abstractInfo: String = "update site-packages in projects based on pyproject.toml"
}


extension PSProject.Init {
    static let abstractInfo: String = "create pyproject.toml project <mandatory for working with psproject>"
    
}