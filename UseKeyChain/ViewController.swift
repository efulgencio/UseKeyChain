//
//  ViewController.swift
//  UseKeyChain
//
//  Created by Fulgencio Comendeiro, Eduardo on 19/10/25.
//

import UIKit

class ViewController: UIViewController {
    
    private let textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Introduce tu nombre"
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()
    
    private let saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Guardar", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let readButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Recuperar", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let resultLabel: UILabel = {
        let lbl = UILabel()
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(textField)
        view.addSubview(saveButton)
        view.addSubview(readButton)
        view.addSubview(resultLabel)
        
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.widthAnchor.constraint(equalToConstant: 250),
            
            saveButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20),
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            readButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 10),
            readButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            resultLabel.topAnchor.constraint(equalTo: readButton.bottomAnchor, constant: 40),
            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultLabel.widthAnchor.constraint(equalToConstant: 250)
        ])
        
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        readButton.addTarget(self, action: #selector(readTapped), for: .touchUpInside)
    }
    
    @objc private func saveTapped() {
        guard let text = textField.text, !text.isEmpty else { return }
        KeychainHelper.shared.save(text, for: "userName")
        resultLabel.text = "Nombre guardado ✅"
        textField.text = ""
    }
    
    @objc private func readTapped() {
        if let value = KeychainHelper.shared.read(for: "userName") {
            resultLabel.text = "Valor recuperado: \(value)"
        } else {
            resultLabel.text = "No hay datos guardados."
        }
    }
}


