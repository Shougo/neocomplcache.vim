"=============================================================================
" FILE: snippets_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 26 Nov 2009
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
" Version: 1.31, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.31:
"    - Fixed disable expand when buftype is 'nofile' bug.
"    - Implemented <Plug>(neocomplcache_snippets_jump).
"    - Implemented hard tab expand.
"
"   1.30:
"    - Fixed snippet merge bug.
"    - Allow keyword trigger.
"    - Fixed NeoComplCacheEditRuntimeSnippets bug.
"
"   1.29:
"    - Recognized snippets directory of snipMate automatically.
"    - Fixed eval snippet bug.
"
"   1.28:
"    - Split nicely when edit snippets_file.
"    - Fixed snippets escape bug.
"
"   1.27:
"    - Fixed empty snippet edit error.
"    - Improved snippet alias syntax.
"
"   1.26:
"    - Fixed regex escape bug.
"    - Fixed import error bug.
"
"   1.25:
"    - Substitute tilde.
"    - Fixed neocomplcache#plugin#snippets_complete#expandable()'s error.
"    - Improved snippet menu.
"    - Improved keymapping.
"
"   1.24:
"    - Fixed fatal bug when snippet expand.
"    - Fixed marker substitute bug.
"    - Added NeoComplCacheEditRuntimeSnippets command.
"    - Implemented filetype completion.
"
"   1.23:
"    - Added select mode mappings.
"    - Supported same filetype lists.
"    - Expandable a snippet including sign.
"    - Added registers snippet.
"    - Sort alphabetical order.
"    - Improved get cur_text.
"    - Implemented condition.
"    - Implemented optional placeholder.
"
"   1.22:
"    - Fixed non-initialize error.
"    - Fixed error.
"    - Fixed expand cursor bug.
"    - Supported neocomplcache 3.0.
"
"   1.21:
"    - Added NeoComplCachePrintSnippets command.
"    - Supported placeholder 0.
"    - Implemented sync placeholder.
"    - Supported snipMate's multi snippet.
"    - Improved no new line snippet expand.
"
"   1.20:
"    - Fixed dup bug.
"    - Fixed no new line snippet expand bug.
"
"   1.19:
"    - Create g:NeoComplCache_SnippetsDir directory if not exists.
"    - Implemented direct expantion.
"    - Implemented snippet alias.
"    - Fixed expand jump bug.
"    - Fixed expand() bug.
"
"   1.18:
"    - Fixed snippet expand bugs.
"    - Caching snippets when file open.
"    - g:NeoComplCache_SnippetsDir is comma-separated list.
"    - Fixed snippet without default value expand bug.
"
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
"    - Implemented neocomplcache#plugin#snippets_complete#expandable().
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

if !exists('s:snippets')
    let s:snippets = {}
endif

function! neocomplcache#plugin#snippets_complete#initialize()"{{{
    " Initialize.
    let s:snippets = {}
    let s:begin_snippet = 0
    let s:end_snippet = 0
    let s:snippet_holder_cnt = 1

    " Set snippets dir.
    let s:runtime_dir = split(globpath(&runtimepath, 'autoload/neocomplcache/plugin/snippets_complete'), '\n')
    let s:snippets_dir = split(globpath(&runtimepath, 'snippets'), '\n') + s:runtime_dir
    if exists('g:NeoComplCache_SnippetsDir')
        for l:dir in split(g:NeoComplCache_SnippetsDir, ',')
            let l:dir = expand(l:dir)
            if !isdirectory(l:dir)
                call mkdir(l:dir, 'p')
            endif
            call add(s:snippets_dir, l:dir)
        endfor
    endif

    augroup neocomplcache"{{{
        " Set caching event.
        autocmd FileType * call s:caching()
        " Recaching events
        autocmd BufWritePost *.snip,*.snippets call s:caching_snippets(expand('<afile>:t:r')) 
        " Detect syntax file.
        autocmd BufNewFile,BufWinEnter *.snip,*.snippets setfiletype snippet
        autocmd BufNewFile,BufWinEnter * syn match   NeoComplCacheExpandSnippets         
                    \'\${\d\+\%(:.\{-}\)\?\\\@<!}\|\$<\d\+\%(:.\{-}\)\?\\\@<!>\|\$\d\+'
    augroup END"}}}

    command! -nargs=? -complete=customlist,s:filetype_complete NeoComplCacheEditSnippets call s:edit_snippets(<q-args>, 0)
    command! -nargs=? -complete=customlist,s:filetype_complete NeoComplCacheEditRuntimeSnippets call s:edit_snippets(<q-args>, 1)
    command! -nargs=? -complete=customlist,s:filetype_complete NeoComplCachePrintSnippets call s:print_snippets(<q-args>)

    hi def link NeoComplCacheExpandSnippets Special

    " Select mode mappings.
    if !exists('g:NeoComplCache_DisableSelectModeMappings')
        snoremap <CR>     a<BS>
        snoremap <BS> a<BS>
        snoremap <right> <ESC>a
        snoremap <left> <ESC>bi
        snoremap ' a<BS>'
        snoremap ` a<BS>`
        snoremap % a<BS>%
        snoremap U a<BS>U
        snoremap ^ a<BS>^
        snoremap \ a<BS>\
        snoremap <C-x> a<BS><c-x>
    endif

    " Caching _ snippets.
    call s:caching_snippets('_')
