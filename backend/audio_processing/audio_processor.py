import firebase_admin
from firebase_admin import credentials, firestore_async, storage
import nest_asyncio
import asyncio
import os
import torch
from TTS.api import TTS
import librosa
import soundfile as sf
import requests
import whisper
from googletrans import Translator
from pydub import AudioSegment
import logging
from datetime import datetime
import subprocess
from decimal import Decimal
from pydub.effects import speedup

# Configure logging
def setup_logger(post_id):
    log_file = f'{post_id}.log'
    logging.basicConfig(level=logging.INFO, filename=log_file, filemode='w',
                        format='%(asctime)s - %(levelname)s - %(message)s')
    return logging.getLogger(__name__), log_file

async def getUrl(postId):
    logger.info(f"Fetching URL for postId: {postId}")
    docPost = doc_ref.document(postId)
    doc = await docPost.get()
    if doc.exists:
        doc_dict = doc.to_dict()
        originalAudioUrl = doc_dict.get('originalAudioUrl')
        logger.info(f"Original audio URL fetched: {originalAudioUrl}")
        return originalAudioUrl
    else:
        logger.warning(f"No document found for postId: {postId}")
        return None

def measure_duration(file_path):
    logger.info(f"Measuring duration of file: {file_path}")
    y, sr = librosa.load(file_path)
    duration = librosa.get_duration(y=y, sr=sr)
    logger.info(f"Duration measured: {duration} seconds")
    return duration

# Function to generate TTS output and measure its duration
def generate_tts_and_measure(text, speaker_wav, language, file_path, speed=1.0):
    logger.info(f"Generating TTS for text in language: {language} with speed: {speed}")
    tts.tts_to_file(text=text, speaker_wav=speaker_wav, language=language, file_path=file_path, speed=speed)
    duration = round(measure_duration(file_path),1)
    logger.info(f"TTS generated and saved to: {file_path}, duration: {duration} seconds")
    return duration

async def writeUrl(postId, translatedUrl):
    logger.info(f"Writing translated URL for postId: {postId}")
    docPost = doc_ref.document(postId)
    await docPost.update({
        'translatedAudioUrl': firestore_async.ArrayUnion([translatedUrl])
    })
    logger.info("Translated URL updated successfully.")

async def writeLanguage(postId, orignalLanuage):
    logger.info(f"Writing original language for postId: {postId}: {orignalLanuage}")
    docPost = doc_ref.document(postId)
    await docPost.update({
        'original_audio_key': orignalLanuage
    })
    logger.info("Original language updated successfully.")

async def convert_to_wav_using_ffmpeg(input_path, output_path):
    logger.info(f"Converting {input_path} to WAV format using ffmpeg.")
    try:
        subprocess.run(['ffmpeg', '-i', input_path, output_path], check=True)
        logger.info(f"Conversion complete. WAV file saved to {output_path}.")
    except subprocess.CalledProcessError as e:
        logger.error(f"ffmpeg conversion failed: {e}")
        raise

async def getAudio(postId, audioUrl):
    logger.info(f"Downloading audio for postId: {postId} from URL: {audioUrl}")
    response = requests.get(audioUrl)
    path = postId + '.aac'  # Save as .aac initially
    if response.status_code == 200:
        with open(path, 'wb') as file:
            file.write(response.content)
        logger.info(f'Audio file downloaded successfully and saved to: {path}')
        
        # Convert to WAV format using ffmpeg
        wav_path = postId + '.wav'
        await convert_to_wav_using_ffmpeg(path, wav_path)
        return wav_path
    else:
        logger.error(f'Failed to download audio file. Status code: {response.status_code}')
    return None

def detectAudioLanguage(transcript):
    logger.info("Detecting language from transcript")
    detectLanguage = translator.detect(transcript)
    language = detectLanguage.lang
    logger.info(f"Detected language: {language}")
    return language

def translateTranscript(transcript, languages, original_language):
    logger.info("Translating transcript")
    allTranscript = {lang: '' for lang in languages}
    for lang in languages:
        if lang != original_language:
            logger.info(f"Translating to {lang}")
            translation = translator.translate(transcript, dest=lang)
            allTranscript[lang] = translation.text
            logger.info(f"Translation to {lang} completed")
            logger.info(f"Translation {lang}: {translation.text}")
    return allTranscript

def textToSpeech(postId, translatedText, orignalLanguage, audioTime):
    logger.info("Starting text-to-speech conversion")
    target_duration = audioTime
    logger.info(f"Orginal duration : {target_duration} seconds")
    orignal_audio_file = postId + ".wav"
    for lang, transcript in translatedText.items():
        if lang != orignalLanguage:
            logger.info(f"Generating TTS for language: {lang}")
            initial_file_path = lang + "_initial.mp3"
            initial_duration = generate_tts_and_measure(
                text=transcript,
                speaker_wav=orignal_audio_file,
                language=lang,
                file_path=initial_file_path
            )

            logger.info(f"Initial duration for {lang}: {initial_duration} seconds")
            speed_ratio = target_duration/initial_duration
            logger.info(f"Speed ratio for {lang}: {speed_ratio}")

            final_file_path = lang + "_" + postId + ".mp3"
            final_duration = generate_tts_and_measure(
                text=transcript,
                speaker_wav=orignal_audio_file,
                language=lang,
                file_path=final_file_path,
                speed=speed_ratio
            )
            logger.info(f"Final duration for {lang}: {final_duration} seconds")
            logger.info(f"TTS for language {lang} generated and saved to {final_file_path}")

