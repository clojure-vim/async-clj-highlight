" vim-clojure-highlight

function! AsyncCljHighlightHandle(msg)
  let exists = a:msg[0]['value']
  if exists =~ 'nil'
      let buf = join(readfile(globpath(&runtimepath, 'autoload/vim_clojure_highlight.clj')), "\n")
      call AcidSendNrepl({'op': 'eval', 'code': "(do ". buf . ")"}, 'Ignore')
  endif
endfunction

function! AsyncCljHighlightRequire()
  call AcidSendNrepl({'op': 'eval', 'code': "(find-ns 'vim-clojure-highlight)"}, 'VimFn', 'AsyncCljHighlightHandle')
endfunction

function! AsyncCljHighlightExec(msg)
  let highlight = a:msg[0]['value']
  exec highlight
endfunction

" Pass zero explicitly to prevent highlighting local vars
function! vim_clojure_highlight#syntax_match_references(...)
  if !s:session_exists() | return | endif

  try
    call s:require()

    let opts = (a:0 > 0 && !a:1) ? ' :local-vars false' : ''

    execute AcidSendNrepl({"op": "eval", "code": "(vim-clojure-highlight/ns-syntax-command " . ns . opts . ")"}, 'VimFn', 'AsyncCljHighlightExec')
    let &syntax = &syntax
  catch /./
  endtry
endfunction
