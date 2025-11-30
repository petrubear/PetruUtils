xcodebuild test \
       -scheme PetruUtils \
       -destination 'platform=macOS' \
       -derivedDataPath "$(pwd)/DerivedData"
# xcodebuild test \
       # -scheme PetruUtils \
       # -destination 'platform=macOS' \
       # -derivedDataPath "$(pwd)/DerivedData" \
