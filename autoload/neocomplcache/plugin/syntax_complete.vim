"=============================================================================
" FILE: syntax_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 11 Jun 2010
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
" Version: 1.28, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.29:
"    - Improved for same filetype.
"
"   1.28:
"    - Improved caching.
"    - Use caching helper.
"    - Improved analyze.
"
"   1.27:
"    - Disabled in vim.
"
"   1.26:
"    - Fixed dup check bug.
"
"   1.25:
"    - Implemented fast search.
"    - Print filename when caching.
"
"   1.24:
"    - Supported neocomplcache 3.0.
"
"   1.23:
"    - Supported g:NeoComplCache_CachingPercentInStatusline.
"
"   1.22:
"    - Fixed long abbr bug.
"    - Ignore japanese syntax message.
"
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
"=============================================================================

function! neocomplcache#plugin#syntax_complete#initialize()"{{{
    " Initialize.
    let s:syntax_list = {}
    let s:completion_length = neocomplcache#get_completion_length('syntax_complete')

    " Set caching event.
    autocmd neocomplcache FileType * call s:caching()

    " Add command.
    command! -nargs=? -complete=customlist,neocomplcache#filetype_complete NeoComplCacheCachingSyntax call s:recaching(<q-args>)

    " Create cache directory.
    if !isdirectory(g:NeoComplCache_TemporaryDir . '/syntax_cache')
        call mkdir(g:NeoComplCache_TemporaryDir . '/syntax_cache')
    endif
endfunction"}}}

function! neocomplcache#plugin#syntax_complete#finalize()"{{{
    delcommand NeoComplCacheCachingSyntax
endfunction"}}}

function! neocomplcache#plugin#syntax_complete#get_keyword_list(cur_keyword_str)"{{{
    let l:list = []
    
    for l:source in neocomplcache#get_sources_list(s:syntax_list, &filetype)
        if len(a:cur_keyword_str) < s:completion_length ||
                    \neocomplcache#check_match_filter(a:cur_keyword_str, s:completion_length)
            let l:list += neocomplcache#keyword_filter(neocomplcache#unpack_dictionary(l:source), a:cur_keyword_str)
        else
            let l:key = tolower(a:cur_keyword_str[: s:completion_length-1])

            if has_key(l:source, l:key)
                if len(a:cur_keyword_str) == s:completion_length
                    let l:list += l:source[l:key]
                else
                    let l:list += neocomplcache#keyword_filter(copy(l:source[l:key]), a:cur_keyword_str)
                endif
            endif
        endif
    endfor

    return l:list
endfunction"}}}

