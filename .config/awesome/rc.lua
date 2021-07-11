local awful = require('awful')
local beautiful = require('beautiful')
local gears = require('gears')
local naughty = require('naughty')
local wibox = require('wibox')
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
        local arguments = previous and { 1, client } or { client }
        table.insert(clients, table.unpack(arguments))
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
      awful.client.focus.history.disable_tracking()

      count = 0
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

font_size = 14

function configure_notifications()
  local size = 600
  beautiful.notification_max_height = size
  beautiful.notification_max_width = size

  naughty.config.defaults.bg = 'Black'
  naughty.config.defaults.border_color = '#ffffff'
  naughty.config.defaults.border_width = 1
  naughty.config.defaults.font = 'monospace ' .. font_size
  naughty.config.defaults.icon_size = 0
  naughty.config.defaults.margin = 5
  naughty.config.padding = 0
  naughty.config.spacing = 0
end

xkb_groups = gears.string.split(gears.string.split(awesome.xkb_get_group_names():gsub('^[^+]++', ''), ':')[1], '+')

function toggle_keyboard_layot()
  local number = awesome.xkb_get_layout_group()
  local next_number = (number + 1) % #xkb_groups
  awesome.xkb_set_layout_group(next_number)
end

keyboard_layout = {
  {
    { 'Esc', 'Escape' },
    { 'F1', 'F1' },
    { 'F2', 'F2' },
    { 'F3', 'F3' },
    { 'F4', 'F4' },
    { 'F5', 'F5' },
    { 'F6', 'F6' },
    { 'F7', 'F7' },
    { 'F8', 'F8' },
    { 'F9', 'F9' },
    { 'F10', 'F10' },
    { 'F11', 'F11' },
    { 'F12', 'F12' },
    { 'Ins', 'Insert' },
    { 'Del', 'Delete' },
  },
  {
    { '`~', 49 },
    { '1!', 10 },
    { '2@', 11 },
    { '3#', 12 },
    { '4$', 13 },
    { '5%', 14 },
    { '6^', 15 },
    { '7&', 16 },
    { '8*', 17 },
    { '9(', 18 },
    { '0)', 19 },
    { '-_', 20 },
    { '=+', 21 },
    { 'Back', 'BackSpace' },
  },
  {
    { 'Tab', 'Tab' },
    { 'Q Й', 24 },
    { 'W Ц', 25 },
    { 'E У', 26 },
    { 'R К', 27 },
    { 'T Е', 28 },
    { 'Y Н', 29 },
    { 'U Г', 30 },
    { 'I Ш', 31 },
    { 'O Щ', 32 },
    { 'P З', 33 },
    { '[{Х', 34 },
    { ']}Ъ', 35 },
    { '\\|', 51 },
  },
  {
    { 'Ctrl', 'Control_L', true },
    { 'A Ф', 38 },
    { 'S Ы', 39 },
    { 'D В', 40 },
    { 'F А', 41 },
    { 'G П', 42 },
    { 'H Р', 43 },
    { 'J О', 44 },
    { 'K Л', 45 },
    { 'L Д', 46 },
    { '; Ж', 47 },
    { '\' Э', 48 },
    { '', 'Return' },
    { 'Enter', 'Return' },
  },
  {
    { 'Shift', 'Shift_L', true },
    { 'Z Я', 52 },
    { 'X Ч', 53 },
    { 'C С', 54 },
    { 'V М', 55 },
    { 'B И', 56 },
    { 'N Т', 57 },
    { 'M Ь', 58 },
    { ', Б', 59 },
    { '. Ю', 60 },
    { '/ .', 61 },
    { 'PgUp', 'Prior' },
    { '↑', 'Up' },
    { 'PgDn', 'Next' },
  },
  {
    { 'Lang', 'ISO_Next_Group' },
    { 'Alt', 'Alt_L', true },
    { '', 'space' },
    { '', 'space' },
    { '', 'space' },
    { '', 'space' },
    { '', 'space' },
    { '', 'space' },
    { '', 'space' },
    { 'Home', 'Home' },
    { 'End', 'End' },
    { '←', 'Left' },
    { '↓', 'Down' },
    { '→', 'Right' },
  },
}

