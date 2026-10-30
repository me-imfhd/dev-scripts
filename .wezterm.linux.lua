-- Linux WezTerm configuration.
-- Same as the macOS config, with the original keybindings.
-- macOS version: .wezterm.lua

-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()


-- This is where you actually apply your config choices.
config.keys = {}

-- On macOS, WezTerm is launched by launchd and does not inherit PATH from
-- ~/.zshrc, so Homebrew / user binaries are not on PATH for run_child_process.
-- Resolve the tools used below explicitly instead of relying on PATH.
local function find_program(name)
    local home = wezterm.home_dir or os.getenv("HOME") or ""
    if home ~= "" and home:sub(1, 1) ~= "/" then
        home = "/" .. home
    end
    local candidates = {
        home .. "/.local/bin/" .. name,
        "/opt/homebrew/bin/" .. name,
        "/usr/local/bin/" .. name,
        "/usr/bin/" .. name,
        "/bin/" .. name,
    }
    for _, path in ipairs(candidates) do
        local handle = io.open(path, "r")
        if handle then
            handle:close()
            return path
        end
    end
    return name -- fall back to PATH lookup
end

local function absolute(path)
    if path and path ~= "" and path:sub(1, 1) ~= "/" then
        return "/" .. path
    end
    return path
end

local tmux = find_program("tmux")
local tmux_sessionizer = find_program("tmux-sessionizer")
local parallel_git = find_program("parallel-git")

-- run_child_process raises when the binary cannot be spawned. Return nil
-- instead, so a failed spawn cannot abort the whole key handler.
local function run_child_process(args)
    local ok, success, stdout = pcall(wezterm.run_child_process, args)
    if not ok or not success then
        return nil
    end
    return stdout
end

-- Appearance kept from the previous config.
config.initial_cols = 120
config.initial_rows = 28
config.window_background_opacity = 0.97
config.font_size = 16
config.font = wezterm.font("JetBrains Mono")
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
    if not tty then
        return false
    end

    local stdout = run_child_process({
        tmux,
        "list-clients",
        "-F",
        "#{client_tty}",
    })
    if not stdout then
        return false
    end

    for line in stdout:gmatch("[^\n]+") do
        if line == tty then
            return true
        end
    end

    return false
end

-- tmux (idle or busy) -> new tmux window
-- idle shell outside tmux -> run here
-- other process outside tmux -> do nothing
local function launch_cmd(event, key, window_name, cmd)
    cmd = absolute(cmd)
    wezterm.on(event, function(window, pane)
        if pane_in_tmux(pane) then
            local args = { tmux, "new-window", "-n", window_name }
            local tty = pane_tty(pane)
            if tty then
                local stdout = run_child_process({
                    tmux,
                    "display-message",
                    "-c",
                    tty,
                    "-p",
                    "#{pane_current_path}",
                })
                if stdout then
                    local cwd = absolute(stdout:gsub("%s+$", ""))
                    if cwd ~= "" then
                        table.insert(args, "-c")
                        table.insert(args, cwd)
                    end
                end
            end
            table.insert(args, cmd)
            run_child_process(args)
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
        mods = "SUPER",
        action = wezterm.action.EmitEvent(event),
    })
end

-- Cmd = between tmux sessions/projects.
launch_cmd("tmux-sessionizer", "f", "sessionizer", tmux_sessionizer)
launch_cmd("parallel-git", "m", "parallel-git", parallel_git) -- cwd must be the git worktree

local function tmux_cmd(name, mods, cmd, key)
    wezterm.on(name, function(window, pane)
        if pane_in_tmux(pane) then
            run_child_process(cmd)
        end
    end)

    table.insert(config.keys, {
        key = key,
        mods = mods,
        action = wezterm.action.EmitEvent(name),
    })
end

local function session_toggle(session, key)
    local event = session .. "-session-toggle"
    wezterm.on(event, function(window, pane)
        if pane_in_tmux(pane) then
            local tty = pane_tty(pane)
            if not tty then
                return
            end
            wezterm.run_child_process({
                os.getenv("HOME") .. "/.local/bin/tmux-switcher",
                session,
                tty,
            })
            return
        end

        local name = proc_basename(pane:get_foreground_process_name())
        if idle_shells[name] then
            window:perform_action(wezterm.action.SendString("tmux-switcher " .. session .. "\r"), pane)
        end
    end)

    table.insert(config.keys, {
        key = key,
        mods = "SUPER",
        action = wezterm.action.EmitEvent(event),
    })
end

-- Cmd+; toggles the pi tmux session.
session_toggle("pi", ";")

-- Use Option (Alt) for tmux window switching.
-- Option+K = next window, Option+J = previous window.
tmux_cmd("next-window", "ALT", { tmux, "next-window" }, "k")
tmux_cmd("prev-window", "ALT", { tmux, "previous-window" }, "j")

-- Option+1..9 selects tmux window 1..9 (tmux base-index is 1).
for i = 1, 9 do
    tmux_cmd("tmux-window-" .. i, "ALT", { tmux, "select-window", "-t", tostring(i) }, tostring(i))
end

-- Finally, return the configuration to wezterm:
return config
