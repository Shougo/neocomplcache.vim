"=============================================================================
" FILE: syntax_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 12 Aug 2009
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
" Version: 1.21, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.21:
"    - Caching from cache.
"    - Added NeoComplCacheCachingSyntax command.
"
"   1.20:
"    - Don't caching when not buflisted.
"
"   1.19:
"    - Ignore case.
"    - Echo on caching.
"
"   1.18:
"    - Improved empty check.
"    - Fixed for neocomplcache 2.43.
"
"   1.17:
"    - Fixed typo.
"    - Optimized caching.
"    - Fixed menu error.
"
"   1.16:
"    - Optimized.
"    - Delete command abbreviations in vim filetype.
"
"   1.15:
"    - Added g:NeoComplCache_MinSyntaxLength option.
"
"   1.14:
"    - Improved abbr.
"
"   1.13:
"    - Delete nextgroup.
"    - Improved filtering.
"
"   1.12:
"    - Optimized caching.
"    - Caching event changed.
"
"   1.11:
"    - Optimized.
"
"   1.10:
"    - Caching when set filetype.
"    - Analyze match.
"
"   1.03:
"    - Not complete 'Syntax items' message.
"
"   1.02:
"    - Fixed get syntax list.
"
"   1.01:
"    - Caching when initialize.
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

function! neocomplcache#syntax_complete#initialize()"{{{
    " Initialize.
    let s:syntax_list = {}

    " Set caching event.
    autocmd neocomplcache FileType * call s:caching()

    " Add command.
    command! -nargs=? NeoComplCacheCachingSyntax call s:recaching(<q-args>)

    " Create cache directory.
    if !isdirectory(g:NeoComplCache_TemporaryDir . '/syntax_cache')
        call mkdir(g:NeoComplCache_TemporaryDir . '/syntax_cache')
    endif
endfunction"}}}

function! neocomplcache#syntax_complete#finalize()"{{{
    delcommand NeoComplCacheCachingSyntax
endfunction"}}}

function! neocomplcache#syntax_complete#get_keyword_list(cur_keyword_str)"{{{
    if &filetype == '' || !has_key(s:syntax_list, &filetype)
        return []
    endif

    return neocomplcache#keyword_filter(copy(s:syntax_list[&filetype]), a:cur_keyword_str)
endfunction"}}}

" Dummy function.
function! neocomplcache#syntax_complete#calc_rank(cache_keyword_buffer_list)"{{{
    return
endfunction"}}}
function! neocomplcache#syntax_complete#calc_prev_rank(cache_keyword_buffer_list, prev_word, prepre_word)"{{{
    return
endfunction"}}}

function! s:caching()"{{{
    " Caching.
    if &filetype != '' && buflisted(bufnr('%')) && !has_key(s:syntax_list, &filetype)
        redraw
        echo 'Caching syntax... please wait.'
        let s:syntax_list[&filetype] = s:initialize_syntax()
        redraw
        echo 'Caching done.'
    endif
endfunction"}}}

function! s:recaching(filetype)"{{{
    if a:filetype == ''
        let l:filetype = &filetype
    else
        let l:filetype = a:filetype
    endif

    " Caching.
    if l:filetype != ''
        redraw
        echo 'Caching syntax... please wait.'
        let s:syntax_list[l:filetype] = s:caching_from_syn()
        redraw
        echo 'Caching done.'
    endif
endfunction"}}}

function! s:initialize_syntax()"{{{
    let l:keyword_list = s:caching_from_cache()
    if !empty(l:keyword_list)
        " Caching from cache.
        return l:keyword_list
    endif

    return s:caching_from_syn()
endfunction"}}}

