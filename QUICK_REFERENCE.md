# 🚀 Quick Reference: Fix Xcode File References

## Files That Moved (You'll See These in RED)

### OLD PATH → NEW PATH

**Models:**
- `LireFlow/Models/Article.swift` → `LireFlow/Shared/Models/Article.swift`
- `LireFlow/Models/Feed.swift` → `LireFlow/Shared/Models/Feed.swift`
- `LireFlow/Models/Folder.swift` → `LireFlow/Shared/Models/Folder.swift`
- `LireFlow/Models/ReadingList.swift` → `LireFlow/Shared/Models/ReadingList.swift`
- `LireFlow/Models/ExportableModels.swift` → `LireFlow/Shared/Models/ExportableModels.swift`

**Services:**
- `LireFlow/Services/FeedParser.swift` → `LireFlow/Shared/Services/FeedParser.swift`
- `LireFlow/Services/FeedService.swift` → `LireFlow/Shared/Services/FeedService.swift`
- `LireFlow/Services/ArticleExtractor.swift` → `LireFlow/Shared/Services/ArticleExtractor.swift`
- `LireFlow/Services/WeatherService.swift` → `LireFlow/Shared/Services/WeatherService.swift`
- `LireFlow/Services/ConfigService.swift` → `LireFlow/Shared/Services/ConfigService.swift`
- `LireFlow/Services/StoreService.swift` → `LireFlow/Shared/Services/StoreService.swift`
- `LireFlow/Services/DefaultFeeds.swift` → `LireFlow/Shared/Services/DefaultFeeds.swift`
- `LireFlow/Services/ExportService.swift` → `LireFlow/Shared/Services/ExportService.swift`
- `LireFlow/Services/ImportService.swift` → `LireFlow/Shared/Services/ImportService.swift`

**Views:**
- `LireFlow/Views/ContentView.swift` → `LireFlow/Shared/Views/ContentView.swift`
- `LireFlow/Views/Articles/ArticleListView.swift` → `LireFlow/Shared/Views/Articles/ArticleListView.swift`
- `LireFlow/Views/Articles/ArticleDetailView.swift` → `LireFlow/Shared/Views/Articles/ArticleDetailView.swift`
- `LireFlow/Views/Sidebar/SidebarView.swift` → `LireFlow/Shared/Views/Sidebar/SidebarView.swift`
- `LireFlow/Views/Sidebar/WeatherWidget.swift` → `LireFlow/Shared/Views/Sidebar/WeatherWidget.swift`
- `LireFlow/Views/Sidebar/WeatherDetailPopover.swift` → `LireFlow/Shared/Views/Sidebar/WeatherDetailPopover.swift`
- `LireFlow/Views/Sheets/AddFeedSheet.swift` → `LireFlow/Shared/Views/Sheets/AddFeedSheet.swift`
- `LireFlow/Views/Sheets/AddFolderSheet.swift` → `LireFlow/Shared/Views/Sheets/AddFolderSheet.swift`
- `LireFlow/Views/Sheets/AddReadingListSheet.swift` → `LireFlow/Shared/Views/Sheets/AddReadingListSheet.swift`
- `LireFlow/Views/Sheets/SettingsSheet.swift` → `LireFlow/Shared/Views/Sheets/SettingsSheet.swift`
- `LireFlow/Views/Sheets/OnboardingSheet.swift` → `LireFlow/Shared/Views/Sheets/OnboardingSheet.swift`
- `LireFlow/Views/Sheets/UpgradeSheet.swift` → `LireFlow/Shared/Views/Sheets/UpgradeSheet.swift`

**Utilities:**
- `LireFlow/Utilities/AppTheme.swift` → `LireFlow/Shared/Utilities/AppTheme.swift`
- `LireFlow/Utilities/Extensions.swift` → `LireFlow/Shared/Utilities/Extensions.swift`

**Special Files:**
- `LireFlow/LireFlowApp.swift` → `LireFlow/macOS/LireFlowApp+macOS.swift` ⚠️ RENAMED!
- `LireFlow/Views/MenuBarView.swift` → `LireFlow/macOS/MenuBarView.swift`

---

## New Files to Add (Won't Be in Project Yet)

After fixing red files, add these:

1. `LireFlow/Shared/LireFlowAppCore.swift` - Shared model container
2. `LireFlow/Shared/Utilities/PlatformHelpers.swift` - Cross-platform helpers
3. `LireFlow/iOS/LireFlowApp+iOS.swift` - iOS app entry
4. `LireFlow/iOS/RootView.swift` - iOS adaptive navigation
5. `LireFlow/iOS/Helpers/ShareSheet.swift` - iOS share sheet
6. `LireFlow/iOS/iOS.entitlements` - iOS capabilities
7. `LireFlow/iOS/Info.plist` - iOS config

---

## Quick Steps in Xcode

**For Each Red File:**
1. Click red file
2. Press ⌥⌘1 (File Inspector)
3. Click folder icon next to "Location"
4. Navigate to new path (see list above)
5. Select file and click Open

**To Add New Files:**
1. Right-click "LireFlow" in Project Navigator
2. "Add Files to LireFlow"
3. Navigate to file/folder
4. Check "Add to targets: LireFlow"
5. Click Add

**Then:**
- Press ⌘B to build
- Should succeed! 🎉

---

## Troubleshooting

**"Still showing red after selecting file"**
- Make sure you selected the exact file (not just the folder)
- File Inspector should show green dot if found

**"Can't find the file in new location"**
- Check this reference list for exact path
- Use Finder to verify file exists

**"Build fails after fixing all refs"**
- Make sure you added the new files (Step 3)
- Check that PlatformHelpers.swift is included

---

Need help? Read NEXT_STEPS.md for detailed guide!
