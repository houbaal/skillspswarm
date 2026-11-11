# Anomaly Detection & Oracles

## Anomaly Detection

### Certain bugs (always report)
- Crash (fatal exception, error 500, blank page).
- Exception in console logs (even non-fatal).
- Unexpected empty/black screen.

### Probable bugs (report with context)
- Action without feedback (click -> nothing happens).
- Infinite loading (> 10 seconds without change).
- Data lost after navigation.
- Technical error message shown to the user.
- Broken layout (overlaps, clipped text).
- Button active when it should be disabled.
- **State mismatch**: UI shows X, but database/network/console shows Y.

## Anti-dismiss guard (MANDATORY)
When tempted to write "not a real issue", STOP and ask:
1. **Did I verify in the code/docs** that this behavior is expected?
2. **Would a real user be surprised** by this behavior?
3. **Is this documented** anywhere as intentional?

If you cannot answer YES to at least 2, **report it as an observation**.

## Oracles: FEW HICCUPPS
| Oracle              | Question to ask                                                        |
|---------------------|------------------------------------------------------------------------|
| **F**amiliar        | Does this feel right based on my experience?                           |
| **E**xplainability  | Can I explain why it behaves this way?                                 |
| **W**orld           | Does this match how things work in the real world?                     |
| **H**istory         | Did this work differently before?                                      |
| **I**mage           | Does this match the brand/UX quality aimed for?                        |
| **C**omparable      | How do similar products handle this?                                   |
| **C**laims          | Does this match what the spec/AC say?                                  |
| **U**ser expectations| Would a real user be confused?                                        |
| **P**roduct         | Is this consistent with other parts of the product?                    |
| **P**urpose         | Does this serve the purpose it was built for?                          |
| **S**tandards       | Does this violate platform conventions?                                |