endfunction"}}}

function! neocomplcache#plugin#snippets_complete#finalize()"{{{
    delcommand NeoComplCacheEditSnippets
    hi clear NeoComplCacheExpandSnippets
endfunction"}}}

function! neocomplcache#plugin#snippets_complete#get_keyword_list(cur_keyword_str)"{{{
    " Set buffer filetype.
    if &filetype == ''
        let l:ft = 'nothing'
    else
        let l:ft = &filetype
    endif

    let l:snippets = values(s:snippets['_'])
    for l:t in split(l:ft, '\.')
        if has_key(s:snippets, l:t)
            let l:snippets += values(s:snippets[l:t])
        endif
    endfor

    " Set same filetype.
    if has_key(g:NeoComplCache_SameFileTypeLists, l:ft)
        for l:same_ft in split(g:NeoComplCache_SameFileTypeLists[l:ft], ',')
            if has_key(s:snippets, l:same_ft)
                let l:snippets += values(s:snippets[l:same_ft])
            endif
        endfor
    endif

    return sort(s:keyword_filter(l:snippets, a:cur_keyword_str), 's:compare_words')
endfunction"}}}

function! s:compare_words(i1, i2)
    return a:i1.menu > a:i2.menu ? 1 : a:i1.menu == a:i2.menu ? 0 : -1
endfunction

function! s:keyword_filter(list, cur_keyword_str)"{{{
    let l:keyword_escape = neocomplcache#keyword_escape(a:cur_keyword_str)

    " Keyword filter.
    " Head match.
    let l:pattern = printf("v:val.word =~ %s && (v:val.condition == 1 || eval(v:val.condition))", string('^' . l:keyword_escape))

    let l:list = filter(a:list, l:pattern)

    " Substitute abbr.
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    for snippet in l:list
        let snippet.abbr = (snippet.snip =~ '`[^`]*`')? 
                    \s:eval_snippet(snippet.snip) : snippet.snip
        
        if len(snippet.abbr) > g:NeoComplCache_MaxKeywordWidth 
            let snippet.abbr = printf(l:abbr_pattern, snippet.abbr, snippet.abbr[-8:])
        endif
    endfor

    return l:list
endfunction"}}}

" Dummy function.
function! neocomplcache#plugin#snippets_complete#calc_rank(cache_keyword_buffer_list)"{{{
    return
endfunction"}}}

function! neocomplcache#plugin#snippets_complete#calc_prev_rank(cache_keyword_buffer_list, prev_word, prepre_word)"{{{
    " Calc previous rank.
    for keyword in a:cache_keyword_buffer_list
        " Set prev rank.
        let keyword.prev_rank = has_key(keyword.prev_word, a:prev_word)? 10+keyword.rank/2 : 0
    endfor
endfunction"}}}

