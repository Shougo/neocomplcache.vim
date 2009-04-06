"=============================================================================
" FILE: syntax_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 06 Apr 2009
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
" Version: 1.02, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.02:
"    - Fixed get syntax list.
"   1.01:
"    - Caching when initialize.
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

function! neocomplcache#syntax_complete#get_keyword_list(cur_keyword_str)"{{{
    if empty(&filetype)
        return []
    endif

    if !has_key(s:syntax_list, &filetype)
        let s:syntax_list[&filetype] = s:initialize_syntax()
    endif

    return s:syntax_list[&filetype]
endfunction"}}}

function! s:initialize_syntax()
    " Get current syntax list.
    redir => l:syntax_list
    silent! syntax list
    redir END

    if l:syntax_list =~ '^E\d\+' || l:syntax_list =~ '^No Syntax items'
        return []
    endif

    let l:group_name = ''
    let l:keyword_list = []
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    for l:line in split(l:syntax_list, '\n')
        if l:line =~ '^\h\w\+'
            " Change syntax group name.
            let l:group_name = printf('[S] %.'. g:NeoComplCache_MaxFilenameWidth.'s', matchstr(l:line, '^\h\w\+'))
            let l:keywords = split(l:line)[2:]
        else
            let l:keywords = split(l:line)
        endif

        if l:line[0] =~ '^--' || empty(l:keywords) || l:keywords[0] == 'match' || l:keywords[0] == 'links' ||
                    \l:keywords[0] =~ '^\h\w*='
            " Next line.
            continue
        endif

        if l:keywords[0] == 'contained'
            let l:keywords = l:keywords[1:]
        endif

        " Add keywords.
        for l:word in l:keywords
            if len(l:word) >= g:NeoComplCache_MinKeywordLength
                let l:keyword = {
                            \ 'word' : l:word, 'menu' : l:group_name, 'dup' : 0,
                            \ 'rank' : 1, 'prev_rank' : 0, 'prepre_rank' : 0
                            \}
                let l:keyword.abbr = 
                            \ (len(l:word) > g:NeoComplCache_MaxKeywordWidth)? 
                            \ printf(l:abbr_pattern, l:word, l:word[-8:]) : l:word
                call add(l:keyword_list, l:keyword)
            endif
        endfor
    endfor

    return sort(l:keyword_list, 'neocomplcache#compare_words')
endfunction

" Dummy function.
function! neocomplcache#syntax_complete#calc_rank(cache_keyword_buffer_list)"{{{
    return
endfunction"}}}

" Dummy function.
function! neocomplcache#syntax_complete#calc_prev_rank(cache_keyword_buffer_list, prev_word, prepre_word)"{{{
    return
endfunction"}}}

function! neocomplcache#syntax_complete#initialize()"{{{
    " Initialize
    let s:syntax_list = {}

    " Caching.
    if !empty(&filetype)
        let s:syntax_list[&filetype] = s:initialize_syntax()
    endif
endfunction"}}}

function! neocomplcache#syntax_complete#finalize()"{{{
endfunction"}}}

" vim: foldmethod=marker
