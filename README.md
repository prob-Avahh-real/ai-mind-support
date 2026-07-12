# AI Mind Support

A mental health support AI safety system — specification and protocol design.

**Status: Design Documents Only** — This project contains specifications, safety rules, and configuration files. No Swift or application code is present. Build steps (Package.swift, swift build, etc.) do not apply.

## Contents

- `01-crisis-response-protocol.md` — Crisis response protocol specification
- `02-friction-log-and-safety-cases.md` — Friction log and safety case analysis
- `03-baas-selection.md` — Backend-as-a-Service selection analysis
- `impl/` — Implementation specifications and configurations:
  - `safety-engine.spec.md` — Safety engine specification
  - `post-processing-pipeline.spec.md` — Post-processing pipeline spec
  - `system-prompt.txt` — System prompt template
  - `hard-safety-rules.json` — Hard safety rules configuration
  - `crisis-detection-config.json` — Crisis detection configuration
  - `crisis-responses.json` — Crisis response templates
  - `suggestion-rewrite-config.json` — Suggestion rewrite config
  - `pii-sanitization-config.json` — PII sanitization configuration
  - `firestore.rules` — Firestore security rules
  - `test-cases.json` — Safety test cases

## Purpose

This project defines safety protocols and system specifications for an AI-powered mental health support application, focusing on:
- Crisis detection and response
- Hard safety rules for content moderation
- PII sanitization
- Post-processing pipeline
- BaaS selection analysis
