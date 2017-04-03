" vim-clojure-highlight

if !exists('g:clojure_highlight_references')
  let g:clojure_highlight_references = 1
endif

if !exists('g:clojure_highlight_local_vars')
  let g:clojure_highlight_local_vars = 1
endif

function! s:disable_acid_log()
  if exists('b:acid_log_messages')
    let b:acid_old_log_value = b:acid_log_messages
  else
    let b:acid_log_messages = 0
  endif
endfunction

function! s:restore_acid_log()
  if exists('b:acid_old_log_value')
    let b:acid_log_messages = b:acid_old_log_value
    unlet b:acid_old_log_value
  else
    unlet b:acid_log_messages
  endif
endfunction

function! s:silent_acid_send(data, handler_fn)
  call s:disable_acid_log()
  echom "Disabled log: ".b:acid_log_messages
  call AcidSendNrepl(a:data, 'VimFn', a:handler_fn)
  call s:restore_acid_log()
endfunction

function! AsyncCljHighlightExec(msg)
  let fst = a:msg[0]
  if get(fst, 'value', '') !=# ''
    exec eval(fst.value)
    let &syntax = &syntax
    let b:async_clj_updated_highlight = 1
  elseif get(fst, 'err', '') !=# ''
    echohl ErrorMSG
    echo fst.err
    echohl NONE
  endif
endfunction

function! AsyncCljRequestHighlight(...)
  if a:0 > 0 && get(a:1[0], 'err', 0)
    echohl ErrorMSG
    echo a:1[0].err
    echohl NONE
    return
  endif

  let ns = AcidGetNs()
  let opts = g:clojure_highlight_local_vars ? '' : ' :local-vars false'
  call s:silen_acid_send({"op": "eval", "code": "(async-clj-highlight/ns-syntax-command '" . ns . opts . ")"}, 'AsyncCljHighlightExec')
endfunction

function! AsyncCljHighlightPrepare(msg)
  let exists = a:msg[0].value
  if exists =~ 'nil'
      let buf = join(readfile(globpath(&runtimepath, 'clj/async_clj_highlight.clj')), "\n")
      call s:silen_acid_send({'op': 'eval', 'code': "(do ". buf . ")"}, 'AsyncCljRequestHighlight')
  endif
  call AsyncCljRequestHighlight()
endfunction

function! s:syntax_match_references(bang)
  if g:clojure_highlight_references && (a:bang || !exists('b:b:async_clj_updated_highlight'))
    call s:silen_acid_send({'op': 'eval', 'code': "(find-ns 'async-clj-highlight)"}, 'AsyncCljHighlightPrepare')
  endif
endfunction

function! s:toggle_clojure_highlight_references()
  let g:clojure_highlight_references = !g:clojure_highlight_references

  if g:clojure_highlight_references
    call s:syntax_match_references(0)
  else
    unlet! b:clojure_syntax_keywords b:clojure_syntax_without_core_keywords
    let &syntax = &syntax
  endif
endfunction

augroup async_clj_highlight
  autocmd!
  autocmd User AcidRequired ClojureHighlightReferences
augroup END

command! -bar       ToggleClojureHighlightReferences call s:toggle_clojure_highlight_references()
command! -bar -bang ClojureHighlightReferences call s:syntax_match_references(<bang>0)

map <plug>AsyncCljDoHighlight :ClojureHighlightReferences!<CR>
