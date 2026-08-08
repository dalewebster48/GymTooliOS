import Foundation

struct Workout: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let exercises: [Exercise]
}
