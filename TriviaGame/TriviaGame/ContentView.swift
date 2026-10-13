import SwiftUI
import Combine

// MARK: - Models
struct TriviaResponse: Codable {
    let responseCode: Int
    let results: [RawTriviaQuestion]

    enum CodingKeys: String, CodingKey {
        case responseCode = "response_code"
        case results
    }
}

struct RawTriviaQuestion: Codable {
    let category: String
    let type: String
    let difficulty: String
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]

    enum CodingKeys: String, CodingKey {
        case category, type, difficulty
        case question
        case correctAnswer = "correct_answer"
        case incorrectAnswers = "incorrect_answers"
    }
}

struct TriviaQuestion: Identifiable {
    let id: UUID
    let category: String
    let type: String
    let difficulty: String
    let question: String
    let correctAnswer: String
    let answers: [String]

    init(from raw: RawTriviaQuestion) {
        self.id = UUID()
        self.category = raw.category.decodingHTMLEntities()
        self.type = raw.type
        self.difficulty = raw.difficulty
        self.question = raw.question.decodingHTMLEntities()
        self.correctAnswer = raw.correctAnswer.decodingHTMLEntities()
        let decodedIncorrect = raw.incorrectAnswers.map { $0.decodingHTMLEntities() }
        self.answers = (decodedIncorrect + [self.correctAnswer]).shuffled()
    }
}

// Lightweight HTML entity decoder
extension String {
    func decodingHTMLEntities() -> String {
        var result = self
        let entities = [
            ("&quot;", "\""),
            ("&#039;", "'"),
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&eacute;", "é"),
            ("&deg;", "°"),
            ("&shy;", ""),
            ("&hellip;", "…"),
            ("&rsquo;", "'"),
            ("&lsquo;", "'"),
            ("&ldquo;", "\""),
            ("&rdquo;", "\""),
            ("&ndash;", "–"),
            ("&mdash;", "—")
        ]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        return result
    }
}

// Custom error type for Open Trivia DB response codes
enum TriviaAPIError: LocalizedError {
    case noResults
    case invalidParameter
    case tokenNotFound
    case tokenEmpty
    case rateLimit
    case serverError

    var errorDescription: String? {
        switch self {
        case .noResults:
            return "No Results: The API doesn't have enough questions for your query."
        case .rateLimit:
            return "Rate Limit: Please wait a few seconds before trying again."
        default:
            return "Could not retrieve questions. Please change your filters."
        }
    }
}

// MARK: - API Service
class TriviaService {
    static func fetchQuestions(amount: Int, categoryId: Int?, difficulty: String, type: String) async throws -> [TriviaQuestion] {
        var components = URLComponents(string: "https://opentdb.com/api.php")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "amount", value: "\(amount)")
        ]

        if let categoryId = categoryId, categoryId != 0 {
            queryItems.append(URLQueryItem(name: "category", value: "\(categoryId)"))
        }

        if difficulty != "any" {
            queryItems.append(URLQueryItem(name: "difficulty", value: difficulty))
        }

        if type != "any" {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }

        components.queryItems = queryItems

        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw TriviaAPIError.serverError
        }

        let decoded = try JSONDecoder().decode(TriviaResponse.self, from: data)

        switch decoded.responseCode {
        case 0:
            if decoded.results.isEmpty { throw TriviaAPIError.noResults }
            return decoded.results.map { TriviaQuestion(from: $0) }
        case 1:
            throw TriviaAPIError.noResults
        case 5:
            throw TriviaAPIError.rateLimit
        default:
            throw TriviaAPIError.invalidParameter
        }
    }
}

// MARK: - Main Options Screen
struct ContentView: View {
    @State private var numberOfQuestionsText: String = "5"
    @State private var selectedCategoryId: Int = 21 // Sports
    @State private var difficultySliderValue: Double = 0.0 // 0 = Easy, 1 = Medium, 2 = Hard
    @State private var selectedType: String = "multiple"
    @State private var selectedDurationSeconds: Int = 30

    @State private var questions: [TriviaQuestion] = []
    @State private var isLoading: Bool = false
    @State private var alertMessage: String?
    @State private var showAlert: Bool = false
    @State private var navigateToGame: Bool = false

