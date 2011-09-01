"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 01 Sep 2011.
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

function! unite#sources#neocomplcache#define() "{{{
  if !exists('*unite#version') || unite#version() < 150
    echoerr 'Your unite.vim is too old.'
    echoerr 'Please install unite.vim Ver.1.5 or above.'
    return []
  endif

  return s:neocomplcache_source
endfunction "}}}

" neocomplcache unite source.
let s:neocomplcache_source = {
      \ 'name': 'neocomplcache',
      \ 'hooks' : {},
      \ }

function! s:neocomplcache_source.hooks.on_init(args, context) "{{{
  if !neocomplcache#is_enabled()
    let a:context.source__cur_keyword_pos = -1
    let a:context.source__complete_words = []
    return
  endif

  " Save options.
  let l:max_list_save = g:neocomplcache_max_list
  let l:max_keyword_width_save = g:neocomplcache_max_keyword_width
  let g:neocomplcache_max_list = -1
  let g:neocomplcache_max_keyword_width = -1

  let l:cur_text = neocomplcache#get_cur_text(1)
  let l:complete_results = neocomplcache#get_complete_results_pos(
        \ l:cur_text)
  let a:context.source__cur_keyword_pos =
        \ neocomplcache#get_cur_keyword_pos(l:complete_results)
  let a:context.source__complete_words = neocomplcache#get_complete_words(
        \ l:complete_results, 1, a:context.source__cur_keyword_pos,
        \ l:cur_text[a:context.source__cur_keyword_pos :])

  " Restore options.
  let g:neocomplcache_max_list = l:max_list_save
  let g:neocomplcache_max_keyword_width = l:max_keyword_width_save
endfunction"}}}

function! s:neocomplcache_source.gather_candidates(args, context) "{{{
  let l:keyword_pos = a:context.source__cur_keyword_pos
  let l:list = []
  for l:keyword in a:context.source__complete_words
    let l:dict = {
        \   'word' : l:keyword.word,
        \   'abbr' : printf('%-50s', (has_key(l:keyword, 'abbr') ? l:keyword.abbr : l:keyword.word)),
        \   'kind': 'completion',
        \   'action__complete_word' : l:keyword.word,
        \   'action__complete_pos' : l:keyword_pos,
        \ }
    if has_key(l:keyword, 'kind')
      let l:dict.abbr .= ' ' . l:keyword.kind
    endif
    if has_key(l:keyword, 'menu')
      let l:dict.abbr .= ' ' . l:keyword.menu
    endif
    if has_key(l:keyword, 'description')
      if type(l:keyword.description) ==# type(function('tr'))
        let l:dict.action__complete_info_lazy = l:keyword.description
      else
        let l:dict.action__complete_info = l:keyword.description
      endif
    endif

    call add(l:list, l:dict)
  endfor

  return l:list
endfunction "}}}

function! unite#sources#neocomplcache#start_complete() "{{{
  if !neocomplcache#is_enabled()
    return ''
  endif
  if !exists(':Unite')
    echoerr 'unite.vim is not installed.'
    echoerr 'Please install unite.vim Ver.1.5 or above.'
    return ''
  elseif unite#version() < 300
    echoerr 'Your unite.vim is too old.'
    echoerr 'Please install unite.vim Ver.3.0 or above.'
    return ''
  endif

  return unite#start_complete(['neocomplcache'], {
        \ 'auto_preview' : 1,
        \ })
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
