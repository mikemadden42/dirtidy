import Foundation

enum FileError: Error, CustomStringConvertible {
    case pathNotFound(String)
    case notADirectory(String)
    case readFailed(String)

    var description: String {
        switch self {
        case let .pathNotFound(path):
            "Error: path does not exist: \(path)"
        case let .notADirectory(path):
            "Error: not a directory: \(path)"
        case let .readFailed(reason):
            "Error reading directory: \(reason)"
        }
    }
}

func getFileURLs(atPath directoryPath: String, includeHiddenFiles: Bool = false) throws -> [URL] {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: directoryPath, isDirectory: &isDirectory) else {
        throw FileError.pathNotFound(directoryPath)
    }
    guard isDirectory.boolValue else {
        throw FileError.notADirectory(directoryPath)
    }

    let directoryURL = URL(fileURLWithPath: directoryPath, isDirectory: true)
    let options: FileManager.DirectoryEnumerationOptions = includeHiddenFiles ? [] : .skipsHiddenFiles
    let fileURLs: [URL]
    do {
        fileURLs = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil, options: options)
    } catch {
        throw FileError.readFailed(error.localizedDescription)
    }

    // Resolve symlinks so links to directories are skipped like directories
    return fileURLs.filter { fileURL in
        let resourceValues = try? fileURL.resolvingSymlinksInPath().resourceValues(forKeys: [.isDirectoryKey])
        return resourceValues?.isDirectory != true
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
    let fileURLs = try getFileURLs(atPath: directoryPath ?? ".", includeHiddenFiles: includeHiddenFiles)
    let fileGroups = groupFilesByExtension(fileURLs)
    let sortedFileGroups = sortFilesInGroups(fileGroups)
    printFilesByExtension(sortedFileGroups)
} catch {
    printError("\(error)")
    exit(1)
}
