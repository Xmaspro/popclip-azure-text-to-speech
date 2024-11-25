#!/bin/zsh
# #popclip
# name: Azure TTS
# icon: symbol:message.and.waveform

# Please apply for your own key
AZURE_REGION=""
AZURE_SUBSCRIPTION_KEY=""

TEXT_ANALYTICS_ENDPOINT="https://${AZURE_REGION}.api.cognitive.microsoft.com/text/analytics/v3.0-preview.1/languages"
TTS_ENDPOINT="https://${AZURE_REGION}.tts.speech.microsoft.com/cognitiveservices/v1"

# Function to detect language of the text
detect_language() {
    local text="$1"
    local response=$(curl -s -X POST "${TEXT_ANALYTICS_ENDPOINT}" \
        -H "Ocp-Apim-Subscription-Key: ${AZURE_SUBSCRIPTION_KEY}" \
        -H "Content-Type: application/json" \
        -d "{\"documents\": [{\"id\": \"1\", \"text\": \"$text\"}]}")

    echo $(echo "$response" | jq -r '.documents[0].detectedLanguage.iso6391Name')
}

# Detect the language of the selected text
language=$(detect_language "$POPCLIP_TEXT")

# Map detected language to Azure TTS voice
case $language in
    "en") voice="en-US-JennyMultilingualNeural";;
    "fr") voice="fr-FR-JulieNeural";;
    "es") voice="es-ES-ElviraNeural";;
    "de") voice="de-DE-KatjaNeural";;
    "jp") voice="ja-JP-NaokiNeural";;
    "zh") voice="zh-CN-XiaoxiaoNeural";;
    *) voice="en-US-JennyMultilingualNeural";;  # Default to English if language is not recognized
esac

# Create a temporary audio file
temp_audio_file=$(mktemp)

# Use curl to download and save the audio data to the temporary file
curl -X POST "https://${AZURE_REGION}.tts.speech.microsoft.com/cognitiveservices/v1" \
     -H "Ocp-Apim-Subscription-Key: ${AZURE_SUBSCRIPTION_KEY}" \
     -H "Content-Type: application/ssml+xml" \
     -H "X-Microsoft-OutputFormat: audio-16khz-32kbitrate-mono-mp3" \
     -d "<speak version=\"1.0\" xmlns=\"http://www.w3.org/2001/10/synthesis\" xml:lang=\"en-US\">
    <voice name=\"en-US-JennyMultilingualNeural\">
        $POPCLIP_TEXT
    </voice>
</speak>" -so "$temp_audio_file"

# Play the temporary audio file using afplay
afplay "$temp_audio_file"

# Clean up the temporary audio file when you're done with it
rm "$temp_audio_file"
