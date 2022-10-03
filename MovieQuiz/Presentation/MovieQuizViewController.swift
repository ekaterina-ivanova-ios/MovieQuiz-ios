import UIKit

final class MovieQuizViewController: UIViewController {
    
    //связка ui элементов с кодом
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var questionLabel: UILabel!
    
    //переменная для отображения номера вопроса
    private var currentQuestionIndex: Int = 0
    //переменная для запоминания верных ответов
    private var correctAnswerCounter: Int = 0
    
    //общее кол-во вопросов для квиза
    private let questionsAmount: Int = 10
    //фабрика вопросов
    private let questionFactory: QuestionFactory = QuestionFactory()
    //текущий вопрос
    private var currentQuestion: QuizQuestion?
    
    //настройка отображения статус бара
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        show(quiz: convert(model: questions[currentQuestionIndex]))
    }
    
    //функция для конвертации QuizQuestion -> QuizStepViewModel
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    //функция для отображения элемента квиза
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        questionLabel.text = step.question
        counterLabel.text = step.questionNumber
        
    }

    //функция для отображения алерта с результатами квиза
    private func show(quiz result: QuizResultsViewModel) {
        //создание алерта
        let resultAlert = UIAlertController(
            title: result.title,
            message: result.text,
            preferredStyle: .alert)
        
        //добавление кнопки для алерта
        let resultButtonAction = UIAlertAction(title: result.buttonText, style: .default) { [weak self] _ in
            guard let self = self else {return}
            self.currentQuestionIndex = 0
            self.correctAnswerCounter = 0
            
            if let firstQuestion = self.questionFactory.requestNextQuestion() {
                self.currentQuestion = firstQuestion
                let viewModel = self.convert(model: firstQuestion)
                self.show(quiz: viewModel)
            }
            
            //let firstQuestion = self.questions[self.currentQuestionIndex]
            //let viewModel = self.convert(model: firstQuestion)
            //self.show(quiz: viewModel)
        }
        
        //добавление кнопки на алерт
        resultAlert.addAction(resultButtonAction)
        
        //настройка отображения алерта
        self.present(resultAlert, animated: true, completion: nil)
    }
    
    //функция, описывающая логику подсчета результатов
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswerCounter += 1
            imageView.layer.borderWidth = 8
            imageView.layer.borderColor = UIColor.ypGreen.cgColor
        } else {
            correctAnswerCounter += 0
            imageView.layer.borderWidth = 8
            imageView.layer.borderColor = UIColor.ypRed.cgColor
        }
        
        //настройка времени перехода между элементами квиза
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else {return}
            self.showNextQuestionOrResults()
            self.imageView.layer.borderWidth = 0
        }
    }
    
    //функция, описывающая логику отображения следующего элемента квиза || содержание алерта
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questions.count - 1 {
            let viewModel = QuizResultsViewModel(
                title: "Этот раунд окончен!",
                text: "Ваш результат: \(correctAnswerCounter) из \(questions.count)",
                buttonText: "Сыграть ещё раз")
            show(quiz: viewModel)
        } else {
            currentQuestionIndex += 1
            let nextQuestion = questions[currentQuestionIndex]
            let viewModel = convert(model: nextQuestion)
            
            show(quiz: viewModel)
        }
    }
    
    //обработка нажатия на кнопку "Нет"
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        showAnswerResult(isCorrect: false)
    }

    //обработка нажатия на кнопку "Да"
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        showAnswerResult(isCorrect: true)
    }
    
}