function create_keyboard()
  local groups = {
    Return = {},
    space = {},
  }
  local modifiers = {}

  keyboard = awful.wibar({
    height = 285,
    ontop = true,
    position = 'bottom',
    visible = false,
  })
  local rows = gears.table.map(function(keys)
    local row = gears.table.map(function(key)
      local label, keysym, is_modifier = table.unpack(key)

      local markup
      if type(keysym) == 'string' then
        markup = gears.string.xml_escape(label)
      else
        local superscript = gears.string.xml_escape(label:sub(2, 2))
        local regular = gears.string.xml_escape(label:sub(1, 1))
        local subscript = gears.string.xml_escape(label:sub(3))
        markup = ('%s <sup>%s</sup> <sub>%s</sub>'):format(regular, superscript, subscript)
      end

      local cell = wibox.widget({
        widget = wibox.container.background,
        {
          align = 'center',
          font = 'sans-serif 9',
          markup = markup,
          valign = 'center',
          widget = wibox.widget.textbox,
        },
      })

      local update_bg_fg = function(bg, fg)
        for _, cell in ipairs(groups[keysym] or { cell }) do
          cell.bg, cell.fg = bg, fg
        end
      end

      local button = awful.button({}, 1, function()
        update_bg_fg('White', 'Black')

        if is_modifier then
          modifiers[keysym] = not modifiers[keysym] or nil                                              
          return
        end

        if keysym == 'ISO_Next_Group' then
          toggle_keyboard_layot()
          return
        end

        for modifier in pairs(modifiers) do
          root.fake_input('key_press', modifier)
        end
        root.fake_input('key_press', keysym)
        for modifier in pairs(modifiers) do
          root.fake_input('key_release', modifier)
          modifiers[modifier] = nil
        end
      end, function()
        cell:emit_signal('mouse::leave')
      end)
      cell:buttons(button)

      cell:connect_signal('mouse::leave', function()
        if not cell.bg or not cell.fg then
          return
        end

        update_bg_fg()

        if not is_modifier then
          root.fake_input('key_release', keysym)
        end
      end)

      if groups[keysym] then
        table.insert(groups[keysym], cell)
      end

      return cell
    end, keys)

    local rows = gears.table.join({
      layout = wibox.layout.flex.horizontal,
      spacing = -1,
    }, row)
    return rows
  end, keyboard_layout)

  local index = gears.table.hasitem(keyboard_layout, keys)
  local layout = gears.table.join({ layout = wibox.layout.flex.vertical }, rows)
  keyboard:setup({
    bottom = 10,
    layout = wibox.container.margin,
    layout,
  })

  toggle = awful.wibar({
    position = 'right',
    width = 2,
  })
  local button = awful.button({}, 1, function()
    keyboard.visible = not keyboard.visible
  end)
  toggle:buttons(button)
end

function create_tag()
  local screen = awful.screen.focused()
  awful.tag({ 0 }, screen, awful.layout.suit.max)
end

function run_or_raise(name, command, rule, shell)
  function match(client)
    local default_rule = { name = ('^%s$'):format(name) }
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

function set_background()
  gears.wallpaper.set(gears.color())
end

function set_keys()
  local terminal_command = 'x-terminal-emulator -title %q -e '
  local xon_command = 'sh -c \'stty -ixon && exec "$@"\' -- %q'
  local terminal_tmux_command = terminal_command .. 'tmux new-session -Ad -s %q ' .. xon_command .. ' \\; set-option status off \\; attach-session -t %q'
  local terminal_xon_command = terminal_command .. xon_command
  local keys = gears.table.join(
    awful.key({ 'Control' }, 'space', function()
      toggle_keyboard_layot()
    end),
    awful.key({ 'Control', 'Mod1' }, 'Tab', function()
      naughty.destroy_all_notifications()
    end),
    awful.key({ 'Control', 'Mod1' }, 'a', function()
      run_or_raise('calc', terminal_xon_command)
    end),
    awful.key({ 'Control', 'Mod1' }, 'c', function()
      run_or_raise('chromium', 'pgrep \'^%s$\' > /dev/null || exec %q', { class = 'Chromium' }, true)
    end),
    awful.key({ 'Control', 'Mod1' }, 'd', function()
      run_or_raise('sdcv', terminal_xon_command)
    end),
    awful.key({ 'Control', 'Mod1' }, 'e', function()
      local command = terminal_tmux_command:gsub(' exec ', ' while [ "$(stty size)" = 24\\ 80 ]; do sleep 0.1; done &&%0')
      run_or_raise('mutt', command)
    end),
    awful.key({ 'Control', 'Mod1' }, 'g', function()
      awful.spawn.with_shell('path=~/.urls; [[ -f $path ]] || exit 0; uniq "$path"{,~}; rm "$path"; exec xargs -r -a "$path"~ x-www-browser')
    end),
    awful.key({ 'Control', 'Mod1' }, 'r', function()
      local command = ('%%q -i -fn monospace-%d -nb Black -nf White -sb White -sf Black'):format(font_size)
      run_or_raise('dmenu_run', command, { class = 'dmenu' })
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
    awful.key({ 'Mod1' }, 'F4', function()
      if client.focus then
        client.focus:kill()
      end
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
  create_keyboard()
  create_tag()
  set_background()
  set_keys()
  set_rules()
end

main()