def change_audio_duration(postId, languages, orignalLanguage, desired_duration_seconds):

    for lang in languages:
        if lang != orignalLanguage:
            input_file = lang + '_' + postId + '.mp3'
            output_file = 'final_' + lang + '_' + postId + '.mp3'
            audio = AudioSegment.from_file(input_file)
    
             # Get the current duration of the audio in milliseconds
            current_duration_ms = len(audio)
            # Convert desired duration to milliseconds
            desired_duration_ms = desired_duration_seconds * 1000
            # Calculate the speed change factor
            speed_change_factor = current_duration_ms / desired_duration_ms
            # Adjust the playback speed
            if speed_change_factor > 1:
                # Speed up the audio
                modified_audio = speedup(audio, playback_speed=speed_change_factor)
            else:
                # Slow down the audio
                modified_audio = audio.set_frame_rate(int(audio.frame_rate * speed_change_factor))
          # Export the result to a new file
            modified_audio.export(output_file, format="mp3")


async def uploadFiles(postId, languages, originalAudioUrl, orignalLanguage):
    logger.info(f"Uploading files for postId: {postId}")
    allUrls = {lang: '' for lang in languages}
    for lang in languages:
        if lang != orignalLanguage:
            file_name = 'final_' + lang + '_' + postId + '.mp3'
            blob = bucket.blob('convertedAudio/' + os.path.basename(file_name))
            blob.upload_from_filename(file_name)
            blob.make_public()
            allUrls[lang] = blob.public_url
            logger.info(f"File uploaded and made public: {file_name} URL: {blob.public_url}")
        else:
            allUrls[lang] = originalAudioUrl
    return allUrls

async def translateAudio(postId, languages):
    global logger, log_file
    logger, log_file = setup_logger(postId)
    logger.info(f"Starting audio translation for postId: {postId}")
    originalAudioUrl = await getUrl(postId)
    if originalAudioUrl is None:
        logger.error(f"Original audio URL not found for postId: {postId}")
        return
    logger.info(f"Original audio URL: {originalAudioUrl}")
    path = await getAudio(postId, originalAudioUrl)
    logger.info(f"Audio file path: {path}")
    result = model.transcribe(path)
    transcript = result['text']
    logger.info(f"Transcript: {transcript}")
    orignalLanguage = detectAudioLanguage(transcript)
    await writeLanguage(postId, orignalLanguage)
    translatedText = translateTranscript(transcript, languages, orignalLanguage)
    logger.info(f"Translated Text: {translatedText}")
    audioTime = round(librosa.get_duration(path=path), 1)
    textToSpeech(postId, translatedText, orignalLanguage, audioTime)
    change_audio_duration(postId, languages, orignalLanguage, audioTime)
    allUrls = await uploadFiles(postId, languages, originalAudioUrl, orignalLanguage)
    await writeUrl(postId, allUrls)

    # List of files to delete
    files_to_delete = [path]
    for lang in languages:
        if lang != orignalLanguage:
            files_to_delete.append(lang + '_' + postId + '.mp3')
            files_to_delete.append(lang + '_initial' + '.mp3')
            files_to_delete.append('final_' + lang + '_' + postId + '.mp3')
    files_to_delete.append(postId+'.log')
    files_to_delete.append(postId+'.mp3')
    files_to_delete.append(postId+'.aac')
    # Upload log file
    await upload_log_file(postId, log_file)
    delete_files(files_to_delete)

def delete_files(file_paths):
    for file_path in file_paths:
        if os.path.exists(file_path):
            os.remove(file_path)
            logger.info(f"Deleted file: {file_path}")
        else:
            logger.warning(f"File not found: {file_path}")

async def upload_log_file(postId, log_file):
    log_blob = bucket.blob(f'logs/{postId}.log')
    log_blob.upload_from_filename(log_file)
    log_blob.make_public()
    logger.info(f"Log file uploaded: {log_blob.public_url}")

def transcribe_audio(post_id):
    asyncio.run(translateAudio(post_id, languages))

# Firestore 
cred = credentials.Certificate('app/utils/flutter-tiktok-95041-firebase-adminsdk-jbl1g-514a9c1c51.json')
app = firebase_admin.initialize_app(cred, {'storageBucket': 'flutter-tiktok-95041.appspot.com'})
db = firestore_async.client()
doc_ref = db.collection("posts")
bucket = storage.bucket()

# Whisper
model = whisper.load_model("base")

translator = Translator()
languages = ['en', 'es', 'zh-cn']

# TTS
device = "cuda" if torch.cuda.is_available() else "cpu"
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2").to(device)

# Run the async translateAudio function
nest_asyncio.apply()
print("using nest_asyncio")
