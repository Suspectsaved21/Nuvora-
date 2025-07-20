//
//  ChatView.swift
//  Nuvora
//
//  Real-time chat interface with Supabase integration
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var messageText = ""
    
    let roomId: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            ChatMessageRow(
                                message: message,
                                isCurrentUser: message.senderId == supabaseManager.currentUser?.id.uuidString
                            )
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    // Auto-scroll to bottom when new message arrives
                    if let lastMessage = viewModel.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Message input
            MessageInputView(
                text: $messageText,
                onSend: {
                    Task {
                        await viewModel.sendMessage(
                            content: messageText,
                            roomId: roomId,
                            realtimeService: supabaseManager.realtime
                        )
                        messageText = ""
                    }
                }
            )
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setupChat(realtimeService: supabaseManager.realtime)
        }
    }
}

struct ChatMessageRow: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text("User \(message.senderId.prefix(8))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        isCurrentUser ? Color.blue : Color.gray.opacity(0.2)
                    )
                    .foregroundColor(
                        isCurrentUser ? .white : .primary
                    )
                    .cornerRadius(16)
                
                Text(formatDate(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MessageInputView: View {
    @Binding var text: String
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $text, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(1...4)
                .onSubmit {
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSend()
                    }
                }
            
            Button(action: {
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    onSend()
                }
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.gray : Color.blue
                    )
                    .clipShape(Circle())
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    
    private var realtimeService: RealtimeService?
    
    func setupChat(realtimeService: RealtimeService?) {
        self.realtimeService = realtimeService
        
        // In a real app, you would load existing messages from the database
        // and then listen for new ones via realtime
        loadExistingMessages()
        
        // Listen for new messages via realtime
        if let service = realtimeService {
            // The RealtimeService already handles incoming messages
            // and updates its chatMessages property
            // Here you would observe those changes
        }
    }
    
    func sendMessage(content: String, roomId: String?, realtimeService: RealtimeService?) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        do {
            try await realtimeService?.sendChatMessage(content, roomId: roomId)
        } catch {
            print("Failed to send message: \(error)")
        }
    }
    
    private func loadExistingMessages() {
        // In a real app, this would fetch messages from Supabase database
        // For now, we'll add some sample messages
        messages = [
            ChatMessage(
                id: UUID(),
                content: "Welcome to the chat!",
                senderId: "system",
                roomId: nil,
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: nil
            )
        ]
    }
}

#Preview {
    NavigationView {
        ChatView(roomId: "test-room")
            .environmentObject(SupabaseManager.shared)
    }
}