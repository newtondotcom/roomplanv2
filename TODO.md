clear \
# Build for connected iPhone device
xcodebuild -scheme "PlanSpace" -sdk iphoneos -destination 'generic/platform=iOS' build && \
# Install on connected device (replace YOUR_DEVICE_UDID - find it with: xcrun devicectl list devices)
xcrun devicectl device install app --device 7105F485-B4F8-5E67-942B-716118700972 ~/Library/Developer/Xcode/DerivedData/PlanSpace_2D-*/Build/Products/Debug-iphoneos/"PlanSpace.app" && \
# Launch the app
xcrun devicectl device process launch --device 7105F485-B4F8-5E67-942B-716118700972 robinaugereau.PlanSpace


# Ressources :
https://developer.apple.com/documentation/PlanSpace/merging-multiple-scans-into-a-single-structure
https://developer.apple.com/documentation/PlanSpace/create-a-3d-model-of-an-interior-room-by-guiding-the-user-through-an-ar-experience

# TODO
Add regular backup at each room by saving with possiblity to restart an interurpted scan with : 
https://developer.apple.com/documentation/PlanSpace/scanning-the-rooms-of-a-single-structure#Relocalize-an-AR-session-after-an-interruption
https://developer.apple.com/documentation/ARKit/saving-and-loading-world-data

by : 
- Capture and save the AR world map at each room scan end 
- Add a possiblity to Load and relocalize to a saved map and continue the scan by adding rooms