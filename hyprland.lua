-- Minimal Hyprland session used by greetd to host the Caelestia greeter.
-- Monitors and the login user live in local.lua (see local.lua.example).

local dir   = os.getenv("CAELESTIA_GREETER_DIR") or "/etc/caelestia-greeter"
local home  = os.getenv("CAELESTIA_GREETER_HOME") or "/var/lib/caelestia-greeter-sync"
local cache = os.getenv("CAELESTIA_GREETER_CACHE") or "/var/cache/caelestia-greeter"

hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XCURSOR_SIZE", "24")
hl.env("CAELESTIA_GREETER_SESSION", "start-hyprland")

-- Machine-specific settings (monitors, user); may override the above
local ok, err = pcall(dofile, dir .. "/local.lua")
if not ok then print("caelestia-greeter: local.lua not loaded: " .. tostring(err)) end

hl.config({
    input = {
        kb_layout          = "us",
        numlock_by_default = false,
        repeat_delay       = 250,
        repeat_rate        = 35,
    },

    animations = {
        enabled = false,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        background_color         = "rgb(000000)",
    },
})

hl.on("hyprland.start", function()
    -- Quit the compositor once the greeter exits so greetd can start the session
    -- HOME points at the synced copy of the user's theme (see sync.sh)
    hl.exec_cmd("env -u XDG_STATE_HOME -u XDG_DATA_HOME -u XDG_CONFIG_HOME HOME=" .. home .. " XDG_CACHE_HOME=" .. cache .. " qs -p " .. dir .. "/shell.qml; hyprctl dispatch 'hl.dsp.exit()'")
end)
