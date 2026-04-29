# Kaizen ADHD System: Final Technical Implementation Plan

We are building a frictionless **Dump -> Organize -> Work** workflow powered by a unified, agentic AI base using Gemini and `llm_json_stream`.

## 1. Sprints Tab: The Command Center
- [ ] **Main Goal Entry**: A prominent, custom text field at the top of the Sprints Tab for the day's primary objective.
- [ ] **Automated Archiving**: A logic trigger that archives all finished tasks at the start of a new calendar day.
- [ ] **Existing Folders**: Maintain `Deep Work`, `Urgent`, and `Quick` as the primary "Energy Check-in" prompts.

## 2. Audio-First Brain Dump (Gemini-Powered)
- [ ] **Audio Entities**:
    - Treat audio recordings as standalone items in the database.
    - **Internal Transcription**: Use Gemini to generate word-for-word transcriptions with **timestamps** (to enable "subtitle" style playback).
    - **Interpretations**: Use Gemini (with app context) to generate descriptive summaries and metadata.
- [ ] **Frictionless Submission**: One-tap recording in the `BrainDumpInput`.

## 3. The Unified AI Agent Base
This is the core "Brain" that powers the Notes Interpreter and the Assistant Chat.

### A. The Agentic Loop & Logic
- [ ] **Loop Mechanics**: Logic to manage multi-step reasoning (e.g., "Analyze dump -> Search for context -> Suggest tasks").
- [ ] **Model Awareness**: System prompts to ensure the LLM handles tool calls and final responses correctly.

### B. Tools (The Agent's "Hands")
- [ ] **CRUD Suite**: Full Create/Read/Update/Delete capabilities for Brain Dump items, Notes, and Tasks/Sprints.
- [ ] **Context Fetchers**: Specialized tools for deep-searching app state.

### C. Output Visualizer (Realtime JSON)
- [ ] **`llm_json_stream` Integration**:
    - Use the `llm_json_stream` package to parse JSON reactively as it streams from Gemini.
    - Renders rich widgets (confirmation dialogs, task cards, thinking blocks) in realtime.

### D. Prompting & Execution
- [ ] **Strict JSON Formatting**: Ensure model outputs adhere to the visualizer's schema.
- [ ] **Execution Handler**: Intercept tool calls, execute locally, and feed results back.

## 4. Automated Context Grabbing (Edge Cases)
We will inject context automatically for:
- **Recency**: "What did I just finish?" (Last 5 archived tasks).
- **Temporal**: "When is my next deadline?" (Current time + upcoming 3 days).
- **Spatial**: "Where am I?" (Active tab ID).
- **Energy**: "What should I do now?" (Current session state + folder counts).

---

## Verification Plan
- **Audio Flow**: Record note -> Verify Gemini generates transcription with correct timestamps.
- **Visualizer**: Verify `llm_json_stream` correctly renders partial JSON tokens into UI widgets.
- **Agent Loop**: Verify the model can execute a multi-tool chain (e.g., "Find notes about X and archive task Y").

---

## Verification Plan
- **Agent Loop**: Verify the model can successfully "think" through a complex request like "Find my notes about taxes and turn them into Urgent tasks."
- **Visualizer**: Ensure JSON outputs from the model render as the intended Flutter widgets.
- **Archiving**: Set system time to midnight and verify finished tasks are archived.
