import Foundation

// ChatService is now superseded by WebSocketService.
// This file is kept as a namespace for any future REST-only chat utilities.
//
// For chat history:   WebSocketService.shared.fetchStudentChatHistory(counselorId:)
// For sending msgs:   WebSocketService.shared.sendMessage(to:content:)
// For GPT:            WebSocketService.shared.sendGPTMessage(content:)
