//
//  AppVerion.swift
//  
//
//  Created by Ido on 23/05/2023.
//

import Foundation

// See: Utils/SemVer.swift
enum PreRelease: String {
    case none = ""
    case alpha = "alpha"
    case beta = "beta"
    case RC = "RC"
}

// https://semver.org/spec/v2.0.0.html
// Swift package PackageDescription also has a Sever2 Version struct defined, but we will be using:

// Hard coded app version:
let APP_NAME_STR = Bundle.main.bundleName ?? "Bricks Server"

// String fields allow only alphanumerics and a hyphen (-)
let APP_BUILD_NR: Int = 9444
let APP_BUILD_VERSION = Semver(
    major: 0,
    minor: 1,
    patch: 0,
    //prerelease: "\(PreRelease.alpha.rawValue)",
    metadata: [String(format: "0x0x%04X", APP_BUILD_NR)]
)
