# Oracles: How to Judge Results (FEW HICCUPPS)

An **oracle** is a principle for deciding if what you observe is correct.
Use Bolton & Bach's FEW HICCUPPS mnemonic to evaluate behavior:

| Oracle              | Question to ask                                                        |
|---------------------|------------------------------------------------------------------------|
| **F**amiliar        | Does this feel right based on my experience with similar apps?         |
| **E**xplainability  | Can I explain why it behaves this way? If not, investigate.            |
| **W**orld           | Does this match how things work in the real world?                     |
| **H**istory         | Did this work differently before? Has a regression occurred?           |
| **I**mage           | Does this match the brand/UX quality the product aims for?             |
| **C**omparable      | How do similar products handle this? Is our behavior reasonable?       |
| **C**laims          | Does this match what the spec/acceptance criteria say should happen?   |
| **U**ser expectations| Would a real user be confused by this behavior?                       |
| **P**roduct         | Is this consistent with other parts of the same product?               |
| **P**urpose         | Does this serve the purpose the feature was built for?                 |
| **S**tandards       | Does this violate platform conventions (Material, iOS HIG, WCAG)?      |

**Use at least 2 oracles per evaluation.** A single oracle can miss bugs
that another would catch. "Claims" (spec) + "User expectations" (real user)
is a strong default combination.
