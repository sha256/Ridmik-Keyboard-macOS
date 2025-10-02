#!/bin/bash
# Ridmik Keyboard Release Build Script
# Creates a signed, notarized PKG installer for distribution
# Installs to ~/Library/Input Methods

set -e  # Exit on any error

# Configuration
PROJECT_NAME="Ridmik"
SCHEME_NAME="Ridmik"
CONFIG="Release"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/release"
DIST_DIR="${BUILD_DIR}/dist"
PKG_DIR="${BUILD_DIR}/pkg"
VERSION=$(date +"%Y.%m.%d")

# Signing and notarization from environment variables
DEVELOPER_NAME="${DEVELOPER_NAME:-}"
TEAM_ID="${TEAM_ID:-}"
APPLE_ID="${APPLE_ID:-}"
APP_PASSWORD="${APP_PASSWORD:-}"

# Debug: Show what we received from environment
echo "🔍 Debug - Environment variables received:"
echo "  DEVELOPER_NAME: '${DEVELOPER_NAME}'"
echo "  TEAM_ID: '${TEAM_ID}'"
echo "  APPLE_ID: '${APPLE_ID}'"
echo "  APP_PASSWORD: [${#APP_PASSWORD} chars]"
echo "  DEVELOPER_ID_APP (before): '${DEVELOPER_ID_APP:-}'"
echo "  DEVELOPER_ID_INSTALLER (before): '${DEVELOPER_ID_INSTALLER:-}'"

# Construct certificate names from developer name and team ID
if [ -n "$DEVELOPER_NAME" ] && [ -n "$TEAM_ID" ]; then
    DEVELOPER_ID_APP="Developer ID Application: ${DEVELOPER_NAME} (${TEAM_ID})"
    DEVELOPER_ID_INSTALLER="Developer ID Installer: ${DEVELOPER_NAME} (${TEAM_ID})"
    echo "🔧 Constructed certificates from name and team ID"
else
    DEVELOPER_ID_APP="${DEVELOPER_ID_APP:-}"
    DEVELOPER_ID_INSTALLER="${DEVELOPER_ID_INSTALLER:-}"
    echo "🔧 Using manually set certificates (or empty)"
fi

echo "  DEVELOPER_ID_APP (after): '${DEVELOPER_ID_APP}'"
echo "  DEVELOPER_ID_INSTALLER (after): '${DEVELOPER_ID_INSTALLER}'"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Ridmik Keyboard Release Build Script${NC}"
echo -e "${BLUE}📦 Creating signed PKG installer for distribution${NC}"
echo -e "${BLUE}📁 Project: ${PROJECT_DIR}${NC}"
echo ""

# Check for required environment variables
echo -e "${YELLOW}🔍 Checking environment variables...${NC}"
MISSING_VARS=()

# For distribution signing, we need both app and installer certificates
if [ -z "$DEVELOPER_ID_APP" ]; then
    MISSING_VARS+=("DEVELOPER_ID_APP certificate not available")
fi

if [ -z "$DEVELOPER_ID_INSTALLER" ]; then
    MISSING_VARS+=("DEVELOPER_ID_INSTALLER certificate not available")
fi

if [ -z "$APPLE_ID" ]; then
    MISSING_VARS+=("APPLE_ID")
fi

if [ -z "$APP_PASSWORD" ]; then
    MISSING_VARS+=("APP_PASSWORD")
fi

# Additional check: if certificates are missing, suggest what to set
if [ -z "$DEVELOPER_ID_APP" ] || [ -z "$DEVELOPER_ID_INSTALLER" ]; then
    if [ -z "$DEVELOPER_NAME" ] || [ -z "$TEAM_ID" ]; then
        MISSING_VARS+=("Need DEVELOPER_NAME + TEAM_ID for certificate construction")
    fi
