"=============================================================================
" FILE: keyword_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 23 Jun 2010
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

function! neocomplcache#complfunc#keyword_complete#initialize()"{{{
  let s:plugins_func_table = {}

  " Initialize plugins table."{{{
  " Search autoload.
  let l:plugin_list = split(globpath(&runtimepath, 'autoload/neocomplcache/plugin/*.vim'), '\n')
  for list in l:plugin_list
    let l:plugin_name = fnamemodify(list, ':t:r')
    if !has_key(g:neocomplcache_plugin_disable, l:plugin_name) || 
          \ g:neocomplcache_plugin_disable[l:plugin_name] == 0
      let l:func = 'neocomplcache#plugin#' . l:plugin_name . '#'
      let s:plugins_func_table[l:plugin_name] = l:func
    endif
  endfor"}}}

  " Set rank.
  call neocomplcache#set_variable_pattern('g:neocomplcache_plugin_rank', 'keyword_complete', 5)
  
  " Initialize.
  for l:plugin in values(s:plugins_func_table)
    call call(l:plugin . 'initialize', [])
  endfor
endfunction"}}}
function! neocomplcache#complfunc#keyword_complete#finalize()"{{{
  for l:plugin in values(s:plugins_func_table)
    call call(l:plugin . 'finalize', [])
  endfor
endfunction"}}}

function! neocomplcache#complfunc#keyword_complete#get_keyword_pos(cur_text)"{{{
  let l:pattern = neocomplcache#get_keyword_pattern_end()

  let l:cur_keyword_pos = match(a:cur_text, l:pattern)
  if g:neocomplcache_enable_wildcard
    " Check wildcard.
    let l:cur_keyword_pos = neocomplcache#match_wildcard(a:cur_text, l:pattern, l:cur_keyword_pos)
  endif

  return l:cur_keyword_pos
endfunction"}}}

function! neocomplcache#complfunc#keyword_complete#get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
  " Get keyword list.
  let l:cache_keyword_list = []
  for [l:plugin, l:funcname] in items(s:plugins_func_table)
    if !has_key(g:neocomplcache_plugin_completion_length, l:plugin)
          \|| !neocomplcache#is_auto_complete()
          \|| len(a:cur_keyword_str) >= g:neocomplcache_plugin_completion_length[l:plugin]
      let l:list = call(l:funcname . 'get_keyword_list', [a:cur_keyword_str])
      let l:rank = has_key(g:neocomplcache_plugin_rank, l:plugin)? 
              \ g:neocomplcache_plugin_rank[l:plugin] : g:neocomplcache_plugin_rank['keyword_complete']
      for l:keyword in l:list
        let l:keyword.rank = l:rank
      endfor
      let l:cache_keyword_list += l:list
    endif
  endfor

  return l:cache_keyword_list
endfunction"}}}

" vim: foldmethod=marker
