"=============================================================================
" FILE: omni_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 26 Nov 2009
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
" Version: 1.07, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.07:
"    - Deleted \v pattern.
"    - Restore cursor position.
"
"   1.06:
"    - Fixed ruby omni_complete bug.
"    - Refactoringed.
"    - Supported string and dictionary candidates.
"
"   1.05:
"    - Allow dup.
"    - Improved menu.
"    - Deleted C support.
"
"   1.04:
"    - Added rank.
"    - Improved omni pattern.
"
"   1.03:
"    - Fixed manual completion error.
"
"   1.02:
"    - Deleted C++ support.
"
"   1.01:
"    - Added ActionScript support.
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

function! neocomplcache#complfunc#omni_complete#initialize()"{{{
    " Initialize omni completion pattern."{{{
    if !exists('g:NeoComplCache_OmniPatterns')
        let g:NeoComplCache_OmniPatterns = {}
    endif
    if has('ruby')
        call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'ruby',
                    \'\h\w\+\|[^. *\t]%(\.\|::)\h\w*')
    endif
    if has('python')
        call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'python',
                    \'[^. \t]\.\h\w*')
    endif
    call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'html,xhtml,xml',
                \'<[^>]*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'css',
                \'^\s\+\w+\|\w+[):;]?\s\+\|[@!]')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'javascript',
                \'[^. \t]\.\%(\h\w*\)\?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'actionscript',
                \'[^. \t][.:]\h\w*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'php',
                \'[^. \t]%(->\|::)\h\w*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'java',
                \'[^. \t]\.\h\w*')
    "call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'perl',
                "\'\h\w*|[^. \t]%(->\|::)\h\w*')
    "}}}
endfunction"}}}
function! neocomplcache#complfunc#omni_complete#finalize()"{{{
endfunction"}}}

function! neocomplcache#complfunc#omni_complete#get_keyword_pos(cur_text)"{{{
    if !exists('&l:omnifunc') || &l:omnifunc == '' 
        return -1
    endif

    if &l:completefunc == 'neocomplcache#auto_complete' &&
                \(!has_key(g:NeoComplCache_OmniPatterns, &filetype)
                \|| g:NeoComplCache_OmniPatterns[&filetype] == ''
                \|| a:cur_text !~ '\%(' . g:NeoComplCache_OmniPatterns[&filetype] . '\m\)$')
        return -1
    endif

    let l:pos = getpos('.')
    let l:cur_keyword_pos = call(&l:omnifunc, [1, ''])
    call setpos('.', l:pos)
    return l:cur_keyword_pos
endfunction"}}}

function! neocomplcache#complfunc#omni_complete#get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
    if g:NeoComplCache_EnableSkipCompletion && &l:completefunc == 'neocomplcache#auto_complete'
        let l:start_time = reltime()
    else
        let l:start_time = 0
    endif

    let l:cur_keyword_str = (&filetype == 'ruby')? '' : a:cur_keyword_str
    
    let l:pos = getpos('.')
    let l:omni_list = call(&l:omnifunc, [0, l:cur_keyword_str])
    call setpos('.', l:pos)
    
    if empty(l:omni_list)
        return []
    endif

    " Skip completion if takes too much time."{{{
    if neocomplcache#check_skip_time(l:start_time)
        echo 'Skipped auto completion'
        let s:skipped = 1
        return []
    endif"}}}

    echo ''
    redraw

    let l:omni_string_list = filter(copy(l:omni_list), 'type(v:val) == '.type(''))
    let l:list = []
    " Convert string list.
    for str in l:omni_string_list
        call add(l:list, {
                    \'word' : str, 'menu' : '[O]',
                    \'icase' : 1, 'rank' : 5, 'dup' : 1
                    \})
    endfor

    let l:omni_list = filter(l:omni_list, 'type(v:val) != '.type(''))
    for l:omni in l:omni_list
        let l:dict = {
                    \'word' : l:omni.word, 'menu' : '[O]',
                    \'icase' : 1, 'rank' : 5, 'dup' : 1,
                    \}
        if has_key(l:omni, 'abbr')
            let l:dict.abbr = l:omni.abbr
        endif
        if has_key(l:omni, 'kind')
            let l:dict.kind = l:omni.kind
        endif
        if has_key(l:omni, 'menu')
            let l:dict.menu = '[O] ' . l:omni.menu
        endif
        call add(l:list, l:dict)
    endfor
    " Trunk many items.
    let l:list = l:list[: g:NeoComplCache_MaxList-1]

    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    for keyword in l:list
        let l:abbr = has_key(keyword, 'abbr')? keyword.abbr : keyword.word
        if len(l:abbr) > g:NeoComplCache_MaxKeywordWidth
            let l:abbr = printf(l:abbr_pattern, l:abbr, l:abbr[-8:])
        endif

        let keyword.abbr = l:abbr
    endfor

    return l:list
endfunction"}}}

function! neocomplcache#complfunc#omni_complete#get_rank()"{{{
    return 20
endfunction"}}}

" vim: foldmethod=marker
