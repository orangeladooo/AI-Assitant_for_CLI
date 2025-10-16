# AskAI CLI Assistant 🤖

**The local, zero-cost command-line assistant powered by Ollama and Llama 2.**

AskAI translates your natural language questions into executable shell commands, providing a safe, confirmed execution environment right in your terminal.

---

## ✨ Features

* **Local & Private:** Runs entirely on your machine using the **Ollama** server (no external API keys or costs).
* **OS-Aware Context:** Gathers context (OS, shell, current directory) to suggest the correct command (e.g., `tasklist` on Windows, `ps aux` on Linux).
* **Safe Execution:** Requires user confirmation before executing any suggested command, preventing accidental changes.
* **State-Changing Support:** Handles complex commands like `cd` (change directory) by executing them directly in the current shell session.
* **Cross-Platform:** Includes setup scripts for **Bash/Zsh (Linux/macOS)** and **PowerShell (Windows)**.

---

## 🚀 Installation & Setup

### Prerequisites

1.  **Python 3:** Ensure Python is installed and accessible via the `python3` command.
2.  **Ollama:** Install and start the [Ollama server](https://ollama.com/download).
3.  **Model:** Pull the required model for the script to use. This is configured in your code as `codellama:7b-instruct`.
    ```bash
    ollama pull codellama:7b-instruct
    ```

### Step 1: Clone and Prepare

Clone the repository and install the necessary Python dependencies.

```bash
# Clone the repository
git clone [https://github.com/YourUsername/askai.git](https://github.com/YourUsername/askai.git)
cd askai

# Install dependencies (only 'requests' is required)
pip install -r requirements.txt