fi

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    echo -e "${RED}❌ Missing required environment variables:${NC}"
    for var in "${MISSING_VARS[@]}"; do
        echo -e "${RED}   - ${var}${NC}"
    done
    echo ""
    echo -e "${YELLOW}💡 Option 1 - Set developer name and team ID (recommended):${NC}"
    echo -e "${BLUE}export DEVELOPER_NAME=\"Your Name\"${NC}"
    echo -e "${BLUE}export TEAM_ID=\"YOUR_TEAM_ID\"${NC}"
    echo -e "${BLUE}export APPLE_ID=\"your-apple-id@example.com\"${NC}"
    echo -e "${BLUE}export APP_PASSWORD=\"your-app-specific-password\"${NC}"
    echo ""
    echo -e "${YELLOW}💡 Option 2 - Set full certificate names:${NC}"
    echo -e "${BLUE}export DEVELOPER_ID_APP=\"Developer ID Application: Your Name (TEAM_ID)\"${NC}"
    echo -e "${BLUE}export DEVELOPER_ID_INSTALLER=\"Developer ID Installer: Your Name (TEAM_ID)\"${NC}"
    echo -e "${BLUE}export APPLE_ID=\"your-apple-id@example.com\"${NC}"
    echo -e "${BLUE}export APP_PASSWORD=\"your-app-specific-password\"${NC}"
    echo ""
    echo -e "${YELLOW}💡 You can also create a .env file and source it:${NC}"
    echo -e "${BLUE}source .env && ./release_build.sh${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All environment variables set${NC}"

# Debug output
echo -e "${BLUE}📋 Configuration:${NC}"
if [ -n "$DEVELOPER_NAME" ] && [ -n "$TEAM_ID" ]; then
    echo -e "   Developer: ${DEVELOPER_NAME}"
    echo -e "   Team ID: ${TEAM_ID}"
    echo -e "   App Signing: Automatic (using ${TEAM_ID})"
    echo -e "   PKG Certificate: ${DEVELOPER_ID_INSTALLER}"
else
    echo -e "   App Signing: Automatic"
    echo -e "   PKG Certificate: ${DEVELOPER_ID_INSTALLER}"
fi
echo -e "   Apple ID: ${APPLE_ID}"
echo -e "   Password: [${#APP_PASSWORD} characters]"

# Check for required tools
echo -e "${YELLOW}🔍 Checking required tools...${NC}"
command -v xcodebuild >/dev/null 2>&1 || { echo -e "${RED}❌ xcodebuild not found${NC}"; exit 1; }
command -v pkgbuild >/dev/null 2>&1 || { echo -e "${RED}❌ pkgbuild not found${NC}"; exit 1; }
command -v productbuild >/dev/null 2>&1 || { echo -e "${RED}❌ productbuild not found${NC}"; exit 1; }
command -v codesign >/dev/null 2>&1 || { echo -e "${RED}❌ codesign not found${NC}"; exit 1; }
command -v xcrun >/dev/null 2>&1 || { echo -e "${RED}❌ xcrun not found${NC}"; exit 1; }
echo -e "${GREEN}✅ All tools available${NC}"

# Clean and create directories
echo -e "${YELLOW}🧹 Preparing build environment...${NC}"
rm -rf "${BUILD_DIR}"
mkdir -p "${DIST_DIR}"
mkdir -p "${PKG_DIR}"

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
xcodebuild -project "${PROJECT_NAME}.xcodeproj" -scheme "${SCHEME_NAME}" clean

# Build for release
echo -e "${YELLOW}🔨 Building ${PROJECT_NAME} (${CONFIG})...${NC}"
xcodebuild \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIG}" \
    -derivedDataPath "${BUILD_DIR}/xcode" \
    -arch arm64 \
    -arch x86_64 \
    SYMROOT="${BUILD_DIR}/xcode/Build/Products" \
    OBJROOT="${BUILD_DIR}/xcode/Build/Intermediates" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="${DEVELOPER_ID_APP}" \
    DEVELOPMENT_TEAM="${TEAM_ID}" \
    ONLY_ACTIVE_ARCH=NO \
    OTHER_CODE_SIGN_FLAGS="--timestamp --options=runtime" \
    ENABLE_HARDENED_RUNTIME=YES \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    build

