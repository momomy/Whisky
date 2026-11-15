//
//  WhiskyWineInstaller.swift
//  WhiskyKit
//
//  This file is part of Whisky.
//
//  Whisky is free software: you can redistribute it and/or modify it under the terms
//  of the GNU General Public License as published by the Free Software Foundation,
//  either version 3 of the License, or (at your option) any later version.
//
//  Whisky is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with Whisky.
//  If not, see https://www.gnu.org/licenses/.
//

import Foundation
import SemanticVersion

public class WhiskyWineInstaller {
    /// The Whisky application folder
    public static let applicationFolder = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
        )[0].appending(path: Bundle.whiskyBundleIdentifier)

    /// The folder of all the libfrary files
    public static let libraryFolder = applicationFolder.appending(path: "Libraries")

    /// URL to the installed `wine` `bin` directory
    public static let binFolder: URL = libraryFolder.appending(path: "Wine").appending(path: "bin")

    /// Default location of the published WhiskyWine runtime (WineHQ based, built from momomy/wine `macos/`).
    /// `releases/latest/download/<asset>` always resolves to the newest GitHub release.
    public static let defaultRuntimeBaseURL = URL(string: "https://github.com/momomy/wine/releases/latest/download/")!

    /// Base URL the runtime is downloaded from.
    /// Override with the `WHISKY_WINE_BASE_URL` environment variable or the `whiskyWineBaseURL` user default
    /// (e.g. a `file://` directory holding a locally built `Libraries.tar.gz`).
    public static var runtimeBaseURL: URL {
        let override = ProcessInfo.processInfo.environment["WHISKY_WINE_BASE_URL"]
            ?? UserDefaults.standard.string(forKey: "whiskyWineBaseURL")
        if let override, var url = URL(string: override) {
            if !url.path.hasSuffix("/") { url = url.appending(path: "") }
            return url
        }
        return defaultRuntimeBaseURL
    }

    /// `Libraries.tar.gz` runtime archive
    public static var runtimeArchiveURL: URL { runtimeBaseURL.appending(path: "Libraries.tar.gz") }
    /// Version manifest published next to the archive
    public static var runtimeVersionURL: URL { runtimeBaseURL.appending(path: "WhiskyWineVersion.plist") }

    public static func isWhiskyWineInstalled() -> Bool {
        return whiskyWineVersion() != nil
            && FileManager.default.isExecutableFile(atPath: binFolder.appending(path: "wine").path)
    }

    /// Install the runtime from a `Libraries.tar.gz`.
    /// - Parameter removeArchive: delete the archive afterwards (true for downloaded temp files,
    ///   false for a user supplied local file).
    @discardableResult
    public static func install(from: URL, removeArchive: Bool = true) -> Bool {
        do {
            if !FileManager.default.fileExists(atPath: applicationFolder.path) {
                try FileManager.default.createDirectory(at: applicationFolder, withIntermediateDirectories: true)
            } else {
                // Recreate it
                try FileManager.default.removeItem(at: applicationFolder)
                try FileManager.default.createDirectory(at: applicationFolder, withIntermediateDirectories: true)
            }

            try Tar.untar(tarBall: from, toURL: applicationFolder)
            if removeArchive {
                try FileManager.default.removeItem(at: from)
            }
            return isWhiskyWineInstalled()
        } catch {
            print("Failed to install WhiskyWine: \(error)")
            return false
        }
    }

    public static func uninstall() {
        do {
            try FileManager.default.removeItem(at: libraryFolder)
        } catch {
            print("Failed to uninstall WhiskyWine: \(error)")
        }
    }

    /// Fetch the version of the published runtime, if reachable.
    public static func remoteWhiskyWineVersion() async -> SemanticVersion? {
        let request = URLRequest(url: runtimeVersionURL, cachePolicy: .reloadIgnoringLocalCacheData,
                                 timeoutInterval: 15)
        do {
            let (data, _) = try await URLSession(configuration: .ephemeral).data(for: request)
            return try PropertyListDecoder().decode(WhiskyWineVersion.self, from: data).version
        } catch {
            print("Failed to fetch WhiskyWine version: \(error)")
            return nil
        }
    }

    public static func shouldUpdateWhiskyWine() async -> (Bool, SemanticVersion) {
        if let localVersion = whiskyWineVersion(),
           let remoteVersion = await remoteWhiskyWineVersion(),
           localVersion < remoteVersion {
            return (true, remoteVersion)
        }
        return (false, SemanticVersion(0, 0, 0))
    }

    public static func whiskyWineVersion() -> SemanticVersion? {
        do {
            let versionPlist = libraryFolder
                .appending(path: "WhiskyWineVersion")
                .appendingPathExtension("plist")

            let decoder = PropertyListDecoder()
            let data = try Data(contentsOf: versionPlist)
            let info = try decoder.decode(WhiskyWineVersion.self, from: data)
            return info.version
        } catch {
            print(error)
            return nil
        }
    }
}

struct WhiskyWineVersion: Codable {
    var version: SemanticVersion = SemanticVersion(1, 0, 0)
}
