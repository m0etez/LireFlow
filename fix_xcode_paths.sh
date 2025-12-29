#!/bin/bash

# Script to fix file paths in Xcode project after iOS port restructuring
# This updates all old paths to new Shared/, macOS/, iOS/ structure

set -e

PROJECT_FILE="LireFlow.xcodeproj/project.pbxproj"
BACKUP_FILE="LireFlow.xcodeproj/project.pbxproj.backup"

echo "🔧 Fixing Xcode project file paths..."
echo ""

# Create backup
echo "📦 Creating backup: $BACKUP_FILE"
cp "$PROJECT_FILE" "$BACKUP_FILE"

# Update file paths
echo "📝 Updating file paths..."

# Models
sed -i '' 's|LireFlow/Models/|LireFlow/Shared/Models/|g' "$PROJECT_FILE"

# Services  
sed -i '' 's|LireFlow/Services/|LireFlow/Shared/Services/|g' "$PROJECT_FILE"

# Views
sed -i '' 's|LireFlow/Views/|LireFlow/Shared/Views/|g' "$PROJECT_FILE"

# Utilities
sed -i '' 's|LireFlow/Utilities/|LireFlow/Shared/Utilities/|g' "$PROJECT_FILE"

# Update group paths
sed -i '' 's|path = Models;|path = Shared/Models;|g' "$PROJECT_FILE"
sed -i '' 's|path = Services;|path = Shared/Services;|g' "$PROJECT_FILE"
sed -i '' 's|path = Views;|path = Shared/Views;|g' "$PROJECT_FILE"
sed -i '' 's|path = Utilities;|path = Shared/Utilities;|g' "$PROJECT_FILE"

# Fix LireFlowApp.swift -> LireFlowApp+macOS.swift
sed -i '' 's|LireFlow/LireFlowApp.swift|LireFlow/macOS/LireFlowApp+macOS.swift|g' "$PROJECT_FILE"
sed -i '' 's|LireFlowApp.swift|LireFlowApp+macOS.swift|g' "$PROJECT_FILE"

# Fix MenuBarView path
sed -i '' 's|path = MenuBarView.swift;|name = MenuBarView.swift; path = macOS/MenuBarView.swift;|g' "$PROJECT_FILE"

echo "✅ File paths updated!"
echo ""
echo "⚠️  Important: You still need to:"
echo "   1. Open Xcode: open LireFlow.xcodeproj"
echo "   2. Add new files manually:"
echo "      - LireFlow/Shared/LireFlowAppCore.swift"
echo "      - LireFlow/Shared/Utilities/PlatformHelpers.swift"
echo "      - LireFlow/iOS/ folder (all files)"
echo "   3. Build (⌘B) and fix any remaining issues"
echo ""
echo "💾 Backup saved at: $BACKUP_FILE"
echo ""
echo "🔄 To restore backup if needed:"
echo "   cp $BACKUP_FILE $PROJECT_FILE"
