#!/usr/bin/env bash
# Kindle 越狱 + KOReader + 微信读书：一键准备脚本
# 用法：./scripts/setup.sh <fill|stage|clean|plugin|koreader-usb>
#   fill          越狱前：把 Kindle 存储填满，防 OTA 更新
#   stage         下载全部官方文件并校验，把 SpiderCat 放进 Kindle 的 documents/
#   clean         越狱后：删 FILLER/ 和根目录残留的 .bin 更新文件
#   plugin        KOReader 装好后：把微信读书插件拷进 koreader/plugins/
#   koreader-usb  KPM 装不上的兜底：把解压好的 koreader/ 直接拷进 Kindle 根目录
# 支持 macOS / Linux。Kindle 须用 USB 连上电脑。
# 官方源（脚本只从这里下载，不含任何第三方二进制）：
#   SpiderCat   https://kindlemodding.org/spidercat/spidercat.azw3
#   KOReader    https://github.com/koreader/koreader/releases/download/v2026.07.1/koreader-kindlehf-v2026.07.1.zip
#   微信读书插件 https://github.com/finlater/weread.koplugin/releases/download/v1.6.0/weread.koplugin-v1.6.0.zip
set -euo pipefail

# ---------- 固定值（实测校验过） ----------
SPIDERCAT_URL="https://kindlemodding.org/spidercat/spidercat.azw3"
SPIDERCAT_SIZE=484178
SPIDERCAT_MD5="829cccfda186187cafa1e07950918c1f"

KOREADER_URL="https://github.com/koreader/koreader/releases/download/v2026.07.1/koreader-kindlehf-v2026.07.1.zip"
KOREADER_SIZE=40708065
KOREADER_MD5="8866531bbd97fed5de142346c16902d7"
KOREADER_VER="v2026.07.1"

WEREAD_URL="https://github.com/finlater/weread.koplugin/releases/download/v1.6.0/weread.koplugin-v1.6.0.zip"
WEREAD_SIZE=910252
WEREAD_MD5="40a124af86b665739d7bfddf551a5d29"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DL_DIR="$SCRIPT_DIR/../downloads"
KOREADER_DIR="$DL_DIR/koreader"
WEREAD_DIR="$DL_DIR/weread.koplugin"

# ---------- 小工具 ----------
err() { echo "❌ $*" >&2; exit 1; }
info() { echo "==> $*"; }
ok() { echo "✅ $*"; }

# md5（macOS 用 md5 -q，Linux 用 md5sum）
file_md5() {
    if command -v md5sum >/dev/null 2>&1; then
        md5sum "$1" | awk '{print $1}'
    elif command -v md5 >/dev/null 2>&1; then
        md5 -q "$1"
    else
        err "找不到 md5 校验工具（md5sum 或 md5）"
    fi
}

# 找 Kindle 挂载点；找不到就报错退出
find_kindle() {
    if [ -n "${KINDLE_MOUNT:-}" ] && [ -d "$KINDLE_MOUNT" ]; then
        echo "$KINDLE_MOUNT"; return 0
    fi
    for cand in "/Volumes/Kindle" "/media/$USER/Kindle" "/run/media/$USER/Kindle" "/mnt/Kindle"; do
        if [ -d "$cand" ]; then echo "$cand"; return 0; fi
    done
    # 再兜底扫一圈：找名字含 Kindle 的挂载点
    local found=""
    found="$(ls -d /Volumes/*indle* /media/"$USER"/*indle* /run/media/"$USER"/*indle* 2>/dev/null | head -1 || true)"
    if [ -n "$found" ] && [ -d "$found" ]; then echo "$found"; return 0; fi
    err "没找到 Kindle。请用 USB 把 Kindle 连上电脑（设置 KINDLE_MOUNT 可手动指定挂载点）。"
}

# 可用空间（KB）
free_kb() {
    df -k "$1" | tail -1 | awk '{print $4}'
}

