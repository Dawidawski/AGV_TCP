//
//  ConnectionViewController.swift
//  AGV_TCP
//
//  Created by Dawid Widawski on 26/05/2025.
//


import UIKit

class ConnectionViewController: UIViewController {
    
    private var ipTextField: UITextField!
    private var portTextField: UITextField!
    private var connectButton: UIButton!
    private var statusLabel: UILabel!
    private var activityIndicator: UIActivityIndicatorView!
    
    private let tcpManager = TCPManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTCPManager()
    }
    
    private func setupUI() {
        title = "TCP Connection"
        // Navy blue background - zawsze taki sam
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1.0)
        
        // Setup text fields
        ipTextField = UITextField()
        ipTextField.placeholder = "Enter IP Address (e.g., 192.168.1.100)"
        ipTextField.borderStyle = .roundedRect
        ipTextField.keyboardType = .numbersAndPunctuation
        ipTextField.text = "127.0.0.1" // Default localhost
        // Wymuś białe tło i czarny tekst niezależnie od trybu
        ipTextField.backgroundColor = UIColor.white
        ipTextField.textColor = UIColor.black
        
        // Ustaw kolor placeholder
        ipTextField.attributedPlaceholder = NSAttributedString(
            string: ipTextField.placeholder ?? "",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        
        portTextField = UITextField()
        portTextField.placeholder = "Enter Port (e.g., 8080)"
        portTextField.borderStyle = .roundedRect
        portTextField.keyboardType = .numberPad
        portTextField.text = "8080" // Default port
        // Wymuś białe tło i czarny tekst niezależnie od trybu
        portTextField.backgroundColor = UIColor.white
        portTextField.textColor = UIColor.black
        
        // Ustaw kolor placeholder
        portTextField.attributedPlaceholder = NSAttributedString(
            string: portTextField.placeholder ?? "",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray]
        )
        
        // Setup button
        connectButton = UIButton(type: .system)
        connectButton.setTitle("Connect", for: .normal)
        connectButton.backgroundColor = UIColor.systemBlue
        connectButton.setTitleColor(UIColor.white, for: .normal)
        connectButton.layer.cornerRadius = 8
        connectButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)
        
        // Setup status label - zawsze biały tekst
        statusLabel = UILabel()
        statusLabel.text = "Enter connection details"
        statusLabel.textColor = UIColor.white
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 16)
        
        // Setup activity indicator - zawsze biały
        activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = UIColor.white
        activityIndicator.hidesWhenStopped = true
        
        // Layout
        setupConstraints()
    }
    
    private func setupConstraints() {
        let stackView = UIStackView(arrangedSubviews: [
            ipTextField,
            portTextField,
            connectButton,
            statusLabel,
            activityIndicator
        ])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            ipTextField.heightAnchor.constraint(equalToConstant: 44),
            portTextField.heightAnchor.constraint(equalToConstant: 44),
            connectButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupTCPManager() {
        tcpManager.onConnectionLost = { [weak self] in
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @objc private func connectButtonTapped() {
        guard let ipText = ipTextField.text, !ipText.isEmpty,
              let portText = portTextField.text, !portText.isEmpty,
              let port = UInt16(portText) else {
            showAlert(message: "Please enter valid IP address and port")
            return
        }
        
        connectButton.isEnabled = false
        activityIndicator.startAnimating()
        statusLabel.text = "Connecting..."
        statusLabel.textColor = UIColor.orange
        
        tcpManager.connect(to: ipText, port: port)
        
        // Check connection status after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.activityIndicator.stopAnimating()
            self.connectButton.isEnabled = true
            
            if self.tcpManager.isConnected {
                self.statusLabel.text = "Connected successfully!"
                self.statusLabel.textColor = UIColor.green
                self.navigateToControlView()
            } else {
                self.statusLabel.text = self.tcpManager.connectionError ?? "Connection failed"
                self.statusLabel.textColor = UIColor.red
            }
        }
    }
    
    private func navigateToControlView() {
        let controlVC = ControlViewController()
        controlVC.tcpManager = tcpManager
        controlVC.connectionDetails = (ipTextField.text ?? "", portTextField.text ?? "")
        navigationController?.pushViewController(controlVC, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
