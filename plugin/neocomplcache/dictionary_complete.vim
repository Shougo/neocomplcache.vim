"=============================================================================
" FILE: dictionary_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 05 Oct 2012.
"=============================================================================

if exists('g:loaded_neocomplcache_dictionary_complete')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Add commands. "{{{
command! -nargs=? -complete=customlist,neocomplcache#filetype_complete
      \ NeoComplCacheCachingDictionary
      \ call neocomplcache#sources#dictionary_complete#recaching(<q-args>)
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_neocomplcache_dictionary_complete = 1

" vim: foldmethod=marker
