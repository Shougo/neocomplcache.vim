"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 22 Apr 2011.
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

  let [a:context.source__cur_keyword_pos, l:cur_keyword_str, a:context.source__complete_words] =
        \ neocomplcache#integrate_completion(neocomplcache#get_complete_result(neocomplcache#get_cur_text(1)), 1)

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
      let l:dict.action__complete_info = l:keyword.description
    endif

    call add(l:list, l:dict)
  endfor

  return l:list
endfunction "}}}

function! unite#sources#neocomplcache#start_complete() "{{{
  if !neocomplcache#is_enabled()
    return ''
  endif

  return printf("\<ESC>:call unite#start(['neocomplcache'],
        \ { 'col' : %d, 'complete' : 1, 'auto_preview' : 1,
        \   'direction' : 'rightbelow', 'winheight' : 10,
        \   'buffer_name' : 'completion', })\<CR>", col('.'))
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
