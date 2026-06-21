# Office Worker

Free and open source office apps chosen for the best daily-work experience: a full office suite plus a high-fidelity editor for Microsoft formats, PDF reading, annotation, signing, and page editing, mail and calendar with native Exchange, a Teams client, and a Windows app fallback for the line-of-business software that still has no Linux or web version.

## What it installs

| Tool | What it is | Source | Upstream |
| --- | --- | --- | --- |
| libreoffice-fresh | Full office suite: Writer, Calc, Impress, Draw, Base, and Math. | pacman | https://www.libreoffice.org/ |
| onlyoffice-bin | Office suite with high-fidelity Microsoft Word, Excel, and PowerPoint layout. | AUR | https://github.com/ONLYOFFICE/DesktopEditors |
| okular | PDF and document viewer with annotations, forms, and digital signatures. | pacman | https://okular.kde.org/ |
| xournalpp | Handwriting and PDF annotation for filling and signing forms. | pacman | https://xournalpp.github.io/ |
| pdfarranger | Merge, split, rotate, and reorder PDF pages. | pacman | https://github.com/pdfarranger/pdfarranger |
| thunderbird | Email client with integrated calendar and contacts. | pacman | https://www.thunderbird.net/ |
| evolution | Groupware client combining mail, calendar, contacts, and tasks. | pacman | https://gitlab.gnome.org/GNOME/evolution |
| evolution-ews | Connector adding native Microsoft Exchange and Microsoft 365 to Evolution. | pacman | https://gitlab.gnome.org/GNOME/evolution-ews |
| teams-for-linux | Desktop client for Microsoft Teams meetings and chat. | AUR | https://github.com/IsmaelMartinez/teams-for-linux |
| bottles | Wine prefix manager with a GUI for running Windows applications. | AUR | https://usebottles.com/ |

Install it from **Settings, Extras, Office Worker, Install all**, or pick individual items. Anything already on the system is detected and skipped, so re-running only fills the gaps.

Routing: OnlyOffice, Teams, and Bottles come from the AUR; the rest from the official repos. Evolution gains native Microsoft Exchange and Microsoft 365 through evolution-ews.
