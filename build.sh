#!/usr/bin/env bash

token="5445531176:AAGwd6pVM-UoDrNos3R00QSlr0KuffkZLMY"
chat_id="-1001921678002"
android="10 (Q)"
devices="Xiaomi Redmi Note7/7S (lavender)"
nama_zip="tes-hmp-oldcam-lavender"


echo "Cloning dependencies"
git clone --depth=1 https://github.com/sohamxda7/llvm-stable  clang
git clone https://github.com/sohamxda7/llvm-stable -b gcc64 --depth=1 gcc
git clone https://github.com/sohamxda7/llvm-stable -b gcc32  --depth=1 gcc32
git clone --depth=1 https://github.com/sohamxda7/AnyKernel3 AnyKernel
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
KERNEL_DIR=$(pwd)
PATH="${KERNEL_DIR}/clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
export KBUILD_COMPILER_STRING="$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export ARCH=arm64
export KBUILD_BUILD_HOST=teshost
export KBUILD_BUILD_USER="tesuser"
# sticker plox
function sticker() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendSticker" \
        -d sticker="CAACAgEAAxkBAAEnKnJfZOFzBnwC3cPwiirjZdgTMBMLRAACugEAAkVfBy-aN927wS5blhsE" \
        -d chat_id=$chat_id
}
# Send info plox channel
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="⚒️<b>• ${KBUILD_BUILD_HOST} Kernel •</b>%0A %0A⚙️Build started%0A %0A📢 For <b>${devices}</b> %0A %0A📝 branch <code>$(git rev-parse --abbrev-ref HEAD)</code>(master)%0A %0A📖 Under commit <code>$(git log --pretty=format:'"%h : %s"' -1)</code>%0A %0A🛠️ Using compiler: <code>${KBUILD_COMPILER_STRING}</code>%0A %0A⏳ Started on <code>$(date)</code>%0A %0A🔑 <b>Build Status:</b>#Stable%0A %0A %0A #ANDROID %0A #KERNEL"
        }
# Push kernel to channel
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP \
        "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="🔨 Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s).
        
📍 For <b>${devices}</b>

📱 Android <b>${android}</b>

📀 <b>$(${CLANG}clang --version | head -n1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')</b> 
        
#ANDROID  #KERNEL 
#XIAOMI  #UPDATE "
}
# Fin Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="Build throw an error(s)"
    exit 1
}
# Compile plox
function compile() {
    make O=out ARCH=arm64 lavender-perf_defconfig
    make -j$(nproc --all) O=out \
                    ARCH=arm64 \
                    CC=clang \
                    CLANG_TRIPLE=aarch64-linux-gnu- \
                    CROSS_COMPILE=aarch64-linux-android- \
                    CROSS_COMPILE_ARM32=arm-linux-androideabi-

    if ! [ -a "$IMAGE" ]; then
        finerr
        exit 1
    fi
    
    for pattern in Image* *.img *.dtb .gz Image.gz-dtb; do
        for file in out/arch/arm64/boot/$pattern; do
        [ -e "$file" ] && cp "$file" AnyKernel/
        done
    done
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 ${nama_zip}-${android}-${TANGGAL}.zip *
    cd ..
}
sticker
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