# Find the built app
BUILT_APP="${BUILD_DIR}/xcode/Build/Products/${CONFIG}/${PROJECT_NAME}.app"

if [ ! -d "${BUILT_APP}" ]; then
    echo -e "${RED}❌ Could not find built app at: ${BUILT_APP}${NC}"
    echo -e "${YELLOW}🔍 Searching for app in build directory...${NC}"
    find "${BUILD_DIR}" -name "${PROJECT_NAME}.app" -type d 2>/dev/null || true
    exit 1
fi

echo -e "${GREEN}✅ Found built app: ${BUILT_APP}${NC}"

# Verify code signing
echo -e "${YELLOW}🔐 Verifying code signing...${NC}"
codesign --verify --deep --strict "${BUILT_APP}"
codesign --display --verbose=2 "${BUILT_APP}"
echo -e "${GREEN}✅ App is properly signed${NC}"

# Create app directory for PKG
APP_ROOT="${DIST_DIR}/app"
mkdir -p "${APP_ROOT}"

# Copy app to app directory
echo -e "${YELLOW}📦 Preparing distribution package...${NC}"
cp -R "${BUILT_APP}" "${APP_ROOT}/"

# Create component PKG
echo -e "${YELLOW}📦 Creating component package...${NC}"
COMPONENT_PKG="${PKG_DIR}/${PROJECT_NAME}-component.pkg"

xcrun pkgbuild \
    --root "${APP_ROOT}" \
    --install-location "/Library/Input Methods" \
    --identifier "com.ridmik.inputmethod.macos.pkg" \
    --version "${VERSION}" \
    "${COMPONENT_PKG}"

# Prepare distribution XML
DISTRIBUTION_XML="${PKG_DIR}/distribution.xml"
COMPONENT_PKG_NAME="${PROJECT_NAME}-component.pkg"

echo -e "${YELLOW}📝 Preparing distribution XML...${NC}"

# Copy and customize the distribution XML template
sed -e "s/{{VERSION}}/${VERSION}/g" \
    -e "s/{{COMPONENT_PKG_NAME}}/${COMPONENT_PKG_NAME}/g" \
    "${PROJECT_DIR}/distribution.xml" > "${DISTRIBUTION_XML}"

# Create final PKG
echo -e "${YELLOW}📦 Creating final installer package...${NC}"
FINAL_PKG="${BUILD_DIR}/${PROJECT_NAME}-${VERSION}.pkg"

# Check if we have the installer certificate AND private key
if security find-certificate -c "Developer ID Installer" >/dev/null 2>&1; then
    CERT_HASH=$(security find-certificate -Z -c "Developer ID Installer" | grep "SHA-1 hash" | cut -d: -f2 | tr -d ' ')

    # Check if the certificate has an associated private key
    if security find-identity -v -s "${CERT_HASH}" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Found Developer ID Installer certificate with private key${NC}"
        echo -e "${BLUE}Using certificate hash: ${CERT_HASH}${NC}"

        productbuild \
            --distribution "${DISTRIBUTION_XML}" \
            --package-path "${PKG_DIR}" \
            --sign "${CERT_HASH}" \
            "${FINAL_PKG}"
    else
        echo -e "${YELLOW}⚠️  Developer ID Installer certificate found but private key missing${NC}"
        echo -e "${YELLOW}📦 Creating unsigned PKG (certificate without private key)${NC}"
        productbuild \
            --distribution "${DISTRIBUTION_XML}" \
            --package-path "${PKG_DIR}" \
            "${FINAL_PKG}"

        echo -e "${YELLOW}💡 To fix this:${NC}"
        echo -e "${BLUE}   1. Export certificate + private key (.p12) from original Mac${NC}"
        echo -e "${BLUE}   2. Import .p12 file on this Mac${NC}"
        echo -e "${BLUE}   3. Or regenerate certificate on this Mac${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  No Developer ID Installer certificate found${NC}"
    echo -e "${YELLOW}📦 Creating unsigned PKG (for testing only)${NC}"
    productbuild \
        --distribution "${DISTRIBUTION_XML}" \
        --package-path "${PKG_DIR}" \
        "${FINAL_PKG}"

    echo -e "${YELLOW}💡 To create signed PKG for distribution:${NC}"
    echo -e "${BLUE}   1. Get Developer ID certificates from Apple Developer Portal${NC}"
    echo -e "${BLUE}   2. Install them in Keychain${NC}"
    echo -e "${BLUE}   3. Re-run this script${NC}"
