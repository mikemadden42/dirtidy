import Foundation

enum FileError: Error {
    case directoryNotFound
    case fileEnumerationFailed
}

func getFileURLs(from directoryURL: URL, includeHiddenFiles: Bool = false) throws -> [URL] {
    do {
        let options: FileManager.DirectoryEnumerationOptions = includeHiddenFiles ? [] : .skipsHiddenFiles
        let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: options)
        // Resolve symlinks so links to directories are skipped like directories
        return fileURLs.filter { fileURL in
            let resourceValues = try? fileURL.resolvingSymlinksInPath().resourceValues(forKeys: [.isDirectoryKey])
            return resourceValues?.isDirectory != true
        }
    } catch {
        throw FileError.directoryNotFound
    }
}

func groupFilesByExtension(_ fileURLs: [URL]) -> [String: [URL]] {
    var fileGroups: [String: [URL]] = [:]

    for fileURL in fileURLs {
        let fileExtension = fileURL.pathExtension
        fileGroups[fileExtension, default: []].append(fileURL)
    }

    return fileGroups
}

func sortFilesInGroups(_ fileGroups: [String: [URL]]) -> [String: [URL]] {
    fileGroups.mapValues { $0.sorted { $0.lastPathComponent < $1.lastPathComponent } }
}

func printFilesByExtension(_ fileGroups: [String: [URL]]) {
    // Files without an extension are listed first, then extensions alphabetically
    let sortedGroups = fileGroups.sorted { lhs, rhs in
        if lhs.key.isEmpty != rhs.key.isEmpty {
            return lhs.key.isEmpty
        }
        return lhs.key.localizedCaseInsensitiveCompare(rhs.key) == .orderedAscending
    }

    for (fileExtension, files) in sortedGroups {
        print("\(fileExtension.isEmpty ? "No Extension" : fileExtension):")
        for fileURL in files {
            print("- \(fileURL.lastPathComponent)")
        }
        print()
    }
}

// Get the directory path from the command-line arguments, defaulting to the current directory
let arguments = CommandLine.arguments.dropFirst()
let directoryPath = arguments.first { $0 != "-h" } ?? "."
let includeHiddenFiles = arguments.contains("-h")

do {
    guard let directoryURL = URL(string: directoryPath) else {
        throw FileError.directoryNotFound
    }

    let fileURLs = try getFileURLs(from: directoryURL, includeHiddenFiles: includeHiddenFiles)
    let fileGroups = groupFilesByExtension(fileURLs)
    let sortedFileGroups = sortFilesInGroups(fileGroups)
    printFilesByExtension(sortedFileGroups)
} catch {
    print("Error: \(error)")
}
