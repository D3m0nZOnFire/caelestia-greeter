-- Minimal Hyprland session used by greetd to host the Caelestia greeter.
-- Monitors are kept in sync with ~/.config/hypr/hyprland-gui.lua by hand.

local dir   = os.getenv("CAELESTIA_GREETER_DIR") or "/etc/caelestia-greeter"
local home  = os.getenv("CAELESTIA_GREETER_HOME") or "/var/lib/caelestia-greeter-sync"
local cache = os.getenv("CAELESTIA_GREETER_CACHE") or "/var/cache/caelestia-greeter"

hl.monitor({
    output = "desc:GIGA-BYTE TECHNOLOGY CO. LTD. M27Q X 24050B001105",
    mode = "2560x1440@144.00Hz",
    position = "1800x1770",
    scale = 1,
    cm = "srgb",
})
hl.monitor({
    output = "desc:LG Electronics LG ULTRAGEAR+ 401NTTQ31481",
    mode = "3840x2160@60.00Hz",
    position = "0x0",
    scale = 1.2,
    transform = 1,
    cm = "srgb",
})

hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XCURSOR_SIZE", "24")
hl.env("CAELESTIA_GREETER_MONITOR", "DP-3")  -- shows the login card
hl.env("CAELESTIA_GREETER_USER", "ivo")
hl.env("CAELESTIA_GREETER_SESSION", "start-hyprland")

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
