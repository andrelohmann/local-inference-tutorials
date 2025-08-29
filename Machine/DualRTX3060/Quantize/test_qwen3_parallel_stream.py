import requests
import json
import time
import threading
import sys

# --- Konfiguration ---
VLLM_URL = "http://localhost:8000/v1/chat/completions"
HEADERS = { "Content-Type": "application/json" }
SNAKE_GAME_PROMPT = """
Betreff: Programmieranweisung für ein erweitertes, konsolenbasiertes Snake-Spiel

Hallo! Deine Aufgabe ist es, ein voll funktionsfähiges und feature-reiches Snake-Spiel mit der nativen Python-Bibliothek `curses` zu entwickeln. Das Spiel muss vollständig in einem Text-Terminal lauffähig sein, damit es über eine SSH-Verbindung gespielt werden kann.

Bitte implementiere den gesamten Code in einer einzigen Python-Datei. Achte auf eine saubere, lesbare und gut strukturierte Codebasis.

---
### 1. Grundlegende Spielmechanik:
*   **Spielfenster:** Das Spiel soll das gesamte verfügbare Terminalfenster nutzen.
*   **Die Schlange:** Stelle sie mit ASCII-Zeichen dar (z.B. 'O' für den Kopf, 'o' für den Körper).
*   **Das Futter:** Stelle es als '*' dar.
*   **Spielende:** Kollision mit dem Rand oder sich selbst.

### 2. Erweiterte Features & Gameplay-Elemente:
*   **Punktesystem:** 10 Punkte pro Futter.
*   **Schwierigkeitsstufen:** Einfach, Normal, Schwer (beeinflusst Startgeschwindigkeit).
*   **Highscore-System:** Speicherung in `highscore.txt`.
*   **Spezial-Futter:** Goldenes ('$') für 50 Punkte, Blaues ('S') zur Verlangsamung.
*   **Hindernisse:** Statische '#' Blöcke ab 200 Punkten.

### 3. Benutzeroberfläche & Design:
*   Start-, Game-Over- und Auswahl-Bildschirme.
*   Verwende `curses` für Farben und einen Rahmen.

### 4. Technische & Strukturelle Anforderungen:
*   Nutze Klassen für `Snake` und `Food`.
*   Verwende `curses.wrapper` für sauberes Beenden.
*   Füge Kommentare hinzu.

Bitte generiere den vollständigen Python-Code, um dieses konsolenbasierte Spiel zu erstellen.
"""

def run_request(request_id: int, payload: dict, results: list):
    """
    Führt eine einzelne Streaming-Anfrage aus, misst die Performance
    und speichert das Ergebnis in einer geteilten Liste.
    """
    print(f"[Request {request_id+1}] Starte Anfrage...")
    
    start_time = None
    token_count = 0
    
    try:
        response = requests.post(VLLM_URL, headers=HEADERS, json=payload, stream=True, timeout=300)
        response.raise_for_status()

        for line in response.iter_lines():
            if line:
                decoded_line = line.decode('utf-8')
                if decoded_line.startswith('data: '):
                    content = decoded_line[6:]
                    if content == "[DONE]":
                        break
                    
                    try:
                        chunk = json.loads(content)
                        token_text = chunk['choices'][0]['delta'].get('content', '')
                        
                        if token_text:
                            if start_time is None:
                                start_time = time.monotonic()
                            token_count += 1
                    except json.JSONDecodeError:
                        pass
        
        end_time = time.monotonic()
        
        if start_time is not None:
            duration = end_time - start_time
            tps = token_count / duration if duration > 0 else 0
            results[request_id] = {'id': request_id + 1, 'tokens': token_count, 'duration': duration, 'tps': tps, 'status': 'Success'}
            print(f"[Request {request_id+1}] Beendet. Tokens: {token_count}, TPS: {tps:.2f}")
        else:
             results[request_id] = {'id': request_id + 1, 'status': 'No Content'}
             print(f"[Request {request_id+1}] Beendet ohne Inhalt.")

    except requests.exceptions.RequestException as e:
        results[request_id] = {'id': request_id + 1, 'status': f'Error: {e}'}
        print(f"[Request {request_id+1}] FEHLER: {e}")


if __name__ == "__main__":
    num_parallel_requests = 16
    if len(sys.argv) > 1:
        try:
            num_parallel_requests = int(sys.argv[1])
        except ValueError:
            print(f"Ungültige Eingabe '{sys.argv[1]}'. Verwende Default: {num_parallel_requests} Anfragen.")
    
    print(f"--- Starte Performance-Test mit {num_parallel_requests} parallelen Anfragen ---")

    data_payload = {
        "model": "qwen3-coder-30b-awq",
        "messages": [{"role": "user", "content": SNAKE_GAME_PROMPT}],
        "max_tokens": 16384,
        "temperature": 0.2,
        "stream": True
    }

    threads = []
    results = [{} for _ in range(num_parallel_requests)]

    total_start_time = time.monotonic()

    for i in range(num_parallel_requests):
        thread = threading.Thread(target=run_request, args=(i, data_payload, results))
        threads.append(thread)
        thread.start()
        time.sleep(0.1) 

    for thread in threads:
        thread.join()

    total_end_time = time.monotonic()
    total_duration = total_end_time - total_start_time

    print("\n\n--- Alle Anfragen abgeschlossen ---")
    print("--- Individuelle Ergebnisse ---")
    
    successful_requests = [res for res in results if res.get('status') == 'Success']
    
    for res in successful_requests:
        print(f"Request {res['id']}: Tokens={res['tokens']}, Dauer={res['duration']:.2f}s, TPS={res['tps']:.2f}")

    if not successful_requests:
        print("Keine Anfragen erfolgreich abgeschlossen.")
    else:
        # --- ERWEITERTE BERECHNUNG UND AUSGABE ---
        total_tokens_generated = sum(res['tokens'] for res in successful_requests)
        avg_tps_per_request = sum(res['tps'] for res in successful_requests) / len(successful_requests)
        
        # NEU: Berechne den Gesamtdurchsatz des Systems
        overall_system_tps = 0
        if total_duration > 0:
            overall_system_tps = total_tokens_generated / total_duration
        
        print("\n--- Zusammenfassung der Gesamt-Performance ---")
        print(f"Gesamtdauer für den Test: {total_duration:.2f} Sekunden")
        print(f"Anzahl paralleler Anfragen: {num_parallel_requests}")
        print(f"Anzahl erfolgreicher Anfragen: {len(successful_requests)}")
        print("-" * 40)
        # NEU: Klar hervorgehobene Gesamt-Metriken
        print(f"Insgesamt generierte Tokens (alle Anfragen): {total_tokens_generated}")
        print(f"Gesamtdurchsatz des Systems (Tokens/Sekunde): {overall_system_tps:.2f}")
        print("-" * 40)
        # Zur Einordnung: Der Durchschnitt der einzelnen Anfragen
        print(f"Durchschnittliche Performance (pro einzelne Anfrage): {avg_tps_per_request:.2f} T/s")
        # ----------------------------------------------------