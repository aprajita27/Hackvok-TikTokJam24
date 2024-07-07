from flask import request, jsonify, current_app as app
from .services.transcription_service import transcribe

@app.route('/transcribe', methods=['POST'])
def transcribe_audio():
    data = request.get_json()
    post_id = data.get('post_id')
    if not post_id:
        return jsonify({"error": "No post ID provided"}), 400
    
    transcribe(post_id)
    return jsonify({'status': 'Transcription Completed'}), 200