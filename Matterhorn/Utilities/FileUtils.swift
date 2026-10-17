//
//  FileUtils.swift
//  Matterhorn
//
//  Created by Emma Plante on 2026-10-17.
//

import Foundation
import System
import ZIPFoundation

final class FileUtils {
    /// Extracts the zip into a dedicated "bookdata" subfolder and returns that folder.
    static func unzip(from zipURL: URL, to destination: URL) throws -> URL {
        let fm = FileManager.default
        
        let extractDir = destination.appendingPathComponent("bookdata", isDirectory: true)
        try fm.createDirectory(at: extractDir, withIntermediateDirectories: true)
        do {
            try fm.unzipItem(at: zipURL, to: extractDir)
        } catch {
            try? fm.removeItem(at: extractDir) // only remove the half-extracted subfolder
            throw error
        }
        return extractDir
    }
}
