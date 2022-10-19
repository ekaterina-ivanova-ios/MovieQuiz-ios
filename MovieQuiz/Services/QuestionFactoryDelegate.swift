
import Foundation

protocol QuestionFactoryDelegate: class {
    func didReceiveNextQuestion(question: QuizQuestion?)
    func didLoadDataFromServer()
    func didFailLoadData(with error: Error)
}
