**Personal Application (PA)**

A cognitive operating system built for one user. Designed to minimize friction
between thought and action, and to run productivity experiments without guilt.

---

**What it is**

PA is a Windows background application that lives behind a global
keybind—summoned like the Start menu, dismissed instantly. No window management,
no visible productivity theater. Just a sidepanel when you need it, gone when
you don't.

Built in Flutter. Public repo exists solely for unlimited GitHub Actions
compute. Not a product. If someone finds it useful, they can fork it.

---

**Core Philosophy**

Your brain has specific requirements for engagement. PA doesn't try to fix
you—it learns how you work, then builds the machine that produces that state.

---

**Architecture**

**AI Layer**

- One master LLM with context-aware permissions
- Tab-shortcuts control scope: `@simple` (chat only), `@sprints-noactions`
  (read-only sprints), `/caveman` (shorter responses)
- Customization layer: add new triggers and tool wiring without code changes
- Specialized AI instances per tab, or master LLM with auto-permissions per
  context

**Data Flow**

- **Brain Dump**: Low-effort input (screenshots, voice, text). AI auto-extracts
  context and suggests next steps.
- **Organized Base**: Processed dump items—todos, lists, notes, prompts, quotes.
- **Sprint System**: Task batches ordered by preference, with experimental
  structures (low→high friction, total freedom→hard deadlines, etc.). Tasks
  completed get logged with frictionless feedback.
- **Logs**: Progress tracking for motivation ("proud, continue") or pressure
  ("don't lose this streak").
- **Dashboard**: Canvas LMS, GDocs API, other integrations—data and visuals, not
  workflows.
- **Toolkit**: Convenience scripts (auto-fetch Canvas modules to PDF study
  sheets, etc.).

---

**Current Status**

Building AI infrastructure first. Sprint system definition has too much friction
right now—will emerge from usage patterns instead of upfront design.
