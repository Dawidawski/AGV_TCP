//
//  TCPManager.swift
//  AGV_TCP
//
//  Created by Dawid Widawski on 26/05/2025.
//


import Foundation
import Network

class TCPManager: ObservableObject {
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "TCPQueue", qos: .userInitiated)
    
    @Published var isConnected = false
    @Published var connectionError: String?
    
    var onConnectionLost: (() -> Void)?
    
    func connect(to host: String, port: UInt16) {
        disconnect()
        
        let nwEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!)
        connection = NWConnection(to: nwEndpoint, using: .tcp)
        
        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isConnected = true
                    self?.connectionError = nil
                    self?.startReceiving()
                case .failed(let error):
                    self?.isConnected = false
                    self?.connectionError = error.localizedDescription
                    self?.onConnectionLost?()
                case .cancelled:
                    self?.isConnected = false
                default:
                    break
                }
            }
        }
        
        connection?.start(queue: queue)
    }
    
    func disconnect() {
        connection?.cancel()
        connection = nil
        isConnected = false
    }
    
    func sendCommand(_ command: String) {
        guard let connection = connection, isConnected else { return }
        
        let data = Data(command.utf8)
        connection.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                DispatchQueue.main.async {
                    self.connectionError = error.localizedDescription
                    self.onConnectionLost?()
                }
            }
        }))
    }
    
    private func startReceiving() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, isComplete, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.connectionError = error.localizedDescription
                    self?.onConnectionLost?()
                }
                return
            }
            
            if isComplete {
                DispatchQueue.main.async {
                    self?.isConnected = false
                    self?.onConnectionLost?()
                }
                return
            }
            
            // Continue receiving
            self?.startReceiving()
        }
    }
}