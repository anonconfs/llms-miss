#!/bin/bash
#
# gpt-httpd: An HTTP server that uses Ollama to simulate HTTP/1.1 responses
#

# This is the main server script

# Configuration
PORT=8080
OLLAMA_MODEL="llama3"  # Default Ollama model
OLLAMA_URL="http://localhost:11434/api/chat"  # Ollama API URL
LOG_FILE="gpt-httpd.log"

# Check if Ollama is installed and running
if ! command -v ollama &> /dev/null; then
    echo "Error: Ollama command not found. Please install it first."
    echo "Visit https://ollama.com to install Ollama"
    exit 1
fi

# Check if Ollama is running
if ! curl -s "http://localhost:11434/api/tags" &> /dev/null; then
    echo "Error: Ollama server is not running. Please start it with 'ollama serve'."
    exit 1
fi

# Check if selected model is available
if ! curl -s "http://localhost:11434/api/tags" | grep -q "\"$OLLAMA_MODEL\""; then
    echo "Warning: Model '$OLLAMA_MODEL' might not be available in Ollama."
    echo "Attempting to pull the model now..."
    ollama pull $OLLAMA_MODEL
fi

# Ensure log file exists
touch "$LOG_FILE"

echo "Starting GPT-HTTPd server on port $PORT..."
echo "Logs will be written to $LOG_FILE"
echo "Press Ctrl+C to stop the server."

function handle_request() {
    # Read the HTTP request
    local request=""
    while IFS= read -r line; do
        request="${request}${line}\n"
        if [[ $line == $'\r' || $line == "" ]]; then
            # End of headers
            break
        fi
    done

    # Get content length if present
    local content_length=$(echo -e "$request" | grep -i "Content-Length:" | awk '{print $2}' | tr -d '\r')
    
    # Read request body if Content-Length is specified
    if [[ -n "$content_length" ]]; then
        local body=""
        local read_chars=0
        while [[ $read_chars -lt $content_length ]]; do
            IFS= read -r -n1 char
            body="${body}${char}"
            ((read_chars++))
        done
        request="${request}\n${body}"
    fi
    
    # Log the request
    echo -e "$(date): Received request:\n$request" >> "$LOG_FILE"
    
    # Prepare the prompt for ChatGPT - escape special characters for JSON
    local prompt="You are a web server that understands HTTP/1.1. Please respond to the following HTTP request with a valid HTTP/1.1 response. For now, just return a simple 'Hello, World!' HTML page. Make sure to include all necessary HTTP headers, status code, and the HTML content. DO NOT include any explanation, commentary, or additional text. I want ONLY the raw HTTP response that would be sent over the wire. Here is the HTTP request: $request"
    
    # Escape JSON special characters
    prompt=$(echo "$prompt" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed 's/\n/\\n/g' | sed 's/\r/\\r/g' | sed 's/\t/\\t/g')
    
    # Create JSON payload for Ollama
    local ollama_payload='{
  "model": "'$OLLAMA_MODEL'",
  "messages": [
    {
      "role": "system",
      "content": "You are a web server that understands HTTP/1.1. Your responses should be valid HTTP/1.1 responses."
    },
    {
      "role": "user",
      "content": "'$prompt'"
    }
  ],
  "stream": false
}'
    # Make API call to Ollama
    echo "$(date): Using Ollama with model $OLLAMA_MODEL" >> "$LOG_FILE"
    local response=$(curl -s -X POST "$OLLAMA_URL" \
        -H "Content-Type: application/json" \
        -d "$ollama_payload")
    
    # Log raw response for debugging
    echo "$(date): Raw Ollama response: $response" >> "$LOG_FILE"
    
    # Check if response is valid JSON
    if ! echo "$response" | grep -q '"content"'; then
        echo "$(date): Error: Invalid response from Ollama" >> "$LOG_FILE"
        # Fallback response if Ollama fails
        local http_response="HTTP/1.1 500 Internal Server Error
Content-Type: text/html
Connection: close

<html>
<head><title>500 Internal Server Error</title></head>
<body>
<h1>Internal Server Error</h1>
<p>The server encountered an error processing your request. Ollama returned an invalid response.</p>
</body>
</html>"
    else
        # Extract the response content from Ollama's response format
        local raw_content=$(echo "$response" | grep -o '"content":"[^"]*"' | head -1 | sed 's/"content":"//;s/"$//')
        
        # Decode escaped characters
        local decoded_content=$(echo "$raw_content" | sed 's/\\n/\n/g;s/\\r/\r/g;s/\\"/"/g')
        
        # Extract only the HTTP response part - looking for "HTTP/1.1" followed by status code
        if echo "$decoded_content" | grep -q "HTTP/1.1"; then
            # Take everything from HTTP/1.1 onwards
            http_response=$(echo "$decoded_content" | sed -n '/HTTP\/1\.1/,$p')
            
            # Fix escaped HTML entities
            http_response=$(echo "$http_response" | sed 's/\\u003c/</g' | sed 's/\\u003e/>/g')
            
            echo "$(date): Successfully extracted HTTP response" >> "$LOG_FILE"
        else
            # Fallback to a simple response if no valid HTTP response found
            echo "$(date): No valid HTTP/1.1 response in Ollama output" >> "$LOG_FILE"
            http_response="HTTP/1.1 200 OK
Content-Type: text/html
Connection: close

<html><body><h1>Hello, World!</h1><p>Generated by gpt-httpd using Ollama</p></body></html>"
        fi
    fi
    
    # Log the response
    echo -e "$(date): Sending response:\n$http_response" >> "$LOG_FILE"
    
    # Send the response back to the client
    echo -e "$http_response"
}

# Function to handle server shutdown
function cleanup() {
    echo -e "\nShutting down GPT-HTTPd server..."
    echo "$(date): Server shutting down" >> "$LOG_FILE"
    # Kill any background processes
    jobs -p | xargs -I{} kill {} 2>/dev/null
    exit 0
}

# Register the cleanup function to be called on script exit
trap cleanup SIGINT SIGTERM

# Main server loop using ncat for persistent connections
echo "$(date): Server started on port $PORT" >> "$LOG_FILE"

# Check if ncat is available (in macOS, it might be available via Homebrew)
if command -v ncat &> /dev/null; then
    echo "Using ncat for HTTP connections (persistent connections)"
    echo "$(date): Starting ncat server on port $PORT in keep-alive mode" >> "$LOG_FILE"
    
    # Start ncat in keep-open mode with our AI handler script
    ncat -l $PORT --keep-open --exec ./gpt-httpd-handler.sh
    
    # If ncat exits, log it
    echo "$(date): ncat server exited with code $?" >> "$LOG_FILE"
else
    echo "Warning: ncat not found. Falling back to basic nc (connections won't persist)"
    echo "$(date): ncat not found, using basic nc" >> "$LOG_FILE"
    
    echo "For better stability, install ncat (Nmap Netcat):"
    echo "  brew install nmap  # Includes ncat"
    
    # Main server loop using basic netcat
    echo "$(date): Server ready, waiting for connections..." >> "$LOG_FILE"
    
    while true; do
        echo "$(date): Waiting for connection on port $PORT..." >> "$LOG_FILE"
        nc -l $PORT | handle_request
        echo "$(date): Connection handled" >> "$LOG_FILE"
    done
fi
