#!/bin/bash
# Set plugin configuration via hyprctl eval (for Lua config mode)
# Must run after Hyprland and plugins are fully loaded

sleep 3

# dynamic-cursors and hyprfocus use hl.config()
hyprctl eval 'hl.config({
  plugin = {
    ["dynamic-cursors"] = {
      tilt = {
        limit = 5000,
        ["function"] = "quadratic",
        window = 100,
      },
      shaperule = "grab, stretch, stretch:limit: 2000",
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
})'

# hyprwinwrap (gen3vra) uses its own Lua API
hyprctl eval 'hl.plugin.hyprwinwrap.window({
    class = "com.leafman.doomfirewallpaper",
    pos_x = 0, pos_y = 0,
    size_x = 100, size_y = 100,
})'
