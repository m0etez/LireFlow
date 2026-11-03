#!/bin/sh
# Compiles the parser + config code with a small assert-based check and runs it.
# No Xcode test target needed: `sh scripts/selfcheck.sh`
set -eu
cd "$(dirname "$0")/.."
out="$(mktemp -d)/selfcheck"
swiftc -swift-version 5 -o "$out" \
    LireFlow/Services/FeedParser.swift \
    LireFlow/Services/ArticleExtractor.swift \
    LireFlow/Services/ConfigService.swift \
    LireFlow/Services/DefaultFeeds.swift \
    LireFlow/Utilities/AppTheme.swift \
    scripts/selfcheck/main.swift
"$out"
