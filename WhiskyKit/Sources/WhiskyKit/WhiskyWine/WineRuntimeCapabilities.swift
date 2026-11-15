//
//  WineRuntimeCapabilities.swift
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

/// What the installed WhiskyWine runtime can actually do.
///
/// The original runtime was CrossOver 22 + GPTK (D3DMetal, ESync/MSync). The current runtime is
/// upstream WineHQ, which has neither; the UI hides settings that would silently do nothing.
public enum WineRuntimeCapabilities {
    /// D3DMetal (Apple GPTK) is packaged into the runtime.
    public static var d3dMetal: Bool {
        FileManager.default.fileExists(
            atPath: WhiskyWineInstaller.libraryFolder
                .appending(path: "Wine/lib/external/D3DMetal.framework").path(percentEncoded: false)
        )
    }

    /// ESync/MSync patches are present (CrossOver / wine-staging builds only).
    public static var enhancedSync: Bool {
        FileManager.default.fileExists(
            atPath: WhiskyWineInstaller.libraryFolder
                .appending(path: "Wine/share/wine/enhanced-sync").path(percentEncoded: false)
        )
    }
}
