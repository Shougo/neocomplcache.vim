"=============================================================================
" FILE: include_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 27 Dec 2009
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
" Version: 1.11, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.11:
"    - Use neocomplcache#system().
"    - Skip listed files.
"
"   1.10:
"    - Use g:NeoComplCache_TagsFilterPatterns.
"    - Supported nested include file in C/C++ filetype.
"
"   1.09:
"    - Improved caching.
"    - Deleted dup.
"    - Use caching helper.
"    - Use /dev/stdout in Linux and Mac.
"    - Deleted caching current buffer.
"    - Fixed error when load file.
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
    
    if has_key(g:NeoComplCache_MemberPrefixPatterns, l:ft) 
                \&& a:cur_keyword_str =~ g:NeoComplCache_MemberPrefixPatterns[l:ft]
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
    if len(l:cur_keyword_str) < s:completion_length ||
                \neocomplcache#check_match_filter(l:cur_keyword_str, s:completion_length)
        for l:include in s:include_info[bufnr('%')].include_files
            if !buflisted(l:include)
                let l:keyword_list += neocomplcache#unpack_dictionary(s:include_cache[l:include])
            endif
        endfor
        
        let l:keyword_list = neocomplcache#member_filter(l:keyword_list, a:cur_keyword_str)
    else
        let l:key = tolower(l:cur_keyword_str[: s:completion_length-1])
        for l:include in s:include_info[bufnr('%')].include_files
            if !buflisted(l:include) && has_key(s:include_cache[l:include], l:key)
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
        let l:include_files = s:get_buffer_include_files(l:bufnumber)
        for l:filename in l:include_files
            if !has_key(s:include_cache, l:filename)
                " Caching.
                let s:include_cache[l:filename] = s:load_from_tags(l:filename, l:filetype)
            endif
        endfor
        
        let s:include_info[l:bufnumber].include_files = l:include_files
    else
        let s:include_info[l:bufnumber].include_files = []
    endif
endfunction"}}}
function! s:get_buffer_include_files(bufnumber)"{{{
    let l:filetype = getbufvar(a:bufnumber, '&filetype')
    if l:filetype == ''
        return []
    endif
    
    if l:filetype == 'python'
                \&& !has_key(g:NeoComplCache_IncludePath, 'python')
                \&& executable('python')
        " Initialize python path pattern.
        call neocomplcache#set_variable_pattern('g:NeoComplCache_IncludePath', 'python',
                    \neocomplcache#system('python -', 'import sys;sys.stdout.write(",".join(sys.path))'))
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

    let l:include_files = s:get_include_files(0, getbufline(a:bufnumber, 1, 100), l:filetype, l:pattern, l:path, l:expr)
    
    " Restore option.
    if has_key(g:NeoComplCache_IncludeSuffixes, l:filetype)
        let &l:suffixesadd = l:suffixes
    endif
    
    return l:include_files
endfunction"}}}
function! s:get_include_files(nestlevel, lines, filetype, pattern, path, expr)"{{{
    let l:include_files = []
    for l:line in a:lines"{{{
        if l:line =~ a:pattern
            let l:match_end = matchend(l:line, a:pattern)
            if a:expr != ''
                let l:eval = substitute(a:expr, 'v:fname', string(matchstr(l:line[l:match_end :], '\f\+')), 'g')
                let l:filename = fnamemodify(findfile(eval(l:eval), a:path), ':p')
            else
                let l:filename = fnamemodify(findfile(matchstr(l:line[l:match_end :], '\f\+'), a:path), ':p')
            endif
            if filereadable(l:filename) && getfsize(l:filename) < g:NeoComplCache_CachingLimitFileSize
                call add(l:include_files, l:filename)
                
                if (a:filetype == 'c' || a:filetype == 'cpp') && a:nestlevel < 1
                    let l:include_files += s:get_include_files(a:nestlevel + 1, readfile(l:filename)[:100],
                                \a:filetype, a:pattern, a:path, a:expr)
                endif
            endif
        endif
    endfor"}}}
    
    return l:include_files
endfunction"}}}

function! s:load_from_tags(filename, filetype)"{{{
    " Initialize include list from tags.

    let l:keyword_lists = s:load_from_cache(a:filename)
    if !empty(l:keyword_lists) || getfsize(neocomplcache#cache#encode_name('include_cache', a:filename)) == 0
        return l:keyword_lists
    endif

    if !executable(g:NeoComplCache_CtagsProgram)
        return s:load_from_file(a:filename, a:filetype)
    endif
    
    let l:args = has_key(g:NeoComplCache_CtagsArgumentsList, a:filetype) ? 
                \g:NeoComplCache_CtagsArgumentsList[a:filetype] : g:NeoComplCache_CtagsArgumentsList['default']
    let l:command = has('win32') || has('win64') ? 
                \printf('%s -f - %s %s', g:NeoComplCache_CtagsProgram, l:args, fnamemodify(a:filename, ':p:.')) : 
                \printf('%s -f /dev/stdout 2>/dev/null %s %s', g:NeoComplCache_CtagsProgram, l:args, fnamemodify(a:filename, ':p:.'))
    let l:lines = split(neocomplcache#system(l:command), '\n')
    
    if !empty(l:lines)
        " Save ctags file.
        call neocomplcache#cache#writefile('include_tags', a:filename, l:lines)
    endif

    let l:keyword_lists = {}
    
    for l:keyword in neocomplcache#cache#load_from_tags('include_cache', a:filename, l:lines, 'I', a:filetype)
        let l:key = tolower(l:keyword.word[: s:completion_length-1])
        if !has_key(l:keyword_lists, l:key)
            let l:keyword_lists[l:key] = []
        endif
        
        call add(l:keyword_lists[l:key], l:keyword)
    endfor 
    
    call neocomplcache#cache#save_cache('include_cache', a:filename, neocomplcache#unpack_dictionary(l:keyword_lists))
    
    if empty(l:keyword_lists)
        return s:load_from_file(a:filename, a:filetype)
    endif
    
    return l:keyword_lists
endfunction"}}}
function! s:load_from_file(filename, filetype)"{{{
    " Initialize include list from file.

    let l:keyword_lists = {}
    let l:loaded_list = neocomplcache#cache#load_from_file(a:filename, neocomplcache#get_keyword_pattern(), 'I')
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
    
    for l:keyword in neocomplcache#cache#load_from_cache('include_cache', a:filename)
        let l:key = tolower(l:keyword.word[: s:completion_length-1])
        if !has_key(l:keyword_lists, l:key)
            let l:keyword_lists[l:key] = []
        endif
        call add(l:keyword_lists[l:key], l:keyword)
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