    let categories: [(name: String, id: Int)] = [
        ("Any Category", 0),
        ("Sports", 21),
        ("General Knowledge", 9),
        ("Entertainment: Books", 10),
        ("Entertainment: Film", 11),
        ("Entertainment: Music", 12),
        ("Entertainment: Musicals & Theatres", 13),
        ("Entertainment: Television", 14),
        ("Entertainment: Video Games", 15),
        ("Entertainment: Board Games", 16),
        ("Science & Nature", 17),
        ("Science: Computers", 18),
        ("Science: Mathematics", 19),
        ("Mythology", 20),
        ("Geography", 22),
        ("History", 23),
        ("Politics", 24),
        ("Art", 25),
        ("Celebrities", 26),
        ("Animals", 27),
        ("Vehicles", 28),
        ("Entertainment: Comics", 29),
        ("Science: Gadgets", 30),
        ("Entertainment: Japanese Anime & Manga", 31),
        ("Entertainment: Cartoon & Animations", 32)
    ]

    var difficultyString: String {
        let rounded = Int(difficultySliderValue.rounded())
        switch rounded {
        case 0: return "easy"
        case 1: return "medium"
        default: return "hard"
        }
    }

    var difficultyDisplayName: String {
        let rounded = Int(difficultySliderValue.rounded())
        switch rounded {
        case 0: return "Easy"
        case 1: return "Medium"
        default: return "Hard"
        }
    }

    let types = [
        ("Multiple Choice", "multiple"),
        ("True or False", "boolean"),
        ("Any Type", "any")
    ]