function! s:caching_from_syn()"{{{
    " Get current syntax list.
    redir => l:syntax_list
    silent! syntax list
    redir END

    if l:syntax_list =~ '^E\d\+' || l:syntax_list =~ '^No Syntax items'
        return []
    endif

    let l:group_name = ''
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    if has_key(g:NeoComplCache_KeywordPatterns, &filetype)
        let l:keyword_pattern = g:NeoComplCache_KeywordPatterns[&filetype]
    else
        let l:keyword_pattern = g:NeoComplCache_KeywordPatterns['default']
    endif
    let l:dup_check = {}
    let l:menu = '[S] '

    let l:keyword_list = []
    for l:line in split(l:syntax_list, '\n')
        if l:line =~ '^\h\w\+'
            " Change syntax group name.
            let l:menu = printf('[S] %.'. g:NeoComplCache_MaxFilenameWidth.'s', matchstr(l:line, '^\h\w\+'))
            let l:line = substitute(l:line, '^\h\w\+\s*xxx', '', '')
        endif

        if l:line =~ 'Syntax items' || l:line =~ '^\s*links to' ||
                    \l:line =~ '^\s*nextgroup='
            " Next line.
            continue
        endif

        let l:line = substitute(l:line, 'contained\|skipwhite\|skipnl\|oneline', '', 'g')
        let l:line = substitute(l:line, '^\s*nextgroup=.*\ze\s', '', '')

        if l:line =~ '^\s*match'
            let l:line = s:substitute_candidate(matchstr(l:line, '/\zs[^/]\+\ze/'))
            "echomsg l:line
        elseif l:line =~ '^\s*start='
            let l:line = 
                        \s:substitute_candidate(matchstr(l:line, 'start=/\zs[^/]\+\ze/')) . ' ' .
                        \s:substitute_candidate(matchstr(l:line, 'end=/zs[^/]\+\ze/'))
        endif

        " Add keywords.
        let l:match_num = 0
        let l:line_max = len(l:line) - g:NeoComplCache_MinSyntaxLength
        while 1
            let l:match_str = matchstr(l:line, l:keyword_pattern, l:match_num)
            if l:match_str == ''
                break
            endif

            " Ignore too short keyword.
            if len(l:match_str) >= g:NeoComplCache_MinSyntaxLength && !has_key(l:dup_check, l:match_str)
                let l:keyword = {
                            \ 'word' : l:match_str, 'menu' : l:menu, 'icase' : 1,
                            \ 'rank' : 1, 'prev_rank' : 0, 'prepre_rank' : 0
                            \}
                let l:keyword.abbr = 
                            \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                            \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str
                call add(l:keyword_list, l:keyword)
            endif

            let l:match_num += len(l:match_str)
            if l:match_num > l:line_max
                break
            endif
        endwhile
    endfor

    if &filetype == 'vim'
        " Delete vim command abbreviation."{{{
        let l:command_list = filter(copy(l:keyword_list),
                    \'v:val.menu =~ "\\[S\\] vim\\%(Command\\|UserCommand\\|UserAttrbKey\\|FuncKey\\)"')
        call filter(l:keyword_list,
                    \'v:val.menu !~ "\\[S\\] vim\\%(Command\\|UserCommand\\|UserAttrbKey\\|FuncKey\\)"')
        let l:groups = {}
        for command in l:command_list
            let l:name = command.word[: g:NeoComplCache_MinSyntaxLength-1]
            if !has_key(l:groups, l:name)
                let l:groups[l:name] = {}
            endif
            let l:groups[l:name][command.word] = command
        endfor

        for group in values(l:groups)
            for word in keys(group)
                for another_word in keys(group)
                    if word != another_word && word =~ '^' . another_word
                        call remove(group, another_word)
                    endif
                endfor
            endfor
            call extend(l:keyword_list, values(group))
        endfor"}}}
    endif

    " Save syntax cache.
    let l:save_list = []
    for keyword in l:keyword_list
        call add(l:save_list, keyword.word .','. keyword.menu)
    endfor
    let l:cache_name = printf('%s/syntax_cache/%s=', g:NeoComplCache_TemporaryDir, &filetype)
    call writefile(l:save_list, l:cache_name)

    return l:keyword_list
endfunction"}}}

function! s:caching_from_cache()"{{{
    let l:cache_name = printf('%s/syntax_cache/%s=', g:NeoComplCache_TemporaryDir, &filetype)
    let l:syntax_files = split(globpath(&runtimepath, 'syntax/'.&filetype.'.vim'), '\n')
    if getftime(l:cache_name) == -1 || (!empty(l:syntax_files) && getftime(l:cache_name) <= getftime(l:syntax_files[-1]))
        return []
    endif

    let l:syntax_lines = readfile(l:cache_name)
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:keyword_list = []
    for syntax in l:syntax_lines
        let l:splited = split(syntax, ',')
        let l:keyword =  {
                    \ 'word' : l:splited[0], 'menu' : l:splited[1], 'icase' : 1,
                    \ 'rank' : 1, 'prev_rank' : 0, 'prepre_rank' : 0
                    \}
        let l:keyword.abbr = 
                    \ (len(l:splited[0]) > g:NeoComplCache_MaxKeywordWidth)? 
                    \ printf(l:abbr_pattern, l:splited[0], l:splited[-8:]) : l:splited[0]
        call add(l:keyword_list, l:keyword)
    endfor

    return l:keyword_list
endfunction"}}}

" LengthOrder."{{{
function! s:compare_length(i1, i2)
    return a:i1.word < a:i2.word ? 1 : a:i1.word == a:i2.word ? 0 : -1
endfunction"}}}

function! s:substitute_candidate(candidate)"{{{
    let l:candidate = a:candidate

    " Collection.
    let l:candidate = substitute(l:candidate,
                \'\%(\\\\\|[^\\]\)\zs\[.*\]', ' ', 'g')
    if l:candidate =~ '\\v'
        " Delete.
        let l:candidate = substitute(l:candidate,
                    \'\%(\\\\\|[^\\]\)\zs\%([=?+*]\|%[\|\\s\*\)', '', 'g')
        " Space.
        let l:candidate = substitute(l:candidate,
                    \'\%(\\\\\|[^\\]\)\zs\%([<>{()|$^]\|\\z\?\a\)', ' ', 'g')
    else
        " Delete.
        let l:candidate = substitute(l:candidate,
                    \'\%(\\\\\|[^\\]\)\zs\%(\\[=?+]\|\\%[\|\\s\*\|\*\)', '', 'g')
        " Space.
        let l:candidate = substitute(l:candidate,
                    \'\%(\\\\\|[^\\]\)\zs\%(\\[<>{()|]\|[$^]\|\\z\?\a\)', ' ', 'g')
    endif

    " \
    let l:candidate = substitute(l:candidate, '\\\\', '\\', 'g')
    return l:candidate
endfunction"}}}

" Global options definition."{{{
if !exists('g:NeoComplCache_MinSyntaxLength')
    let g:NeoComplCache_MinSyntaxLength = 4
endif
"}}}

" vim: foldmethod=marker
