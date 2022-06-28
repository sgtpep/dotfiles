function s:configure_filetypes()
  filetype plugin on

  autocmd BufNewFile,BufRead *.ts,*.tsx setlocal filetype=javascript

  autocmd FileType * let [&l:formatoptions, &l:textwidth] = [&g:formatoptions, &g:textwidth]
  autocmd FileType gitcommit,mail if getline(0, 1) == [''] | startinsert | endif
  autocmd FileType mail setlocal formatoptions+=w textwidth=72
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

function s:comment_line(line, mask, opening, closing, indent)
  let line = a:line
  if empty(trim(line, a:mask))
    let line = a:indent
  endif

  let width = strlen(a:indent)
  let line = (width ? line[:width - 1] : '') . a:opening . ' ' . line[width:]

  if !empty(a:closing)
    let line .= ' ' . a:closing
  endif

  return line
endfunction

function s:line_commented(line, mask, opening, closing)
  if stridx(trim(a:line, a:mask, 1), trim(a:opening)) != 0
    return v:false
  endif

  if empty(a:closing)
    return v:true
  endif

  let trimmed = trim(a:line, a:mask, 2)
  return strridx(trimmed, a:closing) == strlen(trimmed) - strlen(a:closing)
endfunction

function s:uncomment_line(line, mask, opening, closing)
  if !s:line_commented(a:line, a:mask, a:opening, a:closing)
    return a:line
  endif

  let line = a:line
  let pattern = printf('[%s]*', a:mask)
  let [start, end] = [matchstr(line, '^' . pattern), matchstr(line, pattern . '$')]

  let string = start . a:opening
  if stridx(line, string) == 0
    let line = (empty(start) ? '' : line[:strlen(start) - 1]) . line[strlen(string):]
  endif

  if !empty(a:closing)
    let string = a:closing . end
    if strridx(line, string) == strlen(line) - strlen(string)
      let line = line[:-(strlen(string) + 1)] . line[-strlen(end):]
    endif
  endif

  if empty(trim(line, a:mask))
    let line = ''
  endif

  return line
endfunction

function s:comment_code() range
  let [opening, closing] = split(empty(&commentstring) ? '#%s' : &commentstring, '\s*%s\s*', 1)

  let lines = getline(a:firstline, a:lastline)
  let mask = " \t"
  let comments = len(filter(copy(lines), {_, line -> s:line_commented(line, mask, opening, closing)}))
  let commenting = comments < len(lines)
  let nonempty_lines = filter(copy(lines), {_, line -> !empty(trim(line, mask))})

  if commenting
    if !empty(nonempty_lines)
      let pattern = printf('^[%s]*', mask)
      let width = min(map(copy(nonempty_lines), {_, line -> matchend(line, pattern)}))
      let indent = repeat(nonempty_lines[0][0], width)

      call map(lines, {_, line -> s:comment_line(line, mask, opening, closing, indent)})
    endif
  else
    if len(filter(copy(nonempty_lines), {_, line -> stridx(line, opening . ' ') != -1 && (empty(closing) || strridx(line, ' ' . closing) != -1)})) == len(nonempty_lines)
      let [opening, closing] = [opening . ' ', empty(closing) ? closing : ' ' . closing]
    endif

    call map(lines, {_, line -> s:uncomment_line(line, mask, opening, closing)})
  endif

  let [start, end] = [a:firstline, a:lastline]
  call map(lines, {index, line -> setline(start + index, line)})

  normal ^
endfunction

function s:format_code()
  update

  let path = 'node_modules/.bin/prettier'
  let command = executable(path) ? path : 'npx prettier'
  let offset = abs(line2byte(line('.'))) + col('.') - 2
  let path = expand('%')
  let input = getline(1, '$')
  let output = systemlist(printf('NODE_NO_WARNINGS=1 %s --cursor-offset=%d --stdin-filepath=%s', command, offset, shellescape(path)), input)
  let lines = filter(output, {index, line -> index > 0 || line !~# '^npx: installed'})

  if v:shell_error
    echo join(lines, "\n")
    echo get(lines, 0, '')

    let line = get(lines, 0, '')
    let match = matchlist(line, '(\(\d\+\):\(\d\+\))$')
    if len(match)
      call cursor(match[1], match[2])
    endif
  else
    let [offset, lines] = [lines[-1], lines[:-2]]
    if lines !=# input
      let view = winsaveview()
      call setline(1, lines)
      let expression = (len(lines) + 1) . ',$delete _'
      silent! execute expression
      call winrestview(view)

      if offset != -1
        execute 'goto' offset + 1
      endif
    endif
  endif

  update
endfunction

function s:update_path()
  let output = systemlist('git ls-files')
  let paths = uniq(sort(map(output, {_, path -> path =~ '/' ? substitute(path, '/[^/]*$', '', '') : ''})))
  let &path = join([''] + paths, ',')
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
  nnoremap <Leader>u :call append(line('.') - 1, trim(system('url ' . shellescape(input('URL: '))))) \| normal k<CR>
  nnoremap <silent> <Leader>/ :call <SID>comment_code()<CR>
  nnoremap <silent> <Leader>D :bdelete!<CR>
  nnoremap <silent> <Leader>F :call <SID>update_path()<CR>
  nnoremap <silent> <Leader>N :bnext<CR>
  nnoremap <silent> <Leader>P :bprevious<CR>
  nnoremap <silent> <Leader>R :silent! mkview<CR>:edit!<CR>:silent! loadview<CR>
  nnoremap <silent> <Leader>h :setlocal hlsearch!<CR>
  nnoremap <silent> <Leader>n :cnext<CR>
  nnoremap <silent> <Leader>p :cprevious<CR>
  nnoremap <silent> <Leader>r :call <SID>format_code()<CR>
  nnoremap <silent> <Leader>y :call system('xsel -b', expand('%'))<CR>
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

  let content = readfile(printf('%s/plugin/%s', $VIMRUNTIME, fnamemodify(path, ':t')))
  let updated_content = map(content, {_, line -> substitute(line, ' || (&t_Co .*\|\[c_lnum,[^]]*], ', '', '')})
  call mkdir(fnamemodify(path, ':h'), 'p')
  call writefile(updated_content, path)
endfunction

function s:set_directories()
  let path = fnamemodify(&viewdir, ':h')
  let &directory = path . '/swap'
  let &undodir = path . '/undo'

  call mkdir(&directory, 'p')
  call mkdir(&undodir, 'p')
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

  set noruler
  set nostartofline
  set notitle
  set shortmess+=I

  set wildignorecase
  set wildmode=list:longest,list:full

  set clipboard=unnamedplus
  set iskeyword+=-
  set suffixesadd=.js,.jsx,.ts,.tsx
  set undofile
endfunction

function s:main()
  call s:configure_filetypes()
  call s:disable_colors()
  call s:enable_views()
  call s:map_keys()
  call s:patch_matchparen()
  call s:set_directories()
  call s:set_options()
  call s:update_path()
endfunction

call s:main()
