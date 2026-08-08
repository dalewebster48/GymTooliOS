import Foundation

struct Workout: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let exercises: [Exercise]
}
