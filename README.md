# DevBar

A sleek macOS menu bar app that monitors your local dev servers.

<img width="340" alt="DevBar Screenshot" src="https://github.com/yanirmanor/devbar/raw/main/assets/screenshot.png">

## Features

- **Auto-detects** running dev servers on ports 3000–9000
- **Framework detection** — recognizes Next.js, Remix, Vite, Nuxt, Astro, SvelteKit, and more via `package.json`
- **One-click open** — launch any server in your default browser
- **Stop servers** — kill processes directly from the menu bar
- **Dark UI** — polished dark popover with status indicators and framework badges
- **Lightweight** — native Swift, no Electron, minimal resource usage
- **Auto-refresh** — scans every 5 seconds

## Install

### Homebrew

```bash
brew install yanirmanor/devbar/devbar
```

DevBar will appear in Spotlight, Raycast, and /Applications.

### Manual Build

Requires **macOS 13+** and **Swift 5.9+**.

```bash
git clone https://github.com/yanirmanor/devbar.git
cd devbar
make app
make install-app
```

Or to install as a CLI only:

```bash
make install
```

## Usage

1. Start any dev server (Next.js, Vite, etc.) on ports 3000–9000
2. Click the `</>` icon in your menu bar
3. See all running servers with framework badges
4. Click **Open** to launch in browser, or **X** to stop the server

## Supported Frameworks

| Framework | Detection |
|-----------|-----------|
| Next.js | `next` in package.json |
| Remix | `@remix-run` in package.json |
| Vite | `vite` in package.json |
| Nuxt | `nuxt` in package.json |
| Astro | `astro` in package.json |
| SvelteKit | `svelte` in package.json |
| Python | Process name |
| Rails | Process name |
| Go | Process name |

## Uninstall

```bash
brew uninstall devbar
```

## License

MIT
