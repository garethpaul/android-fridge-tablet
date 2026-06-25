# Security Policy

## Fridge item storage

Fridge items stay in the application-private files directory with Android
backup disabled. Reads reject malformed UTF-8, non-LF line boundaries,
oversized files, excessive item counts, overlong items, control characters,
Unicode invisible-only items, symlinks, and non-regular files.
Writes use a same-directory temporary file, restrict it to owner access, flush
and sync its contents before replacement, and retain the previous file until a
later read validates the new target. Logs use fixed messages and never include
item contents, paths, or exception text.

The Java file API does not expose a portable directory fsync on this preserved
API 21 baseline. File contents are synced before rename and a backup is retained
for recovery, but sudden power loss during directory metadata updates remains a
device/filesystem-specific residual risk.

## Supported Versions

The supported security scope for `android-fridge-tablet` is the current default branch, `master`. Older commits, tags, branches, forks, demos, and generated artifacts are not actively supported unless the repository explicitly marks them as maintained.

Project summary: The App for my fridge.

## Reporting a Vulnerability

Please report suspected vulnerabilities through GitHub's private vulnerability reporting or by opening a draft GitHub Security Advisory for `garethpaul/android-fridge-tablet` when that option is available. If GitHub does not show a private reporting option for this repository, contact the repository owner through GitHub and avoid posting exploit details publicly until the issue can be assessed.

Do not open a public issue that includes exploit code, secrets, personal data, or detailed reproduction steps for an unpatched vulnerability.

## What to Include

Helpful reports include:

- the affected file, endpoint, permission, dependency, or workflow
- a concise impact statement explaining what an attacker could do
- reproduction steps using test data and accounts you control
- the branch, commit SHA, platform version, device, runtime, or dependency versions used
- logs, screenshots, or proof-of-concept snippets that demonstrate impact without exposing private data

## Project Security Posture

- This repository appears to be an Android mobile application or sample. The active security scope is the code and documentation on the default branch.
- Review found network clients, sockets, web APIs, or service endpoints; changes in those areas should receive security-focused review before merge.
- Review found mobile permission or privacy-sensitive data handling; changes in those areas should receive security-focused review before merge.
- Review found file, document, data, or media parsing flows; changes in those areas should receive security-focused review before merge.
- Dependency manifests detected: build.gradle, gradle.properties. Dependency updates should preserve lockfiles when present and avoid introducing packages without a clear maintenance reason.
- Pinned, read-only GitHub Actions runs the repository `/usr/bin/make check` baseline
  before review without inheriting hosted Android SDK state.
- The baseline pins and verifies the wrapper JAR and Gradle distribution checksums.
  An uncached bootstrap still depends on Gradle's HTTPS service, so these
  integrity controls do not provide offline reproducibility.
- Hosted checkout credentials are not persisted. Self-protecting CODEOWNERS
  assigns the workflow, Makefile, and baseline checker to the repository owner;
  repository rules should require that approval.
- `check.yml` remains the only approved workflow until another workflow
  receives an explicit least-privilege security contract.
- Stale tablet layouts should not crash local-only fridge data flows when
  optional header or list views are unavailable.
- Generic fridge storage failure logs identify read, write, and cleanup
  categories without recording exception messages, stack traces, or internal
  paths. Storage permission failures remain inside those reviewed fail-closed
  and rollback boundaries instead of crashing the activity.
- Persistence exceptions restore the exact fridge list before propagation.
- An unavailable app files directory is rejected before canonical or temporary
  storage files are constructed.
- A 1 MiB item-storage limit rejects oversized existing files before parsing
  and oversized temporary output before replacing the durable list.
- A preflight size check runs before temporary output is opened, while the
  post-write check remains in place before replacement.
- Durable replacement retains the prior item file as a same-directory backup
  until installation succeeds. Failed rollback preserves both the backup and
  temporary file instead of deleting the only recoverable copies.
- Line separators in fridge item input are normalized before line-oriented
  local persistence so one submission cannot create extra entries on reload.

## Mobile Privacy Notes

- The explicit launcher export boundary is limited to `.MainActivity`; the
  portable contract rejects unrelated exported components.

If this project requests device permissions such as location, camera, microphone, contacts, Bluetooth, health data, or local storage access, reports should describe the permission involved and whether sensitive data can be accessed, persisted, or transmitted unexpectedly. Please avoid testing against real third-party user data or accounts you do not control.

## Dependency and Supply Chain Security

The generated Gradle 8.14.5 bootstrap retains the legacy Gradle 2.2.1 runtime
required by Android Gradle Plugin 1.1.0. Review all four wrapper files together;
the SDK-free baseline rejects drift from Gradle's published wrapper JAR and
distribution SHA-256 values.

Dependency updates should come from trusted package managers and should keep lockfiles in sync when lockfiles exist. Do not commit credentials, private keys, tokens, generated secrets, or machine-local configuration. If a vulnerability depends on a compromised package, typosquatting risk, insecure transitive dependency, or unsafe build step, include the package name, affected version, and the path through which it is used.

## Safe Research Guidelines

Good-faith research is welcome when it stays within these boundaries:

- use only accounts, devices, data, and infrastructure that you own or have explicit permission to test
- avoid destructive actions, persistence, spam, phishing, social engineering, or denial-of-service testing
- minimize access to personal data and stop testing immediately if private data is exposed
- do not exfiltrate secrets or third-party data; report the minimum evidence needed to verify impact
- keep vulnerability details confidential until the maintainer has assessed the report

## Maintainer Response

The maintainer will review complete reports as availability allows, prioritize issues by exploitability and impact, and coordinate a fix or mitigation when the affected code is still maintained. For sample, archived, or educational repositories, the likely remediation may be documentation, dependency updates, or clearly marking unsupported code rather than a production-style patch release.
