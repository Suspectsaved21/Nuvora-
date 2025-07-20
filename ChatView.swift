import SwiftUI
import Supabase

struct ChatView: View {
    let roomId: String
    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    @State private var isLoading = false
    @StateObject private var realtimeService = RealtimeService.shared
    
    var body: some View {
        VStack {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding(.horizontal)
                }
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message Input
            HStack {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupChat()
        }
        .onDisappear {
            realtimeService.leaveRoom(roomId)
        }
    }
    
    private func setupChat() {
        Task {
            await loadMessages()
            await subscribeToMessages()
        }
    }
    
    private func loadMessages() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: [ChatMessage] = try await SupabaseManager.shared.client
                .from("messages")
                .select()
                .eq("room_id", value: roomId)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            await MainActor.run {
                self.messages = response
            }
        } catch {
            print("Error loading messages: \(error)")
        }
    }
    
    private func subscribeToMessages() async {
        await realtimeService.joinRoom(roomId)
        
        // Listen for new messages
        realtimeService.onMessageReceived = { message in
            Task { @MainActor in
                if !messages.contains(where: { $0.id == message.id }) {
                    messages.append(message)
                }
            }
        }
    }
    
    private func sendMessage() {
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        Task {
            do {
                let message = ChatMessage(
                    id: UUID().uuidString,
                    roomId: roomId,
                    userId: SupabaseManager.shared.currentUser?.id.uuidString ?? "unknown",
                    content: messageText,
                    createdAt: Date()
                )
                
                try await SupabaseManager.shared.client
                    .from("messages")
                    .insert(message)
                    .execute()
                
                await MainActor.run {
                    newMessage = ""
                }
            } catch {
                print("Error sending message: \(error)")
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    @State private var currentUserId = SupabaseManager.shared.currentUser?.id.uuidString ?? ""
    
    private var isCurrentUser: Bool {
        message.userId == currentUserId
    }
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.userId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .foregroundColor(isCurrentUser ? .white : .primary)
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let roomId: String
    let userId: String
    let content: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case roomId = "room_id"
        case userId = "user_id"
        case content
        case createdAt = "created_at"
    }
}

#Preview {
    NavigationView {
        ChatView(roomId: "sample-room-id")
    }
}
