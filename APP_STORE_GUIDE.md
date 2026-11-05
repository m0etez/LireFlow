# LireFlow App Store Preparation Guide

This document outlines everything needed to publish LireFlow on the Mac App Store.

## Pre-Submission Checklist

### Technical Requirements (Completed)

- [x] App Sandbox enabled
- [x] Hardened Runtime enabled
- [x] Version sync (Info.plist: 1.2.1, Build: 2)
- [x] Copyright notice added
- [x] Apple Silicon only (arm64)
- [x] Entitlements configured correctly
- [x] App Transport Security justified (RSS feeds may use HTTP)

### Code Changes (Completed)

- [x] Removed paywall bypass features (12ft.io, Archive.today, Google Cache)
- [x] Europresse integration made configurable (user selects institution)
- [x] Privacy policy created

### Still Required (Manual Steps)

- [ ] Set Development Team ID in Xcode
- [ ] Create App Store provisioning profile
- [ ] Host Privacy Policy URL
- [ ] Create App Store screenshots
- [ ] Set up App Store Connect

---

## Step 1: Apple Developer Account Setup

Since you've purchased the Apple Developer account, complete enrollment:

1. Go to [developer.apple.com](https://developer.apple.com)
2. Complete the enrollment process if not done
3. Note your **Team ID** (found in Membership details)

---

## Step 2: Xcode Configuration

### Set Development Team

1. Open `LireFlow.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the "LireFlow" target
4. Go to "Signing & Capabilities" tab
5. Check "Automatically manage signing"
6. Select your team from the dropdown

### Verify Build Settings

The following have been pre-configured in `project.pbxproj`:

| Setting | Value |
|---------|-------|
| ENABLE_HARDENED_RUNTIME | YES |
| ENABLE_APP_SANDBOX | YES |
| ARCHS | arm64 |
| MARKETING_VERSION | 1.2.1 |
| CURRENT_PROJECT_VERSION | 2 |

---

## Step 3: Host Privacy Policy

The Privacy Policy is ready at `PRIVACY_POLICY.md`. You need to host it publicly:

### Option A: GitHub Pages (Recommended)

1. In your GitHub repo settings, enable GitHub Pages
2. The policy will be available at: `https://m0etez.github.io/LireFlow/PRIVACY_POLICY`

### Option B: Dedicated Website

Host the privacy policy at a URL like: `https://lireflow.app/privacy`

**Note the URL - you'll need it for App Store Connect.**

---

## Step 4: App Store Connect Setup

### Create App Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" > "+" > "New App"
3. Fill in:
   - **Platform**: macOS
   - **Name**: LireFlow
   - **Primary Language**: English (U.S.) or French
   - **Bundle ID**: com.lireflow.app
   - **SKU**: lireflow-macos (any unique string)
   - **User Access**: Full Access

### App Information

| Field | Value |
|-------|-------|
| Name | LireFlow |
| Subtitle | Modern RSS Reader for macOS |
| Category | News |
| Secondary Category | Productivity (optional) |
| Content Rights | Does not contain third-party content |
| Age Rating | 4+ |

### Pricing & Availability

For **Freemium** model:

1. Set base app as **Free**
2. Configure in-app purchases later for premium features
3. **Availability**: Select European countries (or worldwide)

### App Privacy

When prompted for App Privacy details:

| Question | Answer |
|----------|--------|
| Does your app collect data? | No |
| Does your app track users? | No |

**Privacy Policy URL**: Enter your hosted URL from Step 3

---

## Step 5: Prepare Marketing Assets

### App Icon (Already Complete)

Icons are in `LireFlow/Assets.xcassets/AppIcon.appiconset/`:
- 1024x1024 for App Store
- All required sizes present

### Screenshots Required

You need screenshots for Mac App Store. Required sizes:

| Size | Resolution | Usage |
|------|------------|-------|
| 1280 x 800 | @1x | 13-inch displays |
| 2880 x 1800 | @2x | 15/16-inch Retina |

**Recommended Screenshots (5-10):**

1. **Main View** - Three-column layout with articles
2. **Article Reading** - Clean reading view with an article open
3. **Dark Mode** - Same views in dark mode
4. **Card Layout** - Article list in the Cards layout
5. **Settings** - Settings window open
6. **Europresse Setup** - Europresse portal selection
7. **Import/Export** - Backup settings visible
8. **Keyboard Shortcuts** - Could show help overlay

**How to Capture:**

```bash
# Capture window at exact size
screencapture -w screenshot.png

# Or use Xcode's simulator in specific sizes
```

### App Preview Video (Optional but Recommended)

- 15-30 seconds
- Show key features: adding feeds, reading articles, layouts
- Resolution: Same as screenshots
- Format: H.264, .mov or .mp4

---

## Step 6: App Store Description

### Short Description (Subtitle)
```
Modern RSS Reader for macOS
```

### Promotional Text (170 characters, can be updated without review)
```
Stay informed with LireFlow - A beautiful, privacy-focused RSS reader. Subscribe to your favorite websites and read articles distraction-free.
```

### Full Description
```
LireFlow is a modern, native RSS reader designed for macOS. Built with SwiftUI and SwiftData, it offers a beautiful reading experience while respecting your privacy.

KEY FEATURES

Feed Management
• Add RSS and Atom feeds from any URL
• Organize feeds into folders
• Quick add from clipboard
• Feed health monitoring
• 200+ default feeds to get started

Article Reading
• Clean, distraction-free reading view
• Reading time estimates
• Full article extraction
• Mark articles as read, starred, or archived
• Export to PDF or Markdown

Europresse Integration
• Access press archives via your university or library
• Support for 30+ European institutions
• One-click article search

Privacy First
• All data stored locally on your device
• No tracking or analytics
• No account required
• Export your data anytime

Keyboard Shortcuts
• J/K - Navigate articles
• M - Mark read/unread
• S - Star article
• V - Open in browser
• ⌘R - Refresh feeds

REQUIREMENTS
• macOS 14.0 (Sonoma) or later
• Apple Silicon Mac

LireFlow is open source and built with care. Your reading data stays on your device, always.
```

### Keywords (100 characters max, comma-separated)
```
rss,reader,news,feeds,atom,articles,reading,offline,privacy,french,europresse
```

---

## Step 7: Build & Archive

### Create Archive

1. In Xcode, select "Any Mac (Apple Silicon)"
2. Product > Archive
3. Wait for build to complete
4. Organizer window opens automatically

### Validate

1. In Organizer, select the archive
2. Click "Validate App"
3. Sign in with Apple ID if prompted
4. Fix any issues reported

### Upload

1. Click "Distribute App"
2. Select "App Store Connect"
3. Choose "Upload"
4. Follow prompts to upload

---

## Step 8: Submit for Review

### In App Store Connect

1. Go to your app
2. Under "macOS App", click the version
3. Add screenshots (upload all required sizes)
4. Fill in description, keywords, promotional text
5. Add privacy policy URL
6. Complete "App Review Information":
   - Contact info for reviewer
   - Notes: "This is an RSS reader. No login required. Test by adding any RSS feed URL."
7. Click "Submit for Review"

### Review Timeline

- **Typical**: 24-48 hours
- **First submission**: May take longer
- **Rejection reasons to avoid**:
  - Missing privacy policy
  - Crashes or bugs
  - Incomplete metadata
  - Guidelines violations

---

## Step 9: In-App Purchases (Future)

For your freemium model, you'll add IAPs later:

### Potential Premium Features

1. **Pro Unlock** - One-time purchase ($4.99-$9.99)
   - Unlimited feeds (free: limit to 20?)
   - Advanced export options
   - Custom themes
   - Priority support

2. **Premium Subscription** - Monthly/Yearly
   - Cloud sync (future)
   - Cross-device reading position
   - Premium feeds/sources

### Setting Up IAPs

1. App Store Connect > In-App Purchases
2. Create product
3. Implement StoreKit 2 in app
4. Submit for review with app update

---

## Quick Reference

### Bundle ID
```
com.lireflow.app
```

### Version
```
1.2.1 (Build 2)
```

### Category
```
News
```

### Age Rating
```
4+
```

### Minimum macOS
```
14.0 (Sonoma)
```

### Architecture
```
Apple Silicon only (arm64)
```

---

## Troubleshooting

### "No signing certificate"
- Xcode > Preferences > Accounts > Manage Certificates
- Create a new "Apple Distribution" certificate

### "Provisioning profile not found"
- Enable "Automatically manage signing" in Xcode
- Ensure correct team is selected

### "Invalid bundle"
- Check Bundle ID matches App Store Connect
- Verify all icons are present
- Ensure Hardened Runtime is enabled

### App rejected for HTTP
- Already handled: NSAllowsArbitraryLoads is justified for RSS feeds
- If asked, explain: "RSS feeds may be served over HTTP"

---

## Support

- GitHub Issues: https://github.com/m0etez/LireFlow/issues
- Twitter: @mo_saadani
