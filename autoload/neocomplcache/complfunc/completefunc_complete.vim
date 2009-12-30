"=============================================================================
" FILE: completefunc_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 29 Dec 2009
" Usage: Just source this file.
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
" Version: 1.00, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.00:
"    - Initial version.
" }}}
"-----------------------------------------------------------------------------
" TODO: "{{{
"     - Nothing.
""}}}
" Bugs"{{{
"     - Nothing.
""}}}
"=============================================================================

function! neocomplcache#complfunc#completefunc_complete#initialize()"{{{
endfunction"}}}
function! neocomplcache#complfunc#completefunc_complete#finalize()"{{{
endfunction"}}}

function! neocomplcache#complfunc#completefunc_complete#get_keyword_pos(cur_text)"{{{
    return -1
endfunction"}}}

function! neocomplcache#complfunc#completefunc_complete#get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
    return []
endfunction"}}}

function! neocomplcache#complfunc#completefunc_complete#get_rank()"{{{
    return 5
endfunction"}}}

function! neocomplcache#complfunc#completefunc_complete#call_completefunc(funcname)"{{{
    let l:cur_text = neocomplcache#get_cur_text()
    
    " Save pos.
    let l:pos = getpos('.')
    let l:line = getline('.')
    
    let l:cur_keyword_pos = call(a:funcname, [1, ''])

    " Restore pos.
    call setpos('.', l:pos)

    if l:cur_keyword_pos < 0
        return ''
    endif
    let l:cur_keyword_str = l:cur_text[l:cur_keyword_pos :]
    
    let l:pos = getpos('.')

    let l:list = call(a:funcname, [0, l:cur_keyword_str])
    
    call setpos('.', l:pos)
    
    if empty(l:list)
        return ''
    endif

    let l:complete_words = s:get_completefunc_list(l:list)
    
    " Start manual complete.
    return neocomplcache#start_manual_complete_list(l:cur_keyword_pos, l:cur_keyword_str, l:complete_words)
endfunction"}}}

function! s:get_completefunc_list(list)"{{{
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:comp_list = []

    " Convert string list.
    for str in filter(copy(a:list), 'type(v:val) == '.type(''))
        let l:dict = {
                    \'word' : str, 'menu' : '[C]', 'icase' : 1
                    \}
        if len(str) > g:NeoComplCache_MaxKeywordWidth
            let str = printf(l:abbr_pattern, str, str[-8:])
        endif
        let dict.abbr = str

        call add(l:comp_list, l:dict)
    endfor

    for l:comp in filter(a:list, 'type(v:val) != '.type(''))
        let l:dict = {
                    \'word' : l:comp.word, 'menu' : '[C]', 'icase' : 1
                    \}

        let l:abbr = has_key(l:comp, 'abbr')? l:comp.abbr : l:comp.word
        if len(l:abbr) > g:NeoComplCache_MaxKeywordWidth
            let l:abbr = printf(l:abbr_pattern, l:abbr, l:abbr[-8:])
        endif
        let dict.abbr = l:abbr

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

" vim: foldmethod=marker
