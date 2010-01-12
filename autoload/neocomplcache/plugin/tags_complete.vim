"=============================================================================
" FILE: tags_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 03 Jun 2010
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
" Version: 1.15, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.15:
"    - Use g:NeoComplCache_TagsFilterPatterns.
"    - Fixed unpack dictionary bug.
"
"   1.14:
"    - Use cache helper.
"    - Supported neocomplcache ver.4.00.
"    - Fixed tags_complete caching error.
"
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
    
    command! -nargs=? -complete=buffer NeoComplCacheCachingTags call s:caching_tags(<q-args>, 1)
endfunction"}}}

function! neocomplcache#plugin#tags_complete#finalize()"{{{
    delcommand NeoComplCacheCachingTags
endfunction"}}}

function! neocomplcache#plugin#tags_complete#get_keyword_list(cur_keyword_str)"{{{
    if !has_key(s:tags_list, bufnr('%'))
        call s:caching_tags(bufnr('%'), 0)
    endif

    if empty(s:tags_list[bufnr('%')])
        return []
    endif
    let l:tags_list = s:tags_list[bufnr('%')]
    
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
        for tags in values(l:tags_list)
            let l:keyword_list += neocomplcache#unpack_dictionary(tags)
        endfor
    else
        for tags in values(l:tags_list)
            if has_key(tags, l:key)
                let l:keyword_list += tags[l:key]
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

function! s:caching_tags(bufname, force)"{{{
    let l:bufnumber = (a:bufname == '') ? bufnr('%') : bufnr(a:bufname)
    let s:tags_list[l:bufnumber] = {}
    for tags in split(getbufvar(l:bufnumber, '&tags'), ',')
        let l:filename = fnamemodify(tags, ':p')
        if filereadable(l:filename)
                            \&& (a:force || getfsize(l:filename) < g:NeoComplCache_CachingLimitFileSize)
            let s:tags_list[l:bufnumber][l:filename] = s:initialize_tags(l:filename)
        endif
    endfor
endfunction"}}}
function! s:initialize_tags(filename)"{{{
    " Initialize tags list.

    let l:keyword_lists = neocomplcache#cache#index_load_from_cache('tags_cache', a:filename, s:completion_length)
    if !empty(l:keyword_lists)
        return l:keyword_lists
    endif
    
    let l:ft = &filetype
    if l:ft == ''
        let l:ft = 'nothing'
    endif

    let l:keyword_lists = {}
    let l:loaded_list = neocomplcache#cache#load_from_tags('tags_cache', a:filename, readfile(a:filename), 'T', l:ft)
    if len(l:loaded_list) > 300
        call neocomplcache#cache#save_cache('tags_cache', a:filename, l:loaded_list)
    endif
    
    for l:keyword in l:loaded_list
        let l:key = tolower(l:keyword.word[: s:completion_length-1])
        if !has_key(l:keyword_lists, l:key)
            let l:keyword_lists[l:key] = []
        endif
        
        call add(l:keyword_lists[l:key], l:keyword)
    endfor 
    
    return l:keyword_lists
endfunction"}}}

" vim: foldmethod=marker
