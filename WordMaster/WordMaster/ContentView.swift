//
//  ContentView.swift
//  WordMaster
//  Created by Abinet Aniyo on 2025-03-02.
//

import SwiftUI

// MARK: - PlayerScore Model
struct PlayerScore: Codable, Hashable {
    let name: String
    let score: Int
    let date: Date
    let guesses: [String]
}

// MARK: - Leaderboard Model
class Leaderboard: ObservableObject {
    static let shared = Leaderboard()
    @Published var scores: [PlayerScore] = []

    private let storageKey = "playerScores"

    private init() {
        loadScores()
    }

    func addScore(name: String, score: Int, guesses: [String]) {
        let newEntry = PlayerScore(name: name, score: score, date: Date(), guesses: guesses)
        scores.append(newEntry)
        scores.sort { $0.score < $1.score }
        saveScores()
    }

    private func saveScores() {
        if let data = try? JSONEncoder().encode(scores) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadScores() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let savedScores = try? JSONDecoder().decode([PlayerScore].self, from: data) {
            self.scores = savedScores
        }
    }
}

// MARK: - ContentView (Dashboard)
struct ContentView: View {
    @AppStorage("difficulty") private var difficulty = "Easy"
    @State private var playerName = ""
    @State private var score = 0
    @State private var showNamePrompt = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("WordMaster")
                    .font(.largeTitle)
                    .bold()

                Label("Abinet Aniyo, 101228708", systemImage: "person.fill")

                Text("Level: \(difficulty)")
                    .font(.subheadline)

                Text("Player: \(playerName.isEmpty ? "Not set" : playerName)")
                    .font(.headline)

                Text("Score: \(score)")
                    .font(.headline)

                Button("Start Game") {
                    showNamePrompt = true
                }
                .menuButtonStyle(background: .blue)
                .sheet(isPresented: $showNamePrompt) {
                    NameInputView(playerName: $playerName, onContinue: {
                        showNamePrompt = false
                    })
                }

                NavigationLink(destination: GameView(level: difficultyLevel, playerName: playerName, score: $score)) {
                    Text("Play Now")
                        .menuButtonStyle(background: .green)
                }
                .disabled(playerName.isEmpty)

                NavigationLink(destination: LeaderboardView()) {
                    Text("Leaderboard")
                        .menuButtonStyle(background: .purple)
                }

                NavigationLink(destination: SettingsView()) {
                    Text("Settings")
                        .menuButtonStyle(background: .gray)
                }
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }

    private var difficultyLevel: Int {
        switch difficulty {
        case "Easy": return 1
        case "Medium": return 2
        case "Hard": return 3
        default: return 1
        }
    }
}

// MARK: - Name Input View
struct NameInputView: View {
    @Binding var playerName: String
    var onContinue: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter Your Name")
                    .font(.title)

                TextField("Your name", text: $playerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Continue") {
                    onContinue()
                }
                .menuButtonStyle(background: .blue)
            }
            .padding()
            .navigationTitle("Player Info")
        }
    }
}

// MARK: - Game View
struct GameView: View {
    let level: Int
    let playerName: String
    @Binding var score: Int

    private var wordList: [String] {
        switch level {
        case 1: return ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"]
        case 2: return ["APPLE", "MANGO", "GRAPE", "LEMON", "GUAVA"]
        case 3: return ["HONDA", "TOYOTA", "AUDI", "TESLA", "NISSAN"]
        default: return ["APPLE"]
        }
    }

    @State private var guessedWord = ""
    @State private var attempts = 0
    @State private var showResult = false
    @State private var resultMessage = ""
    @State private var guesses: [String] = []

    var body: some View {
        VStack(spacing: 20) {
            Text("Guess the word!")
                .font(.title2)

            Text("Level: \(levelName)")
            TextField("Enter your guess", text: $guessedWord)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)
                .padding()

            Button("Submit Guess") {
                checkGuess()
            }
            .menuButtonStyle(background: .blue)

            Text("Attempts: \(attempts)")
                .font(.subheadline)

            if showResult {
                Text(resultMessage)
                    .font(.headline)
                    .foregroundColor(resultMessage == "Good job!" ? .green : .red)
            }
        }
        .padding()
        .navigationTitle("Game - \(playerName)")
    }

    private var levelName: String {
        switch level {
        case 1: return "Weekdays"
        case 2: return "Fruits"
        case 3: return "Car Brands"
        default: return ""
        }
    }

    private func checkGuess() {
        let cleanGuess = guessedWord.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guesses.append(cleanGuess)
        attempts += 1

        if wordList.contains(where: { $0.uppercased().trimmingCharacters(in: .whitespacesAndNewlines) == cleanGuess }) {
            resultMessage = "Good job!"
            showResult = true
            score += 1
            Leaderboard.shared.addScore(name: playerName, score: attempts, guesses: guesses)
        } else {
            resultMessage = "Try again!"
            showResult = true
        }
    }
}

// MARK: - Leaderboard View
struct LeaderboardView: View {
    @ObservedObject var leaderboard = Leaderboard.shared

    var body: some View {
        VStack {
            Text("Leaderboard")
                .font(.title)
                .padding()

            List(leaderboard.scores, id: \ .self) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Player: \(entry.name)")
                        .font(.headline)
                    Text("Score: \(entry.score) attempts")
                    Text("Guesses: \(entry.guesses.joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text("Date: \(entry.date.formatted(date: .numeric, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Leaderboard")
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @AppStorage("difficulty") private var difficulty = "Easy"

    var body: some View {
        Form {
            Section(header: Text("Select Level")) {
                Picker("Difficulty", selection: $difficulty) {
                    Text("Easy (Weekdays)").tag("Easy")
                    Text("Medium (Fruits)").tag("Medium")
                    Text("Hard (Car Brands)").tag("Hard")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Reusable Button Style
extension View {
    func menuButtonStyle(background: Color) -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity)
            .background(background)
            .foregroundColor(.white)
            .cornerRadius(10)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}