function! neocomplcache#plugin#snippets_complete#expandable()"{{{
    " Set buffer filetype.
    if &filetype == ''
        let l:ft = 'nothing'
    else
        let l:ft = &filetype
    endif

    let l:snippets = copy(s:snippets['_'])
    for l:t in split(l:ft, '\.')
        if has_key(s:snippets, l:t)
            call extend(l:snippets, s:snippets[l:t])
        endif
    endfor

    " Set same filetype.
    if has_key(g:NeoComplCache_SameFileTypeLists, l:ft)
        for l:same_ft in split(g:NeoComplCache_SameFileTypeLists[l:ft], ',')
            if has_key(s:snippets, l:same_ft)
                call extend(l:snippets, s:snippets[l:same_ft], 'keep')
            endif
        endfor
    endif

    let l:cur_text = neocomplcache#get_cur_text()
    let l:cur_word = neocomplcache#match_word(l:cur_text)
    if !has_key(l:snippets, l:cur_word)
        let l:cur_word = matchstr(l:cur_text, '\h\w*[^[:alnum:][:space:]]*$')
    endif
    
    return (has_key(l:snippets, l:cur_word) &&
                \(l:snippets[l:cur_word].condition == 1 || eval(l:snippets[l:cur_word].condition)))
                \|| search('\${\d\+\%(:.\{-}\)\?\\\@<!}\|\$<\d\+\%(:.\{-}\)\?\\\@<!>', 'w') > 0
endfunction"}}}
function! neocomplcache#plugin#snippets_complete#get_cur_text()"{{{
    if mode() ==# 'i'
        return matchstr(neocomplcache#get_cur_text(), '\h\w*[^[:alnum:][:space:]]*$')
    else
        return matchstr(s:cur_text, '\h\w*[^[:alnum:][:space:]]*$')
    endif
endfunction"}}}

function! s:caching()"{{{
    " Set buffer filetype.
    if &filetype == ''
        let l:ft = 'nothing'
    else
        let l:ft = &filetype
    endif

    if !has_key(s:snippets, l:ft)
        call s:caching_snippets(l:ft)
    endif

    " Same filetype.
    if has_key(g:NeoComplCache_SameFileTypeLists, l:ft)
        for l:same_ft in split(g:NeoComplCache_SameFileTypeLists[l:ft], ',')
            if !has_key(s:snippets, l:same_ft)
                call s:caching_snippets(l:same_ft)
            endif
        endfor
    endif
endfunction"}}}

function! s:set_snippet_pattern(dict)"{{{
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)

    let l:word = a:dict.word
    if a:dict.word =~ '\${\d\+\%(:.\{-}\)\?\\\@<!}'
        let l:word .= '<expand>'
        let l:menu_pattern = '<Snip> %.'.g:NeoComplCache_MaxFilenameWidth.'s'
    else
        if a:dict.word =~ '<\\n>'
            let l:word .= '<expand>'
        endif
        let l:menu_pattern = '[Snip] %.'.g:NeoComplCache_MaxFilenameWidth.'s'
    endif
    let l:abbr = has_key(a:dict, 'abbr')? a:dict.abbr : 
                \substitute(a:dict.word, '<\\n>\|<expand>', '', 'g')
    let l:rank = has_key(a:dict, 'rank')? a:dict.rank : 5
    let l:condition = has_key(a:dict, 'condition')? a:dict.condition : 1
    let l:prev_word = {}
    if has_key(a:dict, 'prev_word')
        for l:prev in a:dict.prev_word
            let l:prev_word[l:prev] = 1
        endfor
    endif

    let l:dict = {
                \'word' : a:dict.name, 'snip' : l:word,
                \'menu' : printf(l:menu_pattern, a:dict.name), 
                \'prev_word' : l:prev_word, 'icase' : 1, 'dup' : 1,
                \'rank' : l:rank, 'prev_rank' : 0, 'prepre_rank' : 0, 
                \'condition' : l:condition
                \}
    let l:dict.abbr = 
                \ (len(l:abbr) > g:NeoComplCache_MaxKeywordWidth)? 
                \ printf(l:abbr_pattern, l:abbr, l:abbr[-8:]) : l:abbr
    return l:dict
endfunction"}}}

function! s:filetype_complete(arglead, cmdline, cursorpos)"{{{
    if len(split(a:cmdline)) > 1
        return []
    endif

    return filter(keys(s:snippets), printf('v:val =~ "^%s"', a:arglead))