    let durations: [(label: String, seconds: Int)] = [
        ("30 seconds", 30),
        ("60 seconds", 60),
        ("120 seconds", 120),
        ("300 seconds", 300),
        ("1 hour", 3600)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header Bar
                    VStack {
                        Text("Trivia Game")
                            .font(.title)
                            .bold()
                            .foregroundStyle(.white)
                            .padding(.top, 12)
                            .padding(.bottom, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)

                    Spacer().frame(height: 24)

                    // Options Card
                    VStack(spacing: 18) {
                        // Number of questions
                        HStack {
                            TextField("5", text: $numberOfQuestionsText)
                                .keyboardType(.numberPad)
                                .font(.body)
                        }

                        Divider()

                        // Category
                        HStack {
                            Text("Select Category")
                                .font(.body)
                            Spacer()
                            Picker("", selection: $selectedCategoryId) {
                                ForEach(categories, id: \.id) { category in
                                    Text(category.name).tag(category.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.secondary)
                        }

                        Divider()

                        // Difficulty Slider
                        HStack {
                            Text("Difficulty: \(difficultyDisplayName)")
                                .font(.body)
                            Slider(value: $difficultySliderValue, in: 0...2, step: 1.0)
                        }

                        Divider()

                        // Select Type
                        HStack {
                            Text("Select Type")
                                .font(.body)
                            Spacer()
                            Picker("", selection: $selectedType) {
                                ForEach(types, id: \.1) { t in
                                    Text(t.0).tag(t.1)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.secondary)
                        }

                        Divider()

                        // Timer Duration
                        HStack {
                            Text("Timer Duration")
                                .font(.body)
                            Spacer()
                            Picker("", selection: $selectedDurationSeconds) {
                                ForEach(durations, id: \.seconds) { dur in
                                    Text(dur.label).tag(dur.seconds)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.secondary)
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)

                    Spacer()

                    // Start Trivia Button
                    Button(action: {
                        Task { await loadAndStartGame() }
                    }) {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Start Trivia")
                                    .font(.headline)
                                    .bold()
                                    .foregroundStyle(.white)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .cornerRadius(30)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .disabled(isLoading)
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage ?? "An unknown error occurred.")
            }
            .navigationDestination(isPresented: $navigateToGame) {
                TriviaGameView(
                    questions: questions,
                    timeLimit: selectedDurationSeconds
                )
            }
        }
    }

    private func loadAndStartGame() async {
        isLoading = true

        let amount = max(1, min(Int(numberOfQuestionsText) ?? 5, 50))

        do {
            let fetched = try await TriviaService.fetchQuestions(
                amount: amount,
                categoryId: selectedCategoryId == 0 ? nil : selectedCategoryId,
                difficulty: difficultyString,
                type: selectedType
            )

            self.questions = fetched
            self.navigateToGame = true
        } catch {
            self.alertMessage = error.localizedDescription
            self.showAlert = true
        }
        isLoading = false
    }
}

// MARK: - Game View
struct TriviaGameView: View {
    @Environment(\.dismiss) private var dismiss
    let questions: [TriviaQuestion]
    let timeLimit: Int

    @State private var userAnswers: [UUID: String] = [:]
    @State private var timeRemaining: Int
    @State private var showScoreReview: Bool = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(questions: [TriviaQuestion], timeLimit: Int) {
        self.questions = questions
        self.timeLimit = timeLimit
        _timeRemaining = State(initialValue: timeLimit)
    }

    var score: Int {
        var total = 0
        for q in questions {
            if userAnswers[q.id] == q.correctAnswer {
                total += 1
            }
        }
        return total
    }

    var body: some View {
        VStack(spacing: 0) {
            // Live Countdown Header
            HStack {
                Label("Time remaining: \(timeRemaining)s", systemImage: "timer")
                    .font(.headline)
                    .foregroundStyle(timeRemaining <= 10 ? .red : .primary)

                Spacer()

                Text("Answered: \(userAnswers.count)/\(questions.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Q\(index + 1)")
                                    .font(.caption)
                                    .bold()
                                    .padding(6)
                                    .background(Color.blue.opacity(0.15))
                                    .clipShape(Circle())

                                Text(question.category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(question.difficulty.capitalized)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                            }

                            Text(question.question)
                                .font(.headline)

                            ForEach(question.answers, id: \.self) { choice in
                                let isSelected = userAnswers[question.id] == choice

                                HStack {
                                    Text(choice)
                                        .font(.body)
                                        .multilineTextAlignment(.leading)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isSelected ? .blue : .secondary)
                                        .font(.title3)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(isSelected ? Color.blue.opacity(0.12) : Color(.systemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    userAnswers[question.id] = choice
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(14)
                        .padding(.horizontal)
                    }

                    // Submit Button
                    Button {
                        showScoreReview = true
                    } label: {
                        Text("Submit Quiz")
                            .font(.headline)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Trivia Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            if !showScoreReview {
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    showScoreReview = true
                }
            }
        }
        .fullScreenCover(isPresented: $showScoreReview) {
            ScoreReviewView(
                questions: questions,
                userAnswers: userAnswers,
                score: score,
                onDismissToRoot: {
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Score & Review Screen
struct ScoreReviewView: View {
    @Environment(\.dismiss) private var dismiss
    let questions: [TriviaQuestion]
    let userAnswers: [UUID: String]
    let score: Int
    var onDismissToRoot: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Final Score Header
                VStack(spacing: 8) {
                    Text("Quiz Results")
                        .font(.title2)
                        .bold()

                    Text("\(score) / \(questions.count)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(score >= questions.count / 2 ? .green : .orange)

                    Text(score == questions.count ? "Perfect Score! 🎉" : "Good Effort!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))

                List {
                    Section(header: Text("Detailed Review")) {
                        ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                            let selected = userAnswers[question.id]
                            let isCorrect = selected == question.correctAnswer

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(isCorrect ? .green : .red)
                                        .font(.title3)

                                    Text("Q\(index + 1): \(question.question)")
                                        .font(.headline)
                                }

                                if let selected = selected {
                                    HStack {
                                        Text("Your Answer:")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(selected)
                                            .font(.caption)
                                            .bold()
                                            .foregroundStyle(isCorrect ? .green : .red)
                                    }
                                } else {
                                    Text("No answer selected (Timed Out)")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }

                                if !isCorrect {
                                    HStack {
                                        Text("Correct Answer:")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    Text(question.correctAnswer)
                                        .font(.caption)
                                        .bold()
                                        .foregroundStyle(.green)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Score & Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                        onDismissToRoot?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                            Text("Back")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
