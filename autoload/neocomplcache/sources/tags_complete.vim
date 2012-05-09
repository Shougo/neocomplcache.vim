"=============================================================================
" FILE: tags_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 09 May 2012.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:source = {
      \ 'name' : 'tags_complete',
      \ 'kind' : 'plugin',
      \}

function! s:source.initialize()"{{{
  " Initialize
  let s:async_tags_list = {}
  let s:tags_list = {}
  let s:completion_length =
        \ neocomplcache#get_auto_completion_length('tags_complete')

  " Create cache directory.
  if !isdirectory(neocomplcache#get_temporary_directory() . '/tags_cache')
    call mkdir(neocomplcache#get_temporary_directory() . '/tags_cache', 'p')
  endif

  command! -nargs=0 -bar
        \ NeoComplCacheCachingTags
        \ call s:caching_tags(1)
endfunction"}}}

function! s:source.finalize()"{{{
  delcommand NeoComplCacheCachingTags
endfunction"}}}

function! neocomplcache#sources#tags_complete#define()"{{{
  return s:source
endfunction"}}}

function! s:source.get_keyword_list(cur_keyword_str)"{{{
  if !has_key(s:async_tags_list, bufnr('%'))
        \ && !has_key(s:tags_list, bufnr('%'))
    call s:caching_tags(0)
  endif

  if neocomplcache#within_comment()
    return []
  endif

  call neocomplcache#cache#check_cache(
        \ 'tags_cache', bufnr('%'), s:async_tags_list,
        \ s:tags_list, s:completion_length)

  if !has_key(s:tags_list, bufnr('%'))
    return []
  endif
  let keyword_list = neocomplcache#dictionary_filter(
        \ s:tags_list[bufnr('%')], a:cur_keyword_str, s:completion_length)

  return neocomplcache#keyword_filter(keyword_list, a:cur_keyword_str)
endfunction"}}}

function! s:initialize_tags(filename)"{{{
  " Initialize tags list.
  let ft = &filetype
  if ft == ''
    let ft = 'nothing'
  endif

  return {
        \ 'filename' : a:filename,
        \ 'cachename' : neocomplcache#cache#async_load_from_tags(
        \              'tags_cache', a:filename, ft, 'T', 0)
        \ }
endfunction"}}}
function! s:caching_tags(force)"{{{
  let bufnumber = bufnr('%')

  let s:async_tags_list[bufnumber] = []
  for tags in map(tagfiles(),
        \ "neocomplcache#util#substitute_path_separator(
        \    fnamemodify(v:val, ':p'))")
    if a:force || getfsize(tags)
          \         < g:neocomplcache_caching_limit_file_size
      call add(s:async_tags_list[bufnumber],
            \ s:initialize_tags(tags))
    endif
  endfor
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
