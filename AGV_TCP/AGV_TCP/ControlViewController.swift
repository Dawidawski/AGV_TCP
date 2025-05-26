//
//  ControlViewController.swift
//  AGV_TCP
//
//  Created by Dawid Widawski on 26/05/2025.
//


import UIKit

class ControlViewController: UIViewController {
    
    var tcpManager: TCPManager!
    var connectionDetails: (ip: String, port: String) = ("", "")
    
    private var statusLabel: UILabel!
    private var upButton: UIButton!
    private var downButton: UIButton!
    private var leftButton: UIButton!
    private var rightButton: UIButton!
    private var disconnectButton: UIButton!
    private var reconnectButton: UIButton!
    
    // Timers for continuous command sending
    private var commandTimers: [Int: Timer] = [:]
    private let commandInterval: TimeInterval = 0.1 // Send command every 100ms
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTCPManager()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAllCommands()
    }
    
    private func setupUI() {
        title = "Remote Control"
        // Navy blue background
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.5, alpha: 1.0)
        
        createUIElements()
        setupConstraints()
        updateReconnectButtonVisibility()
    }
    
    private func createUIElements() {
        // Status label
        statusLabel = UILabel()
        statusLabel.text = "Connected"
        statusLabel.textColor = .green
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 18, weight: .medium)
        
        // Arrow buttons with touch handling
        upButton = createArrowButton(title: "↑", tag: 0)
        downButton = createArrowButton(title: "↓", tag: 1)
        leftButton = createArrowButton(title: "←", tag: 2)
        rightButton = createArrowButton(title: "→", tag: 3)
        
        // Control buttons
        disconnectButton = UIButton(type: .system)
        disconnectButton.setTitle("Disconnect", for: .normal)
        disconnectButton.backgroundColor = .systemRed
        disconnectButton.setTitleColor(.white, for: .normal)
        disconnectButton.layer.cornerRadius = 8
        disconnectButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        disconnectButton.addTarget(self, action: #selector(disconnectTapped), for: .touchUpInside)
        
        reconnectButton = UIButton(type: .system)
        reconnectButton.setTitle("Reconnect", for: .normal)
        reconnectButton.backgroundColor = .systemOrange
        reconnectButton.setTitleColor(.white, for: .normal)
        reconnectButton.layer.cornerRadius = 8
        reconnectButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        reconnectButton.addTarget(self, action: #selector(reconnectTapped), for: .touchUpInside)
        reconnectButton.isHidden = true
    }
    
    private func createArrowButton(title: String, tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 40, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.tag = tag
        
        // Add touch events for press and release
        button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonReleased(_:)), for: .touchUpInside)
        button.addTarget(self, action: #selector(buttonReleased(_:)), for: .touchUpOutside)
        button.addTarget(self, action: #selector(buttonReleased(_:)), for: .touchCancel)
        
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 4
        
        return button
    }
    
    private func setupConstraints() {
        let allViews = [statusLabel, upButton, downButton, leftButton, rightButton, disconnectButton, reconnectButton]
        allViews.forEach {
            $0?.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0!)
        }
        
        NSLayoutConstraint.activate([
            // Status label
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Up arrow
            upButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            upButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 60),
            upButton.widthAnchor.constraint(equalToConstant: 80),
            upButton.heightAnchor.constraint(equalToConstant: 80),
            
            // Left arrow
            leftButton.centerYAnchor.constraint(equalTo: upButton.bottomAnchor, constant: 50),
            leftButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -50),
            leftButton.widthAnchor.constraint(equalToConstant: 80),
            leftButton.heightAnchor.constraint(equalToConstant: 80),
            
            // Right arrow
            rightButton.centerYAnchor.constraint(equalTo: leftButton.centerYAnchor),
            rightButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 50),
            rightButton.widthAnchor.constraint(equalToConstant: 80),
            rightButton.heightAnchor.constraint(equalToConstant: 80),
            
            // Down arrow
            downButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            downButton.topAnchor.constraint(equalTo: leftButton.bottomAnchor, constant: 20),
            downButton.widthAnchor.constraint(equalToConstant: 80),
            downButton.heightAnchor.constraint(equalToConstant: 80),
            
            // Disconnect button
            disconnectButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            disconnectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            disconnectButton.widthAnchor.constraint(equalToConstant: 200),
            disconnectButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Reconnect button
            reconnectButton.bottomAnchor.constraint(equalTo: disconnectButton.topAnchor, constant: -20),
            reconnectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            reconnectButton.widthAnchor.constraint(equalToConstant: 200),
            reconnectButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupTCPManager() {
        tcpManager.onConnectionLost = { [weak self] in
            DispatchQueue.main.async {
                self?.statusLabel.text = "Connection Lost"
                self?.statusLabel.textColor = .red
                self?.stopAllCommands()
                self?.updateReconnectButtonVisibility()
            }
        }
    }
    
    @objc private func buttonPressed(_ sender: UIButton) {
        guard tcpManager.isConnected else {
            showConnectionLostAlert()
            return
        }
        
        // Visual feedback - button becomes darker when pressed
        sender.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.7)
        sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        
        let command = getCommand(for: sender.tag)
        
        // Send command immediately
        tcpManager.sendCommand(command)
        
        // Start timer for continuous sending
        commandTimers[sender.tag] = Timer.scheduledTimer(withTimeInterval: commandInterval, repeats: true) { [weak self] _ in
            self?.tcpManager.sendCommand(command)
        }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    @objc private func buttonReleased(_ sender: UIButton) {
        // Stop sending commands
        commandTimers[sender.tag]?.invalidate()
        commandTimers[sender.tag] = nil
        
        // Send STOP command
        tcpManager.sendCommand("STOP")
        
        // Visual feedback - return to normal state
        UIView.animate(withDuration: 0.1) {
            sender.backgroundColor = .systemBlue
            sender.transform = .identity
        }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func getCommand(for tag: Int) -> String {
        switch tag {
        case 0: return "FORWARD"   // Up arrow
        case 1: return "BACKWARD"  // Down arrow
        case 2: return "LEFT"      // Left arrow
        case 3: return "RIGHT"     // Right arrow
        default: return "UNKNOWN"
        }
    }
    
    private func stopAllCommands() {
        // Stop all timers and send STOP command
        commandTimers.values.forEach { $0.invalidate() }
        commandTimers.removeAll()
        tcpManager.sendCommand("STOP")
    }
    
    @objc private func disconnectTapped() {
        stopAllCommands()
        tcpManager.disconnect()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func reconnectTapped() {
        guard let port = UInt16(connectionDetails.port) else { return }
        
        statusLabel.text = "Reconnecting..."
        statusLabel.textColor = .orange
        reconnectButton.isEnabled = false
        
        tcpManager.connect(to: connectionDetails.ip, port: port)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.reconnectButton.isEnabled = true
            if self.tcpManager.isConnected {
                self.statusLabel.text = "Connected"
                self.statusLabel.textColor = .green
            } else {
                self.statusLabel.text = "Reconnection Failed"
                self.statusLabel.textColor = .red
            }
            self.updateReconnectButtonVisibility()
        }
    }
    
    private func updateReconnectButtonVisibility() {
        reconnectButton.isHidden = tcpManager.isConnected
    }
    
    private func showConnectionLostAlert() {
        let alert = UIAlertController(title: "Connection Lost",
                                    message: "The connection to the server has been lost. Use Reconnect to try again.",
                                    preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
