"=============================================================================
" FILE: omni_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 26 Jul 2012.
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
      \ 'kind' : 'complfunc',
      \ 'compare_func' : 'neocomplcache#compare_nothing',
      \}

function! s:source.initialize()"{{{
  " Initialize omni completion pattern."{{{
  if !exists('g:neocomplcache_omni_patterns')
    let g:neocomplcache_omni_patterns = {}
  endif
  call neocomplcache#set_dictionary_helper(g:neocomplcache_omni_patterns,
        \'html,xhtml,xml,markdown',
        \'<[^>]*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_omni_patterns,
        \'css',
        \'^\s\+\w\+\|\w\+[):;]\?\s\+\w*\|[@!]')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_omni_patterns,
        \'javascript',
        \'[^. \t]\.\%(\h\w*\)\?')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_omni_patterns,
        \'actionscript',
        \'[^. \t][.:]\h\w*')
  "call neocomplcache#set_dictionary_helper(g:neocomplcache_omni_patterns,
        "\'php',
        "\'[^. \t]->\h\w*\|\h\w*::')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_omni_patterns,
        \'java',
        \'\%(\h\w*\|)\)\.')
  "call neocomplcache#set_dictionary_helper(g:neocomplcache_omni_patterns,
        "\'perl',
        "\'\h\w*->\h\w*\|\h\w*::')
  "call neocomplcache#set_dictionary_helper(g:neocomplcache_omni_patterns,
        "\'c',
        "\'\%(\.\|->\)\h\w*')
  "call neocomplcache#set_dictionary_helper(g:neocomplcache_omni_patterns,
        "\'cpp',
        "\'\h\w*\%(\.\|->\)\h\w*\|\h\w*::')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_omni_patterns,
        \'objc',
        \'\h\w\+\|\h\w*\%(\.\|->\)\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_omni_patterns,
        \'objj',
        \'[\[ \.]\w\+$\|:\w*$')

  " External language interface check.
  if has('ruby')
    " call neocomplcache#set_dictionary_helper(g:neocomplcache_omni_patterns,
          "\'ruby',
          "\'[^. *\t]\.\h\w*\|\h\w*::')
  endif
  if has('python/dyn') || has('python3/dyn')
        \ || has('python') || has('python3')
    call neocomplcache#set_dictionary_helper(g:neocomplcache_omni_patterns,
          \'python', '[^. \t]\.\w*')
  endif
  "}}}

  " Initialize omni function list."{{{
  if !exists('g:neocomplcache_omni_functions')
    let g:neocomplcache_omni_functions = {}
  endif
  "}}}

  " Set rank.
  call neocomplcache#set_dictionary_helper(g:neocomplcache_source_rank,
        \ 'omni_complete', 300)
endfunction"}}}
function! s:source.finalize()"{{{
endfunction"}}}

function! s:source.get_keyword_pos(cur_text)"{{{
  let filetype = neocomplcache#get_context_filetype()

  if neocomplcache#is_eskk_enabled()
    let omnifunc = &l:omnifunc
  elseif has_key(g:neocomplcache_omni_functions, filetype)
    let omnifunc = g:neocomplcache_omni_functions[filetype]
  elseif &filetype == filetype
    let omnifunc = &l:omnifunc
  else
    " &omnifunc is irregal.
    return -1
  endif

  if omnifunc == ''
    return -1
  endif

  if has_key(g:neocomplcache_omni_patterns, omnifunc)
    let pattern = g:neocomplcache_omni_patterns[omnifunc]
  elseif has_key(g:neocomplcache_omni_patterns, filetype)
    let pattern = g:neocomplcache_omni_patterns[filetype]
  else
    let pattern = ''
  endif

  if !neocomplcache#is_eskk_enabled() && pattern == ''
    return -1
  endif

  if !neocomplcache#is_eskk_enabled()
        \ && neocomplcache#is_auto_complete()
        \ && a:cur_text !~ '\%(' . pattern . '\m\)$'
    return -1
  endif

  " Save pos.
  let pos = getpos('.')

  try
    let cur_keyword_pos = call(omnifunc, [1, ''])
  catch
    call neocomplcache#print_error(
          \ 'Error occured calling omnifunction: ' . omnifunc)
    call neocomplcache#print_error(v:throwpoint)
    call neocomplcache#print_error(v:exception)
    let cur_keyword_pos = -1
  finally
    if getpos('.') != pos
      call setpos('.', pos)
    endif
  endtry

  return cur_keyword_pos
endfunction"}}}

function! s:source.get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
  if neocomplcache#is_eskk_enabled()
        \ && exists('g:eskk#start_completion_length')
    " Check complete length.
    if neocomplcache#util#mb_strlen(a:cur_keyword_str) <
          \ g:eskk#start_completion_length
      return []
    endif
  endif

  let is_wildcard = g:neocomplcache_enable_wildcard
        \ && a:cur_keyword_str =~ '\*\w\+$'
        \ && neocomplcache#is_eskk_enabled()
        \ && neocomplcache#is_auto_complete()

  let filetype = neocomplcache#get_context_filetype()
  if neocomplcache#is_eskk_enabled()
    let omnifunc = &l:omnifunc
  elseif has_key(g:neocomplcache_omni_functions, filetype)
    let omnifunc = g:neocomplcache_omni_functions[filetype]
  elseif &filetype == filetype
    let omnifunc = &l:omnifunc
  endif

  let pos = getpos('.')
  if is_wildcard
    " Check wildcard.
    let cur_keyword_str = a:cur_keyword_str[:
          \ match(a:cur_keyword_str, '\%(\*\w\+\)\+$') - 1]
  else
    let cur_keyword_str = a:cur_keyword_str
  endif

  try
    let list = call(omnifunc, [0, cur_keyword_str])
  catch
    call neocomplcache#print_error(
          \ 'Error occured calling omnifunction: ' . omnifunc)
    call neocomplcache#print_error(v:throwpoint)
    call neocomplcache#print_error(v:exception)
    let list = []
  finally
    if getpos('.') != pos
      call setpos('.', pos)
    endif
  endtry

  if empty(list)
    return []
  endif

  if is_wildcard
    let list = neocomplcache#keyword_filter(
          \ s:get_omni_list(list), a:cur_keyword_str)
  else
    let list = s:get_omni_list(list)
  endif

  return list
endfunction"}}}

function! neocomplcache#sources#omni_complete#define()"{{{
  return s:source
endfunction"}}}

function! s:get_omni_list(list)"{{{
  let omni_list = []

  " Convert string list.
  for val in deepcopy(a:list)
    if type(val) == type('')
      let dict = { 'word' : val, 'menu' : '[O]' }
    else
      let dict = val
      let dict.menu = has_key(dict, 'menu') ?
            \ '[O] ' . dict.menu : '[O]'
    endif

    call add(omni_list, dict)

    unlet val
  endfor

  return omni_list
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
