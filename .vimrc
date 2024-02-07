function s:configure_filetypes()
  filetype plugin on

  autocmd BufNewFile,BufRead *.ts,*.tsx setlocal filetype=javascript

  autocmd FileType * let [&l:formatoptions, &l:textwidth] = [&g:formatoptions, &g:textwidth]
  autocmd FileType gitcommit,mail if getline(0, 1) == [''] | startinsert | redraw! | endif
  autocmd FileType mail setlocal formatoptions+=w textwidth=72
endfunction

function s:configure_gui()
  if !has("gui_running")
    return
  endif

  set columns=1000 lines=1000
  set guioptions-=T
  set guioptions-=m
endfunction

function s:disable_colors()
  set t_Co=0
  syntax off
endfunction

function s:enable_views()
  set viewoptions=cursor

  autocmd BufWinEnter * silent! loadview
  autocmd BufWinLeave * silent! mkview
endfunction

function s:append_url()
  let url = input('URL: ')
  let command = printf('url %s', shellescape(url))
  let output = system(command)
  let trimmed_output = trim(output)

  let line = line('.') - 1
  call append(line, trimmed_output)

  normal k
endfunction

function s:comment_line(line, mask, opening, closing, indent)
  let line = a:line
  let trimmed_line = trim(line, a:mask)
  if empty(trimmed_line)
    let line = a:indent
  endif

  let width = strlen(a:indent)
  let indent = width ? line[:width - 1] : ''
  let content = line[width:]
  let space = empty(content) ? '' : ' '
  let line = indent . a:opening . space . content

  if !empty(a:closing)
    let line .= space . a:closing
  endif

  return line
endfunction

function s:line_commented(line, mask, opening, closing)
  let trimmed_line = trim(a:line, a:mask, 1)
  let trimmed_opening = trim(a:opening)
  if stridx(trimmed_line, trimmed_opening) != 0
    return v:false
  endif

  if empty(a:closing)
    return v:true
  endif

  let trimmed_line = trim(a:line, a:mask, 2)
  let trimmed_closing = trim(a:closing)
  let commented = strridx(trimmed_line, trimmed_closing) == strlen(trimmed_line) - strlen(trimmed_closing)
  return commented
endfunction

function s:uncomment_line(line, mask, opening, closing)
  if !s:line_commented(a:line, a:mask, a:opening, a:closing)
    echo [a:line]
    foo
    return a:line
  endif

  let line = a:line
  let pattern = printf('[%s]*', a:mask)
  let [start_pattern, end_pattern] = ['^' . pattern, pattern . '$']
  let start = matchstr(line, start_pattern)
  let end = matchstr(line, end_pattern)

  let opening_closing = trim(a:opening, a:mask, 2) . trim(a:closing, a:mask, 1)
  let index = strridx(line, opening_closing)
  let length = len(line) - len(opening_closing)
  if index == length
    let line = ''
  endif

  let string = start . a:opening
  let index = stridx(line, string)
  if index == 0
    let start_length = strlen(start)
    let string_length = strlen(string)
    let prefix = empty(start) ? '' : line[:start_length - 1]
    let line = prefix . line[string_length:]
  endif

  if !empty(a:closing)
    let string = a:closing . end
    let index = strridx(line, string)
    let line_length = strlen(line)
    let string_length = strlen(string)
    if index == line_length - string_length
      let line = line[:-(string_length + 1)]
      let end_length = strlen(end)
      if end_length
        let line = line[:-(end_length - 1)]
      endif
    endif
  endif

  let trimmed_line = trim(line, a:mask)
  if empty(trimmed_line)
    let line = ''
  endif

  return line
endfunction

