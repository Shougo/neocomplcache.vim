"=============================================================================
" FILE: include_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 09 Dec 2009
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
" Version: 1.09, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.09:
"    - Improved caching.
"    - Deleted dup.
"    - Use caching helper.
"
"   1.08:
"    - Caching current buffer.
"    - Fixed filetype bug.
"    - Don't cache huge file.
"
"   1.07:
"    - Improved caching speed when FileType.
"    - Deleted caching when BufWritePost.
"    - Fixed set path pattern in Python.
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

let s:include_info = {}
function! neocomplcache#plugin#include_complete#initialize()"{{{
    " Initialize
    let s:include_info = {}
    let s:include_cache = {}
    let s:cached_pattern = {}
    let s:completion_length = neocomplcache#get_completion_length('include_complete')
    
    augroup neocomplcache
        " Caching events
        autocmd FileType * call s:check_buffer_all()
    augroup END
    
    " Initialize include pattern."{{{
    call neocomplcache#set_variable_pattern('g:NeoComplCache_IncludePattern', 'java,haskell', '^import')
    "}}}
    " Initialize expr pattern."{{{
    call neocomplcache#set_variable_pattern('g:NeoComplCache_IncludeExpr', 'haskell',
                \'substitute(v:fname,''\\.'',''/'',''g'')')
    "}}}
    " Initialize path pattern."{{{
    "}}}
    " Initialize suffixes pattern."{{{
    call neocomplcache#set_variable_pattern('g:NeoComplCache_IncludeSuffixes', 'haskell', '.hs')
    "}}}
    
    " Create cache directory.
    if !isdirectory(g:NeoComplCache_TemporaryDir . '/include_cache')
        call mkdir(g:NeoComplCache_TemporaryDir . '/include_cache', 'p')
    endif
    
    " Add command.
    command! -nargs=? -complete=buffer NeoComplCacheCachingInclude call s:check_buffer(<q-args>)
endfunction"}}}

function! neocomplcache#plugin#include_complete#finalize()"{{{
    delcommand NeoComplCacheCachingInclude
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

function! neocomplcache#plugin#include_complete#get_include_files(bufnumber)"{{{
    if has_key(s:include_info, a:bufnumber)
        return s:include_info[a:bufnumber].include_files
    else
        return []
    endif
endfunction"}}}

function! s:check_buffer_all()"{{{
    let l:bufnumber = 1

    " Check buffer.
    while l:bufnumber <= bufnr('$')
        if buflisted(l:bufnumber) && !has_key(s:include_info, l:bufnumber)
            call s:check_buffer(bufname(l:bufnumber))
        endif

        let l:bufnumber += 1
    endwhile
endfunction"}}}
function! s:check_buffer(bufname)"{{{
    let l:bufname = fnamemodify((a:bufname == '')? a:bufname : bufname('%'), ':p')
    let l:bufnumber = bufnr(l:bufname)
    let s:include_info[l:bufnumber] = {}
    if (g:NeoComplCache_CachingDisablePattern == '' || l:bufname !~ g:NeoComplCache_CachingDisablePattern)
                \&& getbufvar(l:bufnumber, '&readonly') == 0
        let l:filetype = getbufvar(l:bufnumber, '&filetype')
        if l:filetype == ''
            let l:filetype = 'nothing'
        endif
        
        " Check include.
        let l:include_files = s:get_include_files(l:bufnumber)
        if filereadable(l:bufname)
            let s:include_cache[l:bufname] = s:load_from_tags(l:bufname, l:filetype, 0)
        endif

        for l:filename in l:include_files
            if !has_key(s:include_cache, l:filename)
                " Caching.
                let s:include_cache[l:filename] = s:load_from_tags(l:filename, l:filetype, 1)
            endif
        endfor
        
        let s:include_info[l:bufnumber].include_files = l:include_files
    else
        let s:include_info[l:bufnumber].include_files = []
    endif
endfunction"}}}
function! s:get_include_files(bufnumber)"{{{
    let l:filetype = getbufvar(a:bufnumber, '&filetype')
    if l:filetype == ''
        return []
    endif
    
    if l:filetype == 'python'
                \&& !has_key(g:NeoComplCache_IncludePath, 'python')
                \&& executable('python')
        " Initialize python path pattern.
        call neocomplcache#set_variable_pattern('g:NeoComplCache_IncludePath', 'python',
                    \system('python -', 'import sys;sys.stdout.write(",".join(sys.path))'))
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
            if filereadable(l:filename) && getfsize(l:filename) < g:NeoComplCache_CachingLimitFileSize
                call add(l:include_files, l:filename)
            endif
        endif
    endfor"}}}
    
    " Restore option.
    if has_key(g:NeoComplCache_IncludeSuffixes, l:filetype)
        let &l:suffixesadd = l:suffixes
    endif
    
    return l:include_files
endfunction"}}}

function! s:load_from_tags(filename, filetype, is_force)"{{{
    " Initialize include list from tags.

    let l:keyword_lists = s:load_from_cache(a:filename)
    if !empty(l:keyword_lists)
        return l:keyword_lists
    endif

    if !executable('ctags') && a:is_force
        return s:load_from_file(a:filename, a:filetype)
    endif
    
    let l:args = has_key(g:NeoComplCache_CtagsArgumentsList, a:filetype) ? 
                \g:NeoComplCache_CtagsArgumentsList[a:filetype] : g:NeoComplCache_CtagsArgumentsList['default']
    let l:lines = split(system(printf('ctags -f - %s %s', l:args, fnamemodify(a:filename, ':p:.'))), '\n')
    
    " Save ctags file.
    call neocomplcache#cache#writefile('include_tags', a:filename, l:lines)

    let l:keyword_lists = {}
    
    for l:keyword in neocomplcache#cache#load_from_tags('include_cache', a:filename, l:lines, 'I')
        let l:key = tolower(l:keyword.word[: s:completion_length-1])
        if !has_key(l:keyword_lists, l:key)
            let l:keyword_lists[l:key] = []
        endif
        
        call add(l:keyword_lists[l:key], l:keyword)
    endfor 
    
    if empty(l:keyword_lists) && a:is_force
        return s:load_from_file(a:filename, a:filetype)
    endif
    
    if !empty(l:keyword_lists)
        call neocomplcache#cache#save_cache('include_cache', a:filename, neocomplcache#unpack_list(values(l:keyword_lists)))
    endif
    
    return l:keyword_lists
endfunction"}}}
function! s:load_from_file(filename, filetype)"{{{
    " Initialize include list from file.

    let l:keyword_lists = {}
    let l:loaded_list = neocomplcache#cache#load_from_file(a:filename, neocomplcache#get_keyword_pattern(), 'I', 1, '$')
    if len(l:loaded_list) > 300
        call neocomplcache#cache#save_cache('include_cache', a:filename, l:loaded_list)
    endif

    for l:keyword in l:loaded_list
        let l:key = tolower(l:keyword.word[: s:completion_length-1])
        if !has_key(l:keyword_lists, l:key)
            let l:keyword_lists[l:key] = []
        endif
        call add(l:keyword_lists[l:key], l:keyword)
    endfor"}}}

    return l:keyword_lists
endfunction"}}}
function! s:load_from_cache(filename)"{{{
    let l:keyword_lists = {}
    
    for l:keyword in neocomplcache#cache#load_from_cache('buffer_cache', a:filename)
        let l:key = tolower(l:keyword.word[: s:completion_length-1])
        if !has_key(l:keyword_lists, l:key)
            let l:keyword_lists[l:key] = []
        endif
        call add(l:keyword_lists[l:key], l:keyword)

        let l:keyword_lists[l:keyword.word] = 1
    endfor 
    
    return l:keyword_lists
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