# 下载并校验（大小 + md5）
download() {
    local url="$1" dest="$2" size="$3" md5="$4" name="$5"
    if [ -f "$dest" ]; then
        local cur_size cur_md5
        cur_size="$(wc -c < "$dest" | tr -d ' ')"
        cur_md5="$(file_md5 "$dest")"
        if [ "$cur_size" = "$size" ] && [ "$cur_md5" = "$md5" ]; then
            ok "$name 已下载且校验通过，跳过。"
            return 0
        fi
        info "$name 已存在但校验不对，重新下载。"
        rm -f "$dest"
    fi
    info "下载 $name ..."
    curl -L --fail --retry 2 --connect-timeout 20 -o "$dest" "$url" \
        || err "下载 $name 失败，请检查网络后重试。"
    local cur_size cur_md5
    cur_size="$(wc -c < "$dest" | tr -d ' ')"
    cur_md5="$(file_md5 "$dest")"
    [ "$cur_size" = "$size" ] || err "$name 大小不对（应为 $size，实际 $cur_size），可能下载不完整。"
    [ "$cur_md5" = "$md5" ] || err "$name md5 不对（应为 $md5，实际 $cur_md5）。"
    ok "$name 下载并校验通过。"
}

# ---------- 子命令 ----------
cmd_fill() {
    local kindle; kindle="$(find_kindle)"
    info "Kindle 在：$kindle"
    local free; free="$(free_kb "$kindle")"
    info "当前空闲：$((free / 1024)) MB"
    if [ "$free" -lt 614400 ]; then
        ok "空闲已不足 600MB，不用再填。"
        return 0
    fi
    mkdir -p "$kindle/FILLER"
    local i=0
    # 每次填 64MB，留约 450MB 空闲就停
    while [ "$(free_kb "$kindle")" -gt 460800 ]; do
        local f="$kindle/FILLER/pad_$(printf '%03d' "$i").bin"
        if command -v mkfile >/dev/null 2>&1; then
            mkfile -n 64m "$f" 2>/dev/null || dd if=/dev/zero of="$f" bs=1m count=64 2>/dev/null
        else
            dd if=/dev/zero of="$f" bs=1m count=64 2>/dev/null
        fi
        i=$((i + 1))
        # 安全上限：最多填 120 个（约 7.5GB），防死循环
        [ "$i" -ge 120 ] && break
    done
    sync
    ok "填好了。当前空闲：$(( $(free_kb "$kindle") / 1024 )) MB，FILLER/ 里 $i 个文件。"
    info "下一步：跑 ./scripts/setup.sh stage，然后按 README 第 2 步越狱。"
}

cmd_stage() {
    mkdir -p "$DL_DIR"
    download "$SPIDERCAT_URL" "$DL_DIR/spidercat.azw3" "$SPIDERCAT_SIZE" "$SPIDERCAT_MD5" "SpiderCat"
    download "$KOREADER_URL" "$DL_DIR/koreader-kindlehf-v2026.07.1.zip" "$KOREADER_SIZE" "$KOREADER_MD5" "KOReader $KOREADER_VER"
    download "$WEREAD_URL" "$DL_DIR/weread.koplugin-v1.6.0.zip" "$WEREAD_SIZE" "$WEREAD_MD5" "微信读书插件 v1.6.0"
    # 解压备用（KOReader 与插件）
    info "解压 KOReader 与微信读书插件到 $DL_DIR ..."
    rm -rf "$KOREADER_DIR" "$WEREAD_DIR"
    unzip -o -q "$DL_DIR/koreader-kindlehf-v2026.07.1.zip" -d "$DL_DIR" \
        || err "解压 KOReader 失败。"
    unzip -o -q "$DL_DIR/weread.koplugin-v1.6.0.zip" -d "$DL_DIR" \
        || err "解压微信读书插件失败。"
    [ -d "$KOREADER_DIR" ] || err "解压后没找到 koreader/ 文件夹。"
    [ -f "$WEREAD_DIR/main.lua" ] || err "解压后没找到 weread.koplugin/main.lua。"
    ok "解压完成（$KOREADER_DIR，$WEREAD_DIR）。"
    # 把 SpiderCat 放进 Kindle
    local kindle; kindle="$(find_kindle)"
    info "Kindle 在：$kindle"
    mkdir -p "$kindle/documents"
    cp "$DL_DIR/spidercat.azw3" "$kindle/documents/spidercat.azw3"
    # 校验拷过去的文件
    local cur_size cur_md5
    cur_size="$(wc -c < "$kindle/documents/spidercat.azw3" | tr -d ' ')"
    cur_md5="$(file_md5 "$kindle/documents/spidercat.azw3")"
    [ "$cur_size" = "$SPIDERCAT_SIZE" ] && [ "$cur_md5" = "$SPIDERCAT_MD5" ] \
        || err "拷进 Kindle 的 spidercat.azw3 校验不对，请重跑。"
    ok "SpiderCat 已放进 Kindle 的 documents/，校验通过。"
    info "下一步：推出 Kindle、拔线，Wi-Fi 保持开，在书架里打开 SpiderCat，等它重启。"
}

cmd_clean() {
    local kindle; kindle="$(find_kindle)"
    info "Kindle 在：$kindle"
    if [ -d "$kindle/FILLER" ]; then
        local n; n="$(find "$kindle/FILLER" -type f | wc -l | tr -d ' ')"
        rm -rf "$kindle/FILLER"
        ok "已删 FILLER/（$n 个文件）。"
    else
        info "没有 FILLER/，跳过。"
    fi
    # 只删根目录的 .bin 更新文件，不动别处
    local deleted=0
    for f in "$kindle"/*.bin; do
        [ -e "$f" ] || continue
        rm -f "$f"
        deleted=$((deleted + 1))
        info "已删根目录 .bin：$(basename "$f")"
    done
    [ "$deleted" -eq 0 ] && info "根目录没有 .bin 文件。"
    sync
    ok "清完了。当前空闲：$(( $(free_kb "$kindle") / 1024 )) MB。"
}

cmd_plugin() {
    local kindle; kindle="$(find_kindle)"
    info "Kindle 在：$kindle"
    [ -d "$kindle/koreader" ] || err "Kindle 上没有 koreader/ 文件夹。请先在 Kindle 搜索框输 ;kpm install koreader 装好 KOReader 再跑这步。"
    [ -f "$WEREAD_DIR/main.lua" ] || err "本地没有解压好的 weread.koplugin。请先跑 ./scripts/setup.sh stage 下载解压。"
    mkdir -p "$kindle/koreader/plugins"
    rm -rf "$kindle/koreader/plugins/weread.koplugin"
    cp -R "$WEREAD_DIR" "$kindle/koreader/plugins/weread.koplugin"
    [ -f "$kindle/koreader/plugins/weread.koplugin/main.lua" ] \
        || err "拷贝后没找到 main.lua，请重跑。"
    ok "微信读书插件已装进 koreader/plugins/weread.koplugin/。"
    info "下一步：推出 Kindle、拔线，打开 KOReader，进微信读书插件扫码登录。"
}

cmd_koreader_usb() {
    local kindle; kindle="$(find_kindle)"
    info "Kindle 在：$kindle"
    [ -d "$KOREADER_DIR" ] || err "本地没有解压好的 koreader/。请先跑 ./scripts/setup.sh stage 下载解压。"
    info "把 koreader/ 直接拷进 Kindle 根目录（KPM 装不上的兜底）..."
    rm -rf "$kindle/koreader"
    cp -R "$KOREADER_DIR" "$kindle/koreader"
    local ver; ver="$(cat "$kindle/koreader/git-rev" 2>/dev/null || echo '?')"
    [ "$ver" = "$KOREADER_VER" ] || err "拷贝后 git-rev 不是 $KOREADER_VER（实际 $ver），请重跑。"
    ok "KOReader $KOREADER_VER 已拷进 Kindle 根目录。"
    info "下一步：推出 Kindle、拔线，打开 KOReader；再跑 ./scripts/setup.sh plugin 装微信读书插件。"
}

usage() {
    echo "用法：$0 <fill|stage|clean|plugin|koreader-usb>"
    echo "  fill          越狱前：把 Kindle 存储填满，防 OTA 更新"
    echo "  stage         下载全部官方文件并校验，把 SpiderCat 放进 Kindle 的 documents/"
    echo "  clean         越狱后：删 FILLER/ 和根目录残留的 .bin 更新文件"
    echo "  plugin        KOReader 装好后：把微信读书插件拷进 koreader/plugins/"
    echo "  koreader-usb  KPM 装不上的兜底：把解压好的 koreader/ 直接拷进 Kindle 根目录"
    echo "环境变量 KINDLE_MOUNT 可手动指定 Kindle 挂载点。"
    exit 1
}

case "${1:-}" in
    fill)         cmd_fill ;;
    stage)        cmd_stage ;;
    clean)        cmd_clean ;;
    plugin)       cmd_plugin ;;
    koreader-usb) cmd_koreader_usb ;;
    *)            usage ;;
esac