function s:comment_code() range
  let comment_string = empty(&commentstring) ? '#%s' : &commentstring
  let [opening, closing] = split(comment_string, '\s*%s\s*', 1)

  let lines = getline(a:firstline, a:lastline)
  let mask = " \t"
  let comments = filter(copy(lines), {_, line -> s:line_commented(line, mask, opening, closing)})
  let comment_length = len(comments)
  let line_length = len(lines)
  let commenting = comment_length < line_length
  let nonempty_lines = filter(copy(lines), {_, line -> !empty(trim(line, mask))})

  if commenting
    if !empty(nonempty_lines)
      let pattern = printf('^[%s]*', mask)
      let indexes = map(copy(nonempty_lines), {_, line -> matchend(line, pattern)})
      let width = min(indexes)
      let indent = repeat(nonempty_lines[0][0], width)

      call map(lines, {_, line -> s:comment_line(line, mask, opening, closing, indent)})
    endif
  else
    let full_opening = opening . ' '
    if empty(closing)
      let full_closing = ''
    else
      let full_closing = ' ' . closing
    endif

    let opening_closing = opening . closing
    let commented_lines = filter(copy(nonempty_lines), {_, line -> stridx(line, full_opening) != -1 && strridx(line, full_closing) != -1 || strridx(line, opening_closing) == len(line) - len(opening_closing)})
    let commented_line_length = len(commented_lines)
    let nonempty_line_length = len(nonempty_lines)
    if commented_line_length == nonempty_line_length
      let [opening, closing] = [full_opening, full_closing]
    endif

    call map(lines, {_, line -> s:uncomment_line(line, mask, opening, closing)})
  endif

  let [start, end] = [a:firstline, a:lastline]
  call map(lines, {index, line -> setline(start + index, line)})

  normal ^
endfunction

function s:update_path()
  if isdirectory('.git')
    let output = systemlist('git ls-files')
    let paths = map(output, {_, path -> path =~ '/' ? fnamemodify(path, ':h') : ''})
  else
    let paths = systemlist('find -type d')
  endif

  call sort(paths)
  call uniq(paths)
  call extend(paths, [''], 0)
  let &path = join(paths, ',')
endfunction

function s:toggle_quickfix()
  let number = filter(range(1, winnr('$')), {_, number -> win_gettype(number) == 'quickfix'})->get(0)
  if !number
    cwindow
  elseif &buftype != 'quickfix'
    let id = win_getid(number)
    call win_gotoid(id)
  else
    cclose
  endif
endfunction

function s:format_code()
  update

  let path = 'node_modules/.bin/prettier'
  let executable = executable(path) ? path : 'NPM_CONFIG_UPDATE_NOTIFIER=false npx --loglevel=error prettier'
  let [line, column] = [line('.'), col('.')]
  let offset = abs(line2byte(line)) + column - 2
  let path = expand('%')
  let command = printf('NODE_NO_WARNINGS=1 %s --cursor-offset=%d --ignore-path= --stdin-filepath=%s', executable, offset, shellescape(path))
  let input = getline(1, '$')
  let output = systemlist(command, input)

  if v:shell_error
    echo join(output, "\n")
    echo get(output, 0, '')

    let line = get(output, 0, '')
    let match = matchlist(line, '(\(\d\+\):\(\d\+\))$')
    if len(match)
      call cursor(match[1], match[2])
    endif
  else
    let [lines, offset] = output != input ? [output[:-2], output[-1]] : [output, offset]
    if lines !=# input
      let view = winsaveview()

      call setline(1, lines)

      let number = len(lines) + 1
      let expression = printf('%d,$delete _', number)
      silent! execute expression

      call winrestview(view)

      if offset != -1
        let number = offset + 1
        let expression = printf('goto %d', number)
        execute expression
      endif
    endif
  endif

  update
endfunction

