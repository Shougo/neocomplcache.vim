"=============================================================================
" FILE: tags_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 14 May 2009
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
" Version: 1.08, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.08:
"    - Improved popup menu.
"    - Ignore case.
"   1.07:
"    - Fixed for neocomplcache 2.43.
"   1.06:
"    - Improved abbr.
"    - Refactoring.
"   1.05:
"    - Improved filtering.
"   1.04:
"    - Don't return static member.
"   1.03:
"    - Optimized memory.
"   1.02:
"    - Escape input keyword.
"    - Supported camel case completion.
"    - Fixed echo.
"   1.01:
"    - Not caching.
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

function! neocomplcache#tags_complete#initialize()"{{{
    " Initialize
endfunction"}}}

function! neocomplcache#tags_complete#finalize()"{{{
endfunction"}}}

function! neocomplcache#tags_complete#get_keyword_list(cur_keyword_str)"{{{
    if &l:completefunc == 'neocomplcache#auto_complete' ||
                \len(a:cur_keyword_str) < g:NeoComplCache_TagsCompletionStartLength
        return []
    endif

    let l:keyword_escape = neocomplcache#keyword_escape(a:cur_keyword_str)

    if !g:NeoComplCache_PartialMatch || neocomplcache#skipped() || len(a:cur_keyword_str) < g:NeoComplCache_PartialCompletionStartLength
        " Head match.
        let l:keyword_escape = '^'.l:keyword_escape
    endif
    return neocomplcache#keyword_filter(s:initialize_tags(l:keyword_escape), a:cur_keyword_str)
endfunction"}}}

" Dummy function.
function! neocomplcache#tags_complete#calc_rank(cache_keyword_buffer_list)"{{{
endfunction"}}}

" Dummy function.
function! neocomplcache#tags_complete#calc_prev_rank(cache_keyword_buffer_list, prev_word, prepre_word)"{{{
endfunction"}}}

function! s:initialize_tags(cur_keyword_str)"{{{
    " Get current tags list.

    let l:keyword_list = []
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:menu_pattern = '[T] %s %.'. g:NeoComplCache_MaxFilenameWidth . 's'
    let l:dup_check = {}
    for l:tag in taglist(a:cur_keyword_str)
        " Add keywords.
        if len(l:tag.name) >= g:NeoComplCache_MinKeywordLength
                    \&& !has_key(l:dup_check, l:tag.cmd) && !l:tag.static
                    \&& (!has_key(l:tag, 'access') || l:tag.access == 'public')
            let l:dup_check[l:tag.cmd] = 1
            let l:name = substitute(l:tag.name, '\h\w*::', '', 'g')
            let l:abbr = (l:tag.kind == 'd')? l:name :
                        \ substitute(substitute(substitute(l:tag.cmd, '^/\^\=\s*\|\s*\$\=/$', '', 'g'),
                        \           '\s\+', ' ', 'g'), '\\/', '/', 'g')
            let l:keyword = {
                        \ 'word' : l:name, 'rank' : 1, 'prev_rank' : 0, 'prepre_rank' : 0, 'icase' : 1,
                        \ 'abbr' : (len(l:abbr) > g:NeoComplCache_MaxKeywordWidth)? 
                        \   printf(l:abbr_pattern, l:abbr, l:abbr[-8:]) : l:abbr
                        \}
            if has_key(l:tag, 'struct')
                let keyword.menu = printf(l:menu_pattern, l:tag.kind, l:tag.struct)
            elseif has_key(l:tag, 'class')
                let keyword.menu = printf(l:menu_pattern, l:tag.kind, l:tag.class)
            elseif has_key(l:tag, 'enum')
                let keyword.menu = printf(l:menu_pattern, l:tag.kind, l:tag.enum)
            else
                let keyword.menu = '[T] '. l:tag.kind
            endif

            if g:NeoComplCache_EnableInfo
                " Create info.
                let keyword.info = l:abbr
                if has_key(l:tag, 'struct')
                    let keyword.info .= "\nstruct: " . l:tag.struct 
                elseif has_key(l:tag, 'class')
                    let keyword.info .= "\nclass: " . l:tag.class 
                elseif has_key(l:tag, 'enum')
                    let keyword.info .= "\nenum: " . l:tag.enum
                endif
                if has_key(l:tag, 'namespace')
                    let keyword.info .= "\nnamespace: " . l:tag.namespace
                endif
                if has_key(l:tag, 'access')
                    let keyword.info .= "\naccess: " . l:tag.access
                endif
                if has_key(l:tag, 'inherits')
                    let keyword.info .= "\ninherits: " . l:tag.inherits
                endif
            endif

            call add(l:keyword_list, l:keyword)
        endif
    endfor

    return sort(l:keyword_list, 'neocomplcache#compare_words')
endfunction"}}}

" Global options definition."{{{
if !exists('g:NeoComplCache_TagsCompletionStartLength')
    let g:NeoComplCache_TagsCompletionStartLength = 2
endif
"}}}

" vim: foldmethod=marker
