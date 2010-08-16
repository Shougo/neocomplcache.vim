"=============================================================================
" FILE: abbrev_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 17 Aug 2010
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

let s:source = {
      \ 'name' : 'abbrev_complete',
      \ 'kind' : 'plugin',
      \}

function! s:source.initialize()"{{{
  " Initialize.
endfunction"}}}

function! s:source.finalize()"{{{
endfunction"}}}

function! s:source.get_keyword_list(cur_keyword_str)"{{{
  " Get current abbrev list.
  let l:abbrev_list = ''
  redir => l:abbrev_list
  silent! iabbrev
  redir END

  let l:list = []
  for l:line in split(l:abbrev_list, '\n')
    let l:abbrev = split(l:line)

    if l:abbrev[0] !~ '^[!i]$'
      " No abbreviation found.
      return []
    endif

    call add(l:list, 
          \{ 'word' : l:abbrev[1], 'menu' : printf('[A] %.'. g:neocomplcache_max_filename_width.'s', l:abbrev[2]) })
  endfor

  return neocomplcache#keyword_filter(l:list, a:cur_keyword_str)
endfunction"}}}

function! neocomplcache#sources#abbrev_complete#define()"{{{
  return s:source
endfunction"}}}
" vim: foldmethod=marker
