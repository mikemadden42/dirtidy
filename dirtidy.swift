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

func printUsage() {
    let programName = URL(fileURLWithPath: CommandLine.arguments[0]).lastPathComponent
    print("""
    Usage: \(programName) [-a|--all] [-h|--help] [path]
      -a, --all   Include hidden files (those starting with '.')
      -h, --help  Show this help message
      path        Directory to inspect (default: current directory)
    """)
}

func printError(_ message: String) {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
}

// Parse the command-line arguments, defaulting to the current directory
var directoryPath: String?
var includeHiddenFiles = false

for argument in CommandLine.arguments.dropFirst() {
    switch argument {
    case "-a", "--all":
        includeHiddenFiles = true
    case "-h", "--help":
        printUsage()
        exit(0)
    case _ where argument.hasPrefix("-"):
        printError("Unknown option: \(argument)")
        printUsage()
        exit(2)
    case _ where directoryPath != nil:
        printError("Unexpected argument: \(argument)")
        exit(2)
    default:
        directoryPath = argument
    }
}

do {
    guard let directoryURL = URL(string: directoryPath ?? ".") else {
        throw FileError.directoryNotFound
    }

    let fileURLs = try getFileURLs(from: directoryURL, includeHiddenFiles: includeHiddenFiles)
    let fileGroups = groupFilesByExtension(fileURLs)
    let sortedFileGroups = sortFilesInGroups(fileGroups)
    printFilesByExtension(sortedFileGroups)
} catch {
    print("Error: \(error)")
}
