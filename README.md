# 战舰世界俄服本土化（汉化）

>本汉化包由B站UP主`年糕特工队`、`DDF_FantasyV`、`Mochidzuki`和`walksQAQ`共同制作。

![GitHub License](https://img.shields.io/github/license/DDFantasyV/Korabli_localization_chs)
![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/DDFantasyV/Korabli_localization_chs/total)
[![.github/workflows/ReplicaToGitee.yml](https://github.com/DDFantasyV/Korabli_localization_chs/actions/workflows/ReplicaToGitee.yml/badge.svg)](https://github.com/DDFantasyV/Korabli_localization_chs/actions/workflows/ReplicaToGitee.yml)

**安装前请仔细阅读以下说明及Q&A！**<br>
如在使用汉化包的游玩过程中发现游戏内存在文本错误，请向我们反馈，谢谢您的帮助。<br>
本文另有：[English Version](README_EN.md)

## 声明
**此项目根据 *Apache License 2.0* 开源，仅用于学习交流，请勿用于非法用途。**

## 安装教程

以下提供三种安装方式，使用其中一种即可，请按需选用。

### 安装器安装 *推荐！*
> 安装器技术支持与维护由[MFunction](https://github.com/MFunction96)友情提供。<br>
> 项目地址：https://github.com/MFunction96/KorabliChsMod

无论Github还是Gitee，均转去最新发布下载即可，或访问以下链接以下载安装包含.NET 8运行环境的安装包：

Github: [KorabliChsModInstallerWithRuntime.exe](https://github.com/MFunction96/KorabliChsMod/releases/latest/download/KorabliChsModInstallerWithRuntime.exe)

Gitee: *待完善*

> 如果确定本地已安装.NET 8运行环境，可选择以下安装包：
>
> Github: [KorabliChsModInstaller.exe](https://github.com/MFunction96/KorabliChsMod/releases/latest/download/KorabliChsModInstaller.exe)
>
> Gitee: *待完善*

按照安装说明及提示完成安装即可，默认安装位置为：`%AppData%\KorabliChsMod`，即`C:\Users\<用户名>\AppData\Roaming\KorabliChsMod`，安装过程中会自动在桌面创建快捷方式。

> **<font color='red'>请勿安装在包含空格的路径下，当前版本暂不支持此类路径静默升级。</font>** ~~*后续可能懒得支持了*~~
> 
> 推荐路径：`C:\Program`
>
> 不推荐路径：`C:\Program Files` （包含空格）

### 使用

打开桌面快捷方式，进入程序。

1. 选择正确的游戏客户端安装的位置。
2. 点击`安装`，等待片刻即可完成。**无论检测到汉化安装与否，程序均会安装/覆盖安装最新版本的汉化补丁至指定客户端**。

![主程序](https://dev.azure.com/XanaCN/f06af8ee-5084-455c-ac24-8fc4f735382c/_apis/git/repositories/d36405a6-bc74-45e3-b720-3a2c79f5c30e/items?path=/doc/README/MainWindow.png)

### 自动安装 *推荐！*
1. 下载并打开`Korabli_chs_Setup.exe`，并授权管理员权限
2. 手动选择游戏目录，标准格式为`你的游戏目录/bin/数字最大的文件夹/res_mod`
3. 点击下一步继续安装
4. 安装完成！

### 手动安装 *由于目录文件变动，该方法不推荐使用！*
1. 下载压缩包文件或者`git clone`
2. 找到游戏安装的根目录，其文件名通常为`World_of_Warships`或是`Korabli`
3. 打开游戏根目录下的`bin`文件夹，找到里面**数字最大的文件夹**并打开
4. 打开目录下的`res_mod`文件夹，将`texts`文件夹和`locale_config.xml`直接拖入，如提示是否覆盖请选择`是`
5. 安装完成！

### 卸载
打开`控制面板 > 程序 > 卸载程序`,右键本汉化包执行卸载。

## 常见问题
>在提出任何问题之前，请确保已经阅读过了[提问的智慧](https://github.com/ryanhanwu/How-To-Ask-Questions-The-Smart-Way/blob/main/README-zh_CN.md)。

Q.为什么安装了汉化包，游戏还是没有变化？<br>
A.检查以下内容是否正确：`安装目录`、`游戏及汉化版本`。<br>
**兵工厂、问卷调查等游戏内置浏览器内容仍将以俄语显示。**<br>
**同时，如游戏已经预载更新，请将汉化安装在数字第二大的文件夹中。**<br>
如以上措施无效，请在issue或qq群内反馈。
***
Q.为什么安装了汉化包，游戏内还会出现乱码？<br>
A.检查以下内容是否正确：`安装目录`、`游戏及汉化版本`、`模组冲突`。<br>
如以上措施无效，请在issue或qq群内反馈。
***
Q.杀毒软件提示有病毒，我应该怎么办？<br>
A.杀毒软件误报，选择`信任程序`或者`保留`等选项继续安装。
***
Q.我使用安装器时出现了问题，应该怎么办？<br>
A.安装器相关问题请在KorabliChsMod的[issue](https://github.com/MFunction96/KorabliChsMod/issues)下进行反馈.

## 待实现功能
- [x] 汉化
- [x] 自动检测游戏目录
- [x] 自解压
- [x] 安装器
- [x] 自动检测更新
- [x] 中文自述文件
- [x] 英文自述文件