function! s:caching()"{{{
    if &filetype == '' || &filetype == 'vim'
        return
    endif
    
    for l:filetype in keys(neocomplcache#get_source_filetypes(&filetype))
        if !has_key(s:syntax_list, l:filetype)
            let l:keyword_lists = neocomplcache#cache#index_load_from_cache('syntax_cache', l:filetype, s:completion_length)
            if !empty(l:keyword_lists)
                " Caching from cache.
                let s:syntax_list[l:filetype] = l:keyword_lists
            elseif l:filetype == &filetype
                if g:NeoComplCache_CachingPercentInStatusline
                    let l:statusline_save = &l:statusline
                endif
                
                call neocomplcache#print_caching('Caching syntax "' . l:filetype . '"... please wait.')
                
                " Caching from syn list.
                let s:syntax_list[l:filetype] = s:caching_from_syn()
                
                call neocomplcache#print_caching('Caching done.')

                if g:NeoComplCache_CachingPercentInStatusline
                    let &l:statusline = l:statusline_save
                endif
            endif
        endif
    endfor
endfunction"}}}

function! s:recaching(filetype)"{{{
    if a:filetype == ''
        let l:filetype = &filetype
    else
        let l:filetype = a:filetype
    endif

    " Caching.
    if g:NeoComplCache_CachingPercentInStatusline
        let l:statusline_save = &l:statusline
    endif

    call neocomplcache#print_caching('Caching syntax "' . l:filetype . '"... please wait.')
    let s:syntax_list[l:filetype] = s:caching_from_syn()
    
    call neocomplcache#print_caching('Caching done.')

    if g:NeoComplCache_CachingPercentInStatusline
        let &l:statusline = l:statusline_save
    endif
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
    let l:keyword_pattern = neocomplcache#get_keyword_pattern()
    
    let l:dup_check = {}
    let l:menu = '[S] '

    let l:keyword_lists = {}
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
        elseif l:line =~ '^\s*start='
            let l:line = 
                        \s:substitute_candidate(matchstr(l:line, 'start=/\zs[^/]\+\ze/')) . ' ' .
                        \s:substitute_candidate(matchstr(l:line, 'end=/zs[^/]\+\ze/'))
        endif

        " Add keywords.
        let l:match_num = 0
        let l:match_str = matchstr(l:line, l:keyword_pattern, l:match_num)
        while l:match_str != ''
            " Ignore too short keyword.
            if len(l:match_str) >= g:NeoComplCache_MinSyntaxLength && !has_key(l:dup_check, l:match_str)
                        \&& l:match_str =~ '^[[:print:]]\+$'
                let l:keyword = {
                            \ 'word' : l:match_str, 'menu' : l:menu, 'icase' : 1
                            \}
                let l:keyword.abbr = 
                            \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                            \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str

                let l:key = tolower(l:keyword.word[: s:completion_length-1])
                if !has_key(l:keyword_lists, l:key)
                    let l:keyword_lists[l:key] = []
                endif
                call add(l:keyword_lists[l:key], l:keyword)

                let l:dup_check[l:match_str] = 1
            endif
            
            let l:match_num += len(l:match_str)
            
            let l:match_str = matchstr(l:line, l:keyword_pattern, l:match_num)
        endwhile
    endfor

    " Save syntax cache.
    call neocomplcache#cache#save_cache('syntax_cache', &filetype, neocomplcache#unpack_dictionary(l:keyword_lists))

    return l:keyword_lists
endfunction"}}}

" LengthOrder."{{{
function! s:compare_length(i1, i2)
    return a:i1.word < a:i2.word ? 1 : a:i1.word == a:i2.word ? 0 : -1
endfunction"}}}

function! s:substitute_candidate(candidate)"{{{
    let l:candidate = a:candidate

    " Collection.
    let l:candidate = substitute(l:candidate,
                \'\\\@<!\[[^\]]*\]', ' ', 'g')
    
    " Delete.
    let l:candidate = substitute(l:candidate,
                \'\\\@<!\%(\\[=?+]\|\\%[\|\\s\*\)', '', 'g')
    " Space.
    let l:candidate = substitute(l:candidate,
                \'\\\@<!\%(\\[<>{}]\|[$^]\|\\z\?\a\)', ' ', 'g')

    if l:candidate =~ '\\%\?('
        let l:candidate = join(s:split_pattern(l:candidate))
    endif
    
    " \
    let l:candidate = substitute(l:candidate, '\\\\', '\\', 'g')
    " *
    let l:candidate = substitute(l:candidate, '\\\*', '*', 'g')
    return l:candidate
endfunction"}}}

function! s:split_pattern(keyword_pattern)"{{{
    let l:original_pattern = a:keyword_pattern
    let l:result_patterns = []
    let l:analyzing_patterns = [ '' ]

    let l:i = 0
    let l:max = len(l:original_pattern)
    while l:i < l:max
        if match(l:original_pattern, '^\\%\?(', l:i) >= 0
            " Grouping.
            let l:end = s:match_pair(l:original_pattern, '\\%\?(', '\\)', l:i)
            if l:end < 0
                "call neocomplcache#print_error('Unmatched (.')
                return [ a:keyword_pattern ]
            endif
            
            let l:save_pattern = l:analyzing_patterns
            let l:analyzing_patterns = []
            for l:keyword in split(l:original_pattern[matchend(l:original_pattern, '^\\%\?(', l:i) : l:end], '\\|')
                for l:prefix in l:save_pattern
                    call add(l:analyzing_patterns, l:prefix . l:keyword)
                endfor
            endfor

            let l:i = l:end + 1
        elseif match(l:original_pattern, '^\\|', l:i) >= 0
            " Select.
            let l:result_patterns += l:analyzing_patterns
            let l:analyzing_patterns = [ '' ]
            let l:original_pattern = l:original_pattern[l:i+2 :]
            let l:max = len(l:original_pattern)

            let l:i = 0
        elseif l:original_pattern[l:i] == '\' && l:i+1 < l:max
            let l:save_pattern = l:analyzing_patterns
            let l:analyzing_patterns = []
            for l:prefix in l:save_pattern
                call add(l:analyzing_patterns, l:prefix . l:original_pattern[l:i] . l:original_pattern[l:i+1])
            endfor
            
            " Escape.
            let l:i += 2
        else
            let l:save_pattern = l:analyzing_patterns
            let l:analyzing_patterns = []
            for l:prefix in l:save_pattern
                call add(l:analyzing_patterns, l:prefix . l:original_pattern[l:i])
            endfor
            
            let l:i += 1
        endif
    endwhile

    let l:result_patterns += l:analyzing_patterns
    return l:result_patterns
endfunction"}}}

function! s:match_pair(string, start_pattern, end_pattern, start_cnt)"{{{
    let l:end = -1
    let l:start_pattern = '\%(' . a:start_pattern . '\)'
    let l:end_pattern = '\%(' . a:end_pattern . '\)'

    let l:i = a:start_cnt
    let l:max = len(a:string)
    let l:nest_level = 0
    while l:i < l:max
        let l:start = match(a:string, l:start_pattern, l:i)
        let l:end = match(a:string, l:end_pattern, l:i)

        if l:start >= 0 && (l:end < 0 || l:start < l:end)
            let l:i = matchend(a:string, l:start_pattern, l:i)
            let l:nest_level += 1
        elseif l:end >= 0 && (l:start < 0 || l:end < l:start)
            let l:nest_level -= 1

            if l:nest_level == 0
                return l:end
            endif

            let l:i = matchend(a:string, l:end_pattern, l:i)
        else
            break
        endif
    endwhile

    if l:nest_level != 0
        return -1
    else
        return l:end
    endif
endfunction"}}}

" Global options definition."{{{
if !exists('g:NeoComplCache_MinSyntaxLength')
    let g:NeoComplCache_MinSyntaxLength = 4
endif
"}}}

" vim: foldmethod=marker
