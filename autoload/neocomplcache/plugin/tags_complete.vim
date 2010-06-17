"=============================================================================
" FILE: tags_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 Jun 2010
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

function! neocomplcache#plugin#tags_complete#initialize()"{{{
  " Initialize
  let s:tags_list = {}
  let s:completion_length = neocomplcache#get_auto_completion_length('tags_complete')

  " Create cache directory.
  if !isdirectory(g:neocomplcache_temporary_dir . '/tags_cache')
    call mkdir(g:neocomplcache_temporary_dir . '/tags_cache', 'p')
  endif

  command! -nargs=? -complete=buffer NeoComplCacheCachingTags call s:caching_tags(<q-args>, 1)
endfunction"}}}

function! neocomplcache#plugin#tags_complete#finalize()"{{{
  delcommand NeoComplCacheCachingTags
endfunction"}}}

function! neocomplcache#plugin#tags_complete#get_keyword_list(cur_keyword_str)"{{{
  if !has_key(s:tags_list, bufnr('%'))
    call s:caching_tags(bufnr('%'), 0)
  endif

  if empty(s:tags_list[bufnr('%')])
    return []
  endif
  let l:tags_list = s:tags_list[bufnr('%')]

  let l:keyword_list = []
  let l:key = tolower(a:cur_keyword_str[: s:completion_length-1])
  if len(a:cur_keyword_str) < s:completion_length || neocomplcache#check_match_filter(l:key)
    for tags in values(l:tags_list)
      let l:keyword_list += neocomplcache#unpack_dictionary(tags)
    endfor
  else
    for tags in values(l:tags_list)
      if has_key(tags, l:key)
        let l:keyword_list += tags[l:key]
      endif
    endfor
  endif

  return neocomplcache#member_filter(l:keyword_list, a:cur_keyword_str)
endfunction"}}}

function! s:caching_tags(bufname, force)"{{{
  let l:bufnumber = (a:bufname == '') ? bufnr('%') : bufnr(a:bufname)
  let s:tags_list[l:bufnumber] = {}
  for tags in split(getbufvar(l:bufnumber, '&tags'), ',')
    let l:filename = fnamemodify(tags, ':p')
    if filereadable(l:filename)
          \&& (a:force || getfsize(l:filename) < g:neocomplcache_caching_limit_file_size)
      let s:tags_list[l:bufnumber][l:filename] = s:initialize_tags(l:filename)
    endif
  endfor
endfunction"}}}
function! s:initialize_tags(filename)"{{{
  " Initialize tags list.

  let l:keyword_lists = neocomplcache#cache#index_load_from_cache('tags_cache', a:filename, s:completion_length)
  if !empty(l:keyword_lists)
    return l:keyword_lists
  endif

  let l:ft = &filetype
  if l:ft == ''
    let l:ft = 'nothing'
  endif

  let l:keyword_lists = {}
  let l:loaded_list = neocomplcache#cache#load_from_tags('tags_cache', a:filename, readfile(a:filename), 'T', l:ft)
  if len(l:loaded_list) > 300
    call neocomplcache#cache#save_cache('tags_cache', a:filename, l:loaded_list)
  endif

  for l:keyword in l:loaded_list
    let l:key = tolower(l:keyword.word[: s:completion_length-1])
    if !has_key(l:keyword_lists, l:key)
      let l:keyword_lists[l:key] = []
    endif

    call add(l:keyword_lists[l:key], l:keyword)
  endfor 

  return l:keyword_lists
endfunction"}}}

" vim: foldmethod=marker
