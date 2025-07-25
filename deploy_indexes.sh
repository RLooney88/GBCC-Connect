#!/bin/bash

# Deploy Firestore Indexes Script
# This script deploys the required Firestore indexes for the GBCC Connect App

echo "🚀 Deploying Firestore Indexes for GBCC Connect App..."
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "   npm install -g firebase-tools"
    echo ""
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ You are not logged in to Firebase. Please login first:"
    echo "   firebase login"
    echo ""
    exit 1
fi

# Check for dry-run flag
DRY_RUN=false
if [[ "$1" == "--dry-run" || "$1" == "-d" ]]; then
    DRY_RUN=true
    echo "🔍 DRY RUN MODE - No changes will be made"
    echo ""
fi

# Show current project
CURRENT_PROJECT=$(firebase use --print)
echo "📋 Current Firebase project: $CURRENT_PROJECT"
echo ""

# Check existing indexes
echo "📊 Checking existing indexes..."
if [ "$DRY_RUN" = true ]; then
    echo "🔍 Would check existing indexes (dry run mode)"
else
    # This would show existing indexes - you can add this if needed
    echo "✅ Connected to Firebase project"
fi
echo ""

# Deploy indexes
if [ "$DRY_RUN" = true ]; then
    echo "🔍 DRY RUN: Would deploy indexes..."
    echo "   firebase deploy --only firestore:indexes"
    echo ""
    echo "💡 To actually deploy, run: ./deploy_indexes.sh"
else
    echo "📦 Deploying indexes..."
    echo "   Note: Existing indexes will be skipped automatically"
    echo "   Only new or modified indexes will be deployed"
    echo ""
    
    firebase deploy --only firestore:indexes
    
    echo ""
    echo "✅ Index deployment completed!"
fi

echo ""
echo "📋 Next steps:"
echo "   1. Wait a few minutes for new indexes to build"
echo "   2. Test the Contact Library page in your app"
echo "   3. Verify that contacts load without errors"
echo ""
echo "🔍 You can monitor index status in the Firebase Console:"
echo "   https://console.firebase.google.com/project/networking-app-bfabb/firestore/indexes"
echo ""
echo "💡 Tips:"
echo "   - Existing indexes are automatically skipped"
echo "   - Only new or modified indexes are deployed"
echo "   - Use --dry-run flag to preview changes: ./deploy_indexes.sh --dry-run"
echo "" 