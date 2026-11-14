# Kindle 越狱 + KOReader + 微信读书：一键安装指南

> 在 Kindle 上装 KOReader，再装微信读书插件，用微信读书看书。
> 全程已在 **Kindle Paperwhite 4（10 代，2018）/ 固件 5.18.1.1.1** 上实测跑通。
> 越狱方法 **SpiderCat**，KOReader 由 KPM 安装，微信读书走第三方插件。

## 适用范围

| 项目 | 说明 |
|---|---|
| 越狱方法 | [SpiderCat](https://kindlemodding.org/jailbreaking/SpiderCat/)（sparklerfish，2026-09-01） |
| 支持固件 | **5.16.3 ～ 5.19.5**（5.19.6 已封堵） |
| 实测机型 | Kindle Paperwhite 4（10 代），固件 **5.18.1.1.1**（build 4769680023） |
| KOReader | kindlehf v2026.07.1（经 KPM 安装） |
| 微信读书插件 | [weread.koplugin](https://github.com/finlater/weread.koplugin) v1.6.0（默认）；备选 [觅阅 MiuRead](https://github.com/miumiupy98-art/miuread-koreader) v6.4.1（带书城） |

> 固件高于 5.19.5 请先查 [KindleModding 选型向导](https://kindlemodding.org/kindle-models.html)，不要直接套用本指南。

## 开始之前：先看完这几条

- **越狱会失去保修，失败可能变砖。** 操作前确认能接受这个风险；重要书籍先备份。
- **微信读书不能装 App。** Kindle 没有安卓运行环境，只能走越狱 + KOReader + 第三方插件这条路。
- **微信读书插件是非官方客户端**，用你自己的微信读书账号登录，账号风险自担；没有免费会员、看不了付费书。
- **全程保持 Wi-Fi 开着**，直到越狱完成。越狱要联网，关 Wi-Fi 会失败。
- **不要装通用 hotfix（`Update_hotfix_universal.bin`）！** 这是本指南最大的坑，见[常见问题](#常见问题)。

## 一键准备（电脑端）

电脑上只需要做一次文件准备，脚本会自动下载并校验：

```bash
git clone https://github.com/no10playerzyf/kindle-spidercat-koreader-weread.git
cd kindle-spidercat-koreader-weread
./scripts/setup.sh stage    # 下载全部文件并把 SpiderCat 放进 Kindle
```

脚本会从官方源下载并校验（大小 + md5）：

| 文件 | 来源 | 大小 |
|---|---|---|
| `spidercat.azw3` | https://kindlemodding.org/spidercat/spidercat.azw3 | 484,178 字节 |
| `koreader-kindlehf-v2026.07.1.zip` | https://github.com/koreader/koreader/releases | 40,708,065 字节 |
| `weread.koplugin-v1.6.0.zip` | https://github.com/finlater/weread.koplugin/releases | 910,252 字节 |

脚本还会自动解压 KOReader 和插件到本地备用。**Kindle 上的操作（开书、输命令、扫码）仍需手动点几下**——这是 Kindle 自身限制，脚本代替不了。

> 不想跑脚本也可以手动下载上面三个文件，放到 Kindle 对应位置，效果一样。

## 完整步骤

### 第 1 步：把存储填满（防 OTA）

越狱要联网，联网就可能收到系统更新；一旦更新到 5.19.6，越狱窗口就没了。
先把存储填到只剩约 400MB，让更新文件没地方落：

```bash
./scripts/setup.sh fill     # 在 Kindle 根目录建 FILLER/，自动算需要填多少
```

也可以手动拷几个大文件进去凑满。**填满是越狱前的必要步骤，不要跳过。**

### 第 2 步：越狱（SpiderCat）

1. 用 USB 把 Kindle 连上电脑，确认能看到 Kindle 磁盘。
2. 跑 `./scripts/setup.sh stage`（或手动把 `spidercat.azw3` 拷进 Kindle 的 `documents/` 文件夹）。
3. 推出 Kindle、拔线。**Wi-Fi 保持开。**
4. 在 Kindle 书架里打开 **SpiderCat** 这本书。等几秒，屏幕会出现文字往下流，然后设备显示 `Restarting Kindle` 并重启。
   - 那个闪退/重启就是越狱本身，不是故障。
   - 弹"application error"之类的框不用管。
5. 重启后验一下：用 USB 连电脑，看 Kindle 根目录有没有这两个文件：
   - `privesc_marker.txt`，内容含 `uid=0`（即 root 权限）
   - `documents/JAILBROKEN.txt`，内容含 `SpiderCat Jailbreak by sparklerfish`
   - 还有一个 `libkh/` 目录
   - 三个都在 = 越狱成了。

### 第 3 步：清掉填充物

越狱完成后，更新已经被自动屏蔽了，填充物没用了，删掉腾地方放书：

```bash
./scripts/setup.sh clean    # 删 FILLER/，并删根目录残留的 .bin 更新文件
```

删完空闲约 5.8GB（8GB 机型）。

### 第 4 步：装 KOReader（经 KPM）

SpiderCat 越狱后自带包管理器 **KPM**。在 Kindle 上操作：

1. 先确认 root 是活的：如果越狱后重启过，先重新打开一次 SpiderCat 那本书恢复 root。
   （重启后 root 会掉，重开一次即恢复；KOReader 等文件都在磁盘上，不丢。）
2. 点 Kindle 顶部的**搜索框**，输入：

   ```
   ;kpm install koreader
   ```

   输完等它下载安装。**没有任何输出是正常的**，KPM 命令是静默的。
3. 装完用 USB 连电脑验证：Kindle 根目录出现 `koreader/` 文件夹，里面 `git-rev` 写着 `v2026.07.1`，即装对了。

> KPM 装不上时走 USB 兜底：`./scripts/setup.sh koreader-usb`，把解压好的 `koreader/` 文件夹直接拷进 Kindle 根目录。

### 第 5 步：装微信读书插件

```bash
./scripts/setup.sh plugin   # 把 weread.koplugin 拷进 Kindle 的 koreader/plugins/
```

拷完验证：`koreader/plugins/weread.koplugin/main.lua` 存在即可。

> 想换带书城的版本：把 `miuread.koplugin`（v6.4.1）拷进同一个 `plugins/` 文件夹，二选一或两个都装都行。

### 第 6 步：登录微信读书

1. 推出 Kindle、拔线，打开 **KOReader**（书架里点它）。
2. 在 KOReader 里找到 **微信读书** 插件，点进去。
3. 先在**手机**微信读书 App 里拿 API Key：`我 → 设置 → 微信读书 Skill → 获取 API Key`。
4. 按 Kindle 上插件的提示**扫码登录**（用微信扫）。
5. 登录后书架能打开 = 全通。

## 常见问题

### Q：通用 hotfix（`Update_hotfix_universal.bin`）怎么装？设置里没有"更新 Kindle"？
**A：不要装。** 这是本指南踩过最大的坑。
SpiderCat 属于 hdnext 新栈，越狱后**更新是自动屏蔽的**，设置菜单里永远不会出现"更新 Kindle"，根目录的 `.bin` 文件越狱自己会删掉。
通用 hotfix 经设置菜单安装是**老栈（WinterBreak / SpringBreak / Sanctuary 时代）**的做法，对 SpiderCat 不适用。
正确的"持久化"就是：更新已被屏蔽不怕 OTA；重启后 root 会掉，重开一次 SpiderCat 即恢复。

### Q：重启后 KOReader 打不开了？
**A：** 重启后 root 掉了，KPM 的钩子不工作。重新打开一次 SpiderCat 那本书恢复 root，再打开 KOReader 就行。

### Q：重开 SpiderCat 弹"错误：出现错误…从下载项中移除、从云端重新下载"？
**A：** 第一次闪退时那本书在设备里留了坏状态，重开可能弹这个框。**不用管，exploit 其实已经跑了**——连 USB 看 `privesc_marker.txt`，如果多了新的一行（新的 pid），就是 root 已恢复。
如果反复弹且标记文件没更新，把 Kindle 连电脑，删掉 `documents/` 里的 `spidercat.azw3`，重新拷一份全新的再打开。

### Q：`;kpm install koreader` 输完没反应？
**A：** 正常。KPM 命令是静默的，没有任何输出。等一两分钟，用 USB 连电脑看根目录有没有出现 `koreader/` 文件夹；有 = 装好了。
如果等了很久还没有，检查两点：Wi-Fi 是不是开着；root 是不是活的（先重开一次 SpiderCat 再输命令）。

### Q：越狱时提示固件不在支持范围？
**A：** 先确认固件版本：设置 → 设备选项 → 设备信息。SpiderCat 只支持 5.16.3～5.19.5。
5.19.6 已封堵，不要升级；高于 5.19.5 请查 KindleModding 选型向导找对应方法。

### Q：微信读书插件登录失败 / 书架打不开？
**A：** 先确认 API Key 是在手机微信读书 App 里现取的（`我 → 设置 → 微信读书 Skill → 获取 API Key`），不要用旧的。
插件是非官方客户端，微信读书改接口时可能暂时不可用，等插件更新。

## 文件说明

```
.
├── README.md                 # 本指南
├── LICENSE                   # MIT
└── scripts/
    └── setup.sh              # 一键准备脚本：fill / stage / clean / plugin / koreader-usb
```

`setup.sh` 子命令：

| 子命令 | 作用 |
|---|---|
| `fill` | 在 Kindle 根目录建 FILLER/，填满存储（越狱前） |
| `stage` | 下载三个官方文件并校验，把 SpiderCat 放进 Kindle 的 documents/ |
| `clean` | 删 FILLER/ 和根目录残留的 .bin 更新文件（越狱后） |
| `plugin` | 把 weread.koplugin 拷进 Kindle 的 koreader/plugins/ |
| `koreader-usb` | KPM 装不上的兜底：把解压好的 koreader/ 直接拷进 Kindle 根目录 |

脚本支持 macOS 和 Linux，会自动找 Kindle 挂载点（`/Volumes/Kindle` 或 `/media/$USER/Kindle` 等）。
Kindle 没连上时会直接报错，不会乱写。

## 致谢与来源

- [SpiderCat](https://kindlemodding.org/jailbreaking/SpiderCat/) by sparklerfish（KindleModding）
- [KOReader](https://github.com/koreader/koreader)
- [weread.koplugin](https://github.com/finlater/weread.koplugin) by finlater
- [觅阅 MiuRead](https://github.com/miumiupy98-art/miuread-koreader)
- [KindleModding Wiki](https://kindlemodding.org/)（越狱方法、What's Next、KPM 文档）
- 实测参考：[dalager/kindle-todo](https://github.com/dalager/kindle-todo)（同款 PW4 + 5.18.1.1.1 的 SpiderCat 实测记录）

## 免责

本指南仅供学习交流。越狱会失去保修，操作有风险（包括变砖），请自行评估。
微信读书插件为第三方非官方客户端，账号风险自担；请遵守微信读书的使用条款。
