"=============================================================================
" FILE: omni_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 29 May 2013.
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
      \ 'name' : 'omni_complete',
      \ 'kind' : 'manual',
      \ 'compare_func' : 'neocomplcache#compare_nothing',
      \ 'mark' : '[O]',
      \ 'rank' : 50,
      \}

function! s:source.initialize() "{{{
  " Initialize omni completion pattern. "{{{
  if !exists('g:neocomplcache_omni_patterns')
    let g:neocomplcache_omni_patterns = {}
  endif
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_omni_patterns',
        \'html,xhtml,xml,markdown',
        \'<[^>]*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_omni_patterns',
        \'css,scss,sass',
        \'^\s\+\w\+\|\w\+[):;]\?\s\+\w*\|[@!]')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_omni_patterns',
        \'javascript',
        \'[^. \t]\.\%(\h\w*\)\?')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_omni_patterns',
        \'actionscript',
        \'[^. \t][.:]\h\w*')
  "call neocomplcache#util#set_default_dictionary(
        "\'g:neocomplcache_omni_patterns',
        "\'php',
        "\'[^. \t]->\h\w*\|\h\w*::')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_omni_patterns',
        \'java',
        \'\%(\h\w*\|)\)\.')
  "call neocomplcache#util#set_default_dictionary(
        "\'g:neocomplcache_omni_patterns',
        "\'perl',
        "\'\h\w*->\h\w*\|\h\w*::')
  "call neocomplcache#util#set_default_dictionary(
        "\'g:neocomplcache_omni_patterns',
        "\'c',
        "\'[^.[:digit:] *\t]\%(\.\|->\)'
  "call neocomplcache#util#set_default_dictionary(
        "\'g:neocomplcache_omni_patterns',
        "\'cpp',
        "\'[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_omni_patterns',
        \'objc',
        \'[^.[:digit:] *\t]\%(\.\|->\)')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_omni_patterns',
        \'objj',
        \'[\[ \.]\w\+$\|:\w*$')

  " External language interface check.
  if has('ruby')
    " call neocomplcache#util#set_default_dictionary(
          "\'g:neocomplcache_omni_patterns', 'ruby',
          "\'[^. *\t]\.\h\w*\|\h\w*::')
  endif
  if has('python/dyn') || has('python3/dyn')
        \ || has('python') || has('python3')
    call neocomplcache#util#set_default_dictionary(
          \'g:neocomplcache_omni_patterns',
          \'python', '[^. \t]\.\w*')
  endif
  "}}}
endfunction"}}}
function! s:source.finalize() "{{{
endfunction"}}}

function! s:source.get_keyword_pos(cur_text) "{{{
  let syn_name = neocomplcache#helper#get_syn_name(1)
  if syn_name ==# 'Comment' || syn_name ==# 'String'
    " Skip omni_complete in string literal.
    return -1
  endif

  let filetype = neocomplcache#get_context_filetype()
  let s:complete_results = s:set_complete_results_pos(
        \ s:get_omni_funcs(filetype), a:cur_text)

  return s:get_complete_pos(s:complete_results)
endfunction"}}}

function! s:source.get_complete_words(complete_pos, complete_str) "{{{
  return s:get_candidates(
        \ s:set_complete_results_words(s:complete_results),
        \ a:complete_pos, a:complete_str)
endfunction"}}}

function! neocomplcache#sources#omni_complete#define() "{{{
  return s:source
endfunction"}}}

