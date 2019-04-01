" vim-clojure-highlight

if !exists('g:clojure_highlight_local_vars')
  let g:clojure_highlight_local_vars = 1
endif

function! AsyncCljHighlightExec(value)
  exec eval(a:value)
  let &syntax = &syntax
endfunction

command! -bar -bang ClojureAsyncHighlight call luaeval("require('cljhl').preload()")

augroup async_clj_highlight
  autocmd!
  autocmd User AcidLoadedAllNSs ClojureAsyncHighlight
  autocmd User AcidRequired ClojureAsyncHighlight
augroup END

