import SwiftUI

struct CreateRoomDialog: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: RoomViewModel

    @State private var roomName: String = ""
    @State private var isPrivate: Bool = false
    @State private var maxParticipants: Int = 8
    @State private var selectedMood: RoomMood = .chill

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Start Your Party! 🎉")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.clear)
                    .overlay(
                        Theme.gradientParty
                            .mask(
                                Text("Start Your Party! 🎉")
                                    .font(.title)
                                    .fontWeight(.bold)
                            )
                    )

                // Room Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Room Name")
                        .foregroundColor(Theme.foreground)
                    TextField("Friday Night Hangout", text: $roomName)
                        .padding()
                        .background(Theme.secondary.opacity(0.5))
                        .cornerRadius(12)
                        .foregroundColor(Theme.foreground)
                }

                // Max Participants
                VStack(alignment: .leading, spacing: 8) {
                    Text("Max Participants")
                        .foregroundColor(Theme.foreground)
                    TextField("8", value: $maxParticipants, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Theme.secondary.opacity(0.5))
                        .cornerRadius(12)
                        .foregroundColor(Theme.foreground)
                }

                // Mood Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Room Mood")
                        .foregroundColor(Theme.foreground)
                    Picker("Mood", selection: $selectedMood) {
                        ForEach(RoomMood.allCases, id: \.self) { mood in
                            Text(mood.rawValue.capitalized).tag(mood)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                // Private Toggle
                Toggle(isOn: $isPrivate) {
                    Text("Private Room")
                        .foregroundColor(Theme.foreground)
                }
                .toggleStyle(SwitchToggleStyle(tint: Theme.partyPurple))

                Spacer()

                PartyButton(
                    title: "Create Room",
                    variant: .primary,
                    size: .large,
                    action: handleCreate,
                    disabled: roomName.trimmingCharacters(in: .whitespaces).isEmpty
                )
            }
            .padding()
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            })
        }
    }

    private func handleCreate() {
        let name = roomName.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty {
            viewModel.createRoom(
                name: name,
                maxParticipants: maxParticipants,
                isPrivate: isPrivate,
                mood: selectedMood
            )

            // Reset form
            roomName = ""
            isPrivate = false
            maxParticipants = 8
            selectedMood = .chill
            isPresented = false
        }
    }
}

