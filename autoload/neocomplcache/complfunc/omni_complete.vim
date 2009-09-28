"=============================================================================
" FILE: omni_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 27 Sep 2009
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

function! neocomplcache#complfunc#omni_complete#initialize()"{{{
    " Initialize omni completion pattern."{{{
    if !exists('g:NeoComplCache_OmniPatterns')
        let g:NeoComplCache_OmniPatterns = {}
    endif
    if has('ruby')
        call s:set_omni_pattern('ruby', '\v[^. *\t]%(\.|::)')
    endif
    if has('python')
        call s:set_omni_pattern('python', '\v[^. \t]\.')
    endif
    call s:set_omni_pattern('html,xhtml,xml', '\v\</?|\<[^>]+\s')
    call s:set_omni_pattern('css', '\v^\s+\w+|\w+[):;]?\s+|[@!]')
    call s:set_omni_pattern('javascript', '\v[^. \t]\.')
    call s:set_omni_pattern('c', '\v[^. \t]%(\.|-\>)')
    call s:set_omni_pattern('cpp', '\v[^. \t]%(\.|-\>|::)')
    call s:set_omni_pattern('php', '\v[^. \t]%(-\>|::)')
    call s:set_omni_pattern('java', '\v[^. \t]\.')
    call s:set_omni_pattern('vim', '\v%(^\s*:).*')
    "}}}
endfunction"}}}
function! neocomplcache#complfunc#omni_complete#finalize()"{{{
endfunction"}}}

function! neocomplcache#complfunc#omni_complete#get_keyword_pos(cur_text)"{{{
    if !exists('&l:omnifunc') || &l:omnifunc == '' 
                \|| !has_key(g:NeoComplCache_OmniPatterns, &filetype)
                \|| g:NeoComplCache_OmniPatterns[&filetype] == ''
                \|| a:cur_text !~ '\v%(' . g:NeoComplCache_OmniPatterns[&filetype] . ')$'
        return -1
    endif

    return call(&l:omnifunc, [1, ''])
endfunction"}}}

function! neocomplcache#complfunc#omni_complete#get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
    " Check keyword length.
    let s:short_cur_keyword = (len(a:cur_keyword_str) < g:NeoComplCache_KeywordCompletionStartLength)? 1 : 0

    if g:NeoComplCache_EnableSkipCompletion && &l:completefunc == 'neocomplcache#auto_complete'
        let l:start_time = reltime()
    else
        let l:start_time = 0
    endif

    let l:omni_list = call(&l:omnifunc, [0, a:cur_keyword_str])

    " Skip completion if takes too much time."{{{
    if neocomplcache#check_skip_time(l:start_time)
        echo 'Skipped auto completion'
        let s:skipped = 1
        return []
    endif"}}}

    echo ''
    redraw

    if len(l:omni_list) >= 1 && type(l:omni_list[0]) == type('')
        " Convert string list.
        let l:list = []
        for str in l:omni_list
            call add(l:list, { 'word' : str })
        endfor

        let l:omni_list = l:list
    endif

    let l:list = []
    for l:omni in l:omni_list
        let l:dict = {
                    \'word' : l:omni.word, 'menu' : '[O]', 
                    \'icase' : 1, 'rank' : 5
                    \}
        if has_key(l:omni, 'abbr')
            let l:dict.abbr = l:omni.abbr
        endif
        if has_key(l:omni, 'kind')
            let l:dict.menu = ' ' . l:omni.kind
        endif
        if has_key(l:omni, 'menu')
            let l:dict.menu = ' ' . l:omni.menu
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

function! neocomplcache#complfunc#omni_complete#manual_complete()"{{{
    if !exists(':NeoComplCacheDisable')
        return ''
    endif

    " Get cursor word.
    let l:cur_keyword_pos = call(&l:omnifunc, [1, ''])
    let l:cur_text = (col('.') < 2)? '' : getline('.')[: col('.')-2]
    let l:cur_keyword_str = l:cur_text[l:cur_keyword_pos :]

    if len(l:cur_keyword_str) < g:NeoComplCache_ManualCompletionStartLength
        return ''
    endif

    " Save options.
    let l:ignorecase_save = &ignorecase

    if g:NeoComplCache_SmartCase && l:cur_keyword_str =~ '\u'
        let &ignorecase = 0
    else
        let &ignorecase = g:NeoComplCache_IgnoreCase
    endif

    " Set function.
    let &l:completefunc = 'neocomplcache#manual_complete'

    if &l:omnifunc == ''
        let l:complete_words = []
    else
        let l:complete_words = neocomplcache#get_quickmatch_list(neocomplcache#complfunc#omni_complete#get_complete_words(l:cur_keyword_pos, l:cur_keyword_str),
                \ l:cur_keyword_pos, l:cur_keyword_str, 'omni_complete')
        let l:complete_words = neocomplcache#remove_next_keyword(l:complete_words)
    endif

    " Restore option.
    let &ignorecase = l:ignorecase_save

    " Start complete.
    return neocomplcache#start_manual_complete(l:complete_words, l:cur_keyword_pos, l:cur_keyword_str)
endfunction"}}}

function! s:set_omni_pattern(filetype, pattern)"{{{
    for ft in split(a:filetype, ',')
        if !has_key(g:NeoComplCache_OmniPatterns, ft) 
            let g:NeoComplCache_OmniPatterns[ft] = a:pattern
        endif
    endfor
endfunction"}}}

" vim: foldmethod=marker
