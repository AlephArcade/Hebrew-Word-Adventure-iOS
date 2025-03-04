import Foundation
import os.log

/// Centralized logging system for the app
class Logger {
    static let shared = Logger()
    
    /// Log level to control the verbosity of logs
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
        
        var osLogType: OSLogType {
            switch self {
            case .debug:
                return .debug
            case .info:
                return .info
            case .warning:
                return .default
            case .error:
                return .error
            case .critical:
                return .fault
            }
        }
    }
    
    // MARK: - Properties
    
    private let osLog: OSLog
    private let isLoggingEnabled: Bool
    private let logToFile: Bool
    private let dateFormatter: DateFormatter
    private let fileLogger: FileLogger?
    
    /// Subsystem categories for better filtering
    struct Category {
        static let general = "General"
        static let game = "Game"
        static let audio = "Audio"
        static let data = "Data"
        static let ui = "UI"
        static let network = "Network"
    }
    
    // MARK: - Initialization
    
    private init() {
        #if DEBUG
        isLoggingEnabled = true
        #else
        isLoggingEnabled = UserDefaults.standard.bool(forKey: "logging_enabled")
        #endif
        
        logToFile = UserDefaults.standard.bool(forKey: "log_to_file")
        osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.hebrewwordadventure", category: "HebrewWordAdventure")
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Initialize file logger if needed
        fileLogger = logToFile ? FileLogger() : nil
    }
    
    // MARK: - Logging Methods
    
    /// Logs a message with the specified log level and category
    func log(_ level: LogLevel, _ message: String, category: String = Category.general, file: String = #file, function: String = #function, line: Int = #line) {
        guard isLoggingEnabled else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(level.rawValue)][\(category)] \(message) (\(fileName):\(line) \(function))"
        
        // Log to console using OSLog
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
        
        // Log to file if enabled
        if logToFile, let fileLogger = fileLogger {
            let fileEntry = "\(timestamp) \(logMessage)"
            fileLogger.log(fileEntry)
        }
    }
    
    /// Logs an error with its description
    func logError(_ error: Error, category: String = Category.general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, error.localizedDescription, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - File Logging
    
    /// Helper class for logging to a file
    private class FileLogger {
        private let fileURL: URL
        private let queue = DispatchQueue(label: "com.hebrewwordadventure.filelogger")
        
        init() {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            fileURL = documentsDirectory.appendingPathComponent("HebrewWordAdventure.log")
            
            // Create log file if it doesn't exist
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                FileManager.default.createFile(atPath: fileURL.path, contents: nil)
            }
            
            // Limit log file size by trimming if needed
            trimLogFileIfNeeded()
        }
        
        /// Logs a message to the file
        func log(_ message: String) {
            queue.async { [weak self] in
                guard let self = self else { return }
                
                let logEntry = message + "\n"
                if let data = logEntry.data(using: .utf8) {
                    if let fileHandle = try? FileHandle(forWritingTo: self.fileURL) {
                        // Seek to end of file and append
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        fileHandle.closeFile()
                    }
                }
            }
        }
        
        /// Trims the log file if it exceeds 5MB
        private func trimLogFileIfNeeded() {
            queue.async { [weak self] in
                guard let self = self else { return }
                
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: self.fileURL.path)
                    if let fileSize = attributes[.size] as? UInt64, fileSize > 5 * 1024 * 1024 {
                        // File exceeds 5MB, trim it by keeping only the last 1MB
                        if let fileHandle = try? FileHandle(forReadingFrom: self.fileURL) {
                            fileHandle.seekToEndOfFile()
                            let endPosition = fileHandle.offsetInFile
                            
                            if endPosition > 1024 * 1024 {
                                fileHandle.seek(toFileOffset: endPosition - 1024 * 1024)
                                let lastPortion = fileHandle.readDataToEndOfFile()
                                fileHandle.closeFile()
                                
                                // Write the last portion to the file, overwriting it
                                try lastPortion.write(to: self.fileURL, options: .atomic)
                            }
                        }
                    }
                } catch {
                    print("Error trimming log file: \(error)")
                }
            }
        }
        
        /// Gets the contents of the log file
        func getLogContents() -> String {
            do {
                return try String(contentsOf: fileURL, encoding: .utf8)
            } catch {
                return "Error reading log file: \(error.localizedDescription)"
            }
        }
        
        /// Clears the log file
        func clearLog() {
            queue.async { [weak self] in
                guard let self = self else { return }
                
                do {
                    try "".write(to: self.fileURL, atomically: true, encoding: .utf8)
                } catch {
                    print("Error clearing log file: \(error)")
                }
            }
        }
    }
    
    /// Gets the contents of the log file
    func getLogContents() -> String {
        return fileLogger?.getLogContents() ?? "Logging to file is disabled"
    }
    
    /// Clears the log file
    func clearLog() {
        fileLogger?.clearLog()
    }
}