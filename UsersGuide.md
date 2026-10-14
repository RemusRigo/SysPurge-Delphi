# SysPurge: User's Guide

> This is the Delphi version, **on hold**. The [VB.NET version](https://github.com/RemusRigo/SysPurge-VB.NET)
> has many more cleaning tasks.



## Downloads & Runtimes

Download the latest release from the [Releases page](https://github.com/RemusRigo/SysPurge-Delphi/releases).

|Folder|Architecture|Required Runtime|
|-|-|-|
|`Win32`|32-bit|none (native Windows app)|
|`Win64`|64-bit|none (native Windows app)|

> On 64-bit Windows, use **Win64**.



## Install

SysPurge is portable: there is no installer.

1. Copy `SysPurge.exe` to a folder, for example `D:\My Apps\SysPurge\`.
2. Right-click `SysPurge.exe` → **Run as administrator** to see all the cleaning tasks (or double-click it for the others only).



## Usage

1. Check the actions you want (**Select All** / **Deselect All** help).
2. Click **Purge**. The **Results** and **Progress** columns show what was cleaned.

|Group|Action|Default|Needs admin|
|-|-|-|-|
|**Microsoft Windows FileSystem**|EventViewer logs|checked|yes|
| |Log files (inside Windows)|checked| |
| |Log files (System drive)| | |
| |Prefetch files| | |
| |Temp files (Current User)|checked| |
| |Temp files (Windows)|checked| |
| |Windows Update cache|checked|yes|
|**Microsoft Windows Registry**|MRU list: Run (the history of the **Win+R** Run box)|checked| |
| |Shared DLL's: remove entries of shared DLLs that no longer exist|checked|yes|

> **Warning:** cleaned files and registry entries can't be restored.

Right-click the title bar → **About** for version information.



## Uninstall

Delete `SysPurge.exe`. SysPurge doesn't write any settings.
