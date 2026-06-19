# Fridge Tablet Device Verification

## 2026-06-19 persistence follow-up

The host suite verifies strict decoding, size and item limits, symlink
rejection, owner-only file hardening, backup validation, and serialized
UI-model commits. The checked-in instrumentation test covers an internal-files
round trip on Android, but it has not been run on a physical tablet here.

Device validation must still exercise process death and power loss during each
write phase (temporary write, sync, target-to-backup rename, and install), then
confirm the next launch shows either the complete previous list or the complete
new list. It must also inspect the app sandbox permissions and test low-storage,
read-only, and filesystem-error behavior without exposing item contents in logs.

Run this matrix on the exact reviewed commit with a compatible Android SDK,
Java 8, legacy Gradle runtime, and authorized emulator or tablet. Portable
contracts do not substitute for real app-private storage evidence.

## Evidence Header

Record these values without fridge contents, storage paths, files, backups,
device identifiers, logs, APKs, signing material, or account data:

- commit SHA and pull request
- tester and UTC timestamp
- Android Studio, SDK, build tools, Java, and Gradle versions
- emulator image or physical-tablet model and Android version
- clean install or upgrade path
- Gradle lint, test, and assemble result

Mark every row `pass`, `fail`, `blocked`, or `not run`. Explain blocked and
unexecuted rows. Do not convert `not run` into passing evidence.

## Persistence Matrix

Use synthetic household items only:

| Scenario | Expected result | Result | Evidence |
| --- | --- | --- | --- |
| Fresh install | Empty list and date header render without a storage error. | not run | |
| Create one item | One normalized non-empty row persists after restart. | not run | |
| Line separators in input | Submitted text reloads as one item boundary. | not run | |
| Unicode item | UTF-8 text survives restart unchanged. | not run | |
| Multiple writes | Durable file always reflects the last successful list. | not run | |
| Rotation and restart | UI reloads current durable contents without duplication. | not run | |

## Failure And Corruption Matrix

Prepare fixtures outside git and restore the app sandbox after each case:

| Scenario | Expected result | Result | Evidence |
| --- | --- | --- | --- |
| Unavailable files directory | Read/write fails closed without constructing paths. | not run | |
| Read permission or security failure | Empty safe state appears with one generic error. | not run | |
| Write or rename failure | Visible optimistic item rolls back; durable file survives. | not run | |
| Stale temporary file | Cleanup is generic and canonical contents remain intact. | not run | |
| Oversized existing file | Read rejects before full parsing. | not run | |
| Oversized pending list | Preflight rejects before temporary output opens. | not run | |
| Corrupt UTF-8 or malformed lines | Failure is controlled without content logging. | not run | |

## Lifecycle And Privacy Matrix

| Scenario | Expected result | Result | Evidence |
| --- | --- | --- | --- |
| Background during write | Atomic replacement leaves old or complete new data. | not run | |
| Process recreation | App reloads durable data without relying on memory state. | not run | |
| Backup inspection | Fridge-list files remain excluded from Android backup. | not run | |
| Repeated failures | Logs remain bounded and contain no item or path details. | not run | |

Sanitized evidence must not contain fridge items, canonical or temporary paths,
exception messages, file bytes, device identifiers, or backup payloads.

## Completion

Record unresolved failures and protected evidence links outside git. A runtime
claim requires all applicable rows to pass on the exact commit. This repository
currently records every fridge device and storage row as unexecuted.
