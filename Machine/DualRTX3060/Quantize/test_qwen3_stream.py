import requests
import json
import time

# Die URL des vLLM-Servers
VLLM_URL = "http://localhost:8000/v1/chat/completions"

# Die Header für die Anfrage
headers = {
    "Content-Type": "application/json"
}

# --- NEU: Der lange und komplexe Prompt für das Snake-Spiel ---
snake_game_prompt = """
Betreff: Programmieranweisung für ein erweitertes, konsolenbasiertes Snake-Spiel

Hallo! Deine Aufgabe ist es, ein voll funktionsfähiges und feature-reiches Snake-Spiel mit der nativen Python-Bibliothek `curses` zu entwickeln. Das Spiel muss vollständig in einem Text-Terminal lauffähig sein, damit es über eine SSH-Verbindung gespielt werden kann.

Bitte implementiere den gesamten Code in einer einzigen Python-Datei. Achte auf eine saubere, lesbare und gut strukturierte Codebasis.

---

### 1. Grundlegende Spielmechanik:

*   **Spielfenster:** Das Spiel soll das gesamte verfügbare Terminalfenster nutzen und sich dynamisch an dessen Größe anpassen.
*   **Spielfeld:** Implementiere ein Grid-basiertes System. Die Schlange und das Futter sollen sich auf diesem Grid aus **ASCII-Zeichen** bewegen.
*   **Die Schlange:**
    *   Stelle die Schlange mit ASCII-Zeichen dar (z.B. **'O'** für den Kopf und **'o'** für den Körper).
    *   Sie startet in der Mitte des Bildschirms mit einer Länge von 3 Zeichen.
    *   Sie bewegt sich konstant in eine Richtung (Startrichtung ist rechts).
    *   Der Spieler kann die Richtung mit den Pfeiltasten ändern.
    *   Die Schlange darf sich nicht selbst in die entgegengesetzte Richtung bewegen.
*   **Das Futter:**
    *   Stelle das normale Futter als einzelnes ASCII-Zeichen dar (z.B. **'*'**).
    *   Es erscheint an einer zufälligen Position auf dem Spielfeld.
    *   Wenn die Schlange das Futter frisst, wird sie ein Zeichen länger.
    *   Ein neues Futter erscheint sofort an einer neuen, zufälligen Position.
*   **Spielende:**
    *   Das Spiel endet, wenn der Kopf der Schlange den Rand des Spielfelds (den Terminal-Rand) berührt.
    *   Das Spiel endet, wenn der Kopf der Schlange ihren eigenen Körper berührt.

### 2. Erweiterte Features & Gameplay-Elemente:

*   **Punktesystem:**
    *   Der Spieler startet mit 0 Punkten.
    *   Für jedes gefressene normale Futter erhält der Spieler 10 Punkte.
    *   Der aktuelle Punktestand soll jederzeit gut sichtbar am oberen Rand des Terminals angezeigt werden.
*   **Schwierigkeitsstufen & Geschwindigkeit:**
    *   Die Geschwindigkeit (Aktualisierungsrate des Terminals) soll mit steigendem Punktestand zunehmen.
    *   Implementiere einen einfachen Auswahlbildschirm für drei Schwierigkeitsstufen (Einfach, Normal, Schwer), die die Startgeschwindigkeit bestimmen.
*   **Highscore-System:**
    *   Speichere den höchsten erreichten Punktestand in einer Textdatei (`highscore.txt`), sodass er persistent bleibt.
    *   Zeige auf dem "Game Over"-Bildschirm den aktuellen Punktestand und den Highscore an.
*   **Spezial-Futter (Power-ups):**
    *   **Goldenes Futter:** Erscheint selten. Gibt 50 Bonuspunkte und verschwindet nach 8 Sekunden. Stelle es als **'$'**-Zeichen dar und nutze die Farbfähigkeiten von `curses`, um es **gelb** einzufärben.
    *   **Blaues Futter:** Erscheint sehr selten. Verlangsamt die Geschwindigkeit der Schlange für 10 Sekunden. Stelle es als **'S'**-Zeichen dar und färbe es **blau** ein.
*   **Hindernisse:**
    *   Nachdem 200 Punkte erreicht wurden, sollen 5 stationäre Hindernisse an zufälligen Positionen erscheinen.
    *   Stelle Hindernisse als statische ASCII-Zeichen dar (z.B. **'#'**) und nutze `curses`, um sie **grau (oder eine andere dunkle Farbe)** einzufärben.
    *   Eine Kollision mit einem Hindernis beendet das Spiel.

### 3. Benutzeroberfläche & Design:

*   **Startbildschirm:** Zeige vor dem Spielstart einen zentrierten Text mit dem Titel, der Schwierigkeitsauswahl und der Anweisung "Drücke eine beliebige Taste zum Starten".
*   **Game-Over-Bildschirm:** Zeige einen zentrierten "Game Over"-Text mit dem finalen Punktestand, dem Highscore und den Optionen "Drücke R zum Neustarten" oder "Drücke Q zum Beenden".
*   **Visuelles Design:**
    *   Zeichne mit `curses` einen klaren Rahmen um das Spielfeld mit ASCII-Zeichen.
    *   Nutze die `curses`-Bibliothek, um Farben für die verschiedenen Spiel-Elemente zu verwenden und die Lesbarkeit zu erhöhen.

### 4. Technische & Strukturelle Anforderungen:

*   **Code-Struktur:**
    *   Verwende Konstanten für Spielparameter am Anfang des Skripts.
    *   Nutze eine objektorientierte Herangehensweise (z.B. `Snake`-Klasse, `Food`-Klasse).
    *   Schreibe den Hauptteil des Spiels in einer `main()`-Funktion, die von `curses.wrapper` aufgerufen wird.
*   **`curses`-Handhabung:** Stelle sicher, dass das `curses`-Modul korrekt initialisiert und am Ende des Programms wieder ordnungsgemäß geschlossen wird (idealerweise mit **`curses.wrapper`**), um das Terminal nicht in einem fehlerhaften Zustand zu hinterlassen.
*   **Kommentare:** Füge Kommentare hinzu, um die Hauptfunktionen und komplexere Teile des Codes zu erklären.

Bitte generiere den vollständigen Python-Code, um dieses konsolenbasierte Spiel zu erstellen.
"""
# -----------------------------------------------------------------

