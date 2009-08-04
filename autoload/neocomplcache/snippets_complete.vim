"=============================================================================
" FILE: snippets_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 31 Jul 2009
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
" Version: 1.17, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.17:
"    - Fixed ATOK X3 on when snippets expanded.
"    - Fixed syntax match timing(Thanks thinca!).
"    - Added snippet delete.
"
"   1.16:
"    - Fixed add rank bug.
"    - Loadable snipMate snippets file.
"    - Implemented _ snippets.
"
"   1.15:
"    - Ignore case.
"    - Improved edit snippet.
"
"   1.14:
"    - Fixed for neocomplcache 2.43.
"    - Fixed escape.
"
"   1.13:
"    - Fixed commentout bug.
"    - Improved empty check.
"    - Fixed eval bug.
"    - Fixed include bug.
"
"   1.12:
"    - Fixed syntax highlight.
"    - Overwrite snippet if name is same.
"
"   1.11:
"    - Fixed typo.
"    - Optimized caching.
"    - Fixed syntax highlight bug.
"
"   1.10:
"    - Implemented snipMate like snippet.
"    - Added syntax file.
"    - Detect snippet file.
"    - Fixed default value selection bug.
"
"   1.09:
"    - Added syntax highlight.
"    - Implemented neocomplcache#snippets_complete#expandable().
"    - Change menu when expandable snippet.
"    - Implemented g:NeoComplCache_SnippetsDir.
"
"   1.08:
"    - Fixed place holder's default value bug.
"
"   1.07:
"    - Increment rank when snippet expanded.
"    - Use selection.
"
"   1.06:
"    - Improved place holder's default value behaivior.
"
"   1.05:
"    - Implemented place holder.
"
"   1.04:
"    - Implemented <Plug>(neocomplcache_snippets_expand) keymapping.
"
"   1.03:
"    - Optimized caching.
"
"   1.02:
"    - Caching snippets file.
"
"   1.01:
"    - Refactoring.
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

let s:begin_snippet = 0
let s:end_snippet = 0

function! neocomplcache#snippets_complete#initialize()"{{{
    " Initialize.
    let s:snippets = {}
    let s:begin_snippet = 0
    let s:end_snippet = 0
    let s:snippet_holder_cnt = 1

    " Set snippets dir.
    let s:snippets_dir = split(globpath(&runtimepath, 'autoload/neocomplcache/snippets_complete'), '\n')
    if exists('g:NeoComplCache_SnippetsDir') && isdirectory(g:NeoComplCache_SnippetsDir)
        call add(s:snippets_dir, g:NeoComplCache_SnippetsDir)
    endif

    augroup neocomplcache"{{{
        " Set caching event.
        autocmd CursorHold * call s:caching()
        " Recaching events
        autocmd BufWritePost *.snip,*.snippets call s:caching_snippets(expand('<afile>:t:r')) 
        " Detect syntax file.
        autocmd BufNewFile,BufWinEnter *.snip,*.snippets setfiletype snippet
        autocmd BufNewFile,BufWinEnter * syn match   NeoComplCacheExpandSnippets         '<expand>\|<\\n>\|\${\d\+\%(:\([^}]*\)\)\?}'
    augroup END"}}}

    command! -nargs=? NeoComplCacheEditSnippets call s:edit_snippets(<q-args>)

    hi def link NeoComplCacheExpandSnippets Special

    " Caching _ snippets.
    call s:caching_snippets('_')
endfunction"}}}

function! neocomplcache#snippets_complete#finalize()"{{{
    delcommand NeoComplCacheEditSnippets
    hi clear NeoComplCacheExpandSnippets
endfunction"}}}

function! neocomplcache#snippets_complete#get_keyword_list(cur_keyword_str)"{{{
    if &filetype == '' || !has_key(s:snippets, &filetype)
        return s:keyword_filter(copy(s:snippets['_']), a:cur_keyword_str)
    endif

    return s:keyword_filter(extend(copy(s:snippets['_']), s:snippets[&filetype]), a:cur_keyword_str)
endfunction"}}}

" Dummy function.
function! neocomplcache#snippets_complete#calc_rank(cache_keyword_buffer_list)"{{{
    return
endfunction"}}}

function! neocomplcache#snippets_complete#calc_prev_rank(cache_keyword_buffer_list, prev_word, prepre_word)"{{{
    " Calc previous rank.
    for keyword in a:cache_keyword_buffer_list
        " Set prev rank.
        let keyword.prev_rank = has_key(keyword.prev_word, a:prev_word)? 10+keyword.rank/2 : 0
    endfor
endfunction"}}}

function! neocomplcache#snippets_complete#expandable()"{{{
    return match(getline('.'), '<expand>') >= 0 || search('\${\d\+\%(:\([^}]*\)\)\?}', 'w') > 0
