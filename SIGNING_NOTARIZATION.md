# Code Signing & Notarization Guide

This document explains how to set up code signing and notarization for PetruUtils releases via GitHub Actions.

## Overview

The GitHub Actions workflow (`.github/workflows/release.yml`) currently builds and packages the app, but does not sign or notarize it. This guide explains how to add those capabilities when needed.

## Current Status

✅ **Implemented:**
- Build automation on version tags
- Unit tests execution
- ZIP packaging
- DMG creation
- GitHub Release creation with artifacts

⚠️ **Not Implemented (requires Apple Developer Program):**
- Code signing
- Notarization
- Automatic Gatekeeper approval

## Why Signing & Notarization Matter

### Code Signing
- Verifies the app comes from a trusted developer
- Required for Gatekeeper acceptance
- Protects against tampering

### Notarization
- Apple's automated malware scan
- Required for macOS 10.15+ distribution outside App Store
- Adds extra layer of user trust

## Prerequisites

To add signing and notarization, you need:

1. **Apple Developer Program membership** ($99/year)
2. **Developer ID Application certificate**
3. **App-specific password** for notarization
4. **GitHub repository secrets** configured

## Setup Steps

### 1. Get Developer ID Certificate

1. Join the [Apple Developer Program](https://developer.apple.com/programs/)
2. In Xcode:
   - Open `Preferences` → `Accounts`
   - Add your Apple ID
   - Select your team → `Manage Certificates`
   - Click `+` → `Developer ID Application`
3. Export the certificate:
   - Open `Keychain Access`
   - Find the certificate under `My Certificates`
   - Right-click → `Export`
   - Save as `.p12` file with a password

### 2. Create App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in → `Security` → `App-Specific Passwords`
3. Generate new password
4. Save it securely (you'll need it for GitHub Secrets)

### 3. Configure GitHub Secrets

Add these secrets to your GitHub repository (`Settings` → `Secrets and variables` → `Actions`):

```
APPLE_CERTIFICATE_BASE64
  - Base64-encoded .p12 certificate
  - Generate with: base64 -i certificate.p12 | pbcopy

APPLE_CERTIFICATE_PASSWORD
  - Password you used when exporting the .p12

APPLE_ID
  - Your Apple ID email

APPLE_TEAM_ID
  - Find at developer.apple.com/account
  - Format: 10-character alphanumeric (e.g., AB12CD34EF)

APPLE_APP_PASSWORD
  - App-specific password from step 2

KEYCHAIN_PASSWORD
  - Random secure password for temporary keychain
  - Generate with: openssl rand -base64 32
```

### 4. Update GitHub Workflow

Add these steps to `.github/workflows/release.yml` before the "Archive app" step:

```yaml
- name: Import certificate
  env:
    APPLE_CERTIFICATE_BASE64: ${{ secrets.APPLE_CERTIFICATE_BASE64 }}
    APPLE_CERTIFICATE_PASSWORD: ${{ secrets.APPLE_CERTIFICATE_PASSWORD }}
    KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
  run: |
    # Create temporary keychain
    KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
    security create-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH
    security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" $KEYCHAIN_PATH

    # Import certificate
    echo "$APPLE_CERTIFICATE_BASE64" | base64 --decode > certificate.p12
    security import certificate.p12 \
      -P "$APPLE_CERTIFICATE_PASSWORD" \
      -A -t cert -f pkcs12 \
      -k $KEYCHAIN_PATH
    security list-keychain -d user -s $KEYCHAIN_PATH

    # Verify certificate
    security find-identity -v -p codesigning

- name: Archive app (with signing)
  env:
    ENABLE_PREVIEWS: "NO"
    SWIFT_DISABLE_PREVIEWS: "1"
  run: |
    xcodebuild archive \
      -scheme PetruUtils \
      -configuration Release \
      -archivePath build/PetruUtils.xcarchive \
      -derivedDataPath DerivedData \
      CODE_SIGN_IDENTITY="Developer ID Application" \
      CODE_SIGN_STYLE=Manual \
      DEVELOPMENT_TEAM="${{ secrets.APPLE_TEAM_ID }}"

- name: Notarize app
  env:
    APPLE_ID: ${{ secrets.APPLE_ID }}
    APPLE_APP_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
    APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
  run: |
    APP_PATH="build/PetruUtils.xcarchive/Products/Applications/PetruUtils.app"

    # Create ZIP for notarization (different from distribution ZIP)
    ditto -c -k --keepParent "$APP_PATH" notarization.zip

    # Submit for notarization
    xcrun notarytool submit notarization.zip \
      --apple-id "$APPLE_ID" \
      --password "$APPLE_APP_PASSWORD" \
      --team-id "$APPLE_TEAM_ID" \
      --wait

    # Staple the notarization ticket
    xcrun stapler staple "$APP_PATH"

    # Clean up
    rm notarization.zip

- name: Clean up keychain
  if: always()
  run: |
    KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
    security delete-keychain $KEYCHAIN_PATH || true
```

### 5. Update Xcode Project Settings

In your Xcode project:

1. Select the `PetruUtils` target
2. Go to `Signing & Capabilities`
3. Uncheck `Automatically manage signing`
4. Set `Team` to your Developer Team
5. Set `Provisioning Profile` to `None`
6. Ensure `Code Signing Identity` → `Release` is set to `Developer ID Application`

### 6. Test Locally

Before pushing to GitHub:

```bash
# Build and archive
xcodebuild archive \
  -scheme PetruUtils \
  -configuration Release \
  -archivePath build/PetruUtils.xcarchive

# Verify signing
codesign --verify --verbose build/PetruUtils.xcarchive/Products/Applications/PetruUtils.app

# Check signature
codesign -dv --verbose=4 build/PetruUtils.xcarchive/Products/Applications/PetruUtils.app

# Verify Gatekeeper
spctl -a -vv build/PetruUtils.xcarchive/Products/Applications/PetruUtils.app
```

## Verification

After a release is created:

1. Download the DMG or ZIP from the GitHub Release
2. Extract/mount and move the app
3. Right-click the app → `Open` (first time only)
4. Verify no warnings appear (except first-time open confirmation)

## Troubleshooting

### Certificate Issues
- Ensure certificate is valid and not expired
- Verify team ID matches your Apple Developer account
- Check keychain has the certificate imported

### Notarization Failures
```bash
# Check notarization status
xcrun notarytool log <submission-id> \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --team-id "$APPLE_TEAM_ID"
```

### Gatekeeper Rejection
- Verify app is signed: `codesign -dv /path/to/PetruUtils.app`
- Verify notarization: `spctl -a -vv /path/to/PetruUtils.app`
- Check for hardened runtime issues

## Alternative: Manual Signing

If you prefer to sign releases manually instead of via CI:

```bash
# Sign the app
codesign --force --deep \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  /path/to/PetruUtils.app

# Create ZIP
ditto -c -k --keepParent /path/to/PetruUtils.app PetruUtils.zip

# Notarize
xcrun notarytool submit PetruUtils.zip \
  --apple-id "your@email.com" \
  --password "app-specific-password" \
  --team-id "TEAM_ID" \
  --wait

# Staple
xcrun stapler staple /path/to/PetruUtils.app

# Create final DMG
hdiutil create -volname "PetruUtils" \
  -srcfolder /path/to/PetruUtils.app \
  -ov -format UDZO \
  PetruUtils.dmg
```

## Resources

- [Apple Code Signing Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Notarization Documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow)
- [Xcode Build Settings](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

## Notes

- Code signing and notarization are **optional** for internal distribution
- Users can still run unsigned apps by right-clicking → `Open`
- For public distribution, signing is **highly recommended**
- App Store distribution requires different certificates and process

---

*Last updated: December 2025*