endfunction"}}}
function! s:edit_snippets(filetype, isruntime)"{{{
    if a:filetype == ''
        if &filetype == ''
            echo 'Filetype required'
            return
        endif
        
        let l:filetype = &filetype
    else
        let l:filetype = a:filetype
    endif
    
    " Edit snippet file.
    if a:isruntime
        if empty(s:runtime_dir)
            return
        endif
        
        let l:filename = s:runtime_dir[0].'/'.l:filetype.'.snip'
    else
        if empty(s:snippets_dir) 
            return
        endif
        
        let l:filename = s:snippets_dir[-1].'/'.l:filetype.'.snip'
    endif

    " Split nicely.
    if winheight(0) > &winheight
        split
    else
        vsplit
    endif

    if filereadable(l:filename)
        edit `=l:filename`
    else
        enew
        setfiletype snippet
        saveas `=l:filename`
    endif
endfunction"}}}
function! s:print_snippets(filetype)"{{{
    let l:list = values(s:snippets['_'])

    let l:filetype = (a:filetype != '')?    a:filetype : &filetype

    if l:filetype != ''
        if !has_key(s:snippets, l:filetype)
            call s:caching_snippets(l:filetype)
        endif

        let l:list += values(s:snippets[l:filetype])
    endif

    for snip in sort(l:list, 'neocomplcache#compare_words')
        echohl String
        echo snip.word
        echohl None
        echo snip.abbr
        echo ' '
    endfor

    echohl None
endfunction"}}}

function! s:caching_snippets(filetype)"{{{
    let l:snippet = {}
    let l:snippets_files = split(globpath(join(s:snippets_dir, ','), a:filetype .  '.snip*'), '\n')
    for snippets_file in l:snippets_files
        call extend(l:snippet, s:load_snippets(snippets_file))
    endfor

    let s:snippets[a:filetype] = l:snippet
endfunction"}}}

function! s:load_snippets(snippets_file)"{{{
    let l:snippet = {}
    let l:snippet_pattern = { 'word' : '' }
    for line in readfile(a:snippets_file)
        if line =~ '^include'
            " Include snippets.
            let l:filetype = matchstr(line, '^include\s\+\zs.*$')
            let l:snippets_files = split(globpath(join(s:snippets_dir, ','), l:filetype .  '.snip'), '\n')
            for snippets_file in l:snippets_files
                call extend(l:snippet, s:load_snippets(snippets_file))
            endfor
        elseif line =~ '^snippet\s'
            if has_key(l:snippet_pattern, 'name')
                let l:pattern = s:set_snippet_pattern(l:snippet_pattern)
                let l:snippet[l:snippet_pattern.name] = l:pattern
                if has_key(l:snippet_pattern, 'alias')
                    for alias in l:snippet_pattern.alias
                        let l:alias_pattern = copy(l:pattern)
                        let l:alias_pattern.word = alias
                        let l:snippet[alias] = l:alias_pattern
                    endfor
                endif
                let l:snippet_pattern = { 'word' : '' }
            endif
            let l:snippet_pattern.name = substitute(matchstr(line, '^snippet\s\+\zs.*$'), '\s', '_', 'g')
        elseif line =~ '^abbr\s'
            let l:snippet_pattern.abbr = matchstr(line, '^abbr\s\+\zs.*$')
        elseif line =~ '^rank\s'
            let l:snippet_pattern.rank = matchstr(line, '^rank\s\+\zs\d\+\ze\s*$')
        elseif line =~ '^prev_word\s'
            let l:snippet_pattern.prev_word = []
            for word in split(matchstr(line, '^prev_word\s\+\zs.*$'), ',')
                call add(l:snippet_pattern.prev_word, matchstr(word, "'\\zs[^']*\\ze'"))
            endfor
        elseif line =~ '^alias\s'
            let l:snippet_pattern.alias = split(substitute(matchstr(line, '^alias\s\+\zs.*$'), '\s', '', 'g'), ',')
        elseif line =~ '^\s'
            if l:snippet_pattern.word == ''
                let l:snippet_pattern.word = matchstr(line, '^\s\+\zs.*$')
            elseif line =~ '^\t'
                let line = substitute(line, '^\s', '', '')
                let l:snippet_pattern.word .= '<\n>' . 
                            \substitute(line, '^\t\+', repeat('<\\t>', matchend(line, '^\t\+')), '')
            else
                let l:snippet_pattern.word .= '<\n>' . matchstr(line, '^\s\+\zs.*$')
            endif
        elseif line =~ '^delete\s'
            let l:name = matchstr(line, '^delete\s\+\zs.*$')
            if l:name != '' && has_key(l:snippet, l:name)
                call remove(l:snippet, l:name)
            endif
        elseif line =~ '^condition\s'
            let l:snippet_pattern.condition = matchstr(line, '^condition\s\+\zs.*$')
        endif
    endfor

    if has_key(l:snippet_pattern, 'name')
        let l:pattern = s:set_snippet_pattern(l:snippet_pattern)
        let l:snippet[l:snippet_pattern.name] = l:pattern
        if has_key(l:snippet_pattern, 'alias')
            for alias in l:snippet_pattern.alias
                let l:alias_pattern = copy(l:pattern)
                let l:alias_pattern.word = alias
                let l:snippet[alias] = l:alias_pattern
            endfor
        endif
    endif

    return l:snippet
