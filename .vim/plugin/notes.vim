if getcwd() ==# expand('~/notes')
  function s:sync_notes()
    update
    let output = system('online sync-notes')
    if v:shell_error
      echo output
    endif
    checktime
  endfunction
  nnoremap <silent> <Leader>B :edit budget<CR>
  nnoremap <silent> <Leader>S :%!limit=500; read -r date amount; printf "\%(\%Y-\%m-\%d)T $((amount + ($(printf '\%(\%s)T') - $(date -d "$date" +\%s)) / (60 * 60 * 24) * limit - ($(paste -s -d +))))"<CR>
  nnoremap <silent> <Leader>T :edit tasks<CR>
  nnoremap <silent> <Leader>W :edit job<CR>
  nnoremap <silent> <Leader>s :call <SID>sync_notes()<CR>
endif
