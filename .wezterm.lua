-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.
config.keys = {}
-- For example, changing the initial geometry for new windows:
config.initial_cols = 120
config.initial_rows = 28

-- or, changing the font size and color scheme.
config.font_size = 10
config.color_scheme = "Gruvbox Dark (Gogh)"

table.insert(config.keys, {
	key = "a",
	mods = "SUPER",
	action = wezterm.action.SendKey({ key = "a", mods = "CTRL" }),
})

local idle_shells = {
	zsh = true,
	bash = true,
	fish = true,
	sh = true,
	nu = true,
	dash = true,
}

local function proc_basename(path)
	path = path or ""
	local name = path:match("([^/]+)$") or path
	return name:gsub("^%-", "")
end

local function pane_tty(pane)
	local tty = pane.get_tty_name and pane:get_tty_name()
	if not tty or tty == "" then
		return nil
	end
	if not tty:match("^/") then
		tty = "/dev/" .. tty
	end
	return tty
end

local function pane_in_tmux(pane)
	local tty = pane_tty(pane)
	if tty then
		local ok, stdout = wezterm.run_child_process({
			"tmux",
			"list-clients",
			"-F",
			"#{client_tty}",
		})
		if ok and stdout then
			for line in stdout:gmatch("[^\n]+") do
				if line == tty then
					return true
				end
			end
		end
	end

	return false
end

-- tmux (idle or busy) -> new tmux window
-- idle shell outside tmux -> run here
-- other process outside tmux -> do nothing
local function launch_cmd(event, key, window_name, cmd)
	wezterm.on(event, function(window, pane)
		if pane_in_tmux(pane) then
			wezterm.run_child_process({
				"tmux",
				"new-window",
				"-n",
				window_name,
				cmd,
			})
			return
		end

		local name = proc_basename(pane:get_foreground_process_name())

		if idle_shells[name] then
			-- Idle shell: run in the current pane
			window:perform_action(wezterm.action.SendString(cmd .. "\r"), pane)
		end
	end)

	table.insert(config.keys, {
		key = key,
		mods = "ALT",
		action = wezterm.action.EmitEvent(event),
	})
end

launch_cmd("tmux-sessionizer", "f", "sessionizer", "tmux-sessionizer")

local function tmux_cmd(name, mods, cmd, key)
	wezterm.on(name, function(window, pane)
		if pane_in_tmux(pane) then
			wezterm.run_child_process(cmd)
		end
	end)

	table.insert(config.keys, {
		key = key,
		mods = mods,
		action = wezterm.action.EmitEvent(name),
	})
end

wezterm.on("fx-session-toggle", function(window, pane)
	if pane_in_tmux(pane) then
		local tty = pane_tty(pane)
		if not tty then
			return
		end
		wezterm.run_child_process({
			os.getenv("HOME") .. "/.local/bin/tmux-switcher",
			"pi",
			tty,
		})
		return
	end

	local name = proc_basename(pane:get_foreground_process_name())
	if idle_shells[name] then
		window:perform_action(wezterm.action.SendString("tmux-switcher pi\r"), pane)
	end
end)

table.insert(config.keys, {
	key = ";",
	mods = "ALT",
	action = wezterm.action.EmitEvent("fx-session-toggle"),
})

tmux_cmd("next-window", "SUPER", { "tmux", "next-window" }, "k")
tmux_cmd("prev-window", "SUPER", { "tmux", "previous-window" }, "j")

for i = 0, 9 do
	tmux_cmd("tmux-window-" .. i, "SUPER", { "tmux", "select-window", "-t", tostring(i) }, tostring(i))
end

-- Finally, return the configuration to wezterm:
return config
