# Desktop App

## When to use

When your views have grown beyond what a browser tab or terminal can manage. You have multiple views that relate to each other, you want persistent state between sessions, direct file system access, or proper windowing with panels and tabs.

This is a natural evolution when a project accumulates many moldable views and you want a unified shell to navigate them — without going all the way to a moldable IDE (GT).

**Move here when:**
- You have 5+ views that you regularly use together
- You need persistent layout (which panels are open, which views are pinned)
- You want offline access or direct file system integration
- Browser tabs are becoming unwieldy for view navigation

**Don't move here prematurely.** Web views (served locally) cover most needs. A desktop app adds build/packaging complexity. Make sure you've outgrown web views first.

---

## Candidates

### Tauri (Rust + web frontend)

| Aspect       | Detail                                                                |
|--------------|-----------------------------------------------------------------------|
| Architecture | Rust backend + any web frontend (HTML/JS, React, Svelte, etc.)       |
| Binary size  | ~3-10 MB (much smaller than Electron)                                |
| System access| Full native APIs via Rust plugins                                    |
| Strengths    | Lightweight, secure by default, reuse existing web views             |
| Weaknesses   | Rust backend requires Rust knowledge for native plugins              |

**Best fit:** if your web views already work and you want to wrap them in a native shell with file system access, tray icon, and proper windowing. Your existing HTMX/SSR views can run inside Tauri with minimal changes.

### Electron (Node.js + Chromium)

| Aspect       | Detail                                                                |
|--------------|-----------------------------------------------------------------------|
| Architecture | Node.js backend + Chromium renderer                                  |
| Binary size  | ~150+ MB                                                             |
| System access| Full Node.js APIs                                                    |
| Strengths    | Largest ecosystem, most documentation, AI generates Electron fluently |
| Weaknesses   | Heavy, high memory usage, bundles entire Chromium                    |

**Best fit:** when you need maximum ecosystem support and don't care about binary size. VS Code, Obsidian, and Slack are Electron apps — it works at scale.

### Native GUI (stack-specific)

| Stack        | Framework                    | Notes                                              |
|--------------|------------------------------|----------------------------------------------------|
| Kotlin/JVM   | JavaFX, Compose Desktop     | Same language as your domain objects               |
| C#/.NET      | WPF, MAUI, Avalonia         | Roslyn analysis + native GUI in the same runtime   |
| Python       | tkinter, PyQt, Dear PyGui   | Quick prototyping, `uvx` for dependency management |
| Go           | Fyne, Gio                   | Single binary, cross-platform                      |
| Swift        | SwiftUI                     | macOS only, but excellent integration              |

**Best fit:** when your project's language has a good GUI framework and you want the desktop app to use the same runtime as your domain objects — enabling live object inspection without serialization boundaries.

---

## Architecture

```
Your existing analysis scripts/tools
         ↓
   JSON intermediate representation
         ↓
   Desktop app shell
   ├── View panel 1 (reused web view or native widget)
   ├── View panel 2
   ├── Navigation sidebar (entity list, search)
   └── Inspector panel (drill into selected entity)
```

The key insight: you don't rebuild your views for the desktop app. You reuse them. If your views are web-based (HTMX/SSR), Tauri or Electron can host them directly. If your views are terminal scripts, the desktop app can embed a terminal or convert their JSON output to native widgets.

---

## Connection to the Question/Answer Cycle

A desktop app is where views stop being disposable and start becoming **durable instruments**. The question/answer cycle still applies — you still build new views for new questions — but the desktop app becomes the place where proven, repeatedly-useful views accumulate.

Think of it as the difference between a lab bench (individual experiments = terminal/web views) and a control room (consolidated instruments = desktop app). You still run experiments, but the instruments that proved their worth get promoted to the control room.
