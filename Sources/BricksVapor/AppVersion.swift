//
//  AppVerion.swift
//  
//
// Created by Ido for bricks on 17/1/2024
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
let APP_BUILD_NR: Int = 0
let APP_BUILD_VERSION = Semver(
    major: 0,
    minor: 2,
    patch: 0,
    //prerelease: "\(PreRelease.alpha.rawValue)",
    metadata: [String(format: "0x0x%04X", APP_BUILD_NR)]
)
