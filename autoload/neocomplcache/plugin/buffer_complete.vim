"=============================================================================
" FILE: buffer_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 25 Nov 2009
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
" Version: 3.18, for Vim 7.0
"=============================================================================

" Important variables.
if !exists('s:sources')
    let s:sources = {}
endif

function! neocomplcache#plugin#buffer_complete#initialize()"{{{
    augroup neocomplcache"{{{
        " Caching events
        autocmd FileType,BufWritePost * call s:check_source()
        autocmd BufWritePost,CursorHold * call s:update_source()
        " Caching current buffer events
        autocmd InsertLeave * call s:caching_insert_leave()
        autocmd VimLeavePre * call s:save_all_cache()
    augroup END"}}}

    " Initialize assume file type lists."{{{
    if !exists('g:NeoComplCache_NonBufferFileTypeDetect')
        let g:NeoComplCache_NonBufferFileTypeDetect = {}
    endif
    " For test.
    "let g:NeoComplCache_NonBufferFileTypeDetect['rb'] = 'ruby'"}}}

    " Initialize script variables."{{{
    let s:sources = {}
    let s:rank_cache_count = 1
    let s:prev_cached_count = 0
    let s:caching_disable_list = {}
    let s:completion_length = neocomplcache#get_completion_length('buffer_complete')
    "}}}

    " Create cache directory.
    if !isdirectory(g:NeoComplCache_TemporaryDir . '/buffer_cache')
        call mkdir(g:NeoComplCache_TemporaryDir . '/buffer_cache', 'p')
    endif

    " Initialize dictionary and tags."{{{
    if !exists('g:NeoComplCache_DictionaryFileTypeLists')
        let g:NeoComplCache_DictionaryFileTypeLists = {}
    endif
    if !has_key(g:NeoComplCache_DictionaryFileTypeLists, 'default')
        let g:NeoComplCache_DictionaryFileTypeLists['default'] = ''
    endif
    " For test.
    "let g:NeoComplCache_DictionaryFileTypeLists['vim'] = 'CSApprox.vim,LargeFile.vim'
    "}}}

    " Add commands."{{{
    command! -nargs=? -complete=buffer NeoComplCacheCachingBuffer call s:caching_buffer(<q-args>)
    command! -nargs=? -complete=buffer NeoComplCachePrintSource call s:print_source(<q-args>)
    command! -nargs=? -complete=buffer NeoComplCacheOutputKeyword call s:output_keyword(<q-args>)
    command! -nargs=? -complete=buffer NeoComplCacheCachingDisable call s:caching_disable(<q-args>)
    command! -nargs=? -complete=buffer NeoComplCacheCachingEnable call s:caching_enable(<q-args>)
    "}}}

    " Initialize cache.
    call s:check_source()

    " Plugin key-mappings.
    nnoremap <silent> <Plug>(neocomplcache_keyword_caching)  :<C-u>call <SID>caching(bufnr('%'), line('.'), 1, 2)<CR>
    inoremap <silent> <Plug>(neocomplcache_keyword_caching)  <C-o>:<C-u>call <SID>caching(bufnr('%'), line('.'), 1, 2)<CR>
endfunction
"}}}

function! neocomplcache#plugin#buffer_complete#finalize()"{{{
    delcommand NeoComplCacheCachingBuffer
    delcommand NeoComplCachePrintSource
    delcommand NeoComplCacheOutputKeyword
    delcommand NeoComplCacheCachingDisable
    delcommand NeoComplCacheCachingEnable

    nunmap <Plug>(neocomplcache_keyword_caching)
    iunmap <Plug>(neocomplcache_keyword_caching)

    let s:sources = {}

    call s:save_all_cache()
endfunction"}}}

function! neocomplcache#plugin#buffer_complete#get_keyword_list(cur_keyword_str)"{{{
    let l:keyword_list = []

    let l:key = tolower(a:cur_keyword_str[: s:completion_length-1])
    if len(a:cur_keyword_str) < s:completion_length || neocomplcache#check_match_filter(l:key)
        for src in s:get_sources_list()
            let l:keyword_list += neocomplcache#unpack_list(values(s:sources[src].keyword_cache))
        endfor
        return neocomplcache#keyword_filter(l:keyword_list, a:cur_keyword_str)
    else
        for src in s:get_sources_list()
            if has_key(s:sources[src].keyword_cache, l:key)
                let l:keyword_list += s:sources[src].keyword_cache[l:key]
            endif
        endfor

        if len(a:cur_keyword_str) == s:completion_length
            return l:keyword_list
        else
            return neocomplcache#keyword_filter(l:keyword_list, a:cur_keyword_str)
        endif
    endif
endfunction"}}}

function! neocomplcache#plugin#buffer_complete#calc_rank(cache_keyword_buffer_list)"{{{
    let l:list_len = len(a:cache_keyword_buffer_list)

    if l:list_len > g:NeoComplCache_MaxList * 5
        let l:calc_cnt = 15
    elseif l:list_len > g:NeoComplCache_MaxList * 3
        let l:calc_cnt = 10
    elseif l:list_len > g:NeoComplCache_MaxList
        let l:calc_cnt = 8
    elseif l:list_len > g:NeoComplCache_MaxList / 2
        let l:calc_cnt = 5
    elseif l:list_len > g:NeoComplCache_MaxList / 3
        let l:calc_cnt = 4
    elseif l:list_len > g:NeoComplCache_MaxList / 4
        let l:calc_cnt = 3
    else
        let l:calc_cnt = 2
    endif

    if g:NeoComplCache_CalcRankRandomize
        let l:match_end = matchend(reltimestr(reltime()), '\d\+\.') + 1
    endif

    for keyword in a:cache_keyword_buffer_list
        if s:rank_cache_count <= 0
            " Set rank.
            let keyword.rank = 0
            for keyword_lines in values(s:sources[keyword.srcname].rank_cache_lines)
                if has_key(keyword_lines, keyword.word)
                    let keyword.rank += keyword_lines[keyword.word].rank
                endif
            endfor
            if keyword.rank == 0 && has_key(s:sources[keyword.srcname].dup_check, keyword.word)
                call remove(s:sources[keyword.srcname].dup_check, keyword.word)
            endif

            " Reset count.
            let s:rank_cache_count = (g:NeoComplCache_CalcRankRandomize)? 
                        \ reltimestr(reltime())[l:match_end : ] % l:calc_cnt + 2 : l:calc_cnt
        endif
        let s:rank_cache_count -= 1
    endfor
endfunction"}}}

function! neocomplcache#plugin#buffer_complete#calc_prev_rank(cache_keyword_buffer_list, prev_word, prepre_word)"{{{
    " Get next keyword list.
    let [l:source_next, l:source_next_next, l:operator_list] = [{}, {}, {}]
    " Get operator keyword list.
    let l:pattern = neocomplcache#get_keyword_pattern_end()
    let l:cur_text = strpart(getline('.'), 0, col('.') - 1)
    let l:cur_keyword_pos = match(l:cur_text, l:pattern)
    if l:cur_keyword_pos > 0
        let l:cur_text = l:cur_text[: l:cur_keyword_pos-1]
    endif
    let l:operator = matchstr(l:cur_text,
                \'[!@#$%^&*(=+\\|`~[{:/?.><-]\{1,2}\ze\s*$')

    for src in s:get_sources_list()
        if has_key(s:sources[src].next_word_list, a:prev_word)
            let l:source_next[src] = s:sources[src].next_word_list[a:prev_word]
        endif
        if a:prepre_word != '' && has_key(s:sources[src].next_next_word_list, a:prepre_word)
            let l:source_next_next[src] = s:sources[src].next_next_word_list[a:prepre_word]
        endif
    endfor

    " Calc previous rank.
    for keyword in a:cache_keyword_buffer_list
        let [keyword.prev_rank, keyword.prepre_rank] = [0, 0]
        if has_key(l:source_next, keyword.srcname)
                    \&& has_key(l:source_next[keyword.srcname], keyword.word)
            " Set prev rank.
            let keyword.prev_rank = 0
            for keyword_lines in values(s:sources[keyword.srcname].rank_cache_lines)
                if has_key(keyword_lines, keyword.word)
                            \&& has_key(keyword_lines[keyword.word].prev_rank, a:prev_word)
                    let keyword.prev_rank += keyword_lines[keyword.word].prev_rank[a:prev_word]
                endif
            endfor
            let keyword.prev_rank = keyword.prev_rank * 9
        endif
        if has_key(l:source_next_next, keyword.srcname)
                    \&& has_key(l:source_next_next[keyword.srcname], keyword.word)
            " Set prepre rank.
            let keyword.prepre_rank = 0
            for keyword_lines in values(s:sources[keyword.srcname].rank_cache_lines)
                if has_key(keyword_lines, keyword.word)
                            \&& has_key(keyword_lines[keyword.word].prepre_rank, a:prepre_word)
                    let keyword.prepre_rank += keyword_lines[keyword.word].prepre_rank[a:prepre_word]
                endif
            endfor
            if a:prepre_word != '^'
                let keyword.prepre_rank = keyword.prepre_rank * 3
            endif
        endif
        if has_key(l:operator_list, keyword.srcname)
                    \&& has_key(l:operator_list[keyword.srcname], keyword.word)
            let keyword.prev_rank = keyword.prev_rank * 2
            let keyword.prev_rank += 100
        endif
    endfor
endfunction"}}}

function! neocomplcache#plugin#buffer_complete#exists_current_source()"{{{
    return has_key(s:sources, bufnr('%'))
endfunction"}}}

function! neocomplcache#plugin#buffer_complete#caching_percent(number)"{{{
    if a:number == ''
        let l:number = bufnr('%')
    else
        let l:number = a:number
    endif
    if !has_key(s:sources, l:number)
        return '-'
    elseif s:sources[l:number].cached_last_line >= s:sources[l:number].end_line
        return 100
    else
        return s:sources[l:number].cached_last_line*100 / s:sources[l:number].end_line
    endif
endfunction"}}}

function! s:update_source()"{{{
    call s:check_deleted_buffer()

    let l:caching_num = 0
    for source_name in keys(s:sources)
        if source_name =~ '^\d'
            " Lazy caching.
            if s:caching_source(str2nr(source_name), '^', 2) == 0
                let l:caching_num += 2

                if l:caching_num >= 6
                    break
                endif
            endif
        endif
    endfor
endfunction"}}}

function! s:get_sources_list()"{{{
    " Set buffer filetype.
    if &filetype == ''
        let l:ft = 'nothing'
    else
        let l:ft = &filetype
    endif

    " Check dictionaries are exists.
    if &filetype != '' && has_key(g:NeoComplCache_DictionaryFileTypeLists, &filetype)
        let l:ft_dict = '^' . l:ft
    elseif g:NeoComplCache_DictionaryFileTypeLists['default'] != ''
        let l:ft_dict = '^default'
    else
        " Dummy pattern.
        let l:ft_dict = '^$'
    endif

    let l:sources_list = []
    for key in keys(s:sources)
        if (key =~ '^\d' && l:ft == s:sources[key].filetype) || key =~ l:ft_dict
            call add(l:sources_list, key)
        endif
    endfor

    let l:ft_list = []
    " Set same filetype.
    if has_key(g:NeoComplCache_SameFileTypeLists, l:ft)
        let l:ft_list += split(g:NeoComplCache_SameFileTypeLists[&filetype], ',')
    endif

    " Set compound filetype.
    if l:ft =~ '\.'
        let l:ft_list += split(l:ft, '\.')
    endif

    for l:t in l:ft_list
        if l:t != '' && has_key(g:NeoComplCache_DictionaryFileTypeLists, l:t)
            let l:ft_dict = '^' . l:t
        else
            " Dummy pattern.
            let l:ft_dict = '^$'
        endif

        for key in keys(s:sources)
            if key =~ '^\d' && l:t == s:sources[key].filetype
                        \|| key =~ l:ft_dict
                call add(l:sources_list, key)
            endif
        endfor
    endfor

    return l:sources_list
endfunction"}}}

function! s:caching(srcname, start_line, end_cache_cnt)"{{{
    " Check exists s:sources.
    if !has_key(s:sources, a:srcname)
        call s:word_caching(a:srcname, 1, '$')
    endif

    let l:source = s:sources[a:srcname]
    " Buffer.
    let l:filename = fnamemodify(l:source.name, ':t')

    let l:start_line = (a:start_line-1)/l:source.cache_line_cnt*l:source.cache_line_cnt+1
    let l:end_line = (a:end_cache_cnt < 0)? '$' : 
                \ (l:start_line + a:end_cache_cnt * l:source.cache_line_cnt-1)
    " For debugging.
    "if l:end_line == '$'
        "echomsg printf("%s: start=%d, end=%d", l:filename, l:start_line, l:source.end_line)
    "else
        "echomsg printf("%s: start=%d, end=%d", l:filename, l:start_line, l:end_line)
    "endif

    if a:start_line == 1 && a:end_cache_cnt < 0
        " Cache clear if whole buffer.
        let l:source.keyword_cache = {}
        let l:source.dup_check = {}
        let l:source.rank_cache_lines = {}
    endif

    " Clear cache line.
    let l:cache_line = (l:start_line-1) / l:source.cache_line_cnt
    let l:source.rank_cache_lines[l:cache_line] = {}

    " Buffer.
    let l:buflines = getbufline(a:srcname, l:start_line, l:end_line)
    let l:menu = printf('[B] %.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:keyword_pattern = s:split_keyword(l:source.keyword_pattern)

    let [l:line_cnt, l:max_lines, l:line_num] = [0, len(l:buflines), 0]
    while l:line_num < l:max_lines
        if l:line_cnt >= l:source.cache_line_cnt
            " Next cache line.
            let l:cache_line += 1
            let [l:source.rank_cache_lines[l:cache_line], l:line_cnt] = [{}, 0]
        endif

        let [l:line, l:rank_cache_line] = [buflines[l:line_num], l:source.rank_cache_lines[l:cache_line]]
        for l:pattern in l:keyword_pattern
            let [l:match_num, l:prev_word, l:prepre_word, l:match] =
                    \[0, '^', '', match(l:line, l:pattern)]

            while l:match >= 0"{{{
                let l:match_str = matchstr(l:line, l:pattern, l:match)

                " Ignore too short keyword.
                if len(l:match_str) >= g:NeoComplCache_MinKeywordLength"{{{
                    if !has_key(l:rank_cache_line, l:match_str) 
                        let l:rank_cache_line[l:match_str] = { 'rank' : 1, 'prev_rank' : {}, 'prepre_rank' : {} }
                        let l:match_cache_line = l:rank_cache_line[l:match_str]

                        " Check dup.
                        if !has_key(l:source.dup_check, l:match_str)
                            " Append list.
                            let l:keyword = {
                            \'word' : l:match_str, 'menu' : l:menu,
                            \'filename' : l:filename, 'srcname' : a:srcname, 'icase' : 1, 'rank' : 1
                            \}

                            let l:keyword.abbr = 
                            \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                            \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str

                            let l:key = tolower(l:match_str[: s:completion_length-1])
                            if !has_key(l:source.keyword_cache, l:key)
                                let l:source.keyword_cache[l:key] = []
                            endif
                            call add(l:source.keyword_cache[l:key], l:keyword)
                            let l:source.dup_check[l:match_str] = 1
                        endif
                    else
                        let l:match_cache_line = l:rank_cache_line[l:match_str]
                        let l:match_cache_line.rank += 1
                    endif

                    " Calc previous keyword rank.
                    if l:prepre_word != ''
                        if !has_key(l:source.next_next_word_list, l:prepre_word)
                            let l:source.next_next_word_list[l:prepre_word] = {}
                            let l:source.next_next_word_list[l:prepre_word][l:match_str] = 1
                        elseif !has_key(l:source.next_next_word_list[l:prepre_word], l:match_str)
                            let l:source.next_next_word_list[l:prepre_word][l:match_str] = 1
                        endif

                        if has_key(l:match_cache_line.prepre_rank, l:prepre_word)
                            let l:match_cache_line.prepre_rank[l:prepre_word] += 1
                        else
                            let l:match_cache_line.prepre_rank[l:prepre_word] = 1
                        endif
                    endif

                    if !has_key(l:source.next_word_list, l:prev_word)
                        let l:source.next_word_list[l:prev_word] = {}
                        let l:source.next_word_list[l:prev_word][l:match_str] = 1
                    elseif !has_key(l:source.next_word_list[l:prev_word], l:match_str)
                        let l:source.next_word_list[l:prev_word][l:match_str] = 1
                    endif

                    if has_key(l:match_cache_line.prev_rank, l:prev_word)
                        let l:match_cache_line.prev_rank[l:prev_word] += 1
                    else
                        let l:match_cache_line.prev_rank[l:prev_word] = 1
                    endif
                endif"}}}

                let l:match_num = l:match + len(l:match_str)

                " Next match.
                let [l:prev_word, l:prepre_word, l:match] = [l:match_str, l:prev_word, match(l:line, l:pattern, l:match_num)]
            endwhile"}}}
        endfor

        let l:line_num += 1
        let l:line_cnt += 1
    endwhile
endfunction"}}}

function! s:initialize_source(srcname)"{{{
    if a:srcname =~ '^\d'
        " Buffer.
        let l:filename = fnamemodify(bufname(a:srcname), ':t')

        " Set cache line count.
        let l:buflines = getbufline(a:srcname, 1, '$')
        let l:end_line = len(l:buflines)

        if l:end_line > 150
            let cnt = 0
            for line in l:buflines[50:150] 
                let cnt += len(line)
            endfor

            if cnt <= 3000
                let l:cache_line_cnt = g:NeoComplCache_CacheLineCount
            elseif cnt <= 4000
                let l:cache_line_cnt = g:NeoComplCache_CacheLineCount*7 / 10
            elseif cnt <= 5000
                let l:cache_line_cnt = g:NeoComplCache_CacheLineCount / 2
            elseif cnt <= 7500
                let l:cache_line_cnt = g:NeoComplCache_CacheLineCount / 3
            elseif cnt <= 10000
                let l:cache_line_cnt = g:NeoComplCache_CacheLineCount / 5
            elseif cnt <= 12000
                let l:cache_line_cnt = g:NeoComplCache_CacheLineCount / 7
            elseif cnt <= 14000
                let l:cache_line_cnt = g:NeoComplCache_CacheLineCount / 10
            else
                let l:cache_line_cnt = g:NeoComplCache_CacheLineCount / 13
            endif
        elseif l:end_line > 100
            let l:cache_line_cnt = g:NeoComplCache_CacheLineCount / 3
        else
            let l:cache_line_cnt = g:NeoComplCache_CacheLineCount / 5
        endif
        "echo l:cache_line_cnt

        let l:ft = getbufvar(a:srcname, '&filetype')
        if l:ft == ''
            let l:ft = 'nothing'
        endif

        let l:keyword_pattern = neocomplcache#assume_buffer_pattern(a:srcname)
    else
        " Dictionary.
        let l:filename = split(a:srcname, ',')[1]
        let l:end_line = len(readfile(l:filename))

        " Assuming filetype.
        if a:srcname =~ '^dict:'
            " Current buffer filetype.
            let l:ft = &filetype
        else
            " Embeded filetype.
            let l:ft = split(a:srcname, ',')[0]
        endif

        let l:keyword_pattern = neocomplcache#assume_pattern(l:filename)
        if l:keyword_pattern == ''
            " Assuming failed.
            let l:keyword_pattern = has_key(g:NeoComplCache_KeywordPatterns, l:ft)? 
                        \g:NeoComplCache_KeywordPatterns[l:ft] : g:NeoComplCache_KeywordPatterns['default']
        endif

        " Set cache line count.
        let l:cache_line_cnt = g:NeoComplCache_CacheLineCount
    endif


    let s:sources[a:srcname] = {
                \'keyword_cache' : {}, 'rank_cache_lines' : {}, 'dup_check' : {}, 
                \'next_word_list' : {}, 'next_next_word_list' : {},
                \'name' : l:filename, 'filetype' : l:ft, 'keyword_pattern' : l:keyword_pattern, 
                \'end_line' : l:end_line , 'cached_last_line' : 1, 'cache_line_cnt' : l:cache_line_cnt
                \}
endfunction"}}}

function! s:word_caching(srcname, start_line, end_line)"{{{
    " Initialize source.
    call s:initialize_source(a:srcname)

    if s:caching_from_cache(a:srcname) == 0
        " Caching from cache.
        return
    endif

    let l:source = s:sources[a:srcname]

    let l:filename = fnamemodify(l:source.name, ':t')
    if a:srcname =~ '^\d'
        " Buffer.
        let l:menu = printf('[B] %.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    else
        " Dictionary.
        let l:menu = printf('[D] %.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    endif

    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:keyword_pattern = s:split_keyword(l:source.keyword_pattern)

    if a:srcname =~ '^\d'
        " Buffer.
        let l:buflines = getbufline(a:srcname, a:start_line, a:end_line)
    else
        " Dictionary.
        let l:buflines = readfile(split(a:srcname, ',')[1])
    endif
    let [l:max_lines, l:line_num] = [len(l:buflines), 0]

    if l:max_lines > 200
        if g:NeoComplCache_CachingPercentInStatusline
            let l:statusline_save = &l:statusline

            if a:srcname =~ '^\d'
                let &l:statusline =  'Caching buffer "' . l:filename . '"... please wait.'
            else
                let &l:statusline = 'Caching dictionary "' . l:filename . '"... please wait.'
            endif
            redrawstatus
        else
            redraw
            if a:srcname =~ '^\d'
                echo 'Caching buffer "' . l:filename . '"... please wait.'
            else
                echo 'Caching dictionary "' . l:filename . '"... please wait.'
            endif
        endif
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

    while l:line_num < l:max_lines
        " Percentage check.
        if l:line_cnt == 0
            if g:NeoComplCache_CachingPercentInStatusline
                let &l:statusline = printf('Caching(%s): %d%%', l:filename, l:line_num*100 / l:max_lines)
                redrawstatus!
            else
                redraw
                echo printf('Caching(%s): %d%%', l:filename, l:line_num*100 / l:max_lines)
            endif
            let l:line_cnt = l:print_cache_percent
        endif
        let l:line_cnt -= 1

        let l:line = buflines[l:line_num]
        for l:pattern in l:keyword_pattern
            let [l:match_num, l:match] = [0, match(l:line, l:pattern)]

            while l:match >= 0"{{{
                let l:match_str = matchstr(l:line, l:pattern, l:match)

                " Ignore too short keyword.
                if len(l:match_str) >= g:NeoComplCache_MinKeywordLength
                \&& !has_key(l:source.dup_check, l:match_str)
                    " Append list.
                    let l:keyword = {
                                \'word' : l:match_str, 'menu' : l:menu,
                                \'filename' : l:filename, 'srcname' : a:srcname, 'icase' : 1, 'rank' : 1
                                \}
                    let l:keyword.abbr = 
                                \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                                \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str

                    let l:key = tolower(l:match_str[: s:completion_length-1])
                    if !has_key(l:source.keyword_cache, l:key)
                        let l:source.keyword_cache[l:key] = []
                    endif
                    call add(l:source.keyword_cache[l:key], l:keyword)

                    let l:source.dup_check[l:match_str] = 1
                endif

                let l:match_num = l:match + len(l:match_str)
                let l:match = match(l:line, l:pattern, l:match_num)
            endwhile"}}}
        endfor

        let l:line_num += 1
    endwhile

    if l:max_lines > 200
        if g:NeoComplCache_CachingPercentInStatusline
            let &l:statusline = l:statusline_save
            redrawstatus
        else
            redraw
            echo ''
            redraw
        endif
    endif
endfunction"}}}

function! s:word_caching_current_line()"{{{
    let l:source = s:sources[bufnr('%')]

    " Buffer.
    let l:filename = fnamemodify(l:source.name, ':t')

    let l:menu = printf('[B] %.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:keyword_pattern = s:split_keyword(l:source.keyword_pattern)

    " Buffer.
    let l:start_line = (line('.')-1)/l:source.cache_line_cnt*l:source.cache_line_cnt+1
    let l:end_line = l:start_line + l:source.cache_line_cnt
    let l:buflines = join(getbufline(bufnr('%'), l:start_line, l:end_line), "\<CR>")

    for l:pattern in l:keyword_pattern
        let [l:match_num, l:match] = [0, match(l:buflines, l:pattern)]
        while l:match >= 0
            let l:match_str = matchstr(l:buflines, l:pattern, l:match)

            " Ignore too short keyword.
            if len(l:match_str) >= g:NeoComplCache_MinKeywordLength
                        \&& !has_key(l:source.dup_check, l:match_str)
                " Append list.
                let l:keyword = {
                            \'word' : l:match_str, 'menu' : l:menu,
                            \'filename' : l:filename, 'srcname' : bufnr('%'), 'icase' : 1, 'rank' : 1
                            \}

                let l:keyword.abbr = 
                            \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                            \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str

                let l:key = tolower(l:match_str[: s:completion_length-1])
                if !has_key(l:source.keyword_cache, l:key)
                    let l:source.keyword_cache[l:key] = []
                endif
                call add(l:source.keyword_cache[l:key], l:keyword)

                let l:source.dup_check[l:match_str] = 1
            endif

            let l:match_num = l:match + len(l:match_str)
            let l:match = match(l:buflines, l:pattern, l:match_num)
        endwhile
    endfor
endfunction"}}}

function! s:caching_from_cache(srcname)"{{{
    if a:srcname =~ '^\d'
        if getbufvar(a:srcname, '&buftype') =~ 'nofile'
            return -1
        endif

        " Buffer.
        let l:srcname = fnamemodify(bufname(str2nr(a:srcname)), ':p')
    else
        " Dictionary.
        let l:srcname = split(a:srcname, ',')[1]
    endif
    let l:cache_name = g:NeoComplCache_TemporaryDir . '/buffer_cache/' .
                \substitute(substitute(l:srcname, ':', '=-', 'g'), '[/\\]', '=+', 'g') . '='
    if getftime(l:cache_name) == -1 || getftime(l:cache_name) <= getftime(l:srcname)
        return -1
    endif

    let l:source = s:sources[a:srcname]

    let l:filename = fnamemodify(l:source.name, ':t')
    if a:srcname =~ '^\d'
        " Buffer.
        let l:menu = printf('[B] %.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    else
        " Dictionary.
        let l:menu = printf('[D] %.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    endif

    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)

    let l:buflines = readfile(l:cache_name)
    let l:max_lines = len(l:buflines)

    if l:max_lines > 5000
        let l:print_cache_percent = l:max_lines / 5
    elseif l:max_lines > 3000
        let l:print_cache_percent = l:max_lines / 3
    elseif l:max_lines > 1000
        let l:print_cache_percent = l:max_lines / 2
    else
        let l:print_cache_percent = -1
    endif
    let l:line_cnt = l:print_cache_percent

    if l:max_lines > 1000
        if g:NeoComplCache_CachingPercentInStatusline
            let l:statusline_save = &l:statusline

            if a:srcname =~ '^\d'
                let &l:statusline =  'Caching buffer "' . l:filename . '"... please wait.'
            else
                let &l:statusline = 'Caching dictionary "' . l:filename . '"... please wait.'
            endif
            redrawstatus
        else
            redraw
            if a:srcname =~ '^\d'
                echo 'Caching buffer "' . l:filename . '"... please wait.'
            else
                echo 'Caching dictionary "' . l:filename . '"... please wait.'
            endif
        endif
    endif

    let l:line_num = 0
    while l:line_num < l:max_lines
        " Percentage check.
        if l:line_cnt == 0
            if g:NeoComplCache_CachingPercentInStatusline
                let &l:statusline = printf('Caching(%s): %d%%', l:filename, l:line_num*100 / l:max_lines)
                redrawstatus!
            else
                redraw
                echo printf('Caching(%s): %d%%', l:filename, l:line_num*100 / l:max_lines)
            endif
            let l:line_cnt = l:print_cache_percent
        endif
        let l:line_cnt -= 1

        let l:match_str = buflines[l:line_num]
        " Ignore too short keyword.
        if len(l:match_str) >= g:NeoComplCache_MinKeywordLength
            " Append list.
            let l:keyword = {
                        \'word' : l:match_str, 'menu' : l:menu,
                        \'filename' : l:filename, 'srcname' : a:srcname, 'icase' : 1, 'rank' : 1
                        \}

            let l:keyword.abbr = 
                        \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                        \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str

            let l:key = tolower(l:match_str[: s:completion_length-1])
            if !has_key(l:source.keyword_cache, l:key)
                let l:source.keyword_cache[l:key] = []
            endif
            call add(l:source.keyword_cache[l:key], l:keyword)

            let l:source.dup_check[l:match_str] = 1
        endif

        let l:line_num += 1
    endwhile

    if l:max_lines > 1000
        redraw
        echo ''
    endif

    return 0
endfunction"}}}

function! s:split_keyword(keyword_pattern)"{{{
    let l:keyword_patterns = []
    let l:keyword_pattern = a:keyword_pattern

    let l:i = 0
    let l:max = len(l:keyword_pattern)
    let l:is_very_magic = 0
    while l:i < l:max
        if match(l:keyword_pattern, '^\\v', l:i) >= 0
            " Very magic.
            let l:is_very_magic = 1
            
            let l:i += 2
        elseif match(l:keyword_pattern, '^\\m', l:i) >= 0
            " Magic.
            let l:is_very_magic = 0
            
            let l:i += 2
        elseif l:is_very_magic && match(l:keyword_pattern, '^%\?(', l:i) >= 0
            " Grouping.
            let l:i = s:match_pair(l:keyword_pattern, '\\\@<!%\?(', '\\\@<!)', l:i)
            if l:i < 0
                echoerr 'Unmatched (.'
                return []
            endif

            let l:i += 1
        elseif !l:is_very_magic && match(l:keyword_pattern, '^\\%\?(', l:i) >= 0
            " Grouping.
            let l:i = s:match_pair(l:keyword_pattern, '\\%\?(', '\\)', l:i)
            if l:i < 0
                echoerr 'Unmatched (.'
                return []
            endif

            let l:i += 1
        elseif l:is_very_magic && l:keyword_pattern[l:i] == '|'
            " Select.
            call add(l:keyword_patterns, '\v'.l:keyword_pattern[: l:i-1])
            let l:keyword_pattern = l:keyword_pattern[l:i+1 :]
            let l:max = len(l:keyword_pattern)
            
            let l:i = 0
        elseif !l:is_very_magic && match(l:keyword_pattern, '^\\|', l:i) >= 0
            " Select.
            call add(l:keyword_patterns, l:keyword_pattern[: l:i-1])
            let l:keyword_pattern = l:keyword_pattern[l:i+2 :]
            let l:max = len(l:keyword_pattern)
            
            let l:i = 0
        elseif l:keyword_pattern[l:i] == '\'
            " Escape.
            let l:i += 2
        elseif l:keyword_pattern[l:i] == '['
            " Collection.
            let l:i = matchend(l:keyword_pattern, '\\\@<!]', l:i)
            if l:i < 0
                echoerr 'Unmatched [.'
                return []
            endif
        else
            let l:i += 1
        endif
    endwhile

    call add(l:keyword_patterns, (l:is_very_magic ? '\v' : '').l:keyword_pattern)
    return l:keyword_patterns
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

function! s:check_changed_buffer(bufname)"{{{
    let l:ft = getbufvar(a:bufname, '&filetype')
    if l:ft == ''
        let l:ft = 'nothing'
    endif

    return s:sources[a:bufname].name != fnamemodify(bufname(a:bufname), ':t')
                \ || s:sources[a:bufname].filetype != l:ft
endfunction"}}}

function! s:caching_source(srcname, start_line, end_cache_cnt)"{{{
    if !has_key(s:sources, a:srcname)
        return
    endif

    if a:start_line == '^'
        let l:source = s:sources[a:srcname]

        let l:start_line = l:source.cached_last_line
        " Check overflow.
        if l:start_line > l:source.end_line &&
                    \(a:srcname !~ '^\d' || !s:check_changed_buffer(a:srcname))
            " Caching end.
            return -1
        endif

        let l:source.cached_last_line += a:end_cache_cnt * l:source.cache_line_cnt
    else
        let l:start_line = a:start_line
    endif

    call s:caching(a:srcname, l:start_line, a:end_cache_cnt)

    return 0
endfunction"}}}

function! s:check_source()"{{{
    let l:bufnumber = 1
    let l:ft_dicts = []
    call add(l:ft_dicts, 'default')

    " Check new buffer.
    while l:bufnumber <= bufnr('$')
        if buflisted(l:bufnumber)
            let l:bufname = fnamemodify(bufname(l:bufnumber), ':p')
            if (!has_key(s:sources, l:bufnumber) || s:check_changed_buffer(l:bufnumber))
                        \&& !has_key(s:caching_disable_list, l:bufnumber)
                        \&& (g:NeoComplCache_CachingDisablePattern == '' || l:bufname !~ g:NeoComplCache_CachingDisablePattern)
                        \&& getbufvar(l:bufnumber, '&readonly') == 0
                        \&& getfsize(l:bufname) < g:NeoComplCache_CachingLimitFileSize
                " Caching.
                call s:word_caching(l:bufnumber, 1, '$')
            endif

            if has_key(g:NeoComplCache_DictionaryFileTypeLists, getbufvar(l:bufnumber, '&filetype'))
                call add(l:ft_dicts, getbufvar(l:bufnumber, '&filetype'))
            endif
        endif

        let l:bufnumber += 1
    endwhile

    " Check dictionary.
    for l:ft_dict in l:ft_dicts
        " Ignore if empty.
        if l:ft_dict != ''
            for dict in split(g:NeoComplCache_DictionaryFileTypeLists[l:ft_dict], ',')
                let l:dict_name = printf('%s,%s', l:ft_dict, dict)
                if !has_key(s:sources, l:dict_name) && filereadable(dict)
                    " Caching.
                    call s:word_caching(l:dict_name, 1, '$')
                endif
            endfor
        endif
    endfor
endfunction"}}}
function! s:check_deleted_buffer()"{{{
    " Check deleted buffer.
    for key in keys(s:sources)
        if key =~ '^\d' && !buflisted(str2nr(key))
            " Save cache.
            call s:save_cache(key)

            " Remove item.
            call remove(s:sources, key)
        endif
    endfor
endfunction"}}}

function! s:caching_insert_leave()"{{{
    if !has_key(s:sources, bufnr('%')) || has_key(s:caching_disable_list, bufnr('%')) || @. == ''
        return
    endif

    if s:prev_cached_count <= 0
        " Full caching.
        call s:caching(bufnr('%'), line('.'), 1)
        if g:NeoComplCache_CachingRandomize
            let l:match_end = matchend(reltimestr(reltime()), '\d\+\.') + 1
            let s:prev_cached_count = reltimestr(reltime())[l:match_end : ] % 3
        else
            let s:prev_cached_count = 2
        endif
    else
        " Word caching.
        call s:word_caching_current_line()

        let s:prev_cached_count -= 1
    endif
endfunction"}}}

function! s:save_cache(srcname)"{{{
    if s:sources[a:srcname].end_line < 500
        return
    endif

    if a:srcname =~ '^\d'
        if getbufvar(a:srcname, '&buftype') =~ 'nofile'
            return
        endif

        " Buffer.
        let l:srcname = fnamemodify(bufname(str2nr(a:srcname)), ':p')
        if !filereadable(l:srcname)
            return
        endif
    else
        " Dictionary.
        let l:srcname = split(a:srcname, ',')[1]
    endif
    let l:cache_name = g:NeoComplCache_TemporaryDir . '/buffer_cache/' .
                \substitute(substitute(l:srcname, ':', '=-', 'g'), '[/\\]', '=+', 'g') . '='
    if getftime(l:cache_name) >= getftime(l:srcname)
        return -1
    endif

    " Output buffer.
    let l:word_list = []
    for keyword in keys(s:sources[a:srcname].dup_check)
        call add(l:word_list, keyword)
    endfor
    call writefile(l:word_list, l:cache_name)
endfunction "}}}

function! s:save_all_cache()"{{{
    for l:key in keys(s:sources)
        call s:save_cache(l:key)
    endfor
endfunction"}}}

" Command functions."{{{
function! s:caching_buffer(name)"{{{
    if a:name == ''
        let l:number = bufnr('%')
    else
        let l:number = bufnr(a:name)

        if l:number < 0
            echohl Error | echo 'Invalid buffer name.' | echohl None
            return
        endif
    endif

    if !has_key(s:sources, l:number)
        if buflisted(l:number)
            " Word caching.
            call s:word_caching(l:number, 1, '$')
        endif

        return
    elseif s:sources[l:number].cached_last_line >= s:sources[l:number].end_line
        " Word recaching.
        call s:word_caching(l:number, 1, '$')
        return
    endif

    call s:caching_source(l:number, s:sources[l:number].cached_last_line, -1)

    " Disable auto caching.
    let s:sources[l:number].cached_last_line = s:sources[l:number].end_line+1
endfunction"}}}
function! s:print_source(name)"{{{
    if a:namame == ''
        let l:number = bufnr('%')
    else
        let l:number = bufnr(a:name)

        if l:number < 0
            echohl Error | echo 'Invalid buffer name.' | echohl None
            return
        endif
    endif

    if !has_key(s:sources, l:number)
        return
    endif

    silent put=printf('Print neocomplcache %d source.', l:number)
    for l:key in keys(s:sources[l:number])
        silent put =printf('%s => %s', l:key, string(s:sources[l:number][l:key]))
    endfor
endfunction"}}}
function! s:output_keyword(name)"{{{
    if a:number == ''
        let l:number = bufnr('%')
    else
        let l:number = bufnr(a:name)

        if l:number < 0
            echohl Error | echo 'Invalid buffer name.' | echohl None
            return
        endif
    endif

    if !has_key(s:sources, l:number)
        return
    endif

    " Output buffer.
    for keyword_list in values(s:sources[l:number].keyword_cache)
        for keyword in keyword_list
            silent put=keyword
        endfor
    endfor
endfunction "}}}
function! s:caching_disable(name)"{{{
    if a:number == ''
        let l:number = bufnr('%')
    else
        let l:number = bufnr(a:name)

        if l:number < 0
            echohl Error | echo 'Invalid buffer name.' | echohl None
            return
        endif
    endif

    let s:caching_disable_list[l:number] = 1

    if has_key(s:sources, l:number)
        " Delete source.
        call remove(s:sources, l:number)
    endif
endfunction"}}}
function! s:caching_enable(name)"{{{
    if a:number == ''
        let l:number = bufnr('%')
    else
        let l:number = bufnr(a:number)

        if l:number < 0
            echohl Error | echo 'Invalid buffer name.' | echohl None
            return
        endif
    endif

    if has_key(s:caching_disable_list, l:number)
        call remove(s:caching_disable_list, l:number)
    endif
endfunction"}}}
"}}}

" vim: foldmethod=marker
