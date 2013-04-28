"=============================================================================
" FILE: dictionary_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 28 Apr 2013.
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

" Important variables.
if !exists('s:dictionary_list')
  let s:dictionary_list = {}
  let s:async_dictionary_list = {}
endif

function! neocomplcache#sources#dictionary_complete#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'dictionary_complete',
      \ 'kind' : 'keyword',
      \ 'mark' : '[D]',
      \ 'rank' : 4,
      \}

function! s:source.initialize() "{{{
  " Initialize dictionary. "{{{
  if !exists('g:neocomplcache_dictionary_filetype_lists')
    let g:neocomplcache_dictionary_filetype_lists = {}
  endif
  if !has_key(g:neocomplcache_dictionary_filetype_lists, 'default')
    let g:neocomplcache_dictionary_filetype_lists['default'] = ''
  endif
  "}}}

  " Initialize dictionary completion pattern. "{{{
  if !exists('g:neocomplcache_dictionary_patterns')
    let g:neocomplcache_dictionary_patterns = {}
  endif
  "}}}

  " Set caching event.
  autocmd neocomplcache FileType * call s:caching()

  " Create cache directory.
  if !isdirectory(neocomplcache#get_temporary_directory() . '/dictionary_cache')
    call mkdir(neocomplcache#get_temporary_directory() . '/dictionary_cache')
  endif

  " Initialize check.
  call s:caching()
endfunction"}}}

function! s:source.finalize() "{{{
  delcommand NeoComplCacheCachingDictionary
endfunction"}}}

function! s:source.get_keyword_list(complete_str) "{{{
  let list = []

  let filetype = neocomplcache#is_text_mode() ?
        \ 'text' : neocomplcache#get_context_filetype()
  if !has_key(s:dictionary_list, filetype)
    " Caching.
    call s:caching()
  endif

  for ft in neocomplcache#get_source_filetypes(filetype)
    call neocomplcache#cache#check_cache('dictionary_cache', ft,
          \ s:async_dictionary_list, s:dictionary_list, 1)

    for dict in neocomplcache#get_sources_list(s:dictionary_list, ft)
      let list += neocomplcache#dictionary_filter(dict, a:complete_str)
    endfor
  endfor

  return list
endfunction"}}}

function! s:caching() "{{{
  if !bufloaded(bufnr('%'))
    return
  endif

  let key = neocomplcache#is_text_mode() ?
        \ 'text' : neocomplcache#get_context_filetype()
  for filetype in neocomplcache#get_source_filetypes(key)
    if !has_key(s:dictionary_list, filetype)
          \ && !has_key(s:async_dictionary_list, filetype)
      call neocomplcache#sources#dictionary_complete#recaching(filetype)
    endif
  endfor
endfunction"}}}

function! s:caching_dictionary(filetype)
  let filetype = a:filetype
  if filetype == ''
    let filetype = neocomplcache#get_context_filetype(1)
  endif

  if has_key(s:async_dictionary_list, filetype)
        \ && filereadable(s:async_dictionary_list[filetype].cache_name)
    " Delete old cache.
    call delete(s:async_dictionary_list[filetype].cache_name)
  endif

  call neocomplcache#sources#dictionary_complete#recaching(filetype)
endfunction
function! neocomplcache#sources#dictionary_complete#recaching(filetype) "{{{
  if !exists('g:neocomplcache_dictionary_filetype_lists')
    call neocomplcache#initialize()
  endif

  let filetype = a:filetype
  if filetype == ''
    let filetype = neocomplcache#get_context_filetype(1)
  endif

  " Caching.
  let dictionaries = get(
        \ g:neocomplcache_dictionary_filetype_lists, filetype, '')

  if dictionaries == ''
    if filetype != &filetype &&
          \ &l:dictionary != '' && &l:dictionary !=# &g:dictionary
      let dictionaries .= &l:dictionary
    endif
  endif

  let s:async_dictionary_list[filetype] = []

  let pattern = get(g:neocomplcache_dictionary_patterns, filetype,
        \ neocomplcache#get_keyword_pattern(filetype))
  for dictionary in split(dictionaries, ',')
    let dictionary = neocomplcache#util#substitute_path_separator(
          \ fnamemodify(dictionary, ':p'))
    if filereadable(dictionary)
      call neocomplcache#print_debug('Caching dictionary: ' . dictionary)
      call add(s:async_dictionary_list[filetype], {
            \ 'filename' : dictionary,
            \ 'cachename' : neocomplcache#cache#async_load_from_file(
            \       'dictionary_cache', dictionary, pattern, 'D')
            \ })
    endif
  endfor
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
