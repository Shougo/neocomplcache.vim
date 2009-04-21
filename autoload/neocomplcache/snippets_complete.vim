"=============================================================================
" FILE: syntax_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 21 Apr 2009
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
" Version: 1.06, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.06:
"    - Improved place holder's default value behaivior.
"   1.05:
"    - Implemented place holder.
"   1.04:
"    - Implemented <Plug>(neocomplcache_snippets_expand) keymapping.
"   1.03:
"    - Optimized caching.
"   1.02:
"    - Caching snippets file.
"   1.01:
"    - Refactoring.
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

let s:begin_snippet = 0
let s:end_snippet = 0

function! neocomplcache#snippets_complete#initialize()"{{{
    " Initialize.
    let s:snippets = {}
    let s:begin_snippet = 0
    let s:end_snippet = 0
    let s:snippet_holder_cnt = 1

    augroup neocomplecache"{{{
        " Caching events
        autocmd CursorHold * call s:caching_event() 
        " Recaching events
        autocmd BufWritePost *.snip call s:caching_snippets(expand('<afile>:t:r')) 
    augroup END"}}}

    command! -nargs=? NeoCompleCacheEditSnippets call s:edit_snippets(<q-args>)
endfunction"}}}

function! neocomplcache#snippets_complete#finalize()"{{{
    delcommand NeoCompleCacheEditSnippets
endfunction"}}}

function! neocomplcache#snippets_complete#get_keyword_list(cur_keyword_str)"{{{
    if empty(&filetype) || !has_key(s:snippets, &filetype)
        return []
    endif

    return s:keyword_filter(copy(s:snippets[&filetype]), a:cur_keyword_str)
endfunction"}}}

" Dummy function.
function! neocomplcache#snippets_complete#calc_rank(cache_keyword_buffer_list)"{{{
    return
endfunction"}}}

function! neocomplcache#snippets_complete#calc_prev_rank(cache_keyword_buffer_list, prev_word, prepre_word)"{{{
    " Calc previous rank.
    for keyword in a:cache_keyword_buffer_list
        " Set prev rank.
        let keyword.prev_rank = has_key(keyword.prev_word, a:prev_word)? 10 : 0
    endfor
endfunction"}}}

