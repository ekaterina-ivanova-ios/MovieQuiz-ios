
import UIKit

final class MovieQuizViewController: UIViewController {

    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var questionLabel: UILabel!
    @IBOutlet private var buttons: [UIButton]!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    private var alertPresenter: AlertProtocol?
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var statisticService: StatisticService?
    private var correctAnswerCounter: Int = 0
    //mvc
    //private var currentQuestionIndex: Int = 0
    //private let questionsAmount: Int = 10
    //mvp
    private let presenter = MovieQuizPresenter()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.viewController = self
        
        alertPresenter = AlertPresenter(delegate: self)
        questionFactory = QuestionFactory(delegate: self, moviesLoader: MoviesLoader())
        statisticService = StatisticServiceImplementation()
        
        questionFactory?.loadData()
        showLoadingIndicator()
    }

    //mvc
    /*
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            //image: UIImage(named: model.image) ?? UIImage(),
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    */
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        questionLabel.text = step.question
        counterLabel.text = step.questionNumber
        
    }

    func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswerCounter += 1
            imageView.layer.borderWidth = 8
            imageView.layer.borderColor = UIColor.ypGreen.cgColor
        } else {
            correctAnswerCounter += 0
            imageView.layer.borderWidth = 8
            imageView.layer.borderColor = UIColor.ypRed.cgColor
        }
        enableOrDisableButtons()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else {return}
            self.showNextQuestionOrResults()
            self.imageView.layer.borderWidth = 0
            self.enableOrDisableButtons()
        }
    }
    
    
    private func showNextQuestionOrResults() {
        //mvc
        //if currentQuestionIndex == questionsAmount - 1
        //mvp
        if presenter.isLastQuestion(){
            statisticService?.store(correct: correctAnswerCounter, total: presenter.questionsAmount)
            
            let alertModel = AlertModel (
                title: "Этот раунд окончен!",
                message: "Ваш результат: \(correctAnswerCounter)/10\n" +
                "Количество сыграных квизов: \(statisticService?.gamesCount ?? 0)\n" +
                "Рекорд: \(statisticService?.bestGame.gameStatistic() ?? "Данные отсутствуют")\n" +
                "Средняя точность: " + String(format: "%.2f" , statisticService?.totalAccuracy ?? 0.00) + "%",
                buttonText: "Сыграть ещё раз",
                completion: { [ weak self ] _ in
                    guard let self = self else { return }
                
                    //mvc
                    //self.currentQuestionIndex = 0
                    //mvp
                    self.presenter.resetQuestionIndex()
                    self.correctAnswerCounter = 0
                    
                    self.questionFactory?.requestNextQuestion()
                })
            alertPresenter?.show(alertModel: alertModel)
        } else {
            presenter.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
    
    
    private func enableOrDisableButtons() {
        for button in buttons {
            button.isEnabled.toggle()
        }
    }
 
    //перенесено в презентер
    /*
    private func checkUserAnswer(userAnswer answer: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let isUserGuessed = currentQuestion.correctAnswer == answer ? true : false
        showAnswerResult(isCorrect: isUserGuessed)
    }
    */
    
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.currentQuestion = currentQuestion
        presenter.noButtonClicked()
       
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.currentQuestion = currentQuestion
        presenter.yesButtonClicked()
    }
    
}

// MARK: - QuestionDelegate

extension MovieQuizViewController: QuestionFactoryDelegate {

    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        //mvc
        //let viewModel = convert(model: question)
        //mvp
        let viewModel = presenter.convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
}


// MARK: - AlertDelegate

extension MovieQuizViewController: AlertDelegate {
    func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true)
    }
}

//MARK: - ActivityIndicator func

extension MovieQuizViewController {
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
    }
}

//MARK: - create error allert
extension MovieQuizViewController {
    private func showNetworkError(error: NetworkError) {
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
            alertPresenter?.show(alertModel: alertModel)
        case .networkTaskError:
            let alertModel = AlertModel(title: "Нет подключения к интернету",
                                        message: "Пожалуйста, проверьте подключение к интернету",
                                        buttonText: "Попробовать еще раз",
                                        completion: { [weak self] _ in
                guard let self = self else { return }
                self.questionFactory?.loadData()
            })
            alertPresenter?.show(alertModel: alertModel)
        }
    }
}

//MARK: - Add loading data from server

extension MovieQuizViewController {
    func didLoadDataFromServer() {
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
}
