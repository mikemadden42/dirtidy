import Foundation

enum FileError: Error {
    case directoryNotFound
    case fileEnumerationFailed
}

func getFileURLs(from directoryURL: URL, includeHiddenFiles: Bool = false) throws -> [URL] {
    do {
        let options: FileManager.DirectoryEnumerationOptions = includeHiddenFiles ? [] : .skipsHiddenFiles
        let fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: options)
        return fileURLs.filter { !$0.hasDirectoryPath }
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
    for (fileExtension, files) in fileGroups.sorted(by: { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }) {
        print("\n\(fileExtension):")
        for fileURL in files {
            print(fileURL.lastPathComponent)
        }
    }
}

// Check if a command-line argument for the directory path is provided
guard CommandLine.arguments.count > 1 else {
    print("Usage: \(CommandLine.arguments[0]) <directory path> [-h]")
    exit(1)
}

// Get the directory path from the command-line arguments
let directoryPath = CommandLine.arguments[1]
let includeHiddenFiles = CommandLine.arguments.contains("-h")

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