endfunction"}}}

function! s:snippets_expand(cur_text, col)"{{{
    " Set buffer filetype.
    if &filetype == ''
        let l:ft = 'nothing'
    else
        let l:ft = &filetype
    endif

    let l:snippets = copy(s:snippets['_'])
    for l:t in split(l:ft, '\.')
        if has_key(s:snippets, l:t)
            call extend(l:snippets, s:snippets[l:t])
        endif
    endfor

    " Set same filetype.
    if has_key(g:NeoComplCache_SameFileTypeLists, l:ft)
        for l:same_ft in split(g:NeoComplCache_SameFileTypeLists[l:ft], ',')
            call extend(l:snippets, s:snippets[l:same_ft], 'keep')
        endfor
    endif

    let l:cur_text = a:cur_text
    let l:cur_word = neocomplcache#match_word(l:cur_text)
    if !has_key(l:snippets, l:cur_word)
        let l:cur_word = matchstr(l:cur_text, '\h\w*[^[:alnum:][:space:]]*$')
    endif
    if has_key(l:snippets, l:cur_word)
                \&& (l:snippets[l:cur_word].condition == 1 || eval(l:snippets[l:cur_word].condition))
        let l:snippet = l:snippets[l:cur_word]
        let l:cur_text = l:cur_text[: -1-len(l:cur_word)]

        let l:snip_word = l:snippet.snip
        if l:snip_word =~ '`.\{-}`'
            let l:snip_word = s:eval_snippet(l:snip_word)
        endif
        if l:snip_word =~ '\n'
            let snip_word = substitute(l:snip_word, '\n', '<\\n>', 'g') . '<expand>'
        endif

        " Add rank.
        let l:snippet.rank += 1

        " Insert snippets.
        let l:next_line = getline('.')[a:col-1 :]
        call setline(line('.'), l:cur_text . l:snip_word . l:next_line)
        call setpos('.', [0, line('.'), len(l:cur_text)+len(l:snip_word)+1, 0])
        let l:old_col = len(l:cur_text)+len(l:snip_word)+1

        if l:snip_word =~ '<expand>$'
            if l:snip_word =~ '<\\t>'
                call s:expand_tabline()
            else
                call s:expand_newline()
            endif
            
            call s:snippets_jump(a:cur_text, a:col)
        elseif l:old_col < col('$')
            startinsert
        else
            startinsert!
        endif

        let &l:iminsert = 0
        let &l:imsearch = 0
        return
    endif

    call s:snippets_jump(a:cur_text, a:col)
endfunction"}}}
function! s:expand_newline()"{{{
    " Substitute expand marker.
    silent! s/<expand>//

    let l:match = match(getline('.'), '<\\n>')
    let s:snippet_holder_cnt = 1
    let s:begin_snippet = line('.')
    let s:end_snippet = line('.')

    let l:formatoptions = &l:formatoptions
    setlocal formatoptions-=r

    let l:pos = col('.')

    while l:match >= 0
        let l:end = getline('.')[matchend(getline('.'), '<\\n>') :]
        " Substitute CR.
        silent! s/<\\n>//

        " Return.
        call setpos('.', [0, line('.'), l:match, 0])
        silent execute "normal! a\<CR>"
        let l:pos = len(l:end) + 1
        call setpos('.', [0, line('.'), l:pos, 0])

        " Next match.
        let l:match = match(getline('.'), '<\\n>')
        let s:end_snippet += 1
    endwhile
    
    let &l:formatoptions = l:formatoptions