endfunction"}}}

function! s:caching()"{{{
    if &filetype == '' || has_key(s:snippets, &filetype)
        return
    endif

    call s:caching_snippets(&filetype)
endfunction"}}}

function! s:keyword_filter(list, cur_keyword_str)"{{{
    let l:keyword_escape = neocomplcache#keyword_escape(a:cur_keyword_str)

    " Keyword filter."{{{
    let l:cur_len = len(a:cur_keyword_str)
    if g:NeoComplCache_PartialMatch && !neocomplcache#skipped() && len(a:cur_keyword_str) >= g:NeoComplCache_PartialCompletionStartLength
        " Partial match.
        let l:pattern = printf("v:val.name =~ %s", string(l:keyword_escape))
    else
        " Head match.
        let l:pattern = printf("v:val.name =~ %s", string('^' . l:keyword_escape))
    endif"}}}

    let l:list = deepcopy(filter(a:list, l:pattern))
    for keyword in l:list
        while keyword.word =~ '`[^`]*`'
            let keyword.word = substitute(keyword.word, '`[^`]*`', 
                        \eval(matchstr(keyword.word, '`\zs[^`]*\ze`')), '')
        endwhile
    endfor
    return l:list
endfunction"}}}

function! s:set_snippet_pattern(dict)"{{{
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)

    let l:word = a:dict.word
    if match(a:dict.word, '\${\d\+\%(:\(.*\)\)\?}\|<\\n>') >= 0
        let l:word .= '<expand>'
        let l:menu_pattern = '<Snip> %.'.g:NeoComplCache_MaxFilenameWidth.'s'
    else
        let l:menu_pattern = '[Snip] %.'.g:NeoComplCache_MaxFilenameWidth.'s'
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
                \'word' : l:word, 'name' : a:dict.name, 
                \'menu' : printf(l:menu_pattern, a:dict.name), 
                \'prev_word' : l:prev_word, 'icase' : 1,
                \'rank' : l:rank, 'prev_rank' : 0, 'prepre_rank' : 0
                \}
    let l:dict.abbr = 
                \ (len(l:abbr) > g:NeoComplCache_MaxKeywordWidth)? 
                \ printf(l:abbr_pattern, l:abbr, l:abbr[-8:]) : l:abbr
    return l:dict
endfunction"}}}

function! s:edit_snippets(filetype)"{{{
    if a:filetype == ''
        if &filetype == ''
            echo 'Filetype required'
            return
        endif
        
        let l:filetype = &filetype
    else
        let l:filetype = a:filetype
    endif

    if !empty(s:snippets_dir)
        " Edit snippet file.
        edit `=s:snippets_dir[-1].'/'.l:filetype.'.snip'`
    endif
endfunction"}}}

function! s:caching_snippets(filetype)"{{{
    let l:snippet = {}
    let l:snippets_files = split(globpath(join(s:snippets_dir, ','), a:filetype .  '.snip*'), '\n')
    for snippets_file in l:snippets_files
        let l:snippet_dict = s:load_snippets(snippets_file)
        for snip in keys(l:snippet_dict)
            let l:snippet[snip] = l:snippet_dict[snip]
        endfor
    endfor

    let s:snippets[a:filetype] = values(l:snippet)
endfunction"}}}

function! s:load_snippets(snippets_file)"{{{
    let l:snippet = {}
    let l:snippet_pattern = { 'word' : '' }
    for line in readfile(a:snippets_file)
        if line =~ '^include'
            " Include snippets.
            let l:filetype = matchstr(line, '^\s*include\s\+\zs\h\w*')
            let l:snippets_files = split(globpath(join(s:snippets_dir, ','), l:filetype .  '.snip'), '\n')
            for snippets_file in l:snippets_files
                for snip in values(s:load_snippets(snippets_file))
                    let l:snippet[snip.name] = snip
                endfor
            endfor
        elseif line =~ '^snippet\s'
            if has_key(l:snippet_pattern, 'name')
                let l:snippet[l:snippet_pattern.name] = s:set_snippet_pattern(l:snippet_pattern)
                let l:snippet_pattern = { 'word' : '' }
            endif
            let l:snippet_pattern.name = matchstr(line, '^snippet\s\+\zs.*$')
        elseif line =~ '^abbr\s'
            let l:snippet_pattern.abbr = matchstr(line, '^abbr\s\+\zs.*$')
        elseif line =~ '^rank\s'
            let l:snippet_pattern.rank = matchstr(line, '^rank\s\+\zs\d\+\ze\s*$')
        elseif line =~ '^prev_word\s'
            let l:snippet_pattern.prev_word = []
            for word in split(matchstr(line, '^prev_word\s\+\zs.*$'), ',')
                call add(l:snippet_pattern.prev_word, matchstr(word, "'\\zs[^']*\\ze'"))
            endfor
        elseif line =~ '^\s'
            if l:snippet_pattern['word'] == ''
                let l:snippet_pattern.word = matchstr(line, '^\s\+\zs.*$')
            else
                let l:snippet_pattern.word .= '<\n>' . matchstr(line, '^\s\+\zs.*$')
            endif
        elseif line =~ '^delete\s'
            let l:name = matchstr(line, '^delete\s\+\zs.*$')
            if l:name != '' && has_key(l:snippet, l:name)
                call remove(l:snippet, l:name)
            endif
        endif
    endfor

    if has_key(l:snippet_pattern, 'name')
        let l:snippet[l:snippet_pattern.name] = s:set_snippet_pattern(l:snippet_pattern)
    endif

    return l:snippet
endfunction"}}}

function! s:snippets_expand()"{{{
    if match(getline('.'), '<expand>') >= 0
        call s:expand_newline()

        let &l:iminsert = 0
        let &l:imsearch = 0
        return
    endif

    if !s:search_snippet_range(s:begin_snippet, s:end_snippet)
        " Not found.
        let s:begin_snippet = 0
        let s:end_snippet = 0
        let s:snippet_holder_cnt = 1

        call s:search_outof_range()
    endif

    let &iminsert = 0
    let &imsearch = 0
endfunction"}}}
function! s:expand_newline()"{{{
    " Check expand word.
    if &filetype != '' && has_key(s:snippets, &filetype)
        let l:expand = matchstr(getline('.'), '^.*<expand>')
        for keyword in s:snippets[&filetype]
            if l:expand =~ substitute(escape(keyword.word, '~"\.^$*[]'), "'", "''", 'g') . '$'
                let keyword.rank += 1
                break
            endif
        endfor
    endif

    " Substitute expand marker.
    silent! s/<expand>//

    let l:match = match(getline('.'), '<\\n>')
    let s:begin_snippet = line('.')
    let s:end_snippet = line('.')

    let l:formatoptions = &l:formatoptions
    setlocal formatoptions-=r
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
    let &l:formatoptions = l:formatoptions

    let s:snippet_holder_cnt = 1
    call s:search_snippet_range(s:begin_snippet, s:end_snippet)
endfunction"}}}
function! s:search_snippet_range(start, end)"{{{
    let l:line = a:start
    let l:pattern = '\${'.s:snippet_holder_cnt.'\%(:\([^}]*\)\)\?}'
    let l:pattern2 = '\${'.s:snippet_holder_cnt.':\zs[^}]*\ze}'

    while l:line <= a:end
        let l:match = match(getline(l:line), l:pattern)
        if l:match > 0
            let l:match_len2 = len(matchstr(getline(l:line), l:pattern2))

            " Substitute holder.
            silent! execute l:line.'s/'.l:pattern.'/\1/'
            call setpos('.', [0, line('.'), l:match, 0])
            if l:match_len2 > 0
                " Select default value.
                let l:len = l:match_len2-1
                if &l:selection == "exclusive"
                    let l:len += 1
                endif

                if l:len == 0
                    execute "normal! lv\<C-g>"
                else
                    execute "normal! lv".l:len."l\<C-g>"
                endif
            elseif col('.') < col('$')-1
                normal! l
                startinsert
            else
                startinsert!
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
    if search('\${\d\+\%(:\([^}]*\)\)\?}', 'w') > 0
        let l:match = match(getline('.'), '\${\d\+\%(:\([^}]*\)\)\?}')
        let l:match_len2 = len(matchstr(getline('.'), '\${\d\+:\zs[^}]*\ze}'))

        " Substitute holder.
        silent! s/\${\d\+\%(:\(.*\)\)\?}/\1/
        call setpos('.', [0, line('.'), l:match, 0])
        if l:match_len2 > 0
            " Select default value.
            let l:len = l:match_len2-1
            if &l:selection == "exclusive"
                let l:len += 1
            endif

            if l:len == 0
                execute "normal! lv\<C-g>"
            else
                execute "normal! lv".l:len."l\<C-g>"
            endif

            return
        endif
    endif

    if col('.') < col('$')-1
        normal! l
        startinsert
    else
        startinsert!
    endif
endfunction"}}}

" Plugin key-mappings.
inoremap <silent> <Plug>(neocomplcache_snippets_expand)  <ESC>:<C-u>call <SID>snippets_expand()<CR>
snoremap <silent> <Plug>(neocomplcache_snippets_expand)  <C-g>:<C-u>call <SID>snippets_expand()<CR>

" vim: foldmethod=marker
