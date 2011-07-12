"=============================================================================
" FILE: util.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 12 Jul 2011.
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

let s:V = vital#of('neocomplcache')

function! neocomplcache#util#truncate_smart(...)"{{{
  return call(s:V.truncate_smart, a:000)
endfunction"}}}

function! neocomplcache#util#truncate(...)"{{{
  return call(s:V.truncate, a:000)
endfunction"}}}

function! neocomplcache#util#strchars(...)"{{{
  return call(s:V.strchars, a:000)
endfunction"}}}

function! neocomplcache#util#wcswidth(...)"{{{
  return call(s:V.wcswidth, a:000)
endfunction"}}}
function! neocomplcache#util#strwidthpart(...)"{{{
  return call(s:V.strwidthpart, a:000)
endfunction"}}}
function! neocomplcache#util#strwidthpart_reverse(...)"{{{
  return call(s:V.strwidthpart_reverse, a:000)
endfunction"}}}

function! neocomplcache#util#mb_strlen(...)"{{{
  return call(s:V.strchars, a:000)
endfunction"}}}
function! neocomplcache#util#uniq(list)"{{{
  let l:dict = {}
  for l:item in a:list
    if !has_key(l:dict, l:item)
      let l:dict[l:item] = l:item
    endif
  endfor

  return values(l:dict)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
