"=============================================================================
" FILE: snippet.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 07 Jun 2011.
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

function! unite#sources#snippet#define() "{{{
  if !exists('*unite#version') || unite#version() < 150
    echoerr 'Your unite.vim is too old.'
    echoerr 'Please install unite.vim Ver.1.5 or above.'
    return []
  endif

  let l:kind = {
        \ 'name' : 'snippet',
        \ 'default_action' : 'expand',
        \ 'action_table': {},
        \ 'parents': ['jump_list', 'completion'],
        \ 'alias_table' : { 'edit' : 'open' },
        \ }
  call unite#define_kind(l:kind)

  return s:source
endfunction "}}}

" neocomplcache snippet source.
let s:source = {
      \ 'name': 'snippet',
      \ 'hooks' : {},
      \ 'action_table' : {},
      \ }

function! s:source.hooks.on_init(args, context) "{{{
  let a:context.source__cur_keyword_pos = s:get_keyword_pos(neocomplcache#get_cur_text(1))
  let a:context.source__snippets = sort(values(neocomplcache#sources#snippets_complete#get_snippets()), 's:compare_words')
endfunction"}}}

function! s:source.gather_candidates(args, context) "{{{
  let l:keyword_pos = a:context.source__cur_keyword_pos
  let l:list = []
  for l:keyword in a:context.source__snippets
    let l:dict = {
        \   'word' : l:keyword.word,
        \   'abbr' : printf('%-50s %s', l:keyword.word, l:keyword.menu),
        \   'kind': 'snippet',
        \   'action__complete_word' : l:keyword.word,
        \   'action__complete_pos' : l:keyword_pos,
        \   'action__path' : l:keyword.action__path,
        \   'action__pattern' : l:keyword.action__pattern,
        \   'source__menu' : l:keyword.menu,
        \   'source__snip' : l:keyword.snip,
        \ }

    call add(l:list, l:dict)
  endfor

  return l:list
endfunction "}}}

" Actions"{{{
let s:action_table = {}

let s:action_table.expand = {
      \ 'description' : 'expand snippet',
      \ }
function! s:action_table.expand.func(candidate)"{{{
  let l:context = unite#get_context()
  call neocomplcache#sources#snippets_complete#expand(
        \ neocomplcache#get_cur_text(1), l:context.col,
        \ a:candidate.action__complete_word)
endfunction"}}}

let s:action_table.preview = {
      \ 'description' : 'preview snippet',
      \ 'is_selectable' : 1,
      \ 'is_quit' : 0,
      \ }
function! s:action_table.preview.func(candidates)"{{{
  for snip in a:candidates
    echohl String
    echo snip.action__complete_word
    echohl Special
    echo snip.source__menu
    echohl None
    echo snip.source__snip
    echo ' '
  endfor
endfunction"}}}

let s:source.action_table['*'] = s:action_table
unlet! s:action_table
"}}}

function! unite#sources#snippet#start_complete() "{{{
  return printf("\<ESC>:call unite#start(['snippet'],
        \ { 'col' : %d, 'complete' : 1,
        \   'direction' : 'rightbelow', 'winheight' : 10,
        \   'input' : neocomplcache#get_cur_text(1),
        \   'buffer_name' : 'completion', })\<CR>", col('.'))
endfunction "}}}

function! s:compare_words(i1, i2)"{{{
  return a:i1.menu - a:i2.menu
endfunction"}}}
function! s:get_keyword_pos(cur_text)"{{{
  let [l:cur_keyword_pos, l:cur_keyword_str] = neocomplcache#match_word(a:cur_text)
  if l:cur_keyword_pos < 0
    " Empty string.
    return len(a:cur_text)
  endif

  return l:cur_keyword_pos
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
