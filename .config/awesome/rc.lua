local awful = require('awful')
local beautiful = require('beautiful')
local gears = require('gears')
local naughty = require('naughty')
require('awful.autofocus')

function bind_alt_tab()
  local count

  function activate_client(previous)
    if not client.focus then
      return
    end

    count = count + 1
    local clients = {}
    for _, client in ipairs(awful.client.focus.history.list) do
      if not client.hidden then
        local arguments = table.unpack(previous and { 1, client } or { client })
        table.insert(clients, arguments)
      end
    end
    local index = gears.table.hasitem(clients, client.focus) % #clients + 1
    clients[index]:jump_to()
  end

  local key = 'Tab'
  local modifier = 'Mod1'
  awful.keygrabber({
    export_keybindings = true,
    keybindings = {
      {
        { modifier },
        key,
        function()
          activate_client()
        end,
      },
      {
        { modifier, 'Shift' },
        key,
        function()
          activate_client(true)
        end,
      },
    },
    stop_event = 'release',
    stop_key = modifier,

    start_callback = function()
      count = 0
      awful.client.focus.history.disable_tracking()
    end,

    stop_callback = function()
      awful.client.focus.history.enable_tracking()
      if client.focus then
        awful.client.focus.history.add(client.focus)
      end
      if count <= 1 then
        return
      end

      local list = gears.table.reverse(awful.client.focus.history.list)
      gears.table.map(function(client)
        client:emit_signal('request::activate', 'bind_alt_tab', { raise = true })
      end, list)
    end,
  })
end

function configure_notifications()
  local size = 600
  beautiful.notification_max_height = size
  beautiful.notification_max_width = size
  naughty.config.defaults.bg = 'Black'
  naughty.config.defaults.border_color = '#ffffff'
  naughty.config.defaults.border_width = 1
  naughty.config.defaults.font = 'monospace 14'
  naughty.config.defaults.icon_size = 0
  naughty.config.defaults.margin = 5
  naughty.config.padding = 0
  naughty.config.spacing = 0
end

function create_tag()
  local screen = awful.screen.focused()
  awful.tag({ 0 }, screen, awful.layout.suit.max)
end

function run_or_raise(name, command, rule, shell)
  local default_rule = { name = ('^%s$'):format(name) }
  function match(client)
    return awful.rules.match(client, rule or default_rule)
  end

  if client.focus and match(client.focus) then
    local iterator = awful.client.iterate(match)
    iterator()
    local client = iterator()
    if client then
      client:jump_to()
    end
    return
  end

  local screen = awful.screen.focused()
  local client = awful.client.focus.history.get(screen, 0, match)
  if client then
    client:jump_to()
    return
  end

  local formatted_command = command:format(name, name, name, name)
  if shell then
    awful.spawn.with_shell(formatted_command)
  else
    awful.spawn(formatted_command, false)
  end
end

