#bin/sh
identities=$(security find-identity -p codesigning -v)
#echo "${identities}"
pat=' ([0-9ABCDEF]+) '
[[ $identities =~ $pat ]]
# Can be set to a codesign identity manually
IDT="${BASH_REMATCH[1]}"
if [ -z ${IDT+x} ]; then
    echo error: "error: Please set the codesigning identity above. \nThe identity can be found with $ security find-identities -v -p codesigning"
else
    codesign --entitlements ${SRCROOT}/OpenHaystack/OfflineFinder.entitlements -fs ${IDT} ${TARGET_BUILD_DIR}/OfflineFinder.app/Contents/MacOS/OfflineFinder
fi