endfunction"}}}
function! s:expand_tabline()"{{{
    " Substitute expand marker.
    silent! s/<expand>//

    let l:tablines = split(getline('.'), '<\\n>')

    let l:indent = matchstr(l:tablines[0], '^\s\+')
    let l:line = line('.')
    call setline(line, l:tablines[0])
    for l:tabline in l:tablines[1:]
        if &expandtab
            let l:tabline = substitute(l:tabline, '<\\t>', repeat(' ', &softtabstop ? &softtabstop : &shiftwidth), 'g')
        else
            let l:tabline = substitute(l:tabline, '<\\t>', '\t', 'g')
        endif
        
        call append(l:line, l:indent . l:tabline)
        let l:line += 1
    endfor

    let s:snippet_holder_cnt = 1
    let s:begin_snippet = line('.')
    let s:end_snippet = line('.') + len(l:tablines) - 1
    echomsg s:end_snippet
endfunction"}}}
function! s:snippets_jump(cur_text, col)"{{{
    if !s:search_snippet_range(s:begin_snippet, s:end_snippet)
        if s:snippet_holder_cnt != 0
            " Search placeholder 0.
            let s:snippet_holder_cnt = 0
            if s:search_snippet_range(s:begin_snippet, s:end_snippet)
                let &iminsert = 0
                let &imsearch = 0
                return
            endif
        endif

        " Not found.
        let s:begin_snippet = 1
        let s:end_snippet = 0
        let s:snippet_holder_cnt = 1

        call s:search_outof_range(a:col)
    endif

    let &iminsert = 0
    let &imsearch = 0
