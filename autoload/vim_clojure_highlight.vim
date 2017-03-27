" vim-clojure-highlight

" Pass zero explicitly to prevent highlighting local vars
function! vim_clojure_highlight#syntax_match_references(...)
    call AcidSendNrepl({'op': 'eval', 'code': "(find-ns 'vim-clojure-highlight)"}, 'VimFn', 'AsyncCljHighlightHandle')
endfunction
