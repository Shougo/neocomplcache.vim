"=============================================================================
" FILE: filename_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Nov 2009
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
" Version: 1.05, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.05:
"    - Fixed freeze bug.
"    - Improved backslash.
"
"   1.04:
"    - Fixed auto completion bug.
"    - Fixed executable bug.
"
"   1.03:
"    - Added rank.
"
"   1.02:
"    - Add '*' to a delimiter.
"
"   1.01:
"    - Improved completion.
"    - Deleted cdpath completion.
"    - Fixed escape bug.
"
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

function! neocomplcache#complfunc#filename_complete#initialize()"{{{
endfunction"}}}
function! neocomplcache#complfunc#filename_complete#finalize()"{{{
endfunction"}}}

function! neocomplcache#complfunc#filename_complete#get_keyword_pos(cur_text)"{{{
    let l:is_win = has('win32') || has('win64')
    if l:is_win && &filetype == 'tex'
        return -1
    endif

    " Not Filename pattern.
    if a:cur_text =~ '[/\\][/\\]\f*$\|[^[:print:]]\f*$\|/c\%[ygdrive/]$\|\\|$\|^\a:$'
        return -1
    endif

    " Filename pattern.
    let l:pattern = '[~]\?\%(\\[^[:alnum:].-]\|\f\|\*\)\+$'

    let l:cur_keyword_pos = match(a:cur_text, l:pattern)
    let l:cur_keyword_str = a:cur_text[l:cur_keyword_pos :]
    if len(l:cur_keyword_str) < g:NeoComplCache_KeywordCompletionStartLength
        return -1
    endif
    
    " Not Filename pattern.
    if l:is_win && l:cur_keyword_str =~ 
                \'|\|^\a:[/\\]\@!\|\\[[:alnum:].-]'
        return -1
    elseif l:cur_keyword_str =~ '\*\*\|^{}'
        return -1
    endif

    return l:cur_keyword_pos
endfunction"}}}

function! neocomplcache#complfunc#filename_complete#get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
    let l:cur_keyword_str = escape(a:cur_keyword_str, '[]')

    let l:is_win = has('win32') || has('win64')
    let l:cur_keyword_str = substitute(l:cur_keyword_str, '\\ ', ' ', 'g')
    " Substitute ... -> ../..
    while l:cur_keyword_str =~ '\.\.\.'
        let l:cur_keyword_str = substitute(l:cur_keyword_str, '\.\.\zs\.', '/\.\.', 'g')
    endwhile

    if g:NeoComplCache_EnableSkipCompletion && &l:completefunc == 'neocomplcache#auto_complete'
        let l:start_time = reltime()
    else
        let l:start_time = 0
    endif

    try
        let l:glob = (l:cur_keyword_str !~ '\*$')?  l:cur_keyword_str . '*' : l:cur_keyword_str
        let l:files = split(substitute(glob(l:glob), '\\', '/', 'g'), '\n')
        if empty(l:files)
            " Add '*' to a delimiter.
            let l:cur_keyword_str = substitute(l:cur_keyword_str, '\w\+\ze[/._-]', '\0*', 'g')
            let l:glob = (l:cur_keyword_str !~ '\*$')?  l:cur_keyword_str . '*' : l:cur_keyword_str
            let l:files = split(substitute(glob(l:glob), '\\', '/', 'g'), '\n')
        endif
    catch /.*/
        return []
    endtry

    if neocomplcache#check_skip_time(l:start_time)
        echo 'Skipped auto completion'
        let s:skipped = 1
        return []
    endif

    let l:list = []
    let l:home_pattern = '^'.substitute($HOME, '\\', '/', 'g').'/'
    for word in l:files
        let l:dict = {
                    \'word' : substitute(word, l:home_pattern, '\~/', ''), 'menu' : '[F]', 
                    \'icase' : 1, 'rank' : 6
                    \}
        " Skip completion if takes too much time."{{{
        if neocomplcache#check_skip_time(l:start_time)
            echo 'Skipped auto completion'
            let s:skipped = 1
            return []
        endif"}}}

        call add(l:list, l:dict)
    endfor

    call sort(l:list, 'neocomplcache#compare_rank')
    " Trunk many items.
    let l:list = l:list[: g:NeoComplCache_MaxList-1]

    let l:exts = escape(substitute($PATHEXT, ';', '\\|', 'g'), '.')
    for keyword in l:list
        let l:abbr = keyword.word
        if len(l:abbr) > g:NeoComplCache_MaxKeywordWidth
            let l:abbr = printf('%s~%s', l:abbr[:9], l:abbr[len(l:abbr)-g:NeoComplCache_MaxKeywordWidth-10:])
        endif

        if isdirectory(keyword.word)
            let l:abbr .= '/'
            let keyword.rank += 1
        elseif l:is_win
            if '.'.fnamemodify(keyword.word, ':e') =~ l:exts
                let l:abbr .= '*'
            endif
        elseif executable(keyword.word)
            let l:abbr .= '*'
        endif

        let keyword.abbr = l:abbr

        if !filewritable(keyword.word)
            let keyword.menu .= ' [-]'
        endif
    endfor

    echo ''
    redraw

    " Escape word.
    for keyword in l:list
        let keyword.word = escape(keyword.word, ' *?[]"={}')
    endfor

    return l:list
endfunction"}}}

function! neocomplcache#complfunc#filename_complete#get_rank()"{{{
    return 10
endfunction"}}}
" vim: foldmethod=marker
