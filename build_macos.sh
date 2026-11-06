#!/bin/bash
echo "========================================================"
echo "  Compilation d'Elyxia EB pour macOS (.app)"
echo "========================================================"

flutter pub get
flutter build macos --release

echo "========================================================"
echo "  Compilation terminée !"
echo "  Application située dans : build/macos/Build/Products/Release/elyxia_eb.app"
echo "========================================================"
