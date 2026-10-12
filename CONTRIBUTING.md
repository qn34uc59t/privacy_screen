# Contributing to PrivacyScreen

Thank you for your interest in contributing to PrivacyScreen! We welcome bug fixes, documentation enhancements, and feature proposals that respect user privacy.

---

## Code of Conduct & Principles

1. **Zero Surveillance Guarantee:** PrivacyScreen must never capture screens, transmit network data, or collect telemetry. All CoreMotion computation runs strictly on-device.
2. **Native Performance:** Follow Apple platform conventions—SwiftUI, Swift Concurrency (`@MainActor`, async/await), and standard Cocoa windowing patterns.
3. **Clean Logging:** Never leave raw `print(...)` statements in production paths. Use `os.Logger` with appropriate log levels (`debug`, `info`, `warning`, `error`).

---

## Getting Started

### Prerequisites

- **macOS:** 14.0 (Sonoma) or newer
- **Xcode:** 15.0 or newer
- **Hardware:** Mac with Bluetooth + motion-enabled Apple headphones (AirPods Pro, AirPods Max, AirPods 3rd Gen, Beats Fit Pro)

### Local Development Setup

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/qn34uc59t/privacy_screen.git
   cd privacy_screen
   ```

2. Open the project in Xcode:
   ```bash
   open PrivacyScreen.xcodeproj
   ```

3. Select the **PrivacyScreen** scheme and build/run (`Cmd+R`).

---

## Verifying Release Builds

Before submitting a pull request, verify that the Release target compiles cleanly without code signing errors:

```bash
xcodebuild -scheme PrivacyScreen -configuration Release clean build CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=YES
```

You can also test packaging a DMG:

```bash
./scripts/package-dmg.sh 1.0
```

---

## Pull Request Guidelines

1. **Feature Branches:** Create your branch from `main` (e.g. `feature/multi-display-tuning` or `fix/disconnect-detection`).
2. **Commit Messages:** Use clear, descriptive messages following conventional commit style (e.g. `fix: handle headphone disconnect gracefully`).
3. **Keep Scope Focused:** Keep pull requests targeted to a single issue or feature.
4. **Licensing:** By contributing, you agree that your contributions will be licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE).
