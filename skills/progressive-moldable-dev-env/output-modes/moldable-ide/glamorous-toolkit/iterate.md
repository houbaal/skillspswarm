# Glamorous Toolkit — Generate & Iterate

## Generate a view

### Step 1: Analyze the project

Scan the current project to understand:
- Language/framework (Kotlin/Spring, Java/Maven, TypeScript, Python, etc.)
- Structural units (modules, packages, classes, endpoints)
- Relationships (imports, dependencies, inheritance)

### Step 2: Generate the .st file

Write the Smalltalk code following the rules in `codegen/st-generation.md`.

Save to: `<project>/moldable-views/gt/<view-name>.st`

Add the Question/Answer header (standard moldable-dev convention):

```smalltalk
"Question: <what decision does this view inform?>
 Answer:   [pending]
 Why:      <what blind spot does this address?>"
```

### Step 3: Launch GT

```bash
GT_DIR=~/.gt  # or wherever GT was detected
cd "$GT_DIR" && ./GlamorousToolkit.app/Contents/MacOS/GlamorousToolkit-cli \
    GlamorousToolkit.image --interactive eval --no-quit \
    "Smalltalk compiler evaluate: ('/absolute/path/to/view.st' asFileReference contents)" &
```

**Critical rules**:
- You MUST `cd` into the GT install directory before running the CLI
- Use ABSOLUTE paths in the Smalltalk string for the .st file
- The `&` runs GT in background so the terminal stays usable

### Step 4: Guide the user

Tell them:
- GT should open with an Inspector window
- List the custom tab names you created
- What to look for in each tab
- "Click any item to drill down" (Inspector navigation)
- "Cmd+Tab to switch back here when done"

Then ask: *"What do you see? Any new questions from the visualization?"*

## Iterate on an existing view

1. Kill GT: `pkill -f GlamorousToolkit`
2. Modify the `.st` file
3. Relaunch (same command as Step 3 above)
4. Tell the user what changed
