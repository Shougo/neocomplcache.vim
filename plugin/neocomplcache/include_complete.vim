"=============================================================================
" FILE: include_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 05 Oct 2012.
"=============================================================================

if exists('g:loaded_neocomplcache_include_complete')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Add commands. "{{{
command! -nargs=? -complete=buffer NeoComplCacheCachingInclude
      \ call neocomplcache#sources#include_complete#caching_include(<q-args>)
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_neocomplcache_include_complete = 1

" vim: foldmethod=marker
