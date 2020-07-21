#!/bin/sh
# Create a read-only disk image of the contents of a folder
#
# Usage: make-diskimage <image_file>
#                       <src_folder>
#                       <volume_name>
#                       <applescript>
#                       <eula_resource_file>

set -e;

DMG_DIRNAME=$(dirname "$1")
DMG_DIR=$(cd "$DMG_DIRNAME" > /dev/null; pwd)
DMG_NAME=$(basename "$1")
DMG_TEMP_NAME=${DMG_DIR}/rw.${DMG_NAME}
SRC_FOLDER=$(cd "$2" > /dev/null; pwd)
VOLUME_NAME=$3
CODESIGN_IDENTITY=$4

# optional arguments
APPLESCRIPT=$5
EULA_RSRC=$6

# Create the image
echo "creating disk image"
rm -f "$DMG_TEMP_NAME"
hdiutil create -srcfolder "$SRC_FOLDER" -nocrossdev -volname "$VOLUME_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW "$DMG_TEMP_NAME"

# mount it
echo "mounting disk image"
MOUNT_DIR=/Volumes/$VOLUME_NAME
DEV_NAME=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP_NAME" | grep -E '^/dev/' | sed 1q | awk '{print $1}')

# run applescript
if [ -n "${APPLESCRIPT}" ] && [ "${APPLESCRIPT}" != "-null-" ]; then
	echo "running ${APPLESCRIPT}"
	/usr/bin/osascript "$APPLESCRIPT"
fi

# make sure it's not world writeable
echo "fixing permissions"
chmod -Rf go-w "${MOUNT_DIR}" || true

# make the top window open itself on mount:
if [ -x /usr/local/bin/openUp ]; then
	/usr/local/bin/openUp "${MOUNT_DIR}"
elif [ -x ~/bin/openUp ]; then
	~/bin/openUp "${MOUNT_DIR}"
fi

# unmount
echo "unmounting disk image"
hdiutil detach "$DEV_NAME"

# compress image
echo "compressing disk image"
hdiutil convert "$DMG_TEMP_NAME" -format UDBZ -o "${DMG_DIR}/${DMG_NAME}"
rm -f "$DMG_TEMP_NAME"

# adding EULA resources
if [ -n "${EULA_RSRC}" ] && [ "${EULA_RSRC}" != "-null-" ]; then
	echo "adding EULA resources"
	hdiutil unflatten "${DMG_DIR}/${DMG_NAME}"
	xcrun ResMerger -a "${EULA_RSRC}" -o "${DMG_DIR}/${DMG_NAME}"
	hdiutil flatten "${DMG_DIR}/${DMG_NAME}"
fi

# sign image
codesign -s "${CODESIGN_IDENTITY}" "${DMG_DIR}/${DMG_NAME}"

echo "disk image done"
exit 0