fi

# Verify PKG signing (only if signed)
if security find-certificate -c "Developer ID Installer" >/dev/null 2>&1; then
    CERT_HASH=$(security find-certificate -Z -c "Developer ID Installer" | grep "SHA-1 hash" | cut -d: -f2 | tr -d ' ')
    if security find-identity -v -s "${CERT_HASH}" >/dev/null 2>&1; then
        # PKG was signed
        echo -e "${YELLOW}🔐 Verifying PKG signature...${NC}"
        pkgutil --check-signature "${FINAL_PKG}"

        # Submit for notarization
        echo -e "${YELLOW}📝 Submitting for notarization...${NC}"
        echo -e "${BLUE}This may take several minutes...${NC}"

        xcrun notarytool submit \
            "${FINAL_PKG}" \
            --apple-id "${APPLE_ID}" \
            --password "${APP_PASSWORD}" \
            --team-id "${TEAM_ID}" \
            --wait

        # Staple the notarization
        echo -e "${YELLOW}📎 Stapling notarization...${NC}"
        xcrun stapler staple "${FINAL_PKG}"

        # Verify notarization
        echo -e "${YELLOW}✅ Verifying notarization...${NC}"
        xcrun stapler validate "${FINAL_PKG}"
    else
        echo -e "${YELLOW}⚠️  Skipping notarization (unsigned PKG - no private key)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping notarization (no installer certificate)${NC}"
fi

# Create DMG for distribution (optional)
echo -e "${YELLOW}💿 Creating DMG for distribution...${NC}"
DMG_PATH="${BUILD_DIR}/${PROJECT_NAME}-${VERSION}.dmg"
hdiutil create -volname "Ridmik" -srcfolder "${FINAL_PKG}" -ov -format UDZO "${DMG_PATH}"

# Final output
echo ""
echo -e "${GREEN}🎉 Release build complete!${NC}"
echo ""
echo -e "${BLUE}📦 Files created:${NC}"
echo -e "   PKG: ${FINAL_PKG}"
echo -e "   DMG: ${DMG_PATH}"
echo ""

# Show file info
PKG_SIZE=$(du -sh "${FINAL_PKG}" | cut -f1)
DMG_SIZE=$(du -sh "${DMG_PATH}" | cut -f1)

echo -e "${BLUE}📊 Package info:${NC}"
echo -e "   Version: ${VERSION}"
echo -e "   PKG Size: ${PKG_SIZE}"
echo -e "   DMG Size: ${DMG_SIZE}"
echo ""

echo -e "${GREEN}✅ Ready for distribution!${NC}"
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "   1. Test the PKG installer on a clean machine"
echo -e "   2. Upload to your distribution platform"
echo -e "   3. Update release notes and documentation"
echo ""

# Clean up intermediate files
echo -e "${YELLOW}🧹 Cleaning up intermediate files...${NC}"
rm -rf "${BUILD_DIR}/xcode"
rm -rf "${DIST_DIR}"
rm -rf "${PKG_DIR}"

echo -e "${GREEN}✨ All done!${NC}"
