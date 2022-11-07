import Foundation
import UIKit

final class MovieQuizPresenter: QuestionFactoryDelegate {
    let questionsAmount: Int = 10
    private var currentQuestionIndex: Int = 0
    var currentQuestion: QuizQuestion?
    weak var viewController: MovieQuizViewController?
    var correctAnswerCounter: Int = 0
    var questionFactory: QuestionFactoryProtocol?
    var statisticService: StatisticService?
    var activityIndicator: UIActivityIndicatorView!
    
    init(viewController: MovieQuizViewController) {
        self.viewController = viewController
        questionFactory = QuestionFactory(delegate: self, moviesLoader: MoviesLoader())
        statisticService = StatisticServiceImplementation()
        questionFactory?.loadData()
        showLoadingIndicator()
        }
    
    func isLastQuestion() -> Bool {
        currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func switchToNextQuestion() {
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
        self.viewController?.showAnswerResult(isCorrect: isUserGuessed)
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
            self?.viewController?.show(quiz: viewModel)
        }
    }
  
    func showNextQuestionOrResults() {
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
            self.viewController?.alertPresenter?.show(alertModel: alertModel)
        } else {
            self.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
    
    func didLoadDataFromServer() {
        guard let activityIndicator = self.viewController?.activityIndicator else {return}
        activityIndicator.isHidden = true
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
        default:
            "error"
        }
    }
    


    func showLoadingIndicator() {
        guard let activityIndicator = self.viewController?.activityIndicator else {return}
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        guard let activityIndicator = self.viewController?.activityIndicator else {return}
        activityIndicator.isHidden = true
    }
    
    func showNetworkError(error: NetworkError) {
        hideLoadingIndicator()
        
        switch error {
        case .codeError, .invalidUrl, .test:
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
            self.viewController?.alertPresenter?.show(alertModel: alertModel)
        case .networkTaskError:
            let alertModel = AlertModel(title: "Нет подключения к интернету",
                                        message: "Пожалуйста, проверьте подключение к интернету",
                                        buttonText: "Попробовать еще раз",
                                        completion: { [weak self] _ in
                guard let self = self else { return }
                self.questionFactory?.loadData()
            })
            self.viewController?.alertPresenter?.show(alertModel: alertModel)
        }
    }
    
} 
