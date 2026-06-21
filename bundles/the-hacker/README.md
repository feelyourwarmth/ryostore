# The Hacker

Turns a Ryoku workstation into a reverse engineering and DFIR lab: the heavier disassemblers, debuggers, memory and disk forensics suites, hex and binary inspection tools, and packet analysis utilities that are deliberately kept off the default ISO. Most tools come from the official repos, with Cutter, BinDiff, and Autopsy from the AUR, plus capa via pipx and termshark via Go.

## What it installs

| Tool | What it is | Source | Upstream |
| --- | --- | --- | --- |
| ghidra | NSA reverse engineering suite with a multi-architecture decompiler. | pacman | https://ghidra-sre.org/ |
| radare2 | CLI framework to disassemble, debug, and analyze binaries. | pacman | https://radare.org |
| rizin | Maintained radare2 fork for binary analysis and disassembly. | pacman | https://rizin.re |
| cutter-bin | Qt graphical reverse engineering interface powered by rizin. | AUR | https://github.com/rizinorg/cutter/ |
| gdb | GNU debugger for native code with scripting and remote debugging. | pacman | https://www.gnu.org/software/gdb/ |
| pwndbg | GDB plugin for exploit development and heap inspection. | pacman | https://github.com/pwndbg/pwndbg |
| gef | GDB enhancement script for exploit development, loaded from gdbinit. | pacman | https://github.com/hugsy/gef |
| ltrace | Traces library calls and signals of a running program. | pacman | https://www.ltrace.org/ |
| strace | Traces system calls and signals of a running program. | pacman | https://strace.io/ |
| bindiff | Diffs disassembled binaries to match and compare code. | AUR | https://github.com/google/bindiff |
| binwalk | Scans and extracts embedded files and firmware images. | pacman | https://github.com/ReFirmLabs/binwalk |
| tinyxxd | Standalone xxd hex dump and reverse utility. | pacman | https://github.com/xyproto/tinyxxd |
| hexedit | Interactive terminal editor for viewing and modifying files in hex. | pacman | https://rigaux.org/hexedit.html |
| hexyl | Colored command-line hex viewer with byte category highlighting. | pacman | https://github.com/sharkdp/hexyl |
| capa | Identifies capabilities in executable files using a rule set. | pipx | https://github.com/mandiant/capa |
| sleuthkit | Command-line toolkit to analyze disk images and file systems. | pacman | https://www.sleuthkit.org/sleuthkit |
| autopsy | Graphical digital forensics platform built on The Sleuth Kit. | AUR | https://www.sleuthkit.org/autopsy/ |
| volatility3 | Memory forensics framework for analyzing RAM captures. | pacman | https://github.com/volatilityfoundation/volatility3 |
| foremost | Recovers files from disk images by header and footer carving. | pacman | http://foremost.sourceforge.net/ |
| testdisk | Recovers lost partitions and undeletes files, includes PhotoRec. | pacman | https://www.cgsecurity.org/index.html?testdisk.html |
| ddrescue | Images failing drives while skipping bad sectors. | pacman | https://www.gnu.org/software/ddrescue/ddrescue.html |
| perl-image-exiftool | Reads and writes metadata in images, documents, and media. | pacman | https://exiftool.org/ |
| wireshark-qt | Graphical network protocol analyzer for live and captured traffic. | pacman | https://www.wireshark.org/ |
| wireshark-cli | Command-line packet analyzer (tshark) from the Wireshark project. | pacman | https://www.wireshark.org/ |
| tcpdump | Command-line packet capture and inspection using libpcap. | pacman | https://www.tcpdump.org/ |
| termshark | Terminal user interface for tshark. | Go | https://github.com/gcla/termshark |

Install it from **Settings, Extras, The Hacker, Install all**, or pick individual items. Anything already on the system is detected and skipped, so re-running only fills the gaps.

Ghidra pulls a JDK as a dependency. pwndbg and gef both hook GDB and are mutually exclusive at runtime; load only one in ~/.gdbinit. For non-root capture, add yourself to the wireshark group. capa installs via pipx and termshark via go install, both into ~/.local/bin.
