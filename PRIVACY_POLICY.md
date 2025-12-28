# LireFlow Privacy Policy

**Last Updated: December 2024**

## Overview

LireFlow is designed with your privacy in mind. We believe your data belongs to you, and we've built LireFlow to respect that principle.

## Data Collection

### What We Do NOT Collect

LireFlow does **not** collect, store, or transmit any personal data to external servers. Specifically:

- We do not collect analytics or usage data
- We do not track your reading habits
- We do not collect device identifiers
- We do not use advertising networks
- We do not share any data with third parties

### Data Stored Locally on Your Device

All data created and managed by LireFlow is stored **exclusively on your device**:

- **RSS Feeds**: Your subscribed feeds and their URLs
- **Articles**: Fetched article content and metadata
- **Reading Lists**: Your custom reading lists and saved articles
- **Folders**: Your organizational folder structure
- **Starred Articles**: Articles you've marked as favorites
- **App Settings**: Your preferences stored in a local configuration file

**Location**: All configuration data is stored in:
```
~/Library/Application Support/LireFlow/config.json
```

Your article data is stored using Apple's SwiftData framework in the app's local container.

## Network Requests

LireFlow makes network requests only for the following purposes:

### 1. RSS Feed Fetching
When you add a feed or refresh your subscriptions, LireFlow connects directly to the RSS/Atom feed URLs you've provided to download article content.

### 2. Weather Information (Optional)
If you enable the weather widget, LireFlow uses the [Open-Meteo API](https://open-meteo.com/) to fetch weather data. Open-Meteo is a free, open-source weather API that does not require authentication and does not track users.

### 3. Feed Icons
LireFlow may fetch favicon images from websites to display feed icons.

### 4. Europresse Integration (Optional)
If you configure Europresse access through your institution, LireFlow will open URLs to your institution's Europresse portal in your default browser. No data is sent to Europresse directly from LireFlow.

## Location Data

LireFlow requests location permission **only** if you use the weather widget feature. Your location is:

- Used solely to fetch local weather information
- Sent to the Open-Meteo API as coordinates only
- Never stored permanently or shared with any other service
- Optional - you can manually set a location or disable the weather widget entirely

You can revoke location permission at any time through macOS System Settings > Privacy & Security > Location Services.

## Third-Party Services

LireFlow uses the following third-party services:

| Service | Purpose | Privacy Policy |
|---------|---------|----------------|
| Open-Meteo | Weather data (optional) | [open-meteo.com/en/terms](https://open-meteo.com/en/terms) |

## Data Export & Portability

You have full control over your data:

- **Export**: You can export all your feeds, folders, and reading lists at any time via Settings > Backup & Import
- **Import**: You can import data from JSON or OPML files
- **Delete**: Uninstalling the app removes all local data

## Children's Privacy

LireFlow does not knowingly collect any information from children under 13. The app does not require account creation or personal information to function.

## Changes to This Policy

We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.

## Your Rights (GDPR)

If you are in the European Union, you have the right to:

- Access your personal data (all data is stored locally on your device)
- Rectify inaccurate personal data
- Erase your personal data (delete the app)
- Data portability (use the export feature)

Since LireFlow does not collect or process personal data on external servers, most GDPR data rights are automatically fulfilled by the local-only architecture.

## Contact

If you have any questions about this Privacy Policy, please contact us:

- GitHub: [github.com/m0etez/LireFlow](https://github.com/m0etez/LireFlow)
- Twitter: [@mo_saadani](https://twitter.com/mo_saadani)

---

## Summary

**LireFlow is a privacy-first application:**

- All data stored locally on your device
- No accounts required
- No tracking or analytics
- No data sold to third parties
- Full data export capability
- Open source for transparency
