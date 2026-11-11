# Smalltalk Code Generation Rules

## The Template

Every generated `.st` file MUST follow this structure:

```smalltalk
"Question: <what decision does this view inform?>
 Answer:   [pending]
 Why:      <what blind spot does this address?>"

| cls |
Object subclass: #<ClassName>
    instanceVariableNames: '<space-separated field names>'
    classVariableNames: ''
    package: 'GTVibes'.
cls := Smalltalk globals at: #<ClassName>.

"--- Data accessors ---"
cls compile: '<accessor methods>'.

"--- Views ---"
cls compile: '<gtView method>'.

"--- Launch ---"
GtWorld open.
cls new inspect
```

## Iron Rules

1. **Dynamic class lookup**: ALWAYS use `cls := Smalltalk globals at: #ClassName` after the `subclass:` call. NEVER reference the class name directly — the Pharo compiler resolves names at compile time, before the class exists.

2. **Quote escaping**: inside `compile:` string arguments, every single quote becomes TWO single quotes. Example: `cls compile: 'name ^ ''hello'''` defines a method returning the string `'hello'`.

3. **One method per compile**: each `cls compile:` call defines exactly one method. Do not try to batch.

4. **`<gtView>` pragma is mandatory**: every Inspector view method MUST include the `<gtView>` pragma. Without it, the Inspector will not discover the view.

5. **Return the view builder**: view methods MUST return `^ aView <viewType> title: ...; ...`

6. **Use `Smalltalk compiler evaluate:`**: to load from file. NEVER use `fileIn` (it uses chunk format with `!` separators, incompatible with script-style code).

## View Types Reference

### list — Simple item collection

```smalltalk
cls compile: 'gtItemsFor: aView
    <gtView>
    ^ aView list
        title: ''Items'';
        priority: 1;
        items: [ self items ];
        itemText: [ :each | each printString ]'.
```

### columnedList — Multi-column table

```smalltalk
cls compile: 'gtTableFor: aView
    <gtView>
    ^ aView columnedList
        title: ''Modules'';
        priority: 1;
        items: [ self modules ];
        column: ''Name'' text: [ :m | m at: #name ];
        column: ''Dependencies'' text: [ :m | (m at: #deps) size printString ];
        column: ''Lines'' text: [ :m | (m at: #loc) printString ]'.
```

### textEditor — Text content display

```smalltalk
cls compile: 'gtSummaryFor: aView
    <gtView>
    ^ aView textEditor
        title: ''Summary'';
        priority: 2;
        text: [ self description ]'.
```

### tree — Hierarchical data

```smalltalk
cls compile: 'gtTreeFor: aView
    <gtView>
    ^ aView tree
        title: ''File Tree'';
        priority: 1;
        items: [ self rootDirs ];
        children: [ :each | each children ];
        itemText: [ :each | each name ]'.
```

### mondrian — Graph visualization

```smalltalk
cls compile: 'gtGraphFor: aView
    <gtView>
    ^ aView mondrian
        title: ''Dependencies'';
        priority: 1;
        painting: [ :m |
            m nodes
                shape: [ :mod |
                    BrLabel new
                        aptitude: (BrGlamorousLabelAptitude new foreground: Color white);
                        text: mod;
                        padding: (BlInsets all: 8);
                        background: (Color fromHexString: ''4A90D9'');
                        geometry: (BlRoundedRectangleGeometry cornerRadius: 6) ];
                with: self modules.
            m edges
                shape: [
                    BlLineElement new
                        border: (BlBorder paint: (Color gray alpha: 0.5) width: 1.5);
                        toHead: (BlArrowheadSimpleArrow new
                            border: (BlBorder paint: Color gray width: 1.5)) ];
                connect: self edges from: [ :e | e at: #from ] to: [ :e | e at: #to ].
            m layout force ]'.
```

### forward — Delegate to another object's views

```smalltalk
cls compile: 'gtDetailsFor: aView
    <gtView>
    ^ aView forward
        title: ''Details'';
        priority: 3;
        object: [ self innerObject ];
        view: #gtLiveFor:'.
```

## Array Syntax

- **Literal arrays** (compile-time, only symbols/numbers/strings): `#(''a'' ''b'' ''c'')`
- **Dynamic arrays** (runtime, any expression): `{ expr1 . expr2 . expr3 }`
- **OrderedCollection**: `OrderedCollection withAll: { ... }`

## Data Loading Patterns

### Scan files from disk

```smalltalk
cls compile: 'scanModules
    | root |
    root := ''/absolute/path/to/project/src'' asFileReference.
    ^ root directories collect: [ :dir | dir basename ]'.
```

### Parse file contents

```smalltalk
cls compile: 'scanImports: aFile
    | content lines |
    content := aFile contents.
    lines := content lines select: [ :l | l includesSubstring: ''import'' ].
    ^ lines collect: [ :l | l trim ]'.
```

### Build dictionaries for structured data

```smalltalk
cls compile: 'buildModule: name deps: deps
    ^ { #name -> name. #deps -> deps } asDictionary'.
```
