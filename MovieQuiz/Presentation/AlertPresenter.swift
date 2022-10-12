
import UIKit

struct AlertPresenter {
    
    weak var delegate: AlertDelegate?
    
    init (delegate: AlertDelegate) {
        self.delegate = delegate
    }
}

extension AlertPresenter: AlertProtocol {
    
    func show(alertModel: AlertModel) {
        let alert = UIAlertController(
            title: alertModel.title,
            message: alertModel.message,
            preferredStyle: .alert)
        
        let action = UIAlertAction(title: alertModel.buttonText, style: .default, handler: alertModel.completion)
        alert.addAction(action)
        delegate?.presentAlert(alert)
    }
}
