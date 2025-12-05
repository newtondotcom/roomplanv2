# Build for connected iPhone device
xcodebuild -scheme "RoomPlan 2D" -sdk iphoneos -destination 'generic/platform=iOS' build && \
# Install on connected device (replace YOUR_DEVICE_UDID - find it with: xcrun devicectl list devices)
xcrun devicectl device install app --device 7105F485-B4F8-5E67-942B-716118700972 ~/Library/Developer/Xcode/DerivedData/RoomPlan_2D-*/Build/Products/Debug-iphoneos/"RoomPlan 2D.app" && \
# Launch the app
xcrun devicectl device process launch --device 7105F485-B4F8-5E67-942B-716118700972 robinaugereau.RoomPlan


# Ressources :
https://developer.apple.com/documentation/roomplan/merging-multiple-scans-into-a-single-structure
https://developer.apple.com/documentation/roomplan/create-a-3d-model-of-an-interior-room-by-guiding-the-user-through-an-ar-experience