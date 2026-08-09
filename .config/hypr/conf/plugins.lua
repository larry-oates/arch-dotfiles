-- Plugin configuration for Hyprland Lua config
-- Plugins are loaded by hyprpm. Plugin config keys must be set at runtime
-- because the Lua parser validates keys before plugins register them.

hl.on("hyprland.start", function()
    -- hyprwinwrap (gen3vra) uses its own Lua API
    if hl.plugin.hyprwinwrap ~= nil then
        hl.plugin.hyprwinwrap.window({
            class = "com.leafman.doomfirewallpaper",
            pos_x = 0, pos_y = 0,
            size_x = 100, size_y = 100,
        })
    end

    -- dynamic-cursors and hyprfocus use hl.config()
    hl.config({
        plugin = {
            ["dynamic-cursors"] = {
                shaperule = {
                    { "grab", "stretch", "stretch:limit:2000" },
                    { "clientside", "none" },
                },
                tilt = {
                    limit = 5000,
                    ["function"] = "quadratic",
                    window = 100,
                },
                hyprcursor = {
                    nearest = true,
                    enabled = true,
                    resolution = -1,
                    fallback = "clientside",
                },
            },
            hyprfocus = {
                only_on_monitor_change = true,
            },
        },
    })
end)
