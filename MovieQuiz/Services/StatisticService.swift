
import Foundation

protocol StatisticService {
    func store(correct count: Int, total amount: Int)
    
    var totalAccuracy: Double { get }
    var gamesCount: Int { get }
    var bestGame: GameRecord { get }
}

final class StatisticServiceImplementation: StatisticService {
    
    private enum Keys: String {
        case correct, total, bestGame, gamesCount
    }
    
    //создаем экземпляр UserDefaults
    private let userDefaults = UserDefaults.standard
    
    private(set) var totalAccuracy: Double {
        get {
            if userDefaults.object(forKey: Keys.total.rawValue) == nil {
                userDefaults.set(Double(), forKey: Keys.total.rawValue)
            }
            return userDefaults.double(forKey: Keys.total.rawValue)
        }
        set {
            userDefaults.set(newValue, forKey: Keys.total.rawValue)
        }
    }
    
    private(set) var gamesCount: Int {
        get {
          if userDefaults.object(forKey: Keys.gamesCount.rawValue) == nil {
            userDefaults.set(Int(), forKey: Keys.gamesCount.rawValue)
          }
          return userDefaults.integer(forKey: Keys.gamesCount.rawValue)
        }
        set {
          userDefaults.set(newValue, forKey: Keys.gamesCount.rawValue)
        }
    }
    
    private(set) var correctAnswersCount: Int {
        get {
            if userDefaults.object(forKey: Keys.correct.rawValue) == nil {
            userDefaults.set(Int(), forKey: Keys.correct.rawValue)
          }
          return userDefaults.integer(forKey: Keys.correct.rawValue)
        }
        set {
          userDefaults.set(newValue, forKey: Keys.correct.rawValue)
        }
    }
    
    var bestGame: GameRecord {
        get {
            guard let data = userDefaults.data(forKey: Keys.bestGame.rawValue),
            let record = try? JSONDecoder().decode(GameRecord.self, from: data) else {
                return .init(correct: 0, total: 0, date: Date())
            }
            
            return record
        }
        
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                print("Невозможно сохранить результат")
                return
            }
            
            userDefaults.set(data, forKey: Keys.bestGame.rawValue)
        }
    }
    
    func store(correct count: Int, total amount: Int) {
        gamesCount += 1
        correctAnswersCount += count
        totalAccuracy = (Double(correctAnswersCount) / Double(gamesCount * 10)) * 100
        let currentGame = GameRecord(correct: count, total: amount, date: Date())
        if bestGame <= currentGame {
            bestGame = currentGame
        }
    }
}