function s:map_keys()
  let g:mapleader = ' '

  cnoremap <C-A> <Home>
  cnoremap <C-E> <End>
  cnoremap <Esc>b <S-Left>
  cnoremap <Esc>f <S-Right>
  inoremap # X#
  inoremap <C-S> <C-O>:write<CR>
  nnoremap <C-S> :write<CR>
  nnoremap <Leader> <Nop>
  nnoremap <Leader>E :edit %:h/
  nnoremap <Leader>b :buffer<Space><C-D>
  nnoremap <Leader>e :edit<Space>
  nnoremap <Leader>f :find<Space>
  nnoremap <Leader>g :grep<Space>
  nnoremap <Leader>u :call <SID>append_url()<CR>
  nnoremap <silent> <Leader>/ :call <SID>comment_code()<CR>
  nnoremap <silent> <Leader>D :bdelete!<CR>
  nnoremap <silent> <Leader>F :call <SID>update_path()<CR>
  nnoremap <silent> <Leader>N :bnext<CR>
  nnoremap <silent> <Leader>P :bprevious<CR>
  nnoremap <silent> <Leader>q :call <SID>toggle_quickfix()<CR>
  nnoremap <silent> <Leader>R :silent! mkview<CR>:edit!<CR>:silent! loadview<CR>
  nnoremap <silent> <Leader>h :setlocal hlsearch!<CR>
  nnoremap <silent> <Leader>n :cnext<CR>
  nnoremap <silent> <Leader>p :cprevious<CR>
  nnoremap <silent> <Leader>r :call <SID>format_code()<CR>
  nnoremap <silent> <Leader>y :call system('wl-copy', expand('%'))<CR>
  nnoremap Q <Nop>
  vnoremap <silent> <Leader>/ :call <SID>comment_code()<CR>
  vnoremap <silent> <Leader>s :sort<CR>
endfunction

function s:patch_matchparen()
  highlight MatchParen term=underline

  let path = expand('~/.vim/plugin/matchparen.vim')
  if filereadable(path)
    return
  endif

  let filename = fnamemodify(path, ':t')
  let source = printf('%s/plugin/%s', $VIMRUNTIME, filename)
  let content = readfile(source)
  let substituted_content = map(content, {_, line -> substitute(line, ' || (&t_Co .*\|\[c_lnum,[^]]*], ', '', '')})

  let directory = fnamemodify(path, ':h')
  call mkdir(directory, 'p')
  call writefile(substituted_content, path)
endfunction

function s:purge_directories()
  let path = fnamemodify(&viewdir, ':h') . '/.purge'
  let delta = localtime() - getftime(path)
  let days = 30
  let seconds = 60 * 60 * 24 * days
  if delta < seconds
    return
  endif
  call writefile([], path)

  let command = printf('find %s %s %s -type f -mtime +%d -delete', shellescape(&directory), shellescape(&undodir), shellescape(&viewdir), days)
  call system(command)
endfunction

function s:set_directories()
  let path = fnamemodify(&viewdir, ':h')

  let &directory = path . '/swap'
  call mkdir(&directory, 'p')

  let &undodir = path . '/undo'
  call mkdir(&undodir, 'p')

  call s:purge_directories()
endfunction

function s:set_options()
  set nocompatible

  set autoindent
  set expandtab
  set shiftwidth=2
  set smartindent
  set softtabstop=2

  set grepformat=%f:%l:%c:%m
  set grepprg=rg\ --vimgrep

  set ignorecase
  set smartcase
  set nohlsearch
  set noincsearch

  set noruler
  set nostartofline
  set notitle
  set scrolloff=0
  set shortmess+=I

  set nowildmenu
  set wildignorecase
  set wildmode=list:longest,list:full

  set clipboard=unnamedplus
  set iskeyword+=-
  set suffixesadd=.js,.jsx,.ts,.tsx
  set undofile
endfunction

function s:main()
  call s:configure_filetypes()
  call s:configure_gui()
  call s:disable_colors()
  call s:enable_views()
  call s:map_keys()
  call s:patch_matchparen()
  call s:set_directories()
  call s:set_options()
  call s:update_path()
endfunction

call s:main()
