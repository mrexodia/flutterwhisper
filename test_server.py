import time
import time
import json
from base64 import b64decode
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/api/extra/transcribe', methods=['POST'])
def transcribe():
    try:
        data = request.get_json()
        audio_data = data['audio_data']
        prompt = data.get('prompt', '')
        suppress_non_speech = data.get('suppress_non_speech', False)
        langcode = data.get('langcode', 'en')

        print(f"Received audio  {len(audio_data)} bytes")
        print(f"Prompt: {prompt}")
        print(f"Suppress non-speech: {suppress_non_speech}")
        print(f"Language code: {langcode}")

        decoded_audio = b64decode(audio_data)
        # Save audio to file in ./temp, use timestamp as filename
        with open(f'./temp/{int(time.time())}.wav', 'wb') as f:
            f.write(decoded_audio)
        size = len(decoded_audio)
        return jsonify({'text': f"Transcribed {size} bytes of audio successfully"})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

if __name__ == '__main__':
    app.run(debug=True, port=5001)
