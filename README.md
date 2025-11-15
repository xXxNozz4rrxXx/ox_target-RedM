# ox_target · CodexCore Fork (RedM)

A customized **RedM** fork of [`ox_target`](https://github.com/overextended/ox_target) integrated with **CodexCore** and bundled with a **Codex/qtarget-style API** and a custom **“3rd eye” NUI**.

---

## ✨ Features

- 🔐 **CodexCore integration**
  - Uses CodexCore jobs/groups for target permissions.
  - Optional item checks via `ox_inventory` (SOON will be fully ready for VORP , RSG , TPZ).

- 🧩 **CodexStudios / qtarget compatibility**
  - Provides `codexstudios-target` exports.
  - Keeps most existing Codex/qtarget-style scripts working with minimal changes.

- 🎯 **Custom NUI**
  - “3rd eye” crosshair UI.
  - Animated options list styled for Codex.

- ♻️ **Backwards-friendly**
  - Original `ox_target` exports still available.
  - Can gradually migrate scripts from qtarget-style to native ox_target.

---

## 📦 Requirements

- RedM (`game 'rdr3'` in your resource)
- [`ox_lib`](https://github.com/overextended/ox_lib) `3.0.0+`
- `codex_core` (framework / job system)
- `ox_inventory` *(optional, but recommended for item-based conditions)*

---

## ⚙️ Installation

1. Download / clone this repository into your RedM `resources` folder as:

   ```text
   resources/[ox]/ox_target
Ensure dependencies and this fork in your server.cfg in this order:

ensure ox_lib
ensure codex_core
ensure ox_inventory      # optional but recommended
ensure ox_target         # this fork


Remove or disable any other codexstudios-target / qtarget resource if you use this fork for compatibility.



🧠 Framework & Compatibility

This fork binds directly to codex_core:

Uses```exports['codex_core']:getLibClient()``` on the client.

Resolves player job / group through CodexCore.

It also provides:

ox_target
codexstudios-target


so scripts can call:

exports.ox_target:...
exports['codexstudios-target']:...

🚀 Quick Usage Examples

Native ox_target (recommended for new code):

```
exports.ox_target:addSphereZone({
    name   = 'codex_sheriff_armory',
    coords = vec3(-274.5, 806.2, 119.4),
    radius = 1.5,
    options = {
        {
            label  = 'Open Armory',
            icon   = 'fa-solid fa-gun',
            groups = { police = 2, sheriff = 1 },
            items  = { weapon_repeater_carbine = 1 },
            event  = 'codex-armory:open',
        }
    }
})
```


Codex/qtarget-style (compat layer):
```
exports['codexstudios-target']:AddBoxZone('bank', vector3(0.0, 0.0, 0.0), 2.0, 2.0, {
    name      = 'bank',
    heading   = 0.0,
    debugPoly = false,
    minZ      = 0.0,
    maxZ      = 2.0,
}, {
    options = {
        {
            label = 'Open Bank',
            icon  = 'fa-solid fa-vault',
            job   = { 'police', 'sheriff' },
            event = 'bank:open',
            type  = 'client',
        }
    },
    distance = 2.5
})
```
📜 Credits

Original ox_target by overextended.

CodexCore + compatibility & NUI integration by Codex Studios / this fork’s authors.

📄 License

This fork follows the license of the original ox_target project.
Check the original repository and adapt to your project’s licensing requirements.
