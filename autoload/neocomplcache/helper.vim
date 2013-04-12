"=============================================================================
" FILE: helper.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 12 Apr 2013.
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

function! neocomplcache#helper#get_cur_text() "{{{
  let cur_text =
        \ (mode() ==# 'i' ? (col('.')-1) : col('.')) >= len(getline('.')) ?
        \      getline('.') :
        \      matchstr(getline('.'),
        \         '^.*\%' . col('.') . 'c' . (mode() ==# 'i' ? '' : '.'))

  if cur_text =~ '^.\{-}\ze\S\+$'
    let cur_keyword_str = matchstr(cur_text, '\S\+$')
    let cur_text = matchstr(cur_text, '^.\{-}\ze\S\+$')
  else
    let cur_keyword_str = ''
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()
  if neocomplcache.event ==# 'InsertCharPre'
    let cur_keyword_str .= v:char
  endif

  let filetype = neocomplcache#get_context_filetype()
  let wildcard = get(g:neocomplcache_wildcard_characters, filetype,
        \ get(g:neocomplcache_wildcard_characters, '_', '*'))
  if g:neocomplcache_enable_wildcard &&
        \ wildcard !=# '*' && len(wildcard) == 1
    " Substitute wildcard character.
    while 1
      let index = stridx(cur_keyword_str, wildcard)
      if index <= 0
        break
      endif

      let cur_keyword_str = cur_keyword_str[: index-1]
            \ . '*' . cur_keyword_str[index+1: ]
    endwhile
  endif

  let neocomplcache.cur_text = cur_text . cur_keyword_str

  " Save cur_text.
  return neocomplcache.cur_text
endfunction"}}}

function! neocomplcache#helper#match_word(cur_text, ...) "{{{
  let pattern = a:0 >= 1 ? a:1 : neocomplcache#get_keyword_pattern_end()

  " Check wildcard.
  let cur_keyword_pos = s:match_wildcard(
        \ a:cur_text, pattern, match(a:cur_text, pattern))

  let cur_keyword_str = (cur_keyword_pos >=0) ?
        \ a:cur_text[cur_keyword_pos :] : ''

  return [cur_keyword_pos, cur_keyword_str]
endfunction"}}}

function! s:match_wildcard(cur_text, pattern, cur_keyword_pos) "{{{
  let cur_keyword_pos = a:cur_keyword_pos
  while cur_keyword_pos > 1 && a:cur_text[cur_keyword_pos - 1] == '*'
    let left_text = a:cur_text[: cur_keyword_pos - 2]
    if left_text == '' || left_text !~ a:pattern
      break
    endif

    let cur_keyword_pos = match(left_text, a:pattern)
  endwhile

  return cur_keyword_pos
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
