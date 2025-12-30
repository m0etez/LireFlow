#!/usr/bin/env python3
"""
Script to fix Xcode project file references after iOS port restructuring.
Updates paths from old structure to new Shared/macOS/iOS structure.
"""

import re
import sys

def fix_xcode_project(project_path):
    """Fix file paths in Xcode project file."""
    
    print("🔧 Reading project file...")
    with open(project_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Create backup
    backup_path = project_path + '.backup'
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"📦 Backup created: {backup_path}")
    
    original_content = content
    
    # Fix individual file paths (more precise replacements)
    replacements = [
        # Models
        ('path = Article.swift;', 'name = Article.swift; path = Shared/Models/Article.swift;'),
        ('path = Feed.swift;', 'name = Feed.swift; path = Shared/Models/Feed.swift;'),
        ('path = Folder.swift;', 'name = Folder.swift; path = Shared/Models/Folder.swift;'),
        ('path = ReadingList.swift;', 'name = ReadingList.swift; path = Shared/Models/ReadingList.swift;'),
        ('path = ExportableModels.swift;', 'name = ExportableModels.swift; path = Shared/Models/ExportableModels.swift;'),
        
        # Services
        ('path = FeedParser.swift;', 'name = FeedParser.swift; path = Shared/Services/FeedParser.swift;'),
        ('path = FeedService.swift;', 'name = FeedService.swift; path = Shared/Services/FeedService.swift;'),
        ('path = ArticleExtractor.swift;', 'name = ArticleExtractor.swift; path = Shared/Services/ArticleExtractor.swift;'),
        ('path = WeatherService.swift;', 'name = WeatherService.swift; path = Shared/Services/WeatherService.swift;'),
        ('path = ConfigService.swift;', 'name = ConfigService.swift; path = Shared/Services/ConfigService.swift;'),
        ('path = StoreService.swift;', 'name = StoreService.swift; path = Shared/Services/StoreService.swift;'),
        ('path = DefaultFeeds.swift;', 'name = DefaultFeeds.swift; path = Shared/Services/DefaultFeeds.swift;'),
        ('path = ExportService.swift;', 'name = ExportService.swift; path = Shared/Services/ExportService.swift;'),
        ('path = ImportService.swift;', 'name = ImportService.swift; path = Shared/Services/ImportService.swift;'),
        
        # Utilities
        ('path = AppTheme.swift;', 'name = AppTheme.swift; path = Shared/Utilities/AppTheme.swift;'),
        ('path = Extensions.swift;', 'name = Extensions.swift; path = Shared/Utilities/Extensions.swift;'),
        
        # Views
        ('path = ContentView.swift;', 'name = ContentView.swift; path = Shared/Views/ContentView.swift;'),
        ('path = ArticleListView.swift;', 'name = ArticleListView.swift; path = Shared/Views/Articles/ArticleListView.swift;'),
        ('path = ArticleDetailView.swift;', 'name = ArticleDetailView.swift; path = Shared/Views/Articles/ArticleDetailView.swift;'),
        ('path = SidebarView.swift;', 'name = SidebarView.swift; path = Shared/Views/Sidebar/SidebarView.swift;'),
        ('path = WeatherWidget.swift;', 'name = WeatherWidget.swift; path = Shared/Views/Sidebar/WeatherWidget.swift;'),
        ('path = WeatherDetailPopover.swift;', 'name = WeatherDetailPopover.swift; path = Shared/Views/Sidebar/WeatherDetailPopover.swift;'),
        ('path = AddFeedSheet.swift;', 'name = AddFeedSheet.swift; path = Shared/Views/Sheets/AddFeedSheet.swift;'),
        ('path = AddFolderSheet.swift;', 'name = AddFolderSheet.swift; path = Shared/Views/Sheets/AddFolderSheet.swift;'),
        ('path = AddReadingListSheet.swift;', 'name = AddReadingListSheet.swift; path = Shared/Views/Sheets/AddReadingListSheet.swift;'),
        ('path = SettingsSheet.swift;', 'name = SettingsSheet.swift; path = Shared/Views/Sheets/SettingsSheet.swift;'),
        ('path = OnboardingSheet.swift;', 'name = OnboardingSheet.swift; path = Shared/Views/Sheets/OnboardingSheet.swift;'),
        ('path = UpgradeSheet.swift;', 'name = UpgradeSheet.swift; path = Shared/Views/Sheets/UpgradeSheet.swift;'),
        
        # Special files
        ('path = LireFlowApp.swift;', 'name = "LireFlowApp+macOS.swift"; path = macOS/LireFlowApp+macOS.swift;'),
        ('path = MenuBarView.swift;', 'name = MenuBarView.swift; path = macOS/MenuBarView.swift;'),
        
        # Group paths
        ('path = Models;', 'name = Models; path = Shared/Models;'),
        ('path = Services;', 'name = Services; path = Shared/Services;'),
        ('path = Views;', 'name = Views; path = Shared/Views;'),
        ('path = Utilities;', 'name = Utilities; path = Shared/Utilities;'),
    ]
    
    print("📝 Applying path updates...")
    changes_made = 0
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new)
            changes_made += 1
    
    print(f"✅ Applied {changes_made} path updates")
    
    # Write updated content
    with open(project_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Project file updated: {project_path}")
    return True

if __name__ == '__main__':
    project_path = 'LireFlow.xcodeproj/project.pbxproj'
    try:
        fix_xcode_project(project_path)
        print("\n✅ SUCCESS! Project file updated.")
        print("⚠️  Still need to add new files manually in Xcode:")
        print("   - LireFlow/Shared/LireFlowAppCore.swift")
        print("   - LireFlow/Shared/Utilities/PlatformHelpers.swift")
        print("   - LireFlow/iOS/ folder")
    except Exception as e:
        print(f"\n❌ ERROR: {e}")
        sys.exit(1)
