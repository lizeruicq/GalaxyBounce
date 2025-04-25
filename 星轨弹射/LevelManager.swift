import Foundation

class LevelManager {
    static let shared = LevelManager()
    private let levelKey = "currentLevel"
    
    private init() {}
    
    func saveLevel(_ level: Int) {
        UserDefaults.standard.set(level, forKey: levelKey)
    }
    
    func getCurrentLevel() -> Int {
        return UserDefaults.standard.integer(forKey: levelKey)
    }
    
    func resetLevel() {
        saveLevel(1)
    }
} 