"=============================================================================
" FILE: include_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 22 Nov 2009
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
"    - Improved caching speed when FileType.
"
"   1.06:
"    - Ignore no suffixes file.
"    - Improved set patterns.
"    - Fixed error; when open the file of the filetype that g:NeoComplCache_KeywordPatterns does not have.
"
"   1.05:
"    - Save error log.
"    - Implemented member filter.
"    - Fixed error.
"
"   1.04:
"    - Implemented fast search.
"
"   1.03:
"    - Improved caching.
"
"   1.02:
"    - Fixed keyword pattern error.
"    - Added g:NeoComplCache_IncludeSuffixes option. 
"    - Fixed empty filetype error.
"    - Echo filename when caching.
"
"   1.01:
"    - Fixed filter bug.
"    - Fixed matchstr timing.
"    - Fixed error when includeexpr is empty.
"    - Don't caching readonly buffer.
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

function! neocomplcache#plugin#include_complete#initialize()"{{{
    " Initialize
    let s:include_info = {}
    let s:include_cache = {}
    let s:completion_length = neocomplcache#get_completion_length('include_complete')
    
    augroup neocomplcache
        " Caching events
        autocmd FileType * call s:check_buffer_all()
        autocmd BufWritePost * call s:check_buffer(bufnr('%'))
    augroup END
    
    " Initialize include pattern."{{{
    call neocomplcache#set_variable_pattern('g:NeoComplCache_IncludePattern', 'java,haskell', '^import')
    "}}}
    " Initialize expr pattern."{{{
    call neocomplcache#set_variable_pattern('g:NeoComplCache_IncludeExpr', 'haskell',
                \'substitute(v:fname,''\\.'',''/'',''g'')')
    "}}}
    " Initialize path pattern."{{{
    if executable('python')
        call neocomplcache#set_variable_pattern('g:NeoComplCache_IncludePath', 'python',
                    \system('python -', 'import sys;sys.stdout.write(",".join(sys.path))'))
    endif
    "}}}
    " Initialize suffixes pattern."{{{
    call neocomplcache#set_variable_pattern('g:NeoComplCache_IncludeSuffixes', 'haskell', '.hs')
    "}}}
    
    " Create cache directory.
    if !isdirectory(g:NeoComplCache_TemporaryDir . '/include_cache')
        call mkdir(g:NeoComplCache_TemporaryDir . '/include_cache', 'p')
    endif
endfunction"}}}

function! neocomplcache#plugin#include_complete#finalize()"{{{
endfunction"}}}

function! neocomplcache#plugin#include_complete#get_keyword_list(cur_keyword_str)"{{{
    if !has_key(s:include_info, bufnr('%'))
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
        
        if len(l:cur_keyword_str) >= s:completion_length
            let l:use_member_filter = 0
            let l:key = tolower(l:cur_keyword_str[: s:completion_length-1])
            for l:include in s:include_info[bufnr('%')].include_files
                if has_key(s:include_cache[l:include], l:key)
                    let l:use_member_filter = 1
                    break
                endif
            endfor

            if !l:use_member_filter
                let l:cur_keyword_str = a:cur_keyword_str
            endif
        endif
    else
        let l:use_member_filter = 0
        let l:cur_keyword_str = a:cur_keyword_str
    endif
    
    let l:keyword_list = []
    let l:key = tolower(l:cur_keyword_str[: s:completion_length-1])
    if len(l:cur_keyword_str) < s:completion_length || neocomplcache#check_match_filter(l:key)
        for l:include in s:include_info[bufnr('%')].include_files
            let l:keyword_list += neocomplcache#unpack_list(values(s:include_cache[l:include]))
        endfor
        
        let l:keyword_list = neocomplcache#member_filter(l:keyword_list, a:cur_keyword_str)
    else
        for l:include in s:include_info[bufnr('%')].include_files
            if has_key(s:include_cache[l:include], l:key)
                let l:keyword_list += s:include_cache[l:include][l:key]
            endif
        endfor
        
        if len(a:cur_keyword_str) != s:completion_length
            let l:keyword_list = neocomplcache#member_filter(l:keyword_list, a:cur_keyword_str)
        endif
    endif

    return l:keyword_list
endfunction"}}}

" Dummy function.
function! neocomplcache#plugin#include_complete#calc_rank(cache_keyword_buffer_list)"{{{
endfunction"}}}
function! neocomplcache#plugin#include_complete#calc_prev_rank(cache_keyword_buffer_list, prev_word, prepre_word)"{{{
endfunction"}}}

function! s:check_buffer_all()"{{{
    let l:bufnumber = 1

    " Check buffer.
    while l:bufnumber <= bufnr('$')
        if buflisted(l:bufnumber) && !has_key(s:include_info, l:bufnumber)
            call s:check_buffer(l:bufnumber)
        endif

        let l:bufnumber += 1
    endwhile
endfunction"}}}
function! s:check_buffer(bufnumber)"{{{
    let l:bufname = fnamemodify(bufname(a:bufnumber), ':p')
    let s:include_info[a:bufnumber] = {}
    if (g:NeoComplCache_CachingDisablePattern == '' || l:bufname !~ g:NeoComplCache_CachingDisablePattern)
                \&& getbufvar(a:bufnumber, '&readonly') == 0
        " Check include.
        let s:include_info[a:bufnumber].include_files = s:get_include_files(a:bufnumber)
    else
        let s:include_info[a:bufnumber].include_files = []
    endif
endfunction"}}}
function! s:get_include_files(bufnumber)"{{{
    let l:filetype = getbufvar(a:bufnumber, '&filetype')
    if l:filetype == ''
        return []
    endif
    let l:pattern = has_key(g:NeoComplCache_IncludePattern, l:filetype) ? 
                \g:NeoComplCache_IncludePattern[l:filetype] : getbufvar(a:bufnumber, '&include')
    if l:pattern == ''
        return []
    endif
    let l:path = has_key(g:NeoComplCache_IncludePath, l:filetype) ? 
                \g:NeoComplCache_IncludePath[l:filetype] : getbufvar(a:bufnumber, '&path')
    let l:expr = has_key(g:NeoComplCache_IncludeExpr, l:filetype) ? 
                \g:NeoComplCache_IncludeExpr[l:filetype] : getbufvar(a:bufnumber, '&includeexpr')
    if has_key(g:NeoComplCache_IncludeSuffixes, l:filetype)
        let l:suffixes = &l:suffixesadd
    endif

    let l:buflines = getbufline(a:bufnumber, 1, 100)
    let l:include_files = []
    for l:line in l:buflines"{{{
        if l:line =~ l:pattern
            let l:match_end = matchend(l:line, l:pattern)
            if l:expr != ''
                let l:eval = substitute(l:expr, 'v:fname', string(matchstr(l:line[l:match_end :], '\f\+')), 'g')
                let l:filename = fnamemodify(findfile(eval(l:eval), l:path), ':p')
            else
                let l:filename = fnamemodify(findfile(matchstr(l:line[l:match_end :], '\f\+'), l:path), ':p')
            endif
            if filereadable(l:filename) && fnamemodify(l:filename, ':e') != ''
                call add(l:include_files, l:filename)

                if !has_key(s:include_cache, l:filename)
                    " Caching.
                    let s:include_cache[l:filename] = s:load_from_tags(l:filename, l:filetype)
                endif
            endif
        endif
    endfor"}}}
    
    " Restore option.
    if has_key(g:NeoComplCache_IncludeSuffixes, l:filetype)
        let &l:suffixesadd = l:suffixes
    endif
    
    return l:include_files
endfunction"}}}

function! s:load_from_tags(filename, filetype)"{{{
    " Initialize include list from tags.

    let l:keyword_lists = s:load_from_cache(a:filename)
    if !empty(l:keyword_lists)
        return l:keyword_lists
    endif

    if !executable('ctags')
        return s:load_from_file(a:filename, a:filetype)
    endif
    
    let l:filetype = getbufvar(bufnr(a:filename), '&filetype')

    let l:args = has_key(g:NeoComplCache_CtagsArgumentsList, l:filetype) ? 
                \g:NeoComplCache_CtagsArgumentsList[l:filetype] : g:NeoComplCache_CtagsArgumentsList['default']
    let l:lines = split(system(printf('ctags %s -f - %s', l:args, a:filename)), '\n')
    let l:max_lines = len(l:lines)
    
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:menu_pattern = '[I] %.' . g:NeoComplCache_MaxFilenameWidth . 's %.'. g:NeoComplCache_MaxFilenameWidth . 's'
    
    if l:max_lines > 1000
        redraw
        echo 'Caching include files "' . a:filename . '"... please wait.'
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
                        \&& !has_key(l:dup_check, l:tag[0])
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
                            \ 'word' : l:tag[0], 'rank' : 5, 'prev_rank' : 0, 'prepre_rank' : 0, 'icase' : 1,
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

                let l:key = tolower(l:tag[0][: s:completion_length-1])
                if !has_key(l:keyword_lists, l:key)
                    let l:keyword_lists[l:key] = []
                endif
                call add(l:keyword_lists[l:key], l:keyword)

                let l:dup_check[l:tag[0]] = 1
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

    if empty(l:keyword_lists)
        return s:load_from_file(a:filename, a:filetype)
    endif
    
    call s:save_cache(a:filename, neocomplcache#unpack_list(values(l:keyword_lists)))
    
    return l:keyword_lists
endfunction"}}}
function! s:load_from_file(filename, filetype)"{{{
    " Initialize include list from file.

    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:lines = readfile(a:filename)
    let l:max_lines = len(l:lines)
    
    if l:max_lines > 1000
        redraw
        echo 'Caching include files "' . a:filename . '"... please wait.'
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
    
    let l:line_num = 1
    let l:pattern = neocomplcache#get_keyword_pattern()
    let l:menu = printf('[I] %.' . g:NeoComplCache_MaxFilenameWidth . 's', fnamemodify(a:filename, ':t'))
    let l:keyword_lists = {}
    let l:dup_check = {}

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
        
        let [l:match_num, l:match] = [0, match(l:line, l:pattern)]
        while l:match >= 0"{{{
            let l:match_str = matchstr(l:line, l:pattern, l:match)

            " Ignore too short keyword.
            if len(l:match_str) >= g:NeoComplCache_MinKeywordLength
                        \&& !has_key(l:dup_check, l:match_str)
                " Append list.
                let l:keyword = {
                            \'word' : l:match_str, 'menu' : l:menu, 'icase' : 1, 'kind' : '', 'class' : '', 
                            \'rank' : 5, 'prev_rank' : 0, 'prepre_rank' : 0,
                            \}

                let l:keyword.abbr = 
                            \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                            \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str

                let l:key = tolower(l:match_str[: s:completion_length-1])
                if !has_key(l:keyword_lists, l:key)
                    let l:keyword_lists[l:key] = []
                endif
                call add(l:keyword_lists[l:key], l:keyword)
                
                let l:dup_check[l:match_str] = 1
            endif

            let l:match_num = l:match + len(l:match_str)
            let l:match = match(l:line, l:pattern, l:match_num)
        endwhile"}}}
        
        let l:line_num += 1
    endfor"}}}

    if l:max_lines > 300
        call s:save_cache(a:filename, neocomplcache#unpack_list(values(l:keyword_lists)))
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
    let l:cache_name = g:NeoComplCache_TemporaryDir . '/include_cache/' .
                \substitute(substitute(a:filename, ':', '=-', 'g'), '[/\\]', '=+', 'g') . '='
    if getftime(l:cache_name) == -1 || getftime(l:cache_name) <= getftime(a:filename)
        return {}
    endif
    
    let l:keyword_lists = {}
    let l:lines = readfile(l:cache_name)
    let l:max_lines = len(l:lines)
    
    if l:max_lines > 3000
        redraw
        echo 'Caching include files "' . a:filename . '"... please wait.'
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
        let l:cache_dir = g:NeoComplCache_TemporaryDir . '/include_cache'
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
function! s:save_cache(filename, keyword_list)"{{{
    let l:cache_name = g:NeoComplCache_TemporaryDir . '/include_cache/' .
                \substitute(substitute(a:filename, ':', '=-', 'g'), '[/\\]', '=+', 'g') . '='

    " Output cache.
    let l:word_list = []
    for keyword in a:keyword_list
        call add(l:word_list, printf('%s!!!%s!!!%s!!!%s!!!%s', 
                    \keyword.word, keyword.abbr, keyword.menu, keyword.kind, keyword.class))
    endfor
    call writefile(l:word_list, l:cache_name)
endfunction"}}}

" Global options definition."{{{
if !exists('g:NeoComplCache_IncludePattern')
    let g:NeoComplCache_IncludePattern = {}
endif
if !exists('g:NeoComplCache_IncludeExpr')
    let g:NeoComplCache_IncludeExpr = {}
endif
if !exists('g:NeoComplCache_IncludePath')
    let g:NeoComplCache_IncludePath = {}
endif
if !exists('g:NeoComplCache_IncludeSuffixes')
    let g:NeoComplCache_IncludeSuffixes = {}
endif
"}}}

" vim: foldmethod=marker
