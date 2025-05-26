#!/usr/bin/env python3
import socket
import threading
import time

class TCPServer:
    def __init__(self, host='0.0.0.0', port=8080):
        self.host = host
        self.port = port
        self.server_socket = None
        self.running = False
        
    def start(self):
        """Uruchamia serwer TCP"""
        try:
            self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.server_socket.bind((self.host, self.port))
            self.server_socket.listen(5)
            self.running = True
            
            print(f"🚀 Serwer TCP uruchomiony na {self.host}:{self.port}")
            print(f"📱 W aplikacji iOS użyj adresu: {self.get_local_ip()}:{self.port}")
            print("⏹️  Naciśnij Ctrl+C aby zatrzymać serwer\n")
            
            while self.running:
                try:
                    client_socket, client_address = self.server_socket.accept()
                    print(f"🔗 Nowe połączenie od: {client_address}")
                    
                    # Uruchom obsługę klienta w osobnym wątku
                    client_thread = threading.Thread(
                        target=self.handle_client,
                        args=(client_socket, client_address)
                    )
                    client_thread.daemon = True
                    client_thread.start()
                    
                except socket.error:
                    if self.running:
                        print("❌ Błąd podczas akceptowania połączenia")
                        
        except Exception as e:
            print(f"❌ Błąd uruchamiania serwera: {e}")
        finally:
            self.stop()
    
    def handle_client(self, client_socket, client_address):
        """Obsługuje komunikację z jednym klientem"""
        try:
            while self.running:
                try:
                    # Odbierz dane od klienta
                    data = client_socket.recv(1024)
                    if not data:
                        break
                        
                    command = data.decode('utf-8').strip()
                    print(f"📨 Otrzymano od {client_address}: {command}")
                    
                    # Przetwórz komendę
                    self.process_command(command, client_address)
                    
                    # Opcjonalnie: wyślij potwierdzenie
                    response = f"OK: {command}"
                    client_socket.send(response.encode('utf-8'))
                    
                except socket.timeout:
                    continue
                except socket.error:
                    break
                    
        except Exception as e:
            print(f"❌ Błąd obsługi klienta {client_address}: {e}")
        finally:
            print(f"🔌 Rozłączono: {client_address}")
            client_socket.close()
    
    def process_command(self, command, client_address):
        """Przetwarza otrzymane komendy"""
        timestamp = time.strftime("%H:%M:%S")
        
        if command == "FORWARD":
            print(f"⬆️  [{timestamp}] RUCH DO PRZODU")
            # Tutaj dodaj kod do sterowania urządzeniem
            
        elif command == "BACKWARD":
            print(f"⬇️  [{timestamp}] RUCH DO TYŁU")
            # Tutaj dodaj kod do sterowania urządzeniem
            
        elif command == "LEFT":
            print(f"⬅️  [{timestamp}] OBRÓT W LEWO")
            # Tutaj dodaj kod do sterowania urządzeniem
            
        elif command == "RIGHT":
            print(f"➡️  [{timestamp}] OBRÓT W PRAWO")
            # Tutaj dodaj kod do sterowania urządzeniem
            
        elif command == "STOP":
            print(f"⏹️  [{timestamp}] STOP")
            # Tutaj dodaj kod do zatrzymania urządzenia
            
        else:
            print(f"❓ [{timestamp}] Nieznana komenda: {command}")
    
    def get_local_ip(self):
        """Zwraca lokalny adres IP"""
        try:
            # Połącz się z Google DNS aby uzyskać lokalny IP
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
            s.close()
            return local_ip
        except:
            return "127.0.0.1"
    
    def stop(self):
        """Zatrzymuje serwer"""
        self.running = False
        if self.server_socket:
            self.server_socket.close()
        print("\n🛑 Serwer zatrzymany")

def main():
    # Utwórz i uruchom serwer
    server = TCPServer(host='0.0.0.0', port=8080)
    
    try:
        server.start()
    except KeyboardInterrupt:
        print("\n⏹️  Zatrzymywanie serwera...")
        server.stop()

if __name__ == "__main__":
    main()
