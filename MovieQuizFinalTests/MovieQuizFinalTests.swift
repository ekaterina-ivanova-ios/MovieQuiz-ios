import XCTest
@testable import MovieQuiz

final class MovieQuizViewControllerProtocolMock: MovieQuizViewControllerProtocol {
    func show(quiz step: QuizStepViewModel) {}
    func highlightImageBorder(isCorrectAnswer: Bool) {}
    func enableOrDisableButtons() {}
    func showResult() {}
    func showLoadingIndicator() {}
    func hideLoadingIndicator() {}
}

final class MovieQuizFinalTests: XCTestCase {
    func testPresenterConvertModel() throws {
            let viewControllerMock = MovieQuizViewControllerProtocolMock()
            let sut = MovieQuizPresenter(viewController: viewControllerMock)
            
            let emptyData = Data()
            let question = QuizQuestion(image: emptyData, text: "Question Text", correctAnswer: true)
            let viewModel = sut.convert(model: question)
            
            XCTAssertNotNil(viewModel.image)
            XCTAssertEqual(viewModel.question, "Question Text")
            XCTAssertEqual(viewModel.questionNumber, "1/10")
        }
}
