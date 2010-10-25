"=============================================================================
" FILE: keyword_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 20 Aug 2010
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
      \ 'name' : 'keyword_complete',
      \ 'kind' : 'complfunc',
      \}

function! s:source.initialize()"{{{
  " Set rank.
  call neocomplcache#set_dictionary_helper(g:neocomplcache_plugin_rank, 'keyword_complete', 5)

  " Set completion length.
  call neocomplcache#set_completion_length('keyword_complete', 0)

  " Initialize.
  for l:plugin in values(neocomplcache#available_plugins())
    call l:plugin.initialize()
  endfor
endfunction"}}}
function! s:source.finalize()"{{{
  for l:plugin in values(neocomplcache#available_plugins())
    call l:plugin.finalize()
  endfor
endfunction"}}}

function! s:source.get_keyword_pos(cur_text)"{{{
  let [l:cur_keyword_pos, l:cur_keyword_str] = neocomplcache#match_word(a:cur_text)
  if l:cur_keyword_pos < 0
    " Empty string.
    return len(a:cur_text)
  endif

  return l:cur_keyword_pos
endfunction"}}}

function! s:source.get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
  " Get keyword list.
  let l:cache_keyword_list = []
  for [l:name, l:plugin] in items(neocomplcache#available_plugins())
    if (has_key(g:neocomplcache_plugin_disable, l:name)
        \ && g:neocomplcache_plugin_disable[l:name])
        \ || len(a:cur_keyword_str) < neocomplcache#get_completion_length(l:name)
      " Skip plugin.
      continue
    endif

    try
      let l:list = l:plugin.get_keyword_list(a:cur_keyword_str)
    catch
      call neocomplcache#print_error(v:throwpoint)
      call neocomplcache#print_error(v:exception)
      call neocomplcache#print_error('Error occured in plugin''s get_keyword_list()!')
      call neocomplcache#print_error('Plugin name is ' . l:name)
      return []
    endtry

    let l:rank = neocomplcache#get_plugin_rank(l:name)
    for l:keyword in l:list
      let l:keyword.rank = l:rank
    endfor
    let l:cache_keyword_list += l:list
  endfor

  return l:cache_keyword_list
endfunction"}}}

function! neocomplcache#sources#keyword_complete#define()"{{{
  return s:source
endfunction"}}}

" vim: foldmethod=marker