endfunction"}}}
function! s:search_snippet_range(start, end)"{{{
    call s:substitute_marker(a:start, a:end)
    
    let l:pattern = '\${'.s:snippet_holder_cnt.'\%(:.\{-}\)\?\\\@<!}'
    let l:pattern2 = '\${'.s:snippet_holder_cnt.':\zs.\{-}\ze\\\@<!}'

    let l:line = a:start
    while l:line <= a:end
        let l:match = match(getline(l:line), l:pattern)
        if l:match >= 0
            let l:default = substitute(matchstr(getline(l:line), l:pattern2), '\\\ze.', '', 'g')
            let l:match_len2 = len(l:default)

            if s:search_sync_placeholder(a:start, a:end, s:snippet_holder_cnt)
                " Substitute holder.
                call setline(l:line, substitute(getline(l:line), l:pattern, '\$<'.s:snippet_holder_cnt.':'.escape(l:default, '\').'>', ''))
                call setpos('.', [0, l:line, l:match+1 + len('$<'.s:snippet_holder_cnt.':'), 0])
                let l:pos = l:match+1 + len('$<'.s:snippet_holder_cnt.':')
            else
                " Substitute holder.
                call setline(l:line, substitute(getline(l:line), l:pattern, escape(l:default, '\'), ''))
                call setpos('.', [0, l:line, l:match+1, 0])
                let l:pos = l:match+1
            endif

            if l:match_len2 > 0
                " Select default value.
                let l:len = l:match_len2-1
                if &l:selection == "exclusive"
                    let l:len += 1
                endif

                execute 'normal! v'. repeat('l', l:len) . "\<C-g>"
            elseif l:pos < col('$')
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
function! s:search_outof_range(col)"{{{
    call s:substitute_marker(1, 0)
    
    let l:pattern = '\${\d\+\%(:.\{-}\)\?\\\@<!}'
    if search(l:pattern, 'w') > 0
        let l:line = line('.')
        let l:match = match(getline(l:line), l:pattern)
        let l:pattern2 = '\${\d\+:\zs.\{-}\ze\\\@<!}'
        let l:default = substitute(matchstr(getline(l:line), l:pattern2), '\\\ze.', '', 'g')
        let l:match_len2 = len(l:default)

        " Substitute holder.
        let l:cnt = matchstr(getline(l:line), '\${\zs\d\+\ze\%(:.\{-}\)\?\\\@<!}')
        if search('\$'.l:cnt.'\d\@!', 'nw') > 0
            let l:pattern = '\${' . l:cnt . '\%(:.\{-}\)\?\\\@<!}'
            call setline(l:line, substitute(getline(l:line), l:pattern, '\$<'.s:snippet_holder_cnt.':'.escape(l:default, '\').'>', ''))
            call setpos('.', [0, l:line, l:match+1 + len('$<'.l:cnt.':'), 0])
            let l:pos = l:match+1 + len('$<'.l:cnt.':')
        else
            " Substitute holder.
            call setline(l:line, substitute(getline(l:line), l:pattern, escape(l:default, '\'), ''))
            call setpos('.', [0, l:line, l:match+1, 0])
            let l:pos = l:match+1
        endif

        if l:match_len2 > 0
            " Select default value.
            let l:len = l:match_len2-1
            if &l:selection == "exclusive"
                let l:len += 1
            endif

            execute 'normal! v'. repeat('l', l:len) . "\<C-g>"

            return
        endif

        if l:pos < col('$')
            startinsert
        else
            startinsert!
        endif
    elseif a:col == 1
        call setpos('.', [0, line('.'), 1, 0])
        startinsert
    elseif a:col == col('$')
        startinsert!
    else
        call setpos('.', [0, line('.'), a:col+1, 0])
        startinsert
    endif
endfunction"}}}
function! s:search_sync_placeholder(start, end, number)"{{{
    let l:line = a:start
    let l:pattern = '\$'.a:number.'\d\@!'

    while l:line <= a:end
        if getline(l:line) =~ l:pattern
            return 1
        endif

        " Next line.
        let l:line += 1
    endwhile

    return 0
endfunction"}}}
function! s:substitute_marker(start, end)"{{{
    if s:snippet_holder_cnt > 1
        let l:cnt = s:snippet_holder_cnt-1
        let l:marker = '\$<'.l:cnt.'\%(:.\{-}\)\?\\\@<!>'
        let l:line = a:start
        while l:line <= a:end
            if getline(l:line) =~ l:marker
                let l:sub = escape(matchstr(getline(l:line), '\$<'.l:cnt.':\zs.\{-}\ze\\\@<!>'), '/\')
                silent! execute printf('%d,%ds/$%d\d\@!/%s/g', 
                            \a:start, a:end, l:cnt, l:sub)
                silent! execute l:line.'s/'.l:marker.'/'.l:sub.'/'
                break
            endif

            let l:line += 1
        endwhile
    elseif search('\$<\d\+\%(:.\{-}\)\?\\\@<!>', 'wb') > 0
        let l:sub = escape(matchstr(getline('.'), '\$<\d\+:\zs.\{-}\ze\\\@<!>'), '/\')
        let l:cnt = matchstr(getline('.'), '\$<\zs\d\+\ze\%(:.\{-}\)\?\\\@<!>')
        silent! execute printf('%%s/$%d\d\@!/%s/g', l:cnt, l:sub)
        silent! execute '%s/'.'\$<'.l:cnt.'\%(:.\{-}\)\?\\\@<!>'.'/'.l:sub.'/'
    endif
endfunction"}}}
function! s:trigger(function)"{{{
    let l:cur_text = neocomplcache#get_cur_text()
    let s:cur_text = l:cur_text
    return printf("\<ESC>:call %s(%s,%d)\<CR>", a:function, string(l:cur_text), col('.'))
endfunction"}}}
function! s:eval_snippet(snippet_text)"{{{
    let l:snip_word = ''
    let l:prev_match = 0
    let l:match = match(a:snippet_text, '`.\{-}`')
    while l:match >= 0
        if l:match - l:prev_match > 0
            let l:snip_word .= a:snippet_text[l:prev_match : l:match - 1]
        endif
        let l:prev_match = matchend(a:snippet_text, '`.\{-}`', l:match)
        let l:snip_word .= eval(a:snippet_text[l:match+1 : l:prev_match - 2])

        let l:match = match(a:snippet_text, '`.\{-}`', l:prev_match)
    endwhile
    if l:prev_match >= 0
        let l:snip_word .= a:snippet_text[l:prev_match :]
    endif

    return l:snip_word
endfunction"}}}

function! s:SID_PREFIX()
    return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

" Plugin key-mappings.
inoremap <silent><expr> <Plug>(neocomplcache_snippets_expand) <SID>trigger(<SID>SID_PREFIX().'snippets_expand')
snoremap <silent><expr> <Plug>(neocomplcache_snippets_expand) <SID>trigger(<SID>SID_PREFIX().'snippets_expand')
inoremap <silent><expr> <Plug>(neocomplcache_snippets_jump) <SID>trigger(<SID>SID_PREFIX().'snippets_jump')
snoremap <silent><expr> <Plug>(neocomplcache_snippets_jump) <SID>trigger(<SID>SID_PREFIX().'snippets_jump')

" vim: foldmethod=marker
