# ztatusbar
*Configurable statusbar developed in Zig for Xorg server using xsetroot*

<img src="https://github.com/javiorfo/img/blob/master/xtatusbar/ztatusbar.png?raw=true" alt="ztatusbar" />

## Caveats
- Dependencies: `xorg-xsetroot`, `curl`, `alsa`
- This library has been developed on and for Linux following open source philosophy.

## Installation
- Downloading, compiling and installing manually:
```bash
git clone https://github.com/javiorfo/ztatusbar
cd ztatusbar
sudo make clean install
```
**NOTE:** variable OPTIMIZE could be pass as parameter to activate different Zig build modes (default is ReleaseFast).

- From AUR Arch Linux:
```bash
yay -S ztatusbar
```

## Setup
- In your **~/.xinitrc** or **~/.xprofile** to start in every login
```bash
ztatusbar 2> ztatusbar.log &
```

## Overview
| Component | rstatusbar | NOTE |
| ------- | ------------- | ---- |
| CPU usage | :heavy_check_mark: | Percentage |
| RAM usage | :heavy_check_mark: | Percentage |
| TEMPERATURE | :heavy_check_mark: | Celcious |
| DISK USAGE | :heavy_check_mark: | Percentage |
| VOLUME LEVEL | :heavy_check_mark: | Level and Mute status |
| BLUETOOTH | :x: | |
| BATTERY LEVEL | :heavy_check_mark: | Percentage |
| CUSTOM SCRIPT | :heavy_check_mark: | Execute a custom script.sh |
| NETWORK STATUS | :heavy_check_mark: | Up or down |
| WEATHER | :heavy_check_mark: | Celcious, using [wttr](https://wttr.in/) |
| DATE | :heavy_check_mark: | Could be custimizable |

## Customizable
- By default the statusbar contains: **cpu usage, memory usage, temperature, disk usage, volume and datetime**
- For a custom configuration put this file [config.toml](https://github.com/javiorfo/ztatusbar/blob/master/config/config.toml) in your `~/.config/ztatusbar/config.toml` and edit it to change values or delete a component.
- Some configuration example in config.toml:
```toml
[memory]
time = 1000  # Time in miliseconds defines how often the process runs
name = "RAM" # Name of the component. Could be empty => name = ""
icon = ""   # Icon of the component. Could be empty => icon = ""

[disk]
time = 2000
name = "DISK"
icon = "󰋊 "
unit = "/"

[volume]
time = 100
name = "VOL"
icon = " " 
icon_muted = "󰖁 "

[temperature]
time = 1000
name = "TEMP"
icon = "󰏈 " 
zone = 1    # thermal zone which has the temperature in /sys/class/thermal_zone{variable here}/temp. If not set it uses thermal_zone0/temp

...
```
---

### Donate
- **Bitcoin** [(QR)](https://raw.githubusercontent.com/javiorfo/img/master/crypto/bitcoin.png)  `1GqdJ63RDPE4eJKujHi166FAyigvHu5R7v`
- [Paypal](https://www.paypal.com/donate/?hosted_button_id=FA7SGLSCT2H8G)
