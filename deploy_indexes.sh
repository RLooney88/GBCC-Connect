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

# Deploy indexes
echo "📦 Deploying indexes..."
firebase deploy --only firestore:indexes

echo ""
echo "✅ Index deployment completed!"
echo ""
echo "📋 Next steps:"
echo "   1. Wait a few minutes for indexes to build"
echo "   2. Test the Contact Library page in your app"
echo "   3. Verify that contacts load without errors"
echo ""
echo "🔍 You can monitor index status in the Firebase Console:"
echo "   https://console.firebase.google.com/project/networking-app-bfabb/firestore/indexes"
echo "" 