"=============================================================================
" FILE: tags_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 10 Nov 2009
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
" Version: 1.13, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.13:
"    - Save error log.
"    - Implemented member filter.
"    - Allow dup.
"
"   1.12:
"    - Implemented fast search.
"    - Print filename when caching.
"
"   1.11:
"    - Disable auto caching in tags_complete.
"    - Improved caching.
"
"   1.10:
"    - Enable auto-complete.
"    - Optimized.
"
"   1.09:
"    - Supported neocomplcache 3.0.
"
"   1.08:
"    - Improved popup menu.
"    - Ignore case.
"
"   1.07:
"    - Fixed for neocomplcache 2.43.
"
"   1.06:
"    - Improved abbr.
"    - Refactoring.
"
"   1.05:
"    - Improved filtering.
"
"   1.04:
"    - Don't return static member.
"
"   1.03:
"    - Optimized memory.
"
"   1.02:
"    - Escape input keyword.
"    - Supported camel case completion.
"    - Fixed echo.
"
"   1.01:
"    - Not caching.
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

function! neocomplcache#plugin#tags_complete#initialize()"{{{
    " Initialize
    let s:tags_list = {}
    let s:completion_length = neocomplcache#get_completion_length('tags_complete')
    
    " Create cache directory.
    if !isdirectory(g:NeoComplCache_TemporaryDir . '/tags_cache')
        call mkdir(g:NeoComplCache_TemporaryDir . '/tags_cache', 'p')
    endif
    
    command! -nargs=? -complete=buffer NeoComplCacheCachingTags call s:caching_tags(<q-args>)
endfunction"}}}

function! neocomplcache#plugin#tags_complete#finalize()"{{{
endfunction"}}}

function! neocomplcache#plugin#tags_complete#get_keyword_list(cur_keyword_str)"{{{
    if empty(s:tags_list)
        return []
    endif
    
    let l:ft = &filetype
    if l:ft == ''
        let l:ft = 'nothing'
    endif
    
    if has_key(g:NeoComplCache_MemberPrefixPatterns, l:ft) && a:cur_keyword_str =~ g:NeoComplCache_MemberPrefixPatterns[l:ft]
        let l:use_member_filter = 1
        let l:prefix = matchstr(a:cur_keyword_str, g:NeoComplCache_MemberPrefixPatterns[l:ft])
        let l:cur_keyword_str = a:cur_keyword_str[len(l:prefix) :]
    else
        let l:use_member_filter = 0
        let l:cur_keyword_str = a:cur_keyword_str
    endif

    let l:keyword_list = []
    let l:key = tolower(l:cur_keyword_str[: s:completion_length-1])
    if len(l:cur_keyword_str) < s:completion_length || neocomplcache#check_match_filter(l:key)
        for tags in split(&l:tags, ',')
            let l:filename = fnamemodify(tags, ':p')
            if filereadable(l:filename) && has_key(s:tags_list, l:filename)
                let l:keyword_list += neocomplcache#unpack_list(values(s:tags_list[l:filename]))
            endif
        endfor
    else
        for tags in split(&l:tags, ',')
            let l:filename = fnamemodify(tags, ':p')
            if filereadable(l:filename) && has_key(s:tags_list, l:filename) 
                        \&& has_key(s:tags_list[l:filename], l:key)
                let l:keyword_list += s:tags_list[l:filename][l:key]
            endif
        endfor
        
        if len(l:cur_keyword_str) == s:completion_length && !l:use_member_filter
            return l:keyword_list
        endif
    endif
    
    return neocomplcache#member_filter(l:keyword_list, a:cur_keyword_str)
endfunction"}}}

" Dummy function.
function! neocomplcache#plugin#tags_complete#calc_rank(cache_keyword_buffer_list)"{{{
endfunction"}}}

" Dummy function.
function! neocomplcache#plugin#tags_complete#calc_prev_rank(cache_keyword_buffer_list, prev_word, prepre_word)"{{{
endfunction"}}}

function! s:caching_tags(bufname)"{{{
    let l:bufname = (a:bufname == '') ? bufname('%') : a:bufname
    for tags in split(getbufvar(bufnr(l:bufname), '&tags'), ',')
        let l:filename = fnamemodify(tags, ':p')
        if filereadable(l:filename) && has_key(s:tags_list, l:filename)
            if !has_key(s:tags_list[l:filename], l:key)
                let s:tags_list[l:filename][l:key] = []
            endif

            let l:list += s:tags_list[l:filename][l:key]
        endif
    endfor
    let s:tags_list[l:filename] = s:initialize_tags(l:filename)
