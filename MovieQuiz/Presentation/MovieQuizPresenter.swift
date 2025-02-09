import Foundation
import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    private var currentQuestion: QuizQuestion?
    weak var viewControllerProtocol: MovieQuizViewControllerProtocol?
    private var correctAnswerCounter: Int = 0
    private var questionFactory: QuestionFactoryProtocol?
    private var statisticService: StatisticService?
    private var activityIndicator: UIActivityIndicatorView!
    var alertPresenter: AlertProtocol?
    
    init(viewController: MovieQuizViewControllerProtocol) {
        self.viewControllerProtocol = viewController
        questionFactory = QuestionFactory(delegate: self, moviesLoader: MoviesLoader())
        statisticService = StatisticServiceImplementation()
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
        }
    
    private func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    private func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    private func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }
    
    
    private func checkUserAnswer(userAnswer answer: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let isUserGuessed = currentQuestion.correctAnswer == answer ? true : false
        showAnswerResult(isCorrect: isUserGuessed)
    }
    
    func noButtonClicked() {
        checkUserAnswer(userAnswer: false)
    }
    
    func yesButtonClicked() {
        checkUserAnswer(userAnswer: true)
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.viewControllerProtocol?.show(quiz: viewModel)
        }
    }
  
    func showAnswerResult(isCorrect: Bool) {
        viewControllerProtocol?.enableOrDisableButtons()
        viewControllerProtocol?.highlightImageBorder(isCorrectAnswer: isCorrect)
        didAnswer(isCorrect: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else {return}
            self.showNextQuestionOrResults()
            self.viewControllerProtocol?.showResult()
        }
    }
    
    private func didAnswer(isCorrect: Bool) {
        correctAnswerCounter += 1
    }
    
    private func showNextQuestionOrResults() {
        if self.isLastQuestion(){
            statisticService?.store(correct: correctAnswerCounter, total: questionsAmount)
            
            let alertModel = AlertModel (
                title: "Этот раунд окончен!",
                message: "Ваш результат: \(correctAnswerCounter)/10\n" +
                "Количество сыграных квизов: \(statisticService?.gamesCount ?? 0)\n" +
                "Рекорд: \(statisticService?.bestGame.gameStatistic() ?? "Данные отсутствуют")\n" +
                "Средняя точность: " + String(format: "%.2f" , statisticService?.totalAccuracy ?? 0.00) + "%",
                buttonText: "Сыграть ещё раз",
                completion: { [ weak self ] _ in
                    guard let self = self else { return }
                
                    self.resetQuestionIndex()
                    self.correctAnswerCounter = 0
                    
                    self.questionFactory?.requestNextQuestion()
                })
            self.alertPresenter?.show(alertModel: alertModel)
        } else {
            self.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
    
    func didLoadDataFromServer() {
        viewControllerProtocol?.hideLoadingIndicator()
        questionFactory?.requestNextQuestion()
    }
    
    func didFailLoadData(with error: NetworkError) {
        switch error {
        case .networkTaskError:
            showNetworkError(error: .networkTaskError)
        case .invalidUrl:
            showNetworkError(error: .invalidUrl)
        case .codeError:
            showNetworkError(error: .codeError)
        }
    }
    
    private func showNetworkError(error: NetworkError) {
        viewControllerProtocol?.hideLoadingIndicator()
        
        switch error {
        case .codeError, .invalidUrl:
            let alertModel = AlertModel(title: "Внутренняя ошибка",
                                        message: "Пожалуйста, переустановите приложение",
                                        buttonText: "Закрыть приложение",
                                        completion: { _ in
                DispatchQueue.main.async {
                    UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                    Thread.sleep(forTimeInterval: 2)
                    exit(0)
                }
            })
            self.alertPresenter?.show(alertModel: alertModel)
        case .networkTaskError:
            let alertModel = AlertModel(title: "Нет подключения к интернету",
                                        message: "Пожалуйста, проверьте подключение к интернету",
                                        buttonText: "Попробовать еще раз",
                                        completion: { [weak self] _ in
                guard let self = self else { return }
                self.questionFactory?.loadData()
            })
            self.alertPresenter?.show(alertModel: alertModel)
        }
    }
    
} 

extension MovieQuizViewController: AlertDelegate {
    func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true)
    }
}
