# Omarchy Neovim Kit

Kit portatile per installare **Neovim** con la configurazione ufficiale di
**Omarchy OS** (il pacchetto `omarchy-nvim`, basato su
[LazyVim](https://www.lazyvim.org/)).

Tutto viene installato **in user-space** (`~/.local` e `~/.config`): non serve
`sudo` e non vengono toccate le directory di sistema.

---

## Contenuto del kit

```
omayrchy_nvim/
├── README.md                                  ← questo file
├── install.sh                                 ← installatore (user-local, senza sudo)
├── omarchy-nvim-2026.8.13-1-any.pkg.tar.zst   ← pacchetto ufficiale Omarchy
│                                                 (config + cache plugin pre-clonati)
└── config/                                    ← config Neovim estraibile/modificabile
    ├── init.lua
    ├── lazy-lock.json                         ← versioni plugin bloccate (come in Omarchy)
    ├── lazyvim.json                            ← extra LazyVim (neo-tree)
    ├── lua/config/…                            ← opzioni, keymaps, lazy, clipboard OSC52
    ├── lua/plugins/…                           ← tema, all-themes, hot-reload, snacks, ecc.
    └── plugin/after/transparency.lua           ← trasparenza (come in Omarchy)
```

---

## Requisiti

- Linux **x86_64** oppure **aarch64** (es. Raspberry Pi 4 con Raspberry Pi OS a **64 bit**)
- Connessione internet per scaricare i binari (Neovim, ripgrep, fd, font)
- `curl`, `tar`, `unzip`, `git`, `gcc`, `make` (di solito già presenti)
- Per alcuni LSP/strumenti: `node`, `python`, ecc. (facoltativi, via `:Mason`)

> **Attenzione**: esegui `install.sh` **senza `sudo`** (installa in user-space,
> `~/.local` e `~/.config`). Su Raspberry Pi con OS a 32 bit (armv7) non ci
> sono binari ufficiali di Neovim: usa Raspberry Pi OS a 64 bit.

---

## Installazione

```bash
cd ~/Desktop/omayrchy_nvim
chmod +x install.sh
./install.sh
```

Al termine:

```bash
source ~/.zshrc     # oppure riapri il terminale
n                   # alias per nvim
```

Nel terminale imposta il font **JetBrainsMono Nerd Font** per vedere le icone.

### Opzioni

| Opzione       | Effetto                                                        |
|---------------|----------------------------------------------------------------|
| `--refresh`   | Reinstalla config e cache sovrascrivendoli (con backup automatico) |
| `--skip-font` | Non installa il Nerd Font                                      |
| `--skip-data` | Non estrae la cache plugin: i plugin verranno clonati al primo avvio |

Esempi:

```bash
./install.sh --refresh          # ripristina i default Omarchy
./install.sh --skip-font        # installa senza font
```

### Raspberry Pi 4

- Usa **Raspberry Pi OS a 64 bit** (aarch64): lo script scarica
  automaticamente i binari ARM64 di Neovim, ripgrep e fd.
- Copia la cartella del kit nella home dell'utente (es. `/home/pi/omayrchy_nvim`)
  e lancia `./install.sh` **senza sudo**.
- I binari Mason inclusi nel pacchetto (stylua, shfmt) sono x86_64: lo script
  li rimuove su ARM e li reinstalla con `:MasonInstall` alla fine.

---

## Cosa installa lo script

1. **Neovim** `v0.12.5` (ultima stable) in `~/.local/nvim` + link `~/.local/bin/nvim`
2. **ripgrep** e **fd** in `~/.local/bin` (richiesti da LazyVim per ricerca/ctags)
3. **JetBrainsMono Nerd Font** in `~/.local/share/fonts`
4. **Config Omarchy** in `~/.config/nvim`
5. **Cache plugin pre-clonati** (51 plugin + mason) in `~/.local/share/nvim`
   → primo avvio istantaneo, nessun download di plugin
6. **Alias `n`** e PATH in `~/.zshrc` e `~/.bashrc`
7. **Neovim come editor predefinito** per i file di testo (xdg-mime)
8. **`Lazy sync`** headless per allineare i plugin al `lazy-lock.json`

Le versioni si possono cambiare con variabili d'ambiente, es.:

```bash
NVIM_VERSION=v0.11.5 ./install.sh
```

---

## La config Omarchy in dettaglio

È la config ufficiale `omarchy-nvim` (pacchetto Arch di Omarchy, repo
`pkgs.omarchy.org`), cioè **LazyVim** con queste personalizzazioni:

- **Tema di default**: *Tokyo Night* (`tokyonight-night`) — il tema predefinito
  di Omarchy OS. `lua/plugins/all-themes.lua` precarica anche tutti gli altri
  temi Omarchy (Matte Black, Gruvbox, Catppuccin, Rose Pine, Kanagawa, ecc.).
- **`relativenumber = false`** e **`autoformat = false`** (scelte Omarchy)
- **Clipboard remota OSC52** per sessioni tmux/ssh/herdr
- **Trasparenza** di sfondi e float (`plugin/after/transparency.lua`)
- **Hot-reload del tema** (`omarchy-theme-hotreload.lua`)
- **Animazioni scroll snacks disattivate**
- **News alert disattivati**
- **Extra**: `neo-tree` come file explorer
- **Mason** preinstallato con `stylua` e `shfmt`

### Cambiare tema

Modifica `~/.config/nvim/lua/plugins/theme.lua`. Esempio con Gruvbox:

```lua
return {
  { "ellisonleao/gruvbox.nvim" },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "gruvbox" },
  },
}
```

I plugin dei temi sono già installati: basta cambiare il nome del colorscheme.

---

## Comandi principali (come in Omarchy)

| Comando         | Azione                                  |
|-----------------|-----------------------------------------|
| `Spazio Spazio` | Trova file (fuzzy find)                 |
| `Spazio S G`    | Cerca nei file con grep                 |
| `Spazio E`      | Attiva/disattiva l'albero file          |
| `Ctrl+W W`      | Salta tra albero file ed editor         |
| `Shift+H` / `Shift+L` | Muoversi tra i buffer             |
| `Spazio B D`    | Chiudi buffer                           |
| `Spazio B O`    | Chiudi tutti gli altri buffer           |
| `Spazio G G`    | LazyGit in finestra flottante           |
| `Spazio U W`    | Attiva/disattiva soft wrap              |
| `:Lazy`         | Gestione plugin                         |
| `:Mason`        | Installa LSP/strumenti                  |

---

## Verifica dell'installazione

```bash
nvim --version | head -1          # NVIM v0.12.5
nvim --headless "+Lazy! sync" +qa # sincronizza plugin
nvim                              # avvia l'editor
```

---

## Disinstallazione / ripristino

```bash
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
rm -f ~/.local/bin/nvim ~/.local/bin/rg ~/.local/bin/fd
rm -rf ~/.local/nvim
# rimuovere manualmente l'alias `n` da ~/.zshrc e ~/.bashrc
```

I backup creati da `--refresh` si trovano in
`~/.config/nvim.backup.<timestamp>` e `~/.local/share/nvim.backup.<timestamp>`.

---

## Fonti

- Omarchy OS: <https://omarchy.org> / <https://github.com/basecamp/omarchy>
- Pacchetto ufficiale `omarchy-nvim`: <https://pkgs.omarchy.org>
- LazyVim: <https://www.lazyvim.org/>
- Manuale Neovim di Omarchy: `manual/16-neovim.md` nel repo Omarchy
# radiks_neovim
# radiks_neovim
