"=============================================================================
" FILE: include_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 03 Apr 2009
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

" Important variables.
let s:sources = {}

function! neocomplcache#plugin#include_complete#initialize()"{{{
    " Initialize

    augroup neocomplcache"{{{
        " Caching events
        autocmd FileType * call s:check_source()
        autocmd BufWritePost * call s:update_source()
        " Garbage collect.
        autocmd VimLeavePre * call s:save_all_cache()
    augroup END"}}}

    " Global options definition."{{{
    if !exists('g:NeoComplCache_IncludePath')
        let g:NeoComplCache_IncludePath = {}
    endif
    if !exists('g:NeoComplCache_IncludeExpr')
        let g:NeoComplCache_IncludeExpr = {}
    endif
    if !exists('g:NeoComplCache_IncludePattern')
        let g:NeoComplCache_IncludePattern = {}
    endif
    if !exists('g:NeoComplCache_IncludePath')
        let g:NeoComplCache_IncludePath = {}
    endif
    "}}}

    " Create cache directory.
    if !isdirectory(g:NeoComplCache_TemporaryDir . '/include_cache')
        call mkdir(g:NeoComplCache_TemporaryDir . '/include_cache')
    endif
endfunction"}}}

function! neocomplcache#plugin#include_complete#finalize()"{{{
endfunction"}}}

function! neocomplcache#plugin#include_complete#get_keyword_list(cur_keyword_str)"{{{
    let s:cur_keyword_len = len(a:cur_keyword_str)
    let l:keyword_escape = neocomplcache#keyword_escape(a:cur_keyword_str)

    " Keyword filter."{{{
    let l:cur_len = len(a:cur_keyword_str)
    if g:NeoComplCache_PartialMatch && !neocomplcache#skipped() && len(a:cur_keyword_str) >= g:NeoComplCache_PartialCompletionStartLength
        " Partial match.
        let l:pattern = printf("len(v:val.word) > l:cur_len && v:val.word =~ %s", string(l:keyword_escape))
    else
        " Head match.
        let l:pattern = printf("len(v:val.word) > l:cur_len && v:val.word =~ %s", string('^' . l:keyword_escape))
    endif"}}}

    let l:keyword_list = []
    for src in s:get_sources_list()
        call extend(l:keyword_list, filter(values(s:sources[src].keyword_cache), l:pattern))
    endfor
    return l:keyword_list
endfunction"}}}

" Dummy function.
function! neocomplcache#plugin#include_complete#calc_rank(cache_keyword_buffer_list)"{{{
endfunction"}}}

" Dummy function.
function! neocomplcache#plugin#include_complete#calc_prev_rank(cache_keyword_buffer_list, prev_word, prepre_word)"{{{
endfunction"}}}

" Event functions.
function! s:check_source()"{{{
    let l:bufnumber = 1

    " Check new buffer.
    while l:bufnumber <= bufnr('$')
        if buflisted(l:bufnumber)
            let l:bufname = fnamemodify(bufname(l:bufnumber), ':p')
            if (!has_key(s:sources, l:bufnumber) || s:check_changed_buffer(l:bufnumber))
                        \&& (g:NeoComplCache_CachingDisablePattern == '' || l:bufname !~ g:NeoComplCache_CachingDisablePattern)
                        \&& getbufvar(l:bufnumber, '&readonly') == 0
                        \&& getfsize(l:bufname) < g:NeoComplCache_CachingLimitFileSize
                " Caching.
            endif
        endif

        let l:bufnumber += 1
    endwhile
endfunction"}}}

function! s:update_source()"{{{
    " Check deleted buffer.
    for key in keys(s:sources)
        if !buflisted(str2nr(key))
            " Save cache.
            call s:save_cache(key)

            " Remove item.
            call remove(s:sources, key)
        endif
    endfor

    let l:caching_num = 0
    for source_name in keys(s:sources)
        " Caching.
    endfor
endfunction"}}}

function! s:save_all_cache()"{{{
    for l:key in keys(s:sources)
        call s:save_cache(l:key)
    endfor
endfunction"}}}

" Helper functions.
function! s:initialize_source(srcname)"{{{
    " Buffer.
    let l:filename = fnamemodify(bufname(a:srcname), ':t')

    let l:ft = &l:filetype
    if l:ft == ''
        let l:ft = 'nothing'
    endif

    let l:keyword_pattern = neocomplcache#assume_buffer_pattern(a:srcname)

    let s:sources[a:srcname] = {
                \'keyword_cache' : {}, 
                \'name' : l:filename, 'filetype' : l:ft, 'keyword_pattern' : l:keyword_pattern, 
                \}
endfunction"}}}

function! s:word_caching(srcname)"{{{
    " Initialize source.
    call s:initialize_source(a:srcname)

    if s:caching_from_cache(a:srcname) == 0
        " Caching from cache.
        return
    endif

    let l:source = s:sources[a:srcname]

    let l:filename = '[I] ' . fnamemodify(l:source.name, ':t')

    let l:menu = printf('%.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:keyword_pattern = l:source.keyword_pattern

    " Buffer.
    let l:buflines = getbufline(a:srcname, a:start_line, a:end_line)
    let [l:max_lines, l:line_num] = [len(l:buflines), 0]

    if l:max_lines > 200
        redraw
        echo 'Caching include file... please wait.'
    endif

    if l:max_lines > 10000
        let l:print_cache_percent = l:max_lines / 9
    elseif l:max_lines > 5000
        let l:print_cache_percent = l:max_lines / 6
    elseif l:max_lines > 3000
        let l:print_cache_percent = l:max_lines / 5
    elseif l:max_lines > 2000
        let l:print_cache_percent = l:max_lines / 4
    elseif l:max_lines > 1000
        let l:print_cache_percent = l:max_lines / 3
    elseif l:max_lines > 500
        let l:print_cache_percent = l:max_lines / 2
    else
        let l:print_cache_percent = -1
    endif
    let l:line_cnt = l:print_cache_percent

    while l:line_num < l:max_lines
        " Percentage check.
        if l:line_cnt == 0
            redraw
            echo printf('Caching: %d%%', l:line_num*100 / l:max_lines)
            let l:line_cnt = l:print_cache_percent
        endif
        let l:line_cnt -= 1

        let [l:line, l:match_num] = [buflines[l:line_num], 0]
        let l:match_str = matchstr(l:line, l:keyword_pattern)
        while l:match_str != ''
            " Ignore too short keyword.
            if len(l:match_str) >= g:NeoComplCache_MinKeywordLength
                        \&& !has_key(l:source.keyword_cache, l:match_str)
                " Append list.
                let l:source.keyword_cache[l:match_str] = {
                            \'word' : l:match_str, 'menu' : l:menu,
                            \'filename' : l:filename, 'srcname' : a:srcname, 'icase' : 1,
                            \'rank' : 1
                            \}

                let l:source.keyword_cache[l:match_str].abbr = 
                            \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                            \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str
            endif

            let l:match_num += len(l:match_str)
            let l:match_str = matchstr(l:line, l:keyword_pattern, l:match_num)
        endwhile

        let l:line_num += 1
    endwhile

    if l:max_lines > 200
        redraw
        echo 'Caching done.'
    endif
endfunction"}}}

function! s:caching_from_cache(srcname)"{{{
    if getbufvar(a:srcname, '&buftype') =~ 'nofile'
        return -1
    endif

    " Buffer.
    let l:srcname = fnamemodify(bufname(str2nr(a:srcname)), ':p')

    let l:cache_name = g:NeoComplCache_TemporaryDir . '/include_cache/' .
                \substitute(substitute(l:srcname, ':', '=-', 'g'), '[/\\]', '=+', 'g') . '='
    if getftime(l:cache_name) == -1 || getftime(l:cache_name) <= getftime(l:srcname)
        return -1
    endif

    let l:source = s:sources[a:srcname]

    let l:filename = '[I] ' . fnamemodify(l:source.name, ':t')

    let l:menu = printf('%.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:keyword_pattern = l:source.keyword_pattern

    let l:buflines = readfile(l:cache_name)
    let l:max_lines = len(l:buflines)

    if l:max_lines > 5000
        let l:print_cache_percent = l:max_lines / 5
    elseif l:max_lines > 3000
        let l:print_cache_percent = l:max_lines / 3
    elseif l:max_lines > 1000
        let l:print_cache_percent = l:max_lines / 2
    else
        let l:print_cache_percent = -1
    endif
    let l:line_cnt = l:print_cache_percent

    redraw
    if l:max_lines > 1000
        echo 'Caching include file... please wait.'
    endif

    let l:line_num = 0
    while l:line_num < l:max_lines
        " Percentage check.
        if l:line_cnt == 0
            redraw
            echo printf('Caching: %d%%', l:line_num*100 / l:max_lines)
            let l:line_cnt = l:print_cache_percent
        endif
        let l:line_cnt -= 1

        let l:match_str = buflines[l:line_num]
        " Ignore too short keyword.
        if len(l:match_str) >= g:NeoComplCache_MinKeywordLength
            " Append list.
            let l:source.keyword_cache[l:match_str] = {
                        \'word' : l:match_str, 'menu' : l:menu,
                        \'filename' : l:filename, 'srcname' : a:srcname, 'icase' : 1,
                        \'rank' : 1
                        \}

            let l:source.keyword_cache[l:match_str].abbr = 
                        \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                        \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str
        endif

        let l:line_num += 1
    endwhile

    if l:max_lines > 1000
        redraw
        echo 'Caching done.'
    endif

    return 0
endfunction"}}}

function! s:save_cache(srcname)"{{{
    if getbufvar(a:srcname, '&buftype') =~ 'nofile'
        return
    endif

    " Buffer.
    let l:srcname = fnamemodify(bufname(str2nr(a:srcname)), ':p')
    if !filereadable(l:srcname)
        return
    endif

    let l:cache_name = g:NeoComplCache_TemporaryDir . '/include_cache/' .
                \substitute(substitute(l:srcname, ':', '=-', 'g'), '[/\\]', '=+', 'g') . '='
    if getftime(l:cache_name) >= getftime(l:srcname)
        return -1
    endif

    " Output buffer.
    let l:word_list = []
    for keyword in values(s:sources[a:srcname].keyword_cache)
        call add(l:word_list, keyword.word)
    endfor
    call writefile(l:word_list, l:cache_name)
endfunction "}}}

function! s:check_changed_buffer(bufname)"{{{
    let l:ft = getbufvar(a:bufname, '&filetype')
    if l:ft == ''
        let l:ft = 'nothing'
    endif

    return s:sources[a:bufname].name != fnamemodify(bufname(a:bufname), ':t')
                \ || s:sources[a:bufname].filetype != l:ft
endfunction"}}}

function! s:get_sources_list()"{{{
    " Set buffer filetype.
    if &filetype == ''
        let l:ft = 'nothing'
    else
        let l:ft = &filetype
    endif

    let l:sources_list = []
    for key in keys(s:sources)
        if (key =~ '^\d' && l:ft == s:sources[key].filetype) || key =~ l:ft_dict
            call add(l:sources_list, key)
        endif
    endfor

    return l:sources_list
endfunction"}}}

" vim: foldmethod=marker
