#!/bin/bash

VERSION=$(cat CopyPaste.xcodeproj/project.pbxproj | \
          grep -m1 'MARKETING_VERSION' | cut -d'=' -f2 | \
          tr -d ';' | tr -d ' ')
ARCHIVE_DIR=/Users/Larry/Library/Developer/Xcode/Archives/CommandLine
APPDIR=Archives/CopyPaste.xcarchive/Products/Applications
APPFILE=CopyPaste.app

rm -f make.log
touch make.log

echo "Building CopyPaste" 2>&1 | tee -a make.log

mkdir -p Archives
xcodebuild -project CopyPaste.xcodeproj DSTROOT=. \
    clean 2>&1 | tee -a make.log
xcodebuild -project CopyPaste.xcodeproj \
    -scheme "CopyPaste-Release" \
    -archivePath Archives/CopyPaste.xcarchive \
    archive 2>&1 | tee -a make.log

rm -rf ${ARCHIVE_DIR}/CopyPaste-v${VERSION}.xcarchive
cp -rf Archives/CopyPaste.xcarchive \
    ${ARCHIVE_DIR}/CopyPaste-v${VERSION}.xcarchive

cd ${APPDIR} && zip -rq ~/Downloads/CopyPaste.zip ${APPFILE}