endfunction"}}}
function! s:initialize_tags(filename)"{{{
    " Initialize tags list.

    let l:keyword_lists = s:load_from_cache(a:filename)
    if !empty(l:keyword_lists)
        return l:keyword_lists
    endif
    
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:menu_pattern = '[T] %.' . g:NeoComplCache_MaxFilenameWidth . 's %.'. g:NeoComplCache_MaxFilenameWidth . 's'
    let l:dup_check = {}
    let l:lines = readfile(a:filename)
    let l:max_lines = len(l:lines)
    
    if l:max_lines > 1000
        redraw
        echo 'Caching tags "' . a:filename . '"... please wait.'
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
    
    try
        let l:dup_check = {}
        let l:line_num = 1
        for l:line in l:lines"{{{
            " Percentage check."{{{
            if l:line_cnt == 0
                if g:NeoComplCache_CachingPercentInStatusline
                    let &l:statusline = printf('Caching(%s): %d%%', a:filename, l:line_num*100 / l:max_lines)
                    redrawstatus!
                else
                    redraw
                    echo printf('Caching(%s): %d%%', a:filename, l:line_num*100 / l:max_lines)
                endif
                let l:line_cnt = l:print_cache_percent
            endif
            let l:line_cnt -= 1"}}}

            let l:tag = split(l:line, '\t')
            " Add keywords.
            if l:line !~ '^!' && len(l:tag) >= 3 && len(l:tag[0]) >= g:NeoComplCache_MinKeywordLength
                        \&& !has_key(l:keyword_lists, l:tag[0])
                let l:option = { 'cmd' : 
                            \substitute(substitute(l:tag[2], '^[/?]\^\?\s*\|\$\?[/?];"$', '', 'g'), '\\\\', '\\', 'g') }
                for l:opt in l:tag[3:]
                    let l:key = matchstr(l:opt, '^\h\w*\ze:')
                    if l:key == ''
                        let l:option['kind'] = l:opt
                    else
                        let l:option[l:key] = matchstr(l:opt, '^\h\w*:\zs.*')
                    endif
                endfor

                if has_key(l:option, 'file') || (has_key(l:option, 'access') && l:option.access != 'public')
                    let l:line_num += 1
                    continue
                endif

                let l:abbr = (l:tag[3] == 'd' || l:option['cmd'] == '')? l:tag[0] : l:option['cmd']
                let l:keyword = {
                            \ 'word' : l:tag[0], 'rank' : 5, 'prev_rank' : 0, 'prepre_rank' : 0, 'icase' : 1, 'dup' : 1,
                            \ 'abbr' : (len(l:abbr) > g:NeoComplCache_MaxKeywordWidth)?
                            \   printf(l:abbr_pattern, l:abbr, l:abbr[-8:]) : l:abbr,
                            \ 'kind' : l:option['kind']
                            \}
                if has_key(l:option, 'struct')
                    let keyword.menu = printf(l:menu_pattern, fnamemodify(l:tag[1], ':t'), l:option.struct)
                    let keyword.class = l:option.struct
                elseif has_key(l:option, 'class')
                    let keyword.menu = printf(l:menu_pattern, fnamemodify(l:tag[1], ':t'), l:option.class)
                    let keyword.class = l:option.class
                elseif has_key(l:option, 'enum')
                    let keyword.menu = printf(l:menu_pattern, fnamemodify(l:tag[1], ':t'), l:option.enum)
                    let keyword.class = l:option.enum
                else
                    let keyword.menu = printf(l:menu_pattern, fnamemodify(l:tag[1], ':t'), '')
                    let keyword.class = ''
                endif

                let l:key = tolower(l:keyword.word[: s:completion_length-1])
                if !has_key(l:keyword_lists, l:key)
                    let l:keyword_lists[l:key] = []
                endif
                call add(l:keyword_lists[l:key], l:keyword)
            endif

            let l:line_num += 1
        endfor"}}}
    catch /E684:/
        echohl WarningMsg | echomsg 'Error occured while analyzing tags!' | echohl None
        let l:log_file = g:NeoComplCache_TemporaryDir . '/tags_cache/error_log'
        echohl WarningMsg | echomsg 'Please look tags file: ' . l:log_file | echohl None
        call writefile(l:lines, l:log_file)
        return {}
    endtry

    if l:max_lines > 200
        call s:save_cache(a:filename, l:keyword_lists)
    endif
    
    if l:max_lines > 1000
        if g:NeoComplCache_CachingPercentInStatusline
            let &l:statusline = l:statusline_save
            redrawstatus
        else
            redraw
            echo ''
            redraw
        endif
    endif
    
    return l:keyword_lists
endfunction"}}}
function! s:load_from_cache(filename)"{{{
    let l:cache_name = g:NeoComplCache_TemporaryDir . '/tags_cache/' .
                \substitute(substitute(a:filename, ':', '=-', 'g'), '[/\\]', '=+', 'g') . '='
    if getftime(l:cache_name) == -1 || getftime(l:cache_name) <= getftime(a:filename)
        return {}
    endif
    
    let l:keyword_lists = {}
    let l:lines = readfile(l:cache_name)
    let l:max_lines = len(l:lines)
    
    if l:max_lines > 3000
        redraw
        echo 'Caching tags "' . a:filename . '"... please wait.'
    endif
    if l:max_lines > 10000
        let l:print_cache_percent = l:max_lines / 5
    elseif l:max_lines > 5000
        let l:print_cache_percent = l:max_lines / 4
    elseif l:max_lines > 3000
        let l:print_cache_percent = l:max_lines / 3
    else
        let l:print_cache_percent = -1
    endif
    let l:line_cnt = l:print_cache_percent
    
    try
        let l:line_num = 1
        for l:line in l:lines"{{{
            " Percentage check."{{{
            if l:line_cnt == 0
                if g:NeoComplCache_CachingPercentInStatusline
                    let &l:statusline = printf('Caching(%s): %d%%', a:filename, l:line_num*100 / l:max_lines)
                    redrawstatus!
                else
                    redraw
                    echo printf('Caching(%s): %d%%', a:filename, l:line_num*100 / l:max_lines)
                endif
                let l:line_cnt = l:print_cache_percent
            endif
            let l:line_cnt -= 1"}}}

            let l:cache = split(l:line, '!!!', 1)
            let l:keyword = {
                        \ 'word' : l:cache[0], 'rank' : 5, 'prev_rank' : 0, 'prepre_rank' : 0, 'icase' : 1, 'dup' : 1, 
                        \ 'abbr' : l:cache[1], 'menu' : l:cache[2], 'kind' : l:cache[3], 'class' :  l:cache[4]
                        \}

            let l:key = tolower(l:cache[0][: s:completion_length-1])
            if !has_key(l:keyword_lists, l:key)
                let l:keyword_lists[l:key] = []
            endif
            call add(l:keyword_lists[l:key], l:keyword)

            let l:line_num += 1
        endfor"}}}
    catch /E684:/
        echohl WarningMsg | echomsg 'Error occured while analyzing cache!' | echohl None
        let l:cache_dir = g:NeoComplCache_TemporaryDir . '/tags_cache'
        echohl WarningMsg | echomsg 'Please delete cache directory: ' . l:cache_dir | echohl None
        return {}
    endtry
    
    if l:max_lines > 3000
        if g:NeoComplCache_CachingPercentInStatusline
            let &l:statusline = l:statusline_save
            redrawstatus
        else
            redraw
            echo ''
            redraw
        endif
    endif
    
    return l:keyword_lists
endfunction"}}}
function! s:save_cache(filename, keyword_lists)"{{{
    let l:cache_name = g:NeoComplCache_TemporaryDir . '/tags_cache/' .
                \substitute(substitute(a:filename, ':', '=-', 'g'), '[/\\]', '=+', 'g') . '='

    " Output tags.
    let l:word_list = []
    for keyword_list in values(a:keyword_lists)
        for keyword in keyword_list
            call add(l:word_list, printf('%s!!!%s!!!%s!!!%s!!!%s', 
                        \keyword.word, keyword.abbr, keyword.menu, keyword.kind, keyword.class))
        endfor
    endfor
    call writefile(l:word_list, l:cache_name)
endfunction"}}}

" vim: foldmethod=marker
