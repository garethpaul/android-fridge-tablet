# Fridge Unicode-Visible Items

## Status: Completed

## Context

The shared item policy used `String.trim()` and rejected control and selected
bidirectional characters, but Unicode separators, format characters, and
default-ignorable combining marks such as variation selectors could still form
a persisted item that rendered as a blank row.

## Design

The item validity loop now records whether at least one code point is neither
Unicode whitespace, a Unicode space character, a format character, nor one of
Unicode's default-ignorable combining marks: the combining grapheme joiner,
Mongolian free variation selectors, and the general variation-selector ranges.
This keeps validation at the shared input and file-read boundary. It does not
strip or rewrite accepted text, and joined emoji remain valid because their
visible emoji code points satisfy the predicate even when a zero-width joiner
or variation selector is present.

Regex normalization and broad removal of format characters were rejected:
the former duplicates the code-point policy, while the latter would alter
valid emoji and language text instead of only rejecting blank-looking rows.

## Work Completed

- Added the shared Unicode-visible-content predicate to `ItemPolicy`.
- Added host regressions for separator/format-only text and joined emoji.
- Added static and hostile-mutation contracts plus synchronized documentation.

## Verification

- `scripts/test-item-store.sh`
- `/usr/bin/make check`
- `git diff --check`

## Scope Boundaries

- Existing UTF-8 byte, item-count, aggregate-size, control-character, and
  bidirectional-control limits are unchanged.
- Accepted item text is preserved byte-for-byte after the existing CR/LF
  replacement and `trim()` behavior.
