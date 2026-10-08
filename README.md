# AI Mind Support

A mental health support AI safety system — iOS application with comprehensive safety protocols.

**Status: iOS Implementation Complete** — This project contains specifications, safety rules, configuration files, and a complete iOS SwiftUI application.

## Contents

### Design Documents
- `01-crisis-response-protocol.md` — Crisis response protocol specification
- `02-friction-log-and-safety-cases.md` — Friction log and safety case analysis
- `03-baas-selection.md` — Backend-as-a-Service selection analysis

### Implementation Specifications
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

### iOS Application
- `AiMindSupport/` — Complete iOS SwiftUI application:
  - `AiMindSupportApp.swift` — App entry point
  - `ContentView.swift` — Main view with tab navigation
  - `Models/` — Data models (Conversation, UserMessage, etc.)
  - `Views/` — SwiftUI views (Authentication, Conversation, Resources, Profile)
  - `Services/` — Firebase integration (Authentication, Conversation)
  - `Safety/` — Safety engine implementation (CrisisDetector, OutputFilter, PIISanitizer)

## Purpose

This project defines safety protocols and system specifications for an AI-powered mental health support application, focusing on:
- Crisis detection and response
- Hard safety rules for content moderation
- PII sanitization
- Post-processing pipeline
- BaaS selection analysis

## iOS Application Features

### Core Safety Features
- **3-Level Crisis Detection**: Level 1 (normal), Level 2 (implied), Level 3 (explicit)
- **Real-time Safety Engine**: Pre-LLM and post-LLM processing pipelines
- **Fixed Response Templates**: Crisis responses cannot be overridden by LLM
- **PII Sanitization**: Automatic removal of sensitive information
- **Drug Discussion Monitoring**: Special handling for medication-related conversations
- **AI Dependency Detection**: Detects and addresses over-reliance on AI

### User Interface
- **Authentication**: Anonymous sign-in with option to link email accounts
- **Conversation Interface**: Chat-based UI with crisis indicators
- **Resources Tab**: Crisis hotlines, emergency services, educational content
- **Profile Management**: Settings, privacy controls, data management

### Backend Integration
- **Firebase Auth**: User authentication and account management
- **Firestore**: Conversation storage and real-time sync
- **HIPAA Compliance**: Designed for healthcare data protection

## Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+
- Firebase account with HIPAA BAA signed

### Setup

1. **Clone the repository**
```bash
git clone <repository-url>
cd ai-mind-support
```

2. **Open in Xcode**
```bash
open AiMindSupport.xcodeproj
```

3. **Configure Firebase**
- Create a Firebase project at console.firebase.google.com
- Enable Authentication (Anonymous + Email/Password)
- Create Firestore database
- Sign HIPAA BAA in GCP Console
- Add `GoogleService-Info.plist` to the project

4. **Install Dependencies**
- Add Firebase SDK via Swift Package Manager
- Install required pods if using CocoaPods

5. **Build and Run**
- Select a simulator or device
- Press Cmd+R to build and run

## Architecture

The iOS application follows a clean architecture pattern:

```
AiMindSupport/
├── Models/              # Data models
├── Views/               # SwiftUI views
├── Services/            # Firebase services
├── Safety/              # Safety engine
└── Resources/           # Static resources
```

### Safety Engine Pipeline

```
User Input
    ↓
Pre-LLM Pipeline
    ├── Input Normalization
    ├── Prompt Injection Detection
    ├── PII Sanitization
    ├── Crisis Keyword Detection
    ├── Drug Discussion Detection
    └── AI Dependency Detection
    ↓
LLM Call (if safe)
    ↓
Post-LLM Pipeline
    ├── Diagnostic Language Filtering
    ├── Suggestion Language Rewriting
    ├── Farewell Tone Detection
    ├── AI Dependency Check Insertion
    ├── Drug Disclaimer Insertion
    └── Integrity Final Check
    ↓
Final Response
```

## Safety Rules Implementation

The iOS app implements all hard safety rules from the design documents:

- **HS-001**: Crisis detection and interception
- **HS-002**: Prohibition of suggestive language
- **HS-003**: Drug discussion safety protocol
- **HS-004**: AI dependency detection
- **HS-005**: Farewell tone detection
- **HS-006**: Prohibition of diagnostic language
- **HS-007**: Prompt injection protection

## Testing

### Unit Tests
- Crisis detector tests
- Output filter tests
- PII sanitizer tests

### Integration Tests
- Firebase authentication flow
- Conversation storage and retrieval
- Safety engine end-to-end

### Manual Testing
- Crisis response simulation
- Safety rule validation
- UI/UX testing

## Deployment

### Development
- Test on iOS Simulator
- Use Firebase development project

### Production
- Configure production Firebase project
- Enable App Transport Security
- Submit to App Store with proper medical disclaimers

## Important Notes

- This is a safety-critical application. All safety rules must be thoroughly tested before deployment.
- The app provides support but does not replace professional mental health services.
- Crisis responses are fixed and cannot be modified by the LLM.
- User data is protected according to HIPAA requirements.
- Regular safety audits and updates are recommended.

## License

MIT License - See LICENSE file for details
