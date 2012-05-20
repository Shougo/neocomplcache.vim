"=============================================================================
" FILE: keyword_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 20 May 2012.
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
      \ 'name' : 'keyword_complete',
      \ 'kind' : 'complfunc',
      \}

function! s:source.initialize()"{{{
  " Set rank.
  call neocomplcache#set_dictionary_helper(g:neocomplcache_source_rank,
        \ 'keyword_complete', 5)

  " Set completion length.
  call neocomplcache#set_completion_length('keyword_complete',
        \ g:neocomplcache_auto_completion_start_length)

  " Initialize.
  for plugin in values(neocomplcache#available_plugins())
    call plugin.initialize()
  endfor
endfunction"}}}
function! s:source.finalize()"{{{
  for plugin in values(neocomplcache#available_plugins())
    call plugin.finalize()
  endfor
endfunction"}}}

function! s:source.get_keyword_pos(cur_text)"{{{
  let [cur_keyword_pos, cur_keyword_str] = neocomplcache#match_word(a:cur_text)

  return cur_keyword_pos
endfunction"}}}

function! s:source.get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
  " Get keyword list.
  let cache_keyword_list = []
  for [name, plugin] in items(neocomplcache#available_plugins())
    if neocomplcache#complete_check()
      return []
    endif

    if !neocomplcache#is_source_enabled(name)
        \ || len(a:cur_keyword_str) < neocomplcache#get_completion_length(name)
        \ || neocomplcache#is_plugin_locked(name)
      " Skip plugin.
      continue
    endif

    try
      let list = plugin.get_keyword_list(a:cur_keyword_str)
    catch
      call neocomplcache#print_error(v:throwpoint)
      call neocomplcache#print_error(v:exception)
      call neocomplcache#print_error(
            \ 'Error occured in plugin''s get_keyword_list()!')
      call neocomplcache#print_error('Plugin name is ' . name)
      return []
    endtry

    let rank = neocomplcache#get_source_rank(name)
    for keyword in list
      let keyword.rank = rank
    endfor
    let cache_keyword_list += list
  endfor

  return cache_keyword_list
endfunction"}}}

function! neocomplcache#sources#keyword_complete#define()"{{{
  return s:source
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
