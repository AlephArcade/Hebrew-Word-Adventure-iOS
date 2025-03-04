import Foundation
import SwiftUI

/// Centralized error handling for the app
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    // MARK: - Published properties
    @Published var currentError: AppError? = nil
    @Published var showingError: Bool = false
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Error handling
    
    /// Handles an error by logging it and showing it to the user if needed
    func handle(_ error: Error, showToUser: Bool = true) {
        // Log the error
        Logger.shared.logError(error)
        
        // Create an AppError if it's not already one
        let appError: AppError
        if let error = error as? AppError {
            appError = error
        } else {
            appError = AppError.system(error)
        }
        
        // Update the current error
        self.currentError = appError
        
        // Show to user if requested
        if showToUser {
            self.showingError = true
        }
    }
    
    /// Handles an error with a specific message
    func handleWithMessage(_ message: String, detail: String? = nil, showToUser: Bool = true) {
        let error = AppError.custom(message: message, detail: detail)
        handle(error, showToUser: showToUser)
    }
    
    /// Clears the current error
    func clearError() {
        currentError = nil
        showingError = false
    }
}

// MARK: - Custom Error Types

/// App-specific error type for better error handling
enum AppError: Error, Identifiable {
    case custom(message: String, detail: String? = nil)
    case system(Error)
    case network(String)
    case data(String)
    case game(String)
    
    var id: String {
        switch self {
        case .custom(let message, _):
            return "custom_\(message)"
        case .system(let error):
            return "system_\(error.localizedDescription)"
        case .network(let message):
            return "network_\(message)"
        case .data(let message):
            return "data_\(message)"
        case .game(let message):
            return "game_\(message)"
        }
    }
    
    var title: String {
        switch self {
        case .custom:
            return "Error"
        case .system:
            return "System Error"
        case .network:
            return "Network Error"
        case .data:
            return "Data Error"
        case .game:
            return "Game Error"
        }
    }
    
    var message: String {
        switch self {
        case .custom(let message, _):
            return message
        case .system(let error):
            return error.localizedDescription
        case .network(let message):
            return message
        case .data(let message):
            return message
        case .game(let message):
            return message
        }
    }
    
    var detail: String? {
        switch self {
        case .custom(_, let detail):
            return detail
        default:
            return nil
        }
    }
}

// MARK: - SwiftUI Components

/// View modifier to add error handling to any view
struct ErrorHandlingModifier: ViewModifier {
    @ObservedObject var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: $errorHandler.showingError) {
                if let error = errorHandler.currentError {
                    return Alert(
                        title: Text(error.title),
                        message: Text(error.detail ?? error.message),
                        dismissButton: .default(Text("OK")) {
                            errorHandler.clearError()
                        }
                    )
                } else {
                    return Alert(
                        title: Text("Error"),
                        message: Text("An unknown error occurred"),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
    }
}

// Extension to make it easier to use the error handling modifier
extension View {
    func withErrorHandling() -> some View {
        self.modifier(ErrorHandlingModifier())
    }
}

// MARK: - Result Extension

extension Result {
    /// Handles the result by returning success value or handling the error
    func handleResult(showError: Bool = true) -> Success? {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            ErrorHandler.shared.handle(error, showToUser: showError)
            return nil
        }
    }
}

// MARK: - Convenience functions

/// Try to execute a throwing function and handle any errors
func tryOrHandle<T>(_ operation: () throws -> T, showError: Bool = true) -> T? {
    do {
        return try operation()
    } catch {
        ErrorHandler.shared.handle(error, showToUser: showError)
        return nil
    }
}

/// Try to execute an asynchronous throwing function and handle any errors
func tryOrHandleAsync<T>(_ operation: () async throws -> T, showError: Bool = true) async -> T? {
    do {
        return try await operation()
    } catch {
        DispatchQueue.main.async {
            ErrorHandler.shared.handle(error, showToUser: showError)
        }
        return nil
    }
}
