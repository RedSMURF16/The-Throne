<h1 align="center">The Throne</h1>

<p align="center">
  <a href="https://www.youtube.com/watch?v=8DYshbO30FY"><img src="https://img.youtube.com/vi/8DYshbO30FY/maxresdefault.jpg" alt="Watch on YouTube" width="600"></a>
</p>

## 📝 Description
This plugin adds placeable toilets to Counter-Strike 1.6, allowing players to sit down or force other players to take a dump complete with explosive surprises.
- Place and configure multiple Throne models around the map
- Send yourself or force other players onto a Throne via menu or chat commands
- Customize dump durations, intervals, and hold durations
- Configure explosion chances during each dump
- Customize voluntary and forced dump messages and toggle chat announcements
- Configure affected teams and team-based usage restrictions
- Play configurable flush and randomized dump sound effects
- Customize screen shake distance, amplitude, frequency, and duration
- Display customizable HUD messages and effects
- Allow players to vote to send others to the Throne
- Configure vote cooldown, duration, and required vote percentage
- Save, load, and dynamically reload Throne placements and configurations per map
- Create custom Throne presets (e.g., Team-specific, Explosive, Fast Long Dump)

## 📋 Requirements
- ReGameDLL
- AMX Mod X 1.10+

## ⚙️ Configuration
```ini
# To add a new The Throne, follow the example below:
# [The Throne Name]
# THRONE_TEAM              = 0 - None, 1 - Terrorist, 2 - Counter-Terrorist, 3 - Both
# THRONE_DUMP_DURATION     = Duration of the dump in seconds, can be a range like 4.0 7.0
# THRONE_DUMP_INTERVAL     = Interval between each dump in seconds, can be a range like 0.6 0.7
# THRONE_EXPLOSION_CHANCE  = Chance of an explosion happening each dump, 0.0 - 1.0
#
# Define a section name to make a Throne available in the menu.
# Models and sounds cannot be changed dynamically during gameplay.
```

## 🔄 Changelog
```text
* v1.0: Initial release.
```

[![Watch on YouTube](https://img.shields.io/badge/YouTube-Watch%20video-FF0000?logo=youtube&logoColor=white)](https://www.youtube.com/watch?v=8DYshbO30FY)
