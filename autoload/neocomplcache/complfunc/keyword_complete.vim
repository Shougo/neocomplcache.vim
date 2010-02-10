"=============================================================================
" FILE: keyword_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 Feb 2010
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
" Version: 4.09, for Vim 7.0
"=============================================================================

function! neocomplcache#complfunc#keyword_complete#initialize()"{{{
  let s:plugins_func_table = {}

  " Initialize plugins table."{{{
  " Search autoload.
  let l:plugin_list = split(globpath(&runtimepath, 'autoload/neocomplcache/plugin/*.vim'), '\n')
  for list in l:plugin_list
    let l:plugin_name = fnamemodify(list, ':t:r')
    if !has_key(g:NeoComplCache_DisablePluginList, l:plugin_name) || 
          \ g:NeoComplCache_DisablePluginList[l:plugin_name] == 0
      let l:func = 'neocomplcache#plugin#' . l:plugin_name . '#'
      let s:plugins_func_table[l:plugin_name] = l:func
    endif
  endfor"}}}

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
  if g:NeoComplCache_EnableWildCard
    " Check wildcard.
    let l:cur_keyword_pos = neocomplcache#match_wildcard(a:cur_text, l:pattern, l:cur_keyword_pos)
  endif
  let l:cur_keyword_str = a:cur_text[l:cur_keyword_pos :]

  let l:start_length = (&l:completefunc == 'neocomplcache#manual_complete')?  
        \g:NeoComplCache_ManualCompletionStartLength : g:NeoComplCache_KeywordCompletionStartLength
  if l:cur_keyword_pos < 0 || len(l:cur_keyword_str) < l:start_length
    return -1
  endif

  return l:cur_keyword_pos
endfunction"}}}

function! neocomplcache#complfunc#keyword_complete#get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
  " Load plugin.
  let l:loaded_plugins = copy(s:plugins_func_table)

  " Get keyword list.
  let l:cache_keyword_lists = {}
  let l:is_empty = 1
  for l:plugin in keys(l:loaded_plugins)
    if has_key(g:NeoComplCache_PluginCompletionLength, l:plugin)
          \&& len(a:cur_keyword_str) < g:NeoComplCache_PluginCompletionLength[l:plugin]
      call remove(l:loaded_plugins, l:plugin)
      let l:cache_keyword_lists[l:plugin] = []
    else
      let l:cache_keyword_lists[l:plugin] = call(l:loaded_plugins[l:plugin] . 'get_keyword_list', [a:cur_keyword_str])
    endif

    if !empty(l:cache_keyword_lists[l:plugin])
      let l:is_empty = 0
    endif
  endfor
  if l:is_empty
    return []
  endif

  " Extend list.
  let l:cache_keyword_list = []
  for l:plugin in keys(l:loaded_plugins)
    let l:cache_keyword_list += l:cache_keyword_lists[l:plugin]
  endfor

  return l:cache_keyword_list
endfunction"}}}

function! neocomplcache#complfunc#keyword_complete#get_rank()"{{{
  return 5
endfunction"}}}

function! neocomplcache#complfunc#keyword_complete#get_manual_complete_list(plugin_name)"{{{
  if !has_key(s:plugins_func_table, a:plugin_name)
    return []
  endif

  " Set function.
  let &l:completefunc = 'neocomplcache#manual_complete'

  let l:cur_text = neocomplcache#get_cur_text()
  let l:cur_keyword_pos = neocomplcache#complfunc#keyword_complete#get_keyword_pos(l:cur_text)
  let l:cur_keyword_str = l:cur_text[l:cur_keyword_pos :]
  if l:cur_keyword_pos < 0 || len(l:cur_keyword_str) < g:NeoComplCache_ManualCompletionStartLength
    return []
  endif

  " Save options.
  let l:ignorecase_save = &ignorecase

  if g:NeoComplCache_SmartCase && l:cur_keyword_str =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase = g:NeoComplCache_IgnoreCase
  endif

  let l:plugins_func_save = s:plugins_func_table
  let s:plugins_func_table = { a:plugin_name : 'neocomplcache#plugin#' . a:plugin_name . '#' }
  let l:complete_words = neocomplcache#complfunc#keyword_complete#get_complete_words(l:cur_keyword_pos, l:cur_keyword_str)
  let s:plugins_func_table = l:plugins_func_save

  let &ignorecase = l:ignorecase_save

  return l:complete_words
endfunction"}}}


" vim: foldmethod=marker
