"=============================================================================
" FILE: completefunc_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 25 Jul 2010
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
      \ 'name' : 'completefunc_complete',
      \ 'kind' : 'complfunc',
      \}

function! s:source.initialize()"{{{
  " Set rank.
  call neocomplcache#set_dictionary_helper(g:neocomplcache_plugin_rank, 'completefunc_complete', 5)
endfunction"}}}
function! s:source.finalize()"{{{
endfunction"}}}

function! s:source.get_keyword_pos(cur_text)"{{{
  return -1
endfunction"}}}

function! s:source.get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
  return []
endfunction"}}}

function! neocomplcache#sources#completefunc_complete#define()"{{{
  return s:source
endfunction"}}}

function! s:get_completefunc_list(list)"{{{
  let l:comp_list = []

  " Convert string list.
  for str in filter(copy(a:list), 'type(v:val) == '.type(''))
    let l:dict = { 'word' : str, 'menu' : '[C]' }

    call add(l:comp_list, l:dict)
  endfor

  for l:comp in filter(a:list, 'type(v:val) != '.type(''))
    let l:dict = {
          \'word' : l:comp.word, 'menu' : '[C]', 
          \'abbr' : has_key(l:comp, 'abbr')? l:comp.abbr : l:comp.word
          \}

    if has_key(l:comp, 'kind')
      let l:dict.kind = l:comp.kind
    endif

    if has_key(l:comp, 'menu')
      let l:dict.menu .= ' ' . l:comp.menu
    endif

    call add(l:comp_list, l:dict)
  endfor

  return l:comp_list
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
