function s:comment_code(is_visual, is_commenting) range
  let [opening, closing] = split(empty(&commentstring) ? '#%s' : &commentstring, '%s', 1)
  let lines = getline(a:firstline, a:lastline)
  let column = min(map(copy(lines), {_, line -> len(matchstr(line, '^\s*'))})) + 1
  let range = a:is_visual ? "'<,'>" : ''
  if a:is_commenting
    execute printf("%snormal %d|i%s\<C-O>$%s\<Esc>\^", range, column, opening, closing)
  elseif empty(filter(lines, {_, line -> stridx(trim(line), opening) == -1 || stridx(line, closing, strlen(closing)) == -1}))
    execute printf('%snormal ^%d"_x$%s%d|', range, strlen(opening), repeat('"_x', strlen(closing)), column)
  endif
endfunction

function s:disable_colors()
  set t_Co=0
  syntax off
endfunction

function s:configure_filetypes()
  autocmd BufNewFile,BufRead *.ts,*.tsx setlocal filetype=javascript
  autocmd FileType * let [&l:formatoptions, &l:textwidth] = [&g:formatoptions, &g:textwidth]
  autocmd FileType mail setlocal formatoptions+=w textwidth=72 | if getline(0, '$') == [''] | startinsert | endif
endfunction

function s:enable_filetypes()
  filetype plugin on
  call s:configure_filetypes()
endfunction

function s:enable_views()
  autocmd BufWinEnter * silent! loadview
  autocmd BufWinLeave * silent! mkview
  set viewoptions=cursor
endfunction

function s:patch_matchparen()
  let path = expand('~/.vim/plugin/matchparen.vim')
  if !filereadable(path)
    call mkdir(fnamemodify(path, ':h'), 'p')
    call writefile(map(readfile(printf('%s/plugin/%s', $VIMRUNTIME, fnamemodify(path, ':t'))), {_, line -> substitute(line, ' || (&t_Co .*\|\[c_lnum,[^]]*], ', '', '')}), path)
  endif
  highlight MatchParen term=underline
endfunction

function s:set_directories()
  let path = fnamemodify(&viewdir, ':h')
  let &directory = path . '/swap'
  call mkdir(&directory, 'p')
  let &undodir = path . '/undo'
  call mkdir(&undodir, 'p')
endfunction

function s:format_code()
  let path = 'node_modules/.bin/prettier'
  let output = filter(systemlist(printf('NODE_NO_WARNINGS=1 %s --cursor-offset=%d --stdin-filepath=%s', executable(path) ? path : 'npx prettier', abs(line2byte(line('.'))) + col('.') - 2, shellescape(expand('%'))), getline(1, '$')), {index, line -> index > 0 || line !~# '^npx: installed'})
  if v:shell_error
    echo join(output, "\n")
    echo get(output, 0, '')
    let match = matchlist(get(output, 0, ''), '(\(\d\+\):\(\d\+\))$')
    if len(match)
      call cursor(match[1], match[2])
    endif
  else
    let [offset, output] = [output[-1], output[:-2]]
    if output !=# getline(1, '$')
      let view = winsaveview()
      call setline(1, output)
      silent! execute printf('%d,$delete _', len(output) + 1)
      call winrestview(view)
      if offset != -1
        execute 'goto' offset + 1
      endif
    endif
  endif
  write
endfunction

function s:update_path()
  let &path = join([''] + uniq(sort(map(systemlist('git ls-files'), {_, path -> path =~ '/' ? substitute(path, '/[^/]*$', '', '') : ''}))), ',')
endfunction

function s:map_keys()
  cnoremap <C-A> <Home>
  cnoremap <C-E> <End>
  cnoremap <Esc>b <S-Left>
  cnoremap <Esc>f <S-Right>
  inoremap <C-S> <C-O>:write<CR>
  nnoremap <C-S> :write<CR>
  nnoremap <Leader> <Nop>
  nnoremap <Leader>E :edit %:h/
  nnoremap <Leader>b :buffer<Space><C-D>
  nnoremap <Leader>e :edit<Space>
  nnoremap <Leader>f :find<Space>
  nnoremap <Leader>g :grep<Space>
  nnoremap <silent> <Leader>/ :call <SID>comment_code(v:false, v:true)<CR>
  nnoremap <silent> <Leader>? :call <SID>comment_code(v:false, v:false)<CR>
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
  vnoremap <silent> <Leader>/ :call <SID>comment_code(v:true, v:true)<CR>
  vnoremap <silent> <Leader>? :call <SID>comment_code(v:true, v:false)<CR>
  vnoremap <silent> <Leader>s :sort<CR>
endfunction

function s:set_keys()
  let g:mapleader = ' '
  call s:map_keys()
endfunction

function s:set_options()
  autocmd SwapExists * let v:swapchoice = 'o'
  set autoindent
  set clipboard=unnamedplus
  set expandtab
  set grepformat=%f:%l:%c:%m
  set grepprg=rg\ --vimgrep
  set ignorecase
  set iskeyword+=-
  set noruler
  set nostartofline
  set notitle
  set shiftwidth=2
  set shortmess+=I
  set smartcase
  set smartindent
  set softtabstop=2
  set suffixesadd=.js,.jsx,.ts,.tsx
  set undofile
  set wildignorecase
  set wildmode=list:longest,list:full
endfunction

function s:main()
  call s:disable_colors()
  call s:enable_filetypes()
  call s:enable_views()
  call s:patch_matchparen()
  call s:set_directories()
  call s:set_keys()
  call s:set_options()
  call s:update_path()
endfunction

call s:main()
