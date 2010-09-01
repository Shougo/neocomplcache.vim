"=============================================================================
" FILE: dictionary_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 29 Aug 2010
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

let s:source = {
      \ 'name' : 'dictionary_complete',
      \ 'kind' : 'plugin',
      \}

function! s:source.initialize()"{{{
  " Initialize.
  let s:dictionary_list = {}
  let s:completion_length = neocomplcache#get_auto_completion_length('dictionary_complete')

  " Initialize dictionary."{{{
  if !exists('g:neocomplcache_dictionary_filetype_lists')
    let g:neocomplcache_dictionary_filetype_lists = {}
  endif
  if !has_key(g:neocomplcache_dictionary_filetype_lists, 'default')
    let g:neocomplcache_dictionary_filetype_lists['default'] = ''
  endif
  "}}}

  " Set caching event.
  autocmd neocomplcache FileType * call s:caching()

  " Add command.
  command! -nargs=? -complete=customlist,neocomplcache#filetype_complete NeoComplCacheCachingDictionary call s:recaching(<q-args>)

  " Create cache directory.
  if !isdirectory(g:neocomplcache_temporary_dir . '/dictionary_cache')
    call mkdir(g:neocomplcache_temporary_dir . '/dictionary_cache')
  endif

  " Initialize check.
  call s:caching()
endfunction"}}}

function! s:source.finalize()"{{{
  delcommand NeoComplCacheCachingDictionary
endfunction"}}}

function! s:source.get_keyword_list(cur_keyword_str)"{{{
  let l:list = []

  let l:key = neocomplcache#is_text_mode() ? 'text' : neocomplcache#get_context_filetype()
  if neocomplcache#is_text_mode() && !has_key(s:dictionary_list, 'text')
    " Caching.
    call s:caching()
  endif

  for l:source in neocomplcache#get_sources_list(s:dictionary_list, l:key)
    let l:list += neocomplcache#dictionary_filter(l:source, a:cur_keyword_str, s:completion_length)
  endfor

  return l:list
endfunction"}}}

function! neocomplcache#sources#dictionary_complete#define()"{{{
  return s:source
endfunction"}}}

function! s:caching()"{{{
  if !bufloaded(bufnr('%'))
    return
  endif

  let l:key = neocomplcache#is_text_mode() ? 'text' : neocomplcache#get_context_filetype()
  for l:filetype in keys(neocomplcache#get_source_filetypes(l:key))
    if !has_key(s:dictionary_list, l:filetype)
      let s:dictionary_list[l:filetype] = s:initialize_dictionary(l:filetype)
    endif
  endfor
endfunction"}}}

function! s:recaching(filetype)"{{{
  if a:filetype == ''
    let l:filetype = neocomplcache#get_context_filetype(1)
  else
    let l:filetype = a:filetype
  endif

  " Caching.
  let s:dictionary_list[l:filetype] = s:caching_from_dict(l:filetype)
endfunction"}}}

function! s:initialize_dictionary(filetype)"{{{
  let l:keyword_lists = neocomplcache#cache#index_load_from_cache('dictionary_cache', a:filetype, s:completion_length)
  if !empty(l:keyword_lists)
    " Caching from cache.
    return l:keyword_lists
  endif

  return s:caching_from_dict(a:filetype)
endfunction"}}}

function! s:caching_from_dict(filetype)"{{{
  if has_key(g:neocomplcache_dictionary_filetype_lists, a:filetype)
    let l:dictionaries = g:neocomplcache_dictionary_filetype_lists[a:filetype]
  elseif a:filetype != &filetype || &l:dictionary == ''
    return {}
  else
    let l:dictionaries = &l:dictionary
  endif

  let l:keyword_list = []

  for l:dictionary in split(l:dictionaries, ',')
    if filereadable(l:dictionary)
      let l:keyword_list += neocomplcache#cache#load_from_file(l:dictionary, 
            \neocomplcache#get_keyword_pattern(a:filetype), 'D')
    endif
  endfor

  let l:keyword_dict = {}

  for l:keyword in l:keyword_list
    let l:key = tolower(l:keyword.word[: s:completion_length-1])
    if !has_key(l:keyword_dict, l:key)
      let l:keyword_dict[l:key] = []
    endif
    call add(l:keyword_dict[l:key], l:keyword)
  endfor 

  " Save dictionary cache.
  call neocomplcache#cache#save_cache('dictionary_cache', a:filetype, neocomplcache#unpack_dictionary(l:keyword_dict))

  return l:keyword_dict
endfunction"}}}
" vim: foldmethod=marker
