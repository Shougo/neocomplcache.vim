"=============================================================================
" FILE: include_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 28 Oct 2009
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
"    - Fixed keyword pattern error.
"    - Added g:NeoComplCache_IncludeSuffixes option. 
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
    let s:include_list = {}
    let s:include_cache = {}
    
    augroup neocomplcache
        " Caching events
        autocmd FileType * call s:check_buffer_all()
        autocmd BufWritePost * call s:check_buffer(bufnr('%'))
    augroup END
    
    " Initialize include pattern."{{{
    call s:set_include_pattern('java,haskell', '^import')
    "}}}
    " Initialize expr pattern."{{{
    call s:set_expr_pattern('haskell', 'substitute(v:fname,''\\.'',''/'',''g'')')
    "}}}
    " Initialize path pattern."{{{
    if executable('python')
        call s:set_path_pattern('python',
                    \system('python -', 'import sys;sys.stdout.write(",".join(sys.path))'))
    endif
    "}}}
    " Initialize suffixes pattern."{{{
    call s:set_suffixes_pattern('haskell', '.hs')
    "}}}
    
    " Create cache directory.
    if !isdirectory(g:NeoComplCache_TemporaryDir . '/include_cache')
        call mkdir(g:NeoComplCache_TemporaryDir . '/include_cache', 'p')
    endif
endfunction"}}}

function! neocomplcache#plugin#include_complete#finalize()"{{{
endfunction"}}}

function! neocomplcache#plugin#include_complete#get_keyword_list(cur_keyword_str)"{{{
    if !has_key(s:include_list, bufnr('%'))
        return []
    endif

    let l:keyword_list = []
    for l:include in s:include_list[bufnr('%')]
        let l:keyword_list += s:include_cache[l:include]
    endfor

    return neocomplcache#keyword_filter(l:keyword_list, a:cur_keyword_str)
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
        if buflisted(l:bufnumber)
            call s:check_buffer(l:bufnumber)
        endif

        let l:bufnumber += 1
    endwhile
endfunction"}}}
function! s:check_buffer(bufnumber)"{{{
    let l:bufname = fnamemodify(bufname(a:bufnumber), ':p')
    if (g:NeoComplCache_CachingDisablePattern == '' || l:bufname !~ g:NeoComplCache_CachingDisablePattern)
                \&& getbufvar(a:bufnumber, '&readonly') == 0 && getbufvar(a:bufnumber, '&filetype') != ''
        " Check include.
        call s:check_include(a:bufnumber)
    endif
endfunction"}}}
function! s:check_include(bufnumber)"{{{
    let l:filetype = getbufvar(a:bufnumber, '&filetype')
    let l:pattern = has_key(g:NeoComplCache_IncludePattern, l:filetype) ? 
                \g:NeoComplCache_IncludePattern[l:filetype] : getbufvar(a:bufnumber, '&include')
    if l:pattern == ''
        return
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
            if filereadable(l:filename)
                call add(l:include_files, l:filename)

                if !has_key(s:include_cache, l:filename)
                    " Caching.
                    let s:include_cache[l:filename] = s:load_from_tags(l:filename)
                endif
            endif
        endif
    endfor"}}}
    
    " Restore option.
    if has_key(g:NeoComplCache_IncludeSuffixes, l:filetype)
        let &l:suffixesadd = l:suffixes
    endif
    
    let s:include_list[a:bufnumber] = l:include_files
endfunction"}}}

function! s:load_from_tags(filename)"{{{
    " Initialize include list from tags.

    let l:keyword_list = s:load_from_cache(a:filename)
    if !empty(l:keyword_list)
        return values(l:keyword_list)
    endif

    if !executable('ctags')
        return values(s:load_from_file(a:filename))
    endif
    
    let l:filetype = getbufvar(bufnr(a:filename), '&filetype')

    let l:args = has_key(g:NeoComplCache_CtagsArgumentsList, l:filetype) ? 
                \g:NeoComplCache_CtagsArgumentsList[l:filetype] : g:NeoComplCache_CtagsArgumentsList['default']
    let l:lines = split(system(printf('ctags %s -f - %s', l:args, a:filename)), '\n')
    let l:max_lines = len(l:lines)
    
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:menu_pattern = '[I] %.'. g:NeoComplCache_MaxFilenameWidth . 's'
    
    if l:max_lines > 1000
        redraw
        echo 'Caching include files... please wait.'
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
    for l:line in l:lines"{{{
        " Percentage check."{{{
        if l:line_cnt == 0
            if g:NeoComplCache_CachingPercentInStatusline
                let &l:statusline = printf('Caching: %d%%', l:line_num*100 / l:max_lines)
                redrawstatus!
            else
                redraw
                echo printf('Caching: %d%%', l:line_num*100 / l:max_lines)
            endif
            let l:line_cnt = l:print_cache_percent
        endif
        let l:line_cnt -= 1"}}}
        
        let l:tag = split(l:line, "\<Tab>")
        " Add keywords.
        if l:line !~ '^!' && len(l:tag[0]) >= g:NeoComplCache_MinKeywordLength
                    \&& !has_key(l:keyword_list, l:tag[0])
            let l:option = {}
            let l:match = matchlist(l:line, '.*\t.*\t/^\(.*\)/;"\t\(\a\)\(.*\)')
            if empty(l:match)
                let l:match = split(l:line, '\t')
                let [l:option['cmd'], l:option['kind'], l:opt] = [l:match[2], l:match[3], join(l:match[4:], '\t')]
            else
                let [l:option['cmd'], l:option['kind'], l:opt] = [l:match[1], l:match[2], l:match[3]]
            endif
            for op in split(l:opt, '\t')
                let l:key = matchstr(op, '^\h\w*\ze:')
                let l:option[l:key] = matchstr(op, '^\h\w*:\zs.*')
            endfor
            
            if has_key(l:option, 'file') || (has_key(l:option, 'access') && l:option.access != 'public')
                let l:line_num += 1
                continue
            endif
            
            let l:abbr = (l:tag[3] == 'd')? l:tag[0] :
                        \ substitute(substitute(substitute(l:tag[2], '^/\^\=\s*\|\$\=/;"$', '', 'g'),
                        \           '\s\+', ' ', 'g'), '\\/', '/', 'g')
            let l:keyword = {
                        \ 'word' : l:tag[0], 'rank' : 5, 'prev_rank' : 0, 'prepre_rank' : 0, 'icase' : 1,
                        \ 'abbr' : (len(l:abbr) > g:NeoComplCache_MaxKeywordWidth)? 
                        \   printf(l:abbr_pattern, l:abbr, l:abbr[-8:]) : l:abbr,
                        \ 'kind' : l:option['kind']
                        \}
            if has_key(l:option, 'struct')
                let keyword.menu = printf(l:menu_pattern, l:option.struct)
            elseif has_key(l:option, 'class')
                let keyword.menu = printf(l:menu_pattern, l:option.class)
            elseif has_key(l:option, 'enum')
                let keyword.menu = printf(l:menu_pattern, l:option.enum)
            else
                let keyword.menu = '[I]'
            endif

            let l:keyword_list[l:tag[0]] = l:keyword
        endif

        let l:line_num += 1
    endfor"}}}

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

    if empty(l:keyword_list)
        return values(s:load_from_file(a:filename))
    endif
    
    call s:save_cache(a:filename, values(l:keyword_list))
    
    return values(l:keyword_list)
endfunction"}}}
function! s:load_from_file(filename)"{{{
    " Initialize include list from file.

    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:menu_pattern = '[I] %s %.'. g:NeoComplCache_MaxFilenameWidth . 's'
    let l:lines = readfile(a:filename)
    let l:max_lines = len(l:lines)
    
    if l:max_lines > 1000
        redraw
        echo 'Caching include files... please wait.'
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
    let l:filetype = getbufvar(bufnr(a:filename), '&filetype')
    let l:pattern = g:NeoComplCache_KeywordPatterns[l:filetype]
    let l:menu = printf('[I] %.' . g:NeoComplCache_MaxFilenameWidth . 's', fnamemodify(a:filename, ':t'))
    let l:keyword_list = {}

    for l:line in l:lines"{{{
        " Percentage check."{{{
        if l:line_cnt == 0
            if g:NeoComplCache_CachingPercentInStatusline
                let &l:statusline = printf('Caching: %d%%', l:line_num*100 / l:max_lines)
                redrawstatus!
            else
                redraw
                echo printf('Caching: %d%%', l:line_num*100 / l:max_lines)
            endif
            let l:line_cnt = l:print_cache_percent
        endif
        let l:line_cnt -= 1"}}}
        
        let [l:match_num, l:match] = [0, match(l:line, l:pattern)]
        while l:match >= 0"{{{
            let l:match_str = matchstr(l:line, l:pattern, l:match)

            " Ignore too short keyword.
            if len(l:match_str) >= g:NeoComplCache_MinKeywordLength
                        \&& !has_key(l:keyword_list, l:match_str)
                " Append list.
                let l:keyword = {
                            \'word' : l:match_str, 'menu' : l:menu, 'icase' : 1, 'kind' : '',
                            \'rank' : 5, 'prev_rank' : 0, 'prepre_rank' : 0,
                            \}

                let l:keyword.abbr = 
                            \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                            \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str
                let l:keyword_list[l:match_str] = l:keyword
            endif

            let l:match_num = l:match + len(l:match_str)
            let l:match = match(l:line, l:pattern, l:match_num)
        endwhile"}}}
        
        let l:line_num += 1
    endfor"}}}

    if l:max_lines > 300
        call s:save_cache(a:filename, values(l:keyword_list))
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
    
    return l:keyword_list
endfunction"}}}
function! s:load_from_cache(filename)"{{{
    let l:cache_name = g:NeoComplCache_TemporaryDir . '/include_cache/' .
                \substitute(substitute(a:filename, ':', '=-', 'g'), '[/\\]', '=+', 'g') . '='
    if getftime(l:cache_name) == -1 || getftime(l:cache_name) <= getftime(a:filename)
        return {}
    endif
    
    let l:keyword_list = {}
    let l:lines = readfile(l:cache_name)
    let l:max_lines = len(l:lines)
    
    if l:max_lines > 3000
        redraw
        echo 'Caching include files... please wait.'
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
    
    let l:line_num = 1
    for l:line in l:lines"{{{
        " Percentage check."{{{
        if l:line_cnt == 0
            if g:NeoComplCache_CachingPercentInStatusline
                let &l:statusline = printf('Caching: %d%%', l:line_num*100 / l:max_lines)
                redrawstatus!
            else
                redraw
                echo printf('Caching: %d%%', l:line_num*100 / l:max_lines)
            endif
            let l:line_cnt = l:print_cache_percent
        endif
        let l:line_cnt -= 1"}}}
        
        let l:cache = split(l:line, '!!!', 1)
        let l:keyword_list[l:cache[0]] = {
                    \ 'word' : l:cache[0], 'rank' : 5, 'prev_rank' : 0, 'prepre_rank' : 0, 'icase' : 1,
                    \ 'abbr' : l:cache[1], 'menu' : l:cache[2], 'kind' : l:cache[3]
                    \}
        let l:line_num += 1
    endfor"}}}
    
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
    
    return l:keyword_list
endfunction"}}}
function! s:save_cache(filename, keyword_list)"{{{
    let l:cache_name = g:NeoComplCache_TemporaryDir . '/include_cache/' .
                \substitute(substitute(a:filename, ':', '=-', 'g'), '[/\\]', '=+', 'g') . '='

    " Output cache.
    let l:word_list = []
    for keyword in a:keyword_list
        call add(l:word_list, printf('%s!!!%s!!!%s!!!%s', keyword.word, keyword.abbr, keyword.menu, keyword.kind))
    endfor
    call writefile(l:word_list, l:cache_name)
endfunction"}}}

" Set pattern helper."{{{
function! s:set_include_pattern(filetype, pattern)"{{{
    for ft in split(a:filetype, ',')
        if !has_key(g:NeoComplCache_IncludePattern, ft) 
            let g:NeoComplCache_IncludePattern[ft] = a:pattern
        endif
    endfor
endfunction"}}}
function! s:set_expr_pattern(filetype, pattern)"{{{
    for ft in split(a:filetype, ',')
        if !has_key(g:NeoComplCache_IncludeExpr, ft) 
            let g:NeoComplCache_IncludeExpr[ft] = a:pattern
        endif
    endfor
endfunction"}}}
function! s:set_path_pattern(filetype, pattern)"{{{
    for ft in split(a:filetype, ',')
        if !has_key(g:NeoComplCache_IncludePath, ft) 
            let g:NeoComplCache_IncludePath[ft] = a:pattern
        endif
    endfor
endfunction"}}}
function! s:set_suffixes_pattern(filetype, pattern)"{{{
    for ft in split(a:filetype, ',')
        if !has_key(g:NeoComplCache_IncludeSuffixes, ft) 
            let g:NeoComplCache_IncludeSuffixes[ft] = a:pattern
        endif
    endfor
endfunction"}}}
"}}}

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
