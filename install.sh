#!/bin/bash

# --- AI CLI Assistant Setup for Bash/Zsh ---

echo "--- Starting AskAI CLI Setup (Linux/Unix) ---"

# 1. Define the full path to the Python script (Uses current working directory)
PYTHON_SCRIPT_PATH="$(pwd)/cli_assistant.py"

if [ ! -f "$PYTHON_SCRIPT_PATH" ]; then
    echo "Error: cli_assistant.py not found at $PYTHON_SCRIPT_PATH"
    exit 1
fi

# 2. The shell function to be injected
SHELL_FUNCTION='
# --- AI CLI Assistant (askai) ---
# Executes the Python script and handles state-changing commands (like cd).
askai() {
    # 1. Run the Python script and capture output
    OUTPUT=$(/usr/bin/env python3 "'"$PYTHON_SCRIPT_PATH"'" "$@")
    
    # 2. Check for the special execution token for state changes
    if [[ "$OUTPUT" == *__EXEC_COMMAND__* ]]; then
        # Extract the command (must be on a line starting with the token)
        COMMAND=$(echo "$OUTPUT" | grep "__EXEC_COMMAND__" | sed 's/.*__EXEC_COMMAND__://')
        
        # Print non-command output
        echo "$OUTPUT" | grep -v "__EXEC_COMMAND__"
        
        # 3. Execute the command directly in the CURRENT SHELL
        eval "$COMMAND"
    else
        # 4. Print all output for non-cd commands (includes confirmation prompt)
        echo "$OUTPUT"
    fi
}
# ------------------------------
'

# 3. Determine the user's primary shell configuration file
if [[ "$SHELL" =~ "zsh" ]]; then
    RC_FILE="$HOME/.zshrc"
elif [[ "$SHELL" =~ "bash" ]]; then
    RC_FILE="$HOME/.bashrc"
else
    echo "Warning: Unsupported shell. Please manually add the 'askai' function to your shell profile."
    RC_FILE=""
fi

if [ -n "$RC_FILE" ]; then
    echo "Targeting shell file: $RC_FILE"
    
    if grep -q "askai() {" "$RC_FILE"; then
        echo "Function already exists. Skipping injection."
    else
        echo -e "$SHELL_FUNCTION" >> "$RC_FILE"
        echo "✅ 'askai' is installed! Run 'source $RC_FILE' or open a new terminal to start."
        echo "Usage: askai <your request>"
    fi
fi