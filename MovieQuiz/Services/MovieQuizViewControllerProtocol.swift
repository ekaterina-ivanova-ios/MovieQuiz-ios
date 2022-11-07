import Foundation

protocol MovieQuizViewControllerProtocol: AnyObject {
    func show(quiz step: QuizStepViewModel)
    func highlightImageBorder(isCorrectAnswer: Bool)
    func enableOrDisableButtons()
    func showResult()
    func showLoadingIndicator()
    func hideLoadingIndicator()
} 
