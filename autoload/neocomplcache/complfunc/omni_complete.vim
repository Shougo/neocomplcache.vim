"=============================================================================
" FILE: omni_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 11 Dec 2009
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
" Version: 1.10, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.10:
"    - Supported mark down filetype.
"
"   1.09:
"    - Fixed manual completion error.
"    - Experimental tags support.
"    - Implemented keyword cache.
"
"   1.08:
"    - Check Python and Ruby interface.
"    - Supported wildcard.
"    - Improved skip.
"
"   1.07:
"    - Deleted \v pattern.
"    - Restore cursor position.
"    - Refactoringed.
"    - Added C/C++ support.
"    - Fixed PHP pattern bug.
"    - Improved omni patterns.
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
        try 
            ruby 1
            call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'ruby',
                        \'[^. *\t]\.\h\w*\|\h\w*::')
        catch
        endtry
    endif
    if has('python')
        try 
            python 1
            call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'python',
                        \'[^. \t]\.\h\w*')
        catch
        endtry
    endif
    call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'html,xhtml,xml,markdown',
                \'<[^>]*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'css',
                \'^\s\+\w+\|\w+[):;]?\s\+\|[@!]')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'javascript',
                \'[^. \t]\.\%(\h\w*\)\?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'actionscript',
                \'[^. \t][.:]\h\w*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'php',
                \'[^. \t]->\h\w*\|\$\h\w*\|\%(=\s*new\|extends\)\s\+\|\h\w*::')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'java',
                \'\%(\h\w*\|)\)\.')
    "call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'perl',
                "\'\%(\h\w*\|)\)->\h\w*\|\h\w*::')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'c',
                \'\h\w\+\|\%(\h\w*\|)\)\%(\.\|->\)\h\w*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_OmniPatterns', 'cpp',
                \'\%(\h\w*\|)\)\%(\.\|->\)\h\w*\|\h\w*::')
    "}}}

    let s:keyword_cache = {}
    let s:iskeyword = 0
    
    augroup neocomplcache
        " Caching events
        autocmd FileType * call s:caching('', 0)
    augroup END
    
    " Add command.
    command! -nargs=? -complete=buffer NeoComplCacheCachingOmni call s:caching(<q-args>, 1)
endfunction"}}}
function! neocomplcache#complfunc#omni_complete#finalize()"{{{
    delcommand NeoComplCacheCachingOmni
endfunction"}}}

function! neocomplcache#complfunc#omni_complete#get_keyword_pos(cur_text)"{{{
    if !exists('&l:omnifunc') || &l:omnifunc == '' || &filetype == '' 
        return -1
    endif

    if neocomplcache#is_auto_complete() &&
                \(!has_key(g:NeoComplCache_OmniPatterns, &filetype) || g:NeoComplCache_OmniPatterns[&filetype] == '')
        return -1
    endif
    
    let l:is_wildcard = g:NeoComplCache_EnableWildCard && a:cur_text =~ '\*\w\+$'
                \&& neocomplcache#is_auto_complete()
    
    " Check wildcard.
    if l:is_wildcard
        " Check wildcard.
        let l:cur_text = a:cur_text[: match(a:cur_text, '\%(\*\w\+\)\+$') - 1]
    else
        let l:cur_text = a:cur_text
    endif
    
    let s:iskeyword = 0

    if neocomplcache#is_auto_complete() &&
                \l:cur_text !~ '\%(' . g:NeoComplCache_OmniPatterns[&filetype] . '\m\)$'
        " Check pattern.
        if has_key(s:keyword_cache, &filetype)
            let s:iskeyword = 1
            return match(l:cur_text, '\h\w\+$')
        else
            return -1
        endif
    endif

    " Save pos.
    let l:pos = getpos('.')
    let l:line = getline('.')
    
    if neocomplcache#is_auto_complete()
        call setline('.', l:cur_text)
    endif
    
    try
        let l:cur_keyword_pos = call(&l:omnifunc, [1, ''])
    catch
        let l:cur_keyword_pos = -1
    endtry

    " Restore pos.
    if neocomplcache#is_auto_complete()
        call setline('.', l:line)
    endif
    call setpos('.', l:pos)

    return l:cur_keyword_pos
endfunction"}}}