# Die Nutzlast (Payload) der Anfrage
data = {
    "model": "qwen3-coder-30b-awq",
    "messages": [
        {"role": "user", "content": snake_game_prompt}
    ],
    "max_tokens": 16384,  # Erhöht, um dem Modell genug Raum für den vollständigen Code zu geben
    "temperature": 0.2, # 0.2 determinitsitscher - besser für code, 0.7 kreativer - besser für text, 1.0 sehr kreativ
    "stream": True
}

# Variablen für die Performance-Messung
start_time = None
token_count = 0

# Sende die Anfrage mit stream=True
response = requests.post(VLLM_URL, headers=headers, json=data, stream=True)

# Verarbeite den Stream Zeile für Zeile
print("--- Antwort des Modells (live gestreamt) ---")
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
                    
                    print(token_text, end='', flush=True)
            except json.JSONDecodeError:
                pass

# Stoppe den Timer und berechne die Statistik
end_time = time.monotonic()
print("\n--- Stream beendet ---")

if start_time is not None:
    duration = end_time - start_time
    if duration > 0:
        tps = token_count / duration
        
        print("\n--- Performance-Statistik ---")
        print(f"Generierte Token (approximiert): {token_count}")
        print(f"Benötigte Zeit: {duration:.2f} Sekunden")
        print(f"Tokens pro Sekunde (TPS): {tps:.2f}")
    else:
        print("\nAntwort war zu schnell, um die Geschwindigkeit zu messen.")
else:
    print("\nKeine Antwort vom Modell erhalten.")