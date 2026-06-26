# Combining-Mark-Only Item Design

## Context

The shared item policy rejects whitespace, format characters, and selected
default-ignorable marks when they are the only content in a fridge item. Other
Unicode combining marks were still counted as visible content, allowing rows
made only from accents or enclosing marks even though those code points are
intended to modify a base character.

## Decision

Treat the three Unicode mark categories (`NON_SPACING_MARK`,
`COMBINING_SPACING_MARK`, and `ENCLOSING_MARK`) as non-visible when deciding
whether an item has a visible base. Keep them valid when any other visible code
point is present, preserving decomposed text and emoji sequences such as
keycaps.

## Verification

Add a dependency-free host regression for combining-mark-only rejection and
positive coverage for decomposed text and keycap emoji. Extend the static
baseline and hostile mutation suite so removing the category check or its
regression is rejected.
