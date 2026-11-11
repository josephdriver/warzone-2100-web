# Warzone 2100 - Web Edition

The Warzone 2100 Web Edition uses [Emscripten](https://emscripten.org) to compile Warzone 2100 to run in modern web browsers via [WebGL2](https://get.webgl.org/webgl2/) and [WebAssembly](https://webassembly.org).

<!--ts-->
   * [Browser Compatibility](#browser-compatibility)
   * [Features & Differences](#features--differences)
   * [Persisting Data](#persisting-data)
   * [Campaign Videos](#campaign-videos)
   * [↗ Building](README-build.md)
<!--te-->

## Browser Compatibility:

To run Warzone 2100 in your web browser, we recommend:
- Recent versions of Chrome, Edge, Firefox, or Safari
  - With JavaScript and modern WebAssembly support enabled
- WebGL 2.0 support
- 4-8+ GiB of RAM
- Minimum 1024 x 768 resolution display / browser window
- Keyboard & mouse are also strongly recommended

The page will automatically perform a basic series of checks for compatibility and inform you if any issues were detected.

## Features & Differences:

This port is able to support most core Warzone 2100 features, including: campaign, challenges, and skirmish.

> [!TIP]
> Some functionality may be limited or not available, due to size constraints or restrictions of the browser environment.

| Feature                        | Web   |  Native  |
| :----------------------------- | :---: |  :---:   |
| Campaign                       | ✅    | ✅      |
| Campaign Videos                | ✅<sup>1</sup>  | ✅     |
| Challenges                     | ✅    | ✅      |
| Skirmish                       | ✅    | ✅      |
| Savegames                      | ✅    | ✅      |
| HQ graphics                    | ❌    | ✅      |
| HQ music                       | ❌    | ✅      |
| Additional music               | ❌    | ✅      |
| Multiplayer (online)           | ❌    | ✅       |
| Mods                           | ❌<sup>2</sup>  | ✅      |
| Multi-language support         | ✅<sup>3</sup>  | ✅      |
| Performance                    | 🆗    | ✅🚀    |

> [!NOTE]
> <sup><sup>1</sup> The Web port supports low-quality video sequences, which it streams on-demand. _An active Internet connection is required._</sup>  
> <sup><sup>2</sup> The Web port does not currently provide an interface for uploading mods into the configuration directory, but support _could_ be added in the future.</sup>  
> <sup><sup>3</sup> The Web port currently supports _most_ of the same languages, but certain languages that require additional large fonts (ex. Chinese, Korean, Japanese) are unsupported.</sup>

The Web Edition also ships with textures that have been optimized for size, at the expense of quality.

> If you want the highest quality textures, and the complete set of features, you should consider downloading the latest [native build for your system](https://github.com/Warzone2100/warzone2100/releases/latest).

## Embedded hosts

Battlewire sets `Module.wzUseHostViewport` to let the host size the canvas around
its controls. A resize observer updates the SDL window and renderer when the
canvas changes size, including fullscreen transitions. The host must suppress
the canvas context menu, as the standalone shell does.

`Module.wzHostRenderScalePercent` sets the initial 3D scene render percentage.
The exported `_wz_set_host_render_scale(percent)` changes it while running;
the interface stays at the drawable resolution. Battlewire's Auto choice targets
CSS pixel density with a roughly 1920 × 1080 scene budget, Performance uses 75%
of that linear scale, and High uses the full drawable resolution.

An optional `Module.wzBenchmarkFrame(cpuMs)` receives each completed game render's
CPU duration. It does not measure GPU completion. Battlewire enables sampling
only with `?benchmark=1`, warms up for five seconds, and records ten seconds.
The results stay in the page and browser console.

## Persisting Data:

The Web Edition can persist Warzone 2100 settings, configuration, savegames and more in your browser storage using technologies such as IndexedDB.

When you explicitly save your game, Warzone 2100 will ask the browser to opt-in to [persistent storage](https://web.dev/articles/persistent-storage).

Depending on your browser, you may receive a prompt (ex. on Firefox), or this may automatically succeed (or be denied by the browser) without any prompt or notice.

> [!TIP]
> By default, browsers store data in a "best-effort" manner.
> This means it may be cleared by the browser:
> - When storage is low
> - If a site hasn't been visited in a while
> - Or for other reasons
>  
> **Persistent storage can help prevent the browser from automatically evicting your saved games and data.**  
> See: [Storage for the Web: Eviction](https://web.dev/articles/storage-for-the-web#eviction)

> [!IMPORTANT]
> If you manually clear your browser's cache / history for all sites, this will still clear your savegames.

## Campaign Videos:

The Web Edition can automatically stream campaign video sequences on-demand (albeit at low-quality).

> [!IMPORTANT]
> If you've never played Warzone 2100 before, the campaign videos provide critical context for the plot of the campaign.  
> **It is strongly recommended you play with an active Internet connection** so these videos can be streamed during gameplay.

If you have a spotty Internet connection, you should strongly consider the native builds instead, which include the campaign videos for offline viewing.


## Battlewire host input and return

Battlewire's version 1 input adapter feeds the existing SDL pointer event path.
While pointer lock is active, the host supplies bounded movement deltas and
mirrors the engine's current CSS cursor. `Module.wzHostPointer` supplies normalized
`x`/`y` coordinates and an increasing `revision` for host input. The SDL backend
uses that absolute position for mouse events and reprojects it after a viewport
resize, keeping hit testing aligned with the visible cursor. Without that
optional state, ordinary SDL/native input behavior is unchanged. Battlewire consumes Enter before SDL
for its chat overlay and releases held input before suspending gameplay input.
Shared behavior is defined in the Battlewire checkout's
`docs/web-port-architecture.md`.

`Module._wz_request_host_return()` queues the native SDL quit event and returns
whether SDL accepted it. Hosts must wait for `wz_js_handle_app_exit`, which runs
after native shutdown and the final persistent-storage sync, before navigating.
The host-return path keeps IDBFS alive until that sync completes, then exits the
runtime. A sync failure calls `wz_js_handle_app_exit(error)` and retains the
filesystem for another `_wz_request_host_return()` attempt; the host must keep
the page open and offer retry.
Deploy the matching engine before enabling menu Return in Battlewire; older
engines do not expose this hook.
