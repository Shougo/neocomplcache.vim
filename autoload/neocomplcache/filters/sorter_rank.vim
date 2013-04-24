"=============================================================================
" FILE: sorter_rank.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Apr 2013.
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

function! neocomplcache#filters#sorter_rank#define() "{{{
  return s:sorter
endfunction"}}}

let s:sorter = {
      \ 'name' : 'sorter_rank',
      \ 'description' : 'sort by matched rank order',
      \}

function! s:sorter.filter(context) "{{{
  " return sort(a:context.candidates, 's:compare_source_rank')
  return reverse(neocomplcache#util#sort_by(
        \ a:context.candidates,
        \ 'neocomplcache#get_source_rank(v:val.name)'))
endfunction"}}}

" Source rank order. "{{{
function! s:compare_source_rank(i1, i2)
  return neocomplcache#get_source_rank(a:i2.name) -
        \ neocomplcache#get_source_rank(a:i1.name)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