function! s:get_omni_funcs(filetype) "{{{
  let funcs = []
  for ft in insert(split(a:filetype, '\.'), '_')
    if has_key(g:neocomplcache_omni_functions, ft)
      let omnifuncs =
            \ (type(g:neocomplcache_omni_functions[ft]) == type([])) ?
            \ g:neocomplcache_omni_functions[ft] :
            \ [g:neocomplcache_omni_functions[ft]]
    else
      let omnifuncs = [&l:omnifunc]
    endif

    for omnifunc in omnifuncs
      if neocomplcache#check_invalid_omnifunc(omnifunc)
        " omnifunc is irregal.
        continue
      endif

      if get(g:neocomplcache_omni_patterns, omnifunc, '') != ''
        let pattern = g:neocomplcache_omni_patterns[omnifunc]
      elseif get(g:neocomplcache_omni_patterns, ft, '') != ''
        let pattern = g:neocomplcache_omni_patterns[ft]
      else
        let pattern = ''
      endif

      if pattern == ''
        continue
      endif

      call add(funcs, [omnifunc, pattern])
    endfor
  endfor

  return neocomplcache#util#uniq(funcs)
endfunction"}}}
function! s:get_omni_list(list) "{{{
  let omni_list = []

  " Convert string list.
  for val in deepcopy(a:list)
    let dict = (type(val) == type('') ?
          \ { 'word' : val } : val)
    let dict.menu = '[O]' . get(dict, 'menu', '')
    call add(omni_list, dict)

    unlet val
  endfor

  return omni_list
endfunction"}}}

function! s:set_complete_results_pos(funcs, cur_text) "{{{
  " Try omnifunc completion. "{{{
  let complete_results = {}
  for [omnifunc, pattern] in a:funcs
    if neocomplcache#is_auto_complete()
          \ && a:cur_text !~ '\%(' . pattern . '\m\)$'
      continue
    endif

    " Save pos.
    let pos = getpos('.')

    try
      let complete_pos = call(omnifunc, [1, ''])
    catch
      call neocomplcache#print_error(
            \ 'Error occurred calling omnifunction: ' . omnifunc)
      call neocomplcache#print_error(v:throwpoint)
      call neocomplcache#print_error(v:exception)
      let complete_pos = -1
    finally
      if getpos('.') != pos
        call setpos('.', pos)
      endif
    endtry

    if complete_pos < 0
      continue
    endif

    let complete_str = a:cur_text[complete_pos :]

    let complete_results[omnifunc] = {
          \ 'candidates' : [],
          \ 'complete_pos' : complete_pos,
          \ 'complete_str' : complete_str,
          \ 'omnifunc' : omnifunc,
          \}
  endfor
  "}}}

  return complete_results
endfunction"}}}
function! s:set_complete_results_words(complete_results) "{{{
  " Try source completion.
  for [omnifunc, result] in items(a:complete_results)
    if neocomplcache#complete_check()
      return a:complete_results
    endif

    let pos = getpos('.')

    " Note: For rubycomplete problem.
    let complete_str =
          \ (omnifunc == 'rubycomplete#Complete') ?
          \ '' : result.complete_str

    try
      let list = call(omnifunc, [0, complete_str])
    catch
      call neocomplcache#print_error(
            \ 'Error occurred calling omnifunction: ' . omnifunc)
      call neocomplcache#print_error(v:throwpoint)
      call neocomplcache#print_error(v:exception)
      let list = []
    finally
      if getpos('.') != pos
        call setpos('.', pos)
      endif
    endtry

    if type(list) != type([])
      " Error.
      return a:complete_results
    endif

    let list = s:get_omni_list(list)

    let result.candidates = list
  endfor

  return a:complete_results
endfunction"}}}
function! s:get_complete_pos(complete_results) "{{{
  if empty(a:complete_results)
    return -1
  endif

  let complete_pos = col('.')
  for result in values(a:complete_results)
    if complete_pos > result.complete_pos
      let complete_pos = result.complete_pos
    endif
  endfor

  return complete_pos
endfunction"}}}
function! s:get_candidates(complete_results, complete_pos, complete_str) "{{{
  " Append prefix.
  let candidates = []
  let len_words = 0
  for [source_name, result] in items(a:complete_results)
    if result.complete_pos > a:complete_pos
      let prefix = a:complete_str[: result.complete_pos
            \                            - a:complete_pos - 1]

      for keyword in result.candidates
        let keyword.word = prefix . keyword.word
      endfor
    endif

    let candidates += result.candidates
  endfor

  return candidates
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
