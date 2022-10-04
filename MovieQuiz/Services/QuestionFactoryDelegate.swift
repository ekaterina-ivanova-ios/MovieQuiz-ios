//
//  QuestionFactoryDelegate.swift
//  MovieQuiz
//
//  Created by Екатерина Иванова on 04.10.2022.
//

import Foundation

protocol QuestionFactoryDelegate: class {
    func didRecieveNextQuestion(question: QuizQuestion?)
}
