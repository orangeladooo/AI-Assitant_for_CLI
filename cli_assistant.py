import io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
import subprocess
import requests
import json
import os
import sys
from dotenv import load_dotenv
load_dotenv()
OLLAMA_URL  = os.getenv("OLLAMA_URL")

MODEL_NAME =os.getenv("MODEL_NAME")

class CLIAssistant:
    """The zero-cost, local AI engine for command generation."""

    def __init__(self):
        self.ollama_url = OLLAMA_URL
        self.model = MODEL_NAME
        
        # Enhanced System Prompt: CRITICAL for strict command output and 'cd' detection.
        prompt_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "system_prompt.txt")
        if os.path.exists(prompt_path):
            try:
                with open(prompt_path, "r", encoding="utf-8") as f:
                    self.system_prompt = f.read().strip()
            except Exception as e:
                print(f"Warning: Could not read system_prompt.txt: {e}", file=sys.stderr)
                self._set_default_system_prompt()
        else:
            self._set_default_system_prompt()

    def _set_default_system_prompt(self):
        self.system_prompt = (
            "You are an expert command-line assistant running on a shell. "
            "Your task is to translate a user's natural language request into a single, "
            "executable shell command (Unix/Linux/Windows). "
            "You MUST provide ONLY the raw, executable command, with NO explanation, NO comments, and NO code block markers."
        )

    def _get_context(self) -> str:
        """Gathers environmental context for the AI."""
        
        platform = 'Windows (PowerShell/CMD)' if sys.platform.startswith('win') else 'Linux/Unix (Bash/Zsh)'
        shell = os.environ.get('SHELL', os.environ.get('COMSPEC', 'Unknown Shell'))
        
        return f"OS: {platform}\nCurrent Working Directory: {os.getcwd()}\nUser's Shell: {shell}"

    def _call_ollama(self, user_request: str) -> str:
        """Calls the local Ollama server to get a command suggestion."""
        
        context = self._get_context()
        
        full_prompt = (
            f"SYSTEM INSTRUCTION: {self.system_prompt}\n\n"
            f"ENVIRONMENT CONTEXT: {context}\n\n"
            f"USER REQUEST: {user_request}"
        )
        
        payload = {
            "model": self.model,
            "prompt": full_prompt,
            "stream": False,
            "options": {"temperature": 0.1}
        }

        try:
            response = requests.post(self.ollama_url, json=payload, timeout=45)
            response.raise_for_status() 
            
            data = response.json()
            generated_text = data.get('response', '').strip()
            
            # Clean up common LLM artifacts (e.g., removing markdown fences)
            if generated_text.startswith('`'):
                generated_text = generated_text.strip('`').strip()
            if generated_text.lower().startswith(('bash', 'zsh', 'sh', 'powershell')):
                 generated_text = ' '.join(generated_text.split()[1:])

            return generated_text.strip()
            
        except requests.exceptions.RequestException as e:
            # Print error to stderr so stdout remains clean for the shell function
            print(f"\n❌ AI Connection Error: Ensure Ollama is running and model '{self.model}' is pulled. Details: {e}", file=sys.stderr)
            return "Error: AI Connection Failed."
        except Exception as e:
            print(f"Error: Unexpected model error: {e}", file=sys.stderr)
            return "Error: Unexpected Model Failure."

    def handle_direct_request(self, user_request: str):
        """Processes a request passed directly from the terminal alias."""
        
        generated_command = self._call_ollama(user_request)

        if generated_command.startswith("Error") or not generated_command:
            return


        # 2. Confirmation and Execution (for all non-cd commands)
        print("\n\n⭐ AI Suggested Command (Review Carefully!):")
        print(f"   >>> {generated_command}")
        print("-" * 30)

        confirmation = input("❓ Execute this command? (y/n): ").strip().lower()

        if confirmation == 'y':
            print("\n🚀 Executing...")
            try:
                subprocess.run(generated_command, shell=True, check=True, text=True, capture_output=False)
                print("\n✅ Command Finished.")
            except subprocess.CalledProcessError as e:
                print(f"\n❌ Command failed with return code {e.returncode}.")
            except Exception as e:
                print(f"\n❌ Execution Error: {e}")
        else:
            print("\n🛑 Command execution cancelled by user.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: askai <your natural language command>", file=sys.stderr)
        sys.exit(1)
        
    request = " ".join(sys.argv[1:]) 
    assistant = CLIAssistant() 
    assistant.handle_direct_request(request)