function! s:keyword_filter(list, cur_keyword_str)"{{{
    let l:keyword_escape = neocomplcache#keyword_escape(a:cur_keyword_str)

    " Keyword filter."{{{
    let l:cur_len = len(a:cur_keyword_str)
    if g:NeoComplCache_PartialMatch && !neocomplcache#skipped() && len(a:cur_keyword_str) >= g:NeoComplCache_PartialCompletionStartLength
        " Partial match.
        let l:pattern = printf("v:val.name =~ '%s'", l:keyword_escape)
    else
        " Head match.
        let l:pattern = printf("v:val.name =~ '^%s'", l:keyword_escape)
    endif"}}}

    let l:list = filter(a:list, l:pattern)
    for keyword in l:list
        let keyword.word = keyword.word_save
        while keyword.word =~ '`.*`'
            let keyword.word = substitute(keyword.word, '`.*`', 
                        \eval(matchstr(keyword.word_save, '`\zs.*\ze`')), '')
        endwhile
    endfor
    return l:list
endfunction"}}}

function! s:set_snippet_pattern(dict)"{{{
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:menu_pattern = '[Snip] %.'.g:NeoComplCache_MaxFilenameWidth.'s'

    let l:word = a:dict.word
    if match(a:dict.word, '\${\d\+\%(:\(.*\)\)\?}\|<\\n>') >= 0
        let l:word .= '<expand>'
    endif
    let l:abbr = has_key(a:dict, 'abbr')? a:dict.abbr : a:dict.word
    let l:rank = has_key(a:dict, 'rank')? a:dict.rank : 5
    let l:prev_word = {}
    if has_key(a:dict, 'prev_word')
        for l:prev in a:dict.prev_word
            let l:prev_word[l:prev] = 1
        endfor
    endif

    let l:dict = {
                \'word_save' : l:word, 'name' : a:dict.name, 
                \'menu' : printf(l:menu_pattern, a:dict.name), 
                \'prev_word' : l:prev_word, 
                \'rank' : l:rank, 'prev_rank' : 0, 'prepre_rank' : 0
                \}
    let l:dict.abbr_save = 
                \ (len(l:abbr) > g:NeoComplCache_MaxKeywordWidth)? 
                \ printf(l:abbr_pattern, l:abbr, l:abbr[-8:]) : l:abbr
    return l:dict
endfunction"}}}

function! s:caching_event()"{{{
    if empty(&filetype) || has_key(s:snippets, &filetype)
        return
    endif

    call s:caching_snippets(&filetype)
endfunction"}}}
function! s:edit_snippets(filetype)"{{{
    if empty(a:filetype)
        if empty(&filetype)
            echo 'Filetype required'
            return
        endif
        
        let l:filetype = &filetype
    else
        let l:filetype = a:filetype
    endif

    let l:snippets_files = split(globpath(&runtimepath, 'autoload/neocomplcache/snippets_complete/' . l:filetype .  '.snip'), '\n')
    if empty(l:snippets_files)
        " Set snippets dir.
        let l:snippets_dir = split(globpath(&runtimepath, 'autoload/neocomplcache/snippets_complete'), '\n')

        if !empty(l:snippets_dir)
            " Edit new snippet file.
            edit `=l:snippets_dir[0].'/'.l:filetype.'.snip'`
        endif

        return
    endif

    for snippets_file in l:snippets_files
        edit `=snippets_file`
    endfor
endfunction"}}}

function! s:caching_snippets(filetype)"{{{
    let s:snippets[a:filetype] = []
    let l:snippets_files = split(globpath(&runtimepath, 'autoload/neocomplcache/snippets_complete/' . a:filetype .  '.snip'), '\n')
    for snippets_file in l:snippets_files
        call extend(s:snippets[a:filetype], s:load_snippets(snippets_file))
    endfor
endfunction"}}}

function! s:load_snippets(snippets_file)"{{{
    let l:snippet = []
    for line in readfile(a:snippets_file)
        if line =~ '^\s*include'
            " Include snippets.
            let l:filetype = matchstr(l:line, '^\s*include\s\+\zs\h\w*')
            let l:snippets_files = split(globpath(&runtimepath, 'autoload/neocomplcache/snippets_complete/' . l:filetype .  '.snip'), '\n')
            for snippets_file in l:snippets_files
                call extend(l:snippet, s:load_snippets(snippets_file))
            endfor
        elseif line !~ '^\s*$\|^\s*#'
            call add(l:snippet, s:set_snippet_pattern(eval('{' . line . '}')))
        endif
    endfor
    return l:snippet
endfunction"}}}

function! s:snippets_expand()"{{{
    if match(getline('.'), '<expand>') >= 0
        call s:expand_newline()
        return
    endif

    if !s:search_snippet_range(s:begin_snippet, s:end_snippet)
        " Not found.
        let s:begin_snippet = 0
        let s:end_snippet = 0
        let s:snippet_holder_cnt = 1

        call s:search_outof_range()
    endif
endfunction"}}}
function! s:expand_newline()"{{{
    " Substitute expand marker.
    silent! s/<expand>//

    let l:match = match(getline('.'), '<\\n>')
    let s:begin_snippet = line('.')
    let s:end_snippet = line('.')

    while l:match >= 0
        " Substitute CR.
        silent! s/<\\n>//

        " Return.
        call setpos('.', [0, line('.'), l:match, 0])
        silent execute "normal! a\<CR>"

        " Next match.
        let l:match = match(getline('.'), '<\\n>')
        let s:end_snippet += 1
    endwhile

    let s:snippet_holder_cnt = 1
    call s:search_snippet_range(s:begin_snippet, s:end_snippet)
endfunction"}}}
function! s:search_snippet_range(start, end)"{{{
    let l:line = a:start
    let l:pattern = '\${'.s:snippet_holder_cnt.'\%(:\(.*\)\)\?}'
    let l:pattern2 = '\${'.s:snippet_holder_cnt.':\zs.*\ze}'

    while l:line <= a:end
        let l:match = match(getline(l:line), l:pattern) + 1
        if l:match > 0
            let l:match_len2 = len(matchstr(getline(l:line), l:pattern2))

            " Substitute holder.
            silent! execute l:line.'s/'.l:pattern.'/\1/'
            if l:match_len2 > 0
                call setpos('.', [0, line('.'), l:match, 0])
                normal! v
                call setpos('.', [0, line('.'), l:match+l:match_len2-1, 0])
                if &l:selection == "exclusive"
                    exec "normal! l"
                endif
            else
                call setpos('.', [0, line('.'), l:match, 0])
            endif

            " Next count.
            let s:snippet_holder_cnt += 1
            return 1
        endif

        " Next line.
        let l:line += 1
    endwhile

    return 0
endfunction"}}}
function! s:search_outof_range()"{{{
    if search('\${\d\+\%(:\(.*\)\)\?}', 'w') > 0
        let l:match = match(getline('.'), '\${\d\+\%(:\(.*\)\)\?}') + 1
        let l:match_len2 = len(matchstr(getline('.'), '\${\d\+:\zs.*\ze}'))

        " Substitute holder.
        silent! s/\${\d\+\%(:\(.*\)\)\?}/\1/
        if l:match_len2 > 0
            call setpos('.', [0, line('.'), l:match, 0])
            normal! v
            call setpos('.', [0, line('.'), l:match+l:match_len2-1, 0])
            if &l:selection == "exclusive"
                exec "normal! l"
            endif
        else
            call setpos('.', [0, line('.'), l:match, 0])
        endif
    endif
endfunction"}}}

inoremap <silent> <Plug>(neocomplcache_snippets_expand)  <C-o>:<C-u>call <SID>snippets_expand()<CR>
vnoremap <silent> <Plug>(neocomplcache_snippets_expand)  :<C-u>call <SID>snippets_expand()<CR>

" vim: foldmethod=marker
