# Unicode fridge-item trimming

Status: Completed

## Problem

`String.trim()` removes only characters at or below U+0020. Tablet input padded
with Unicode spaces such as EM SPACE or NO-BREAK SPACE therefore persisted
visually blank padding around an otherwise valid fridge item.

## Fix

- Trim leading and trailing Unicode whitespace and space characters by code
  point after line separators are normalized.
- Preserve internal spaces, combining marks, variation selectors, and emoji
  joiners.
- Add a red-first dependency-free host assertion covering both EM SPACE and
  NO-BREAK SPACE.

## Validation

- Run the focused item-store host test.
- Run the complete repository Make gate and hosted Gradle/CodeQL checks.
