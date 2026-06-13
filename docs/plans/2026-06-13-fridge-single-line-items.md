# Fridge Single-Line Item Persistence

Status: Planned

## Priority

Fridge items are stored with Commons IO `writeLines()` and restored with
`readLines()`, so one collection item must correspond to one persisted line.
The current input normalizer trims only the ends of the text. A pasted carriage
return or newline can therefore make one submitted item reload as multiple
items, changing the user's list across process restarts.

## Requirements

- **R1:** Replace carriage returns and newlines in submitted item text with
  spaces before trimming and persistence.
- **R2:** Preserve all other item text, empty-input rejection, rollback,
  UTF-8, atomic-write, read-failure, logging, and UI behavior.
- **R3:** Add an SDK-free static contract that binds normalization to the item
  input helper and rejects raw line separators.
- **R4:** Document the one-item-per-line persistence boundary and record
  completed local, external-directory, mutation, and hosted verification.

## Implementation Units

### U1: Normalize Persisted Item Boundaries

**File:** `app/src/main/java/garethpaul/com/fridge/MainActivity.java`

Convert carriage-return and newline characters to spaces before trimming the
submitted item text.

### U2: Protect The Contract

**File:** `scripts/check-baseline.sh`

Require both separator replacements in `normalizedItemText()`, preserve the
existing null and trim behavior, and require completed plan and documentation
evidence.

### U3: Document And Verify

**Files:** `AGENTS.md`, `README.md`, `SECURITY.md`, `VISION.md`, `CHANGES.md`,
`docs/plans/2026-06-13-fridge-single-line-items.md`

Describe the line-oriented persistence boundary and record exact verification.

## Test Scenarios

- Plain single-line text remains unchanged except for existing edge trimming.
- `milk\ncheese`, `milk\rcheese`, and CRLF input persist as one item.
- Null or empty input remains rejected.
- Removing either separator replacement, trim/null guards, guidance, or plan
  completion fails verification.

## Scope Boundaries

- Do not change the file name, encoding, item ordering, visible layout,
  dependencies, Android/Gradle versions, or storage failure behavior.
- Do not claim keyboard, clipboard, emulator, or device behavior without a
  compatible runtime.

## Verification

Pending implementation and execution.

## Sources

- Apache Commons IO `FileUtils` API (`writeLines` writes collection entries line
  by line and `readLines` restores a list of file lines):
  https://commons.apache.org/proper/commons-io/apidocs/org/apache/commons/io/FileUtils.html
- Android `EditText.getText()` API:
  https://developer.android.com/reference/android/widget/EditText#getText()