function set_keys()
  local groups = gears.string.split(gears.string.split(awesome.xkb_get_group_names():gsub('^[^+]++', ''), ':')[1], '+')
  local terminal_command = 'x-terminal-emulator -title %q -e '
  local xon_command = 'sh -c \'stty -ixon && exec "$@"\' -- %q'
  local terminal_tmux_command = terminal_command .. 'tmux new-session -Ad -s %q ' .. xon_command .. ' \\; set-option status off \\; attach-session -t %q'
  local terminal_xon_command = terminal_command .. xon_command
  local keys = gears.table.join(
    awful.key({ 'Control' }, 'F1', function()
      awful.spawn('parallels-keyboard', false)
    end),
    awful.key({ 'Control' }, 'space', function()
      local group = awesome.xkb_get_layout_group()
      local next_group = (group + 1) % #groups
      awesome.xkb_set_layout_group(next_group)
    end),
    awful.key({ 'Control', 'Mod1' }, 'Tab', function()
      naughty.destroy_all_notifications()
    end),
    awful.key({ 'Control', 'Mod1' }, 'a', function()
      run_or_raise('calc', terminal_xon_command)
    end),
    awful.key({ 'Control', 'Mod1' }, 'b', function()
      run_or_raise('acpi', terminal_command .. 'bash -c \'%s; read -s -n 1\'')
    end),
    awful.key({ 'Control', 'Mod1' }, 'c', function()
      run_or_raise('chromium', 'pgrep \'^%s$\' > /dev/null || exec %q', { class = 'Chromium' }, true)
    end),
    awful.key({ 'Control', 'Mod1' }, 'd', function()
      run_or_raise('sdcv', terminal_xon_command)
    end),
    awful.key({ 'Control', 'Mod1' }, 'e', function()
      local command = terminal_tmux_command:gsub(' exec ', ' while [ "$(stty size)" = 24\\ 80 ]]; do sleep 0.1; done &&%0')
      run_or_raise('mutt', command)
    end),
    awful.key({ 'Control', 'Mod1' }, 'f', function()
      awful.spawn.with_shell('path=~/.urls && [[ -f $path ]] && uniq "$path"{,~} && rm "$path" && exec xargs -r -a "$path"~ -d \'\\n\' x-www-browser')
    end),
    awful.key({ 'Control', 'Mod1' }, 'r', function()
      run_or_raise('dmenu_run', '%q -i -fn monospace-14 -nb Black -nf White -sb White -sf Black', { class = 'dmenu' })
    end),
    awful.key({ 'Control', 'Mod1' }, 's', function()
      run_or_raise('code', 'pgrep \'^codium$\' > /dev/null || exec %q', { class = 'VSCodium' }, true)
    end),
    awful.key({ 'Control', 'Mod1' }, 't', function()
      run_or_raise('tmux', terminal_command .. '%q new-session -A -s %q')
    end),
    awful.key({ 'Control', 'Mod1' }, 'w', function()
      run_or_raise('notes', terminal_tmux_command)
    end),
    awful.key({ 'Control', 'Mod1' }, 'x', function()
      run_or_raise('calendar', terminal_command .. 'bash -c \'printf "%%(%%F %%a %%I:%%M %%p)T\n\n" && cal -A 1 && read -s -n 1\'')
    end),
    awful.key({ 'Mod1' }, 'Escape', function()
      local tag = root.tags()[1]
      tag.selected = not tag.selected
    end),
    awful.key({ 'Mod1' }, 'F4', function()
      if client.focus then
        client.focus:kill()
      end
    end),
    awful.key({}, 'XF86AudioLowerVolume', function()
      awful.spawn.with_shell('pactl set-sink-mute 0 no && pactl set-sink-volume 0 -10%')
    end),
    awful.key({}, 'XF86AudioMute', function()
      awful.spawn.with_shell('pactl set-sink-mute 0 toggle')
    end),
    awful.key({}, 'XF86AudioRaiseVolume', function()
      awful.spawn.with_shell('pactl set-sink-mute 0 no && pactl set-sink-volume 0 +10%')
    end)
  )
  root.keys(keys)
end

function set_rules()
  awful.rules.rules = {
    {
      properties = {
        focus = awful.client.focus.filter,
        raise = true,
        size_hints_honor = false,

        callback = function(client)
          client:connect_signal('focus', function()
            awesome.xkb_set_layout_group(0)
          end)
        end,
      },
      rule = {},
    },
    {
      properties = {
        buttons = awful.button({ 'Mod1' }, 1, function(client)
          awful.mouse.client.move(client)
        end),
      },
      rule = { floating = true },
    },
    {
      properties = { floating = true },
      rule = { name = 'Event Tester' },
    },
    {
      properties = {
        border_width = 1,

        callback = function(client)
          awful.placement.centered(client)
        end
      },
      rule = { type = 'dialog' },
    },
  }
end

function main()
  bind_alt_tab()
  configure_notifications()
  create_tag()
  set_keys()
  set_rules()
end

main()
