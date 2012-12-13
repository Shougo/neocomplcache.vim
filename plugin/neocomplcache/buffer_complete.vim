"=============================================================================
" FILE: buffer_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 05 Oct 2012.
"=============================================================================

if exists('g:loaded_neocomplcache_buffer_complete')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Add commands. "{{{
command! -nargs=? -complete=file -bar
      \ NeoComplCacheCachingBuffer
      \ call neocomplcache#sources#buffer_complete#caching_buffer(<q-args>)
command! -nargs=? -complete=buffer -bar
      \ NeoComplCachePrintSource
      \ call neocomplcache#sources#buffer_complete#print_source(<q-args>)
command! -nargs=? -complete=buffer -bar
      \ NeoComplCacheOutputKeyword
      \ call neocomplcache#sources#buffer_complete#output_keyword(<q-args>)
command! -nargs=? -complete=buffer -bar
      \ NeoComplCacheDisableCaching
      \ call neocomplcache#sources#buffer_complete#disable_caching(<q-args>)
command! -nargs=? -complete=buffer -bar
      \ NeoComplCacheEnableCaching
      \ call neocomplcache#sources#buffer_complete#enable_caching(<q-args>)
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_neocomplcache_buffer_complete = 1

" vim: foldmethod=marker