function! neocomplcache#complfunc#omni_complete#get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
    let l:is_wildcard = g:NeoComplCache_EnableWildCard && a:cur_keyword_str =~ '\*\w\+$'
                \&& neocomplcache#is_auto_complete()

    if s:iskeyword
        return neocomplcache#keyword_filter(copy(s:keyword_cache[&filetype]), a:cur_keyword_str)
    endif

    let l:pos = getpos('.')
    if l:is_wildcard
        " Check wildcard.
        let l:cur_keyword_str = a:cur_keyword_str[: match(a:cur_keyword_str, '\%(\*\w\+\)\+$') - 1]
    else
        let l:cur_keyword_str = a:cur_keyword_str
    endif
    
    if &filetype == 'c' || &filetype == 'cpp'
        let l:filename = fnamemodify(bufname('%'), ':p')
        let l:tags_save = &tags
        
        let l:tags = []
        for l:include_file in neocomplcache#plugin#include_complete#get_include_files(bufnr('%'))
            if neocomplcache#cache#filereadable('include_tags', l:include_file)
                call add(l:tags, neocomplcache#cache#getfilename('include_tags', l:include_file))
            endif
        endfor
        
        let &tags = &tags . ',' . escape(join(l:tags, ','), ' ')
    endif
    
    try
        if &filetype == 'ruby' && l:is_wildcard
            let l:line = getline('.')
            let l:cur_text = neocomplcache#get_cur_text()
            call setline('.', l:cur_text[: match(l:cur_text, '\%(\*\w\+\)\+$') - 1])
        endif
        
        let l:list = call(&l:omnifunc, [0, (&filetype == 'ruby')? '' : l:cur_keyword_str])
        
        if &filetype == 'ruby' && l:is_wildcard
            call setline('.', l:line)
        endif
    catch
        let l:list = []
    endtry
    call setpos('.', l:pos)

    if &filetype == 'c' || &filetype == 'cpp'
        let &tags = l:tags_save
    endif
    
    if empty(l:list)
        return []
    endif

    " Skip completion if takes too much time."{{{
    if neocomplcache#check_skip_time()
        return []
    endif"}}}

    if l:is_wildcard
        return neocomplcache#keyword_filter(s:get_omni_list(l:list), a:cur_keyword_str)
    else
        return s:get_omni_list(l:list)
    endif
endfunction"}}}

function! neocomplcache#complfunc#omni_complete#get_rank()"{{{
    return 20
endfunction"}}}

function! s:caching(bufname, force)"{{{
    let l:filetype = (a:bufname == '')? &filetype : getbufvar(a:bufname, '&filetype')
    if l:filetype == '' || (!a:force && has_key(s:keyword_cache, l:filetype))
                \|| !exists('&l:omnifunc') || &l:omnifunc == ''
        return
    endif

    try
        let l:cur_keyword_pos = call(&l:omnifunc, [1, ''])
        let l:list = call(&l:omnifunc, [0, ''])
    catch
        let l:list = []
    endtry
    
    let s:keyword_cache[l:filetype] = s:get_omni_list(l:list)
endfunction"}}}

function! s:get_omni_list(list)"{{{
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:omni_list = []
    
    " Convert string list.
    for str in filter(copy(a:list), 'type(v:val) == '.type(''))
        let l:dict = {
                    \'word' : str, 'menu' : '[O]', 'icase' : 1
                    \}
        if len(str) > g:NeoComplCache_MaxKeywordWidth
            let str = printf(l:abbr_pattern, str, str[-8:])
        endif
        let dict.abbr = str

        call add(l:omni_list, l:dict)
    endfor

    for l:omni in filter(a:list, 'type(v:val) != '.type(''))
        let l:dict = {
                    \'word' : l:omni.word, 'menu' : '[O] ', 'icase' : 1
                    \}

        let l:abbr = has_key(l:omni, 'abbr')? l:omni.abbr : l:omni.word
        if len(l:abbr) > g:NeoComplCache_MaxKeywordWidth
            let l:abbr = printf(l:abbr_pattern, l:abbr, l:abbr[-8:])
        endif
        let dict.abbr = l:abbr

        if has_key(l:omni, 'kind')
            let l:dict.kind = l:omni.kind
        endif

        if has_key(l:omni, 'menu')
            let l:dict.menu .= printf(' %.' . g:NeoComplCache_MaxFilenameWidth . 's', fnamemodify(l:omni.menu, ':t'))
        endif

        call add(l:omni_list, l:dict)
    endfor

    return l:omni_list
endfunction"}}}

" vim: foldmethod=marker
