#!/bin/bash
# Cai bo cong cu Android cho Godot 4.7 - The Little Bookshop
SDK="$HOME/Library/Android/sdk"
pause() { echo; read -r -p "Nhấn Enter để đóng cửa sổ này..." _; }

echo "=== Cài bộ công cụ Android cho Godot ==="
echo

# 1. Kiem tra Java 17
if ! /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
  echo "❌ Chưa thấy Java 17. Hãy cài Temurin 17 (bản x64 .pkg) từ adoptium.net rồi bấm đúp lại file này."
  pause; exit 1
fi
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
echo "✅ Đã có Java 17: $JAVA_HOME"

# 2. Tim bo cong cu da tai ve (file zip, hoac thu muc da duoc Safari tu giai nen)
mkdir -p "$SDK/cmdline-tools"
if [ ! -x "$SDK/cmdline-tools/latest/bin/sdkmanager" ]; then
  ZIP="$(ls -t "$HOME"/Downloads/commandlinetools-mac-*.zip 2>/dev/null | head -1)"
  if [ -n "$ZIP" ]; then
    echo "Đang giải nén $ZIP ..."
    TMP="$(mktemp -d)"
    unzip -q "$ZIP" -d "$TMP" && mv "$TMP/cmdline-tools" "$SDK/cmdline-tools/latest"
  else
    DIR="$(ls -td "$HOME"/Downloads/commandlinetools-mac-*/cmdline-tools "$HOME"/Downloads/cmdline-tools 2>/dev/null | head -1)"
    if [ -n "$DIR" ] && [ -x "$DIR/bin/sdkmanager" ]; then
      echo "Đang chép $DIR ..."
      cp -R "$DIR" "$SDK/cmdline-tools/latest"
    else
      echo "❌ Không tìm thấy file commandlinetools-mac-...zip trong thư mục Downloads."
      echo "   Vào developer.android.com/studio, kéo xuống mục 'Command line tools only', tải bản Mac."
      pause; exit 1
    fi
  fi
fi
SM="$SDK/cmdline-tools/latest/bin/sdkmanager"
if [ ! -x "$SM" ]; then echo "❌ Giải nén không thành công."; pause; exit 1; fi
echo "✅ Đã có bộ công cụ dòng lệnh Android"

# 3. Dong y dieu khoan va tai cac goi Godot 4.7 can
echo
echo "Đang đồng ý điều khoản (tự động)..."
yes | "$SM" --sdk_root="$SDK" --licenses >/dev/null
echo "Đang tải platform-tools, build-tools 35.0.1, platform 35 (có thể mất 5–15 phút)..."
"$SM" --sdk_root="$SDK" "platform-tools" "build-tools;35.0.1" "platforms;android-35"

echo
if [ -x "$SDK/platform-tools/adb" ] && [ -d "$SDK/build-tools/35.0.1" ] && [ -d "$SDK/platforms/android-35" ]; then
  echo "🎉 XONG! Điền 2 đường dẫn này vào Godot > Editor Settings > Export > Android:"
  echo
  echo "   Java SDK Path:    $JAVA_HOME"
  echo "   Android SDK Path: $SDK"
else
  echo "❌ Có gói chưa tải xong. Chụp màn hình cửa sổ này gửi Claude."
fi
pause
