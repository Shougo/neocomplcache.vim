scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

Context types
  It tests compare functions.
    ShouldEqual sort([{ 'word' : 'z0' }, { 'word' : 'z10' },
          \ { 'word' : 'z2'}, { 'word' : 'z3'} ],
          \ 'neocomplcache#compare_human'),
          \ [{ 'word' : 'z0' }, { 'word' : 'z2' },
          \  { 'word' : 'z3' }, { 'word' : 'z10' }]
  End
End

Fin

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
