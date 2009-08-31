"=============================================================================
" FILE: keyword_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 29 Aug 2009
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
" Version: 2.73, for Vim 7.0
"=============================================================================

" Important variables.
let s:sources = {}

function! neocomplcache#keyword_complete#initialize()"{{{
    augroup neocomplcache"{{{
        " Caching events
        autocmd FileType * call s:check_source()
        autocmd BufWritePost,CursorHold * call s:update_source()
        " Caching current buffer events
        autocmd InsertEnter * call s:caching_insert_enter()
        " Garbage collect.
        autocmd BufWritePost * call s:garbage_collect_keyword()
        autocmd VimLeavePre * call s:save_all_cache()
    augroup END"}}}

    if g:NeoComplCache_TagsAutoUpdate
        augroup neocomplcache
            autocmd BufWritePost * call s:update_tags()
        augroup END
    endif

    " Initialize script variables."{{{
    let s:sources = {}
    let s:rank_cache_count = 1
    let s:prev_cached_count = 0
    let s:caching_disable_list = {}
    let s:candidates = {}
    "}}}

    " Create cache directory.
    if !isdirectory(g:NeoComplCache_TemporaryDir . '/keyword_cache')
        call mkdir(g:NeoComplCache_TemporaryDir . '/keyword_cache')
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
    command! -nargs=? NeoComplCacheCachingBuffer call s:caching_buffer(<q-args>)
    command! -nargs=? NeoComplCachePrintSource call s:print_source(<q-args>)
    command! -nargs=? NeoComplCacheOutputKeyword call s:output_keyword(<q-args>)
    command! -nargs=? NeoComplCacheCreateTags call s:create_tags()
    command! -nargs=? NeoComplCacheCachingDisable call s:caching_disable(<q-args>)
    command! -nargs=? NeoComplCacheCachingEnable call s:caching_enable(<q-args>)
    "}}}

    " Initialize ctags arguments.
    if !exists('g:NeoComplCache_CtagsArgumentsList')
        let g:NeoComplCache_CtagsArgumentsList = {}
    endif
    let g:NeoComplCache_CtagsArgumentsList['default'] = ''
    let g:NeoComplCache_CtagsArgumentsList['vim'] = "'--extra=fq --fields=afmiKlnsStz '--regex-vim=/function!? ([a-z#:_0-9A-Z]+)/\\1/function/''"

    " Initialize cache.
    call s:check_source()

    " Plugin key-mappings.
    nnoremap <silent> <Plug>(neocomplcache_keyword_caching)  :<C-u>call <SID>caching(bufnr('%'), line('.'), 1, 2)<CR>
    inoremap <silent> <Plug>(neocomplcache_keyword_caching)  <C-o>:<C-u>call <SID>caching(bufnr('%'), line('.'), 1, 2)<CR>
endfunction
"}}}

function! neocomplcache#keyword_complete#finalize()"{{{
    delcommand NeoComplCacheCachingBuffer
    delcommand NeoComplCachePrintSource
    delcommand NeoComplCacheOutputKeyword
    delcommand NeoComplCacheCreateTags
    delcommand NeoComplCacheCachingDisable
    delcommand NeoComplCacheCachingEnable

    nunmap <Plug>(neocomplcache_keyword_caching)
    iunmap <Plug>(neocomplcache_keyword_caching)

    let s:sources = {}

    call s:save_all_cache()
endfunction"}}}

function! neocomplcache#keyword_complete#get_keyword_list(cur_keyword_str)"{{{
    let s:cur_keyword_len = len(a:cur_keyword_str)
    let l:keyword_escape = neocomplcache#keyword_escape(a:cur_keyword_str)

    " Keyword filter."{{{
    let l:cur_len = len(a:cur_keyword_str)
    if g:NeoComplCache_PartialMatch && !neocomplcache#skipped() && len(a:cur_keyword_str) >= g:NeoComplCache_PartialCompletionStartLength
        " Partial match.
        let l:pattern = printf("len(v:val.word) > l:cur_len && v:val.word =~ %s", string(l:keyword_escape))
    else
        " Head match.
        let l:pattern = printf("len(v:val.word) > l:cur_len && v:val.word =~ %s", string('^' . l:keyword_escape))
    endif"}}}

    let l:keyword_list = []
    for src in s:get_sources_list()
        call extend(l:keyword_list, filter(values(s:sources[src].keyword_cache), l:pattern))
    endfor
    return l:keyword_list
endfunction"}}}

function! neocomplcache#keyword_complete#calc_rank(cache_keyword_buffer_list)"{{{
    if s:cur_keyword_len < g:NeoComplCache_KeywordCompletionStartLength
        return
    endif

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
            let keyword.rank = keyword.user_rank
            for keyword_lines in values(s:sources[keyword.srcname].rank_cache_lines)
                if has_key(keyword_lines, keyword.word)
                    let keyword.rank += keyword_lines[keyword.word].rank
                endif
            endfor

            " Reset count.
            let s:rank_cache_count = (g:NeoComplCache_CalcRankRandomize)? 
                        \ reltimestr(reltime())[l:match_end : ] % l:calc_cnt + 2 : l:calc_cnt

            " Check skip time.
            if neocomplcache#check_skip_time()
                return
            endif
        endif
        let s:rank_cache_count -= 1
    endfor
endfunction"}}}

function! neocomplcache#keyword_complete#calc_prev_rank(cache_keyword_buffer_list, prev_word, prepre_word)"{{{
    " Get next keyword list.
    let [l:source_next, l:source_next_next, l:operator_list] = [{}, {}, {}]
    " Get operator keyword list.
    let l:pattern = '\v%(' .  neocomplcache#keyword_complete#current_keyword_pattern() . ')$'
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
        if l:operator != '' && has_key(s:sources[src].operator_word_list, l:operator)
            let l:operator_list[src] = s:sources[src].operator_word_list[l:operator]
        endif
    endfor

    " Calc previous rank.
    for keyword in a:cache_keyword_buffer_list
        let [keyword.prev_rank, keyword.prepre_rank] = [0, 0]
        if has_key(l:source_next, keyword.srcname)
                    \&& has_key(l:source_next[keyword.srcname], keyword.word)
            " Set prev rank.
            let keyword.prev_rank = keyword.user_rank
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
            let keyword.prepre_rank = keyword.user_rank
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

function! neocomplcache#keyword_complete#exists_current_source()"{{{
    return has_key(s:sources, bufnr('%'))
endfunction"}}}

function! neocomplcache#keyword_complete#current_keyword_pattern()"{{{
    return s:sources[bufnr('%')].keyword_pattern
endfunction"}}}

function! neocomplcache#keyword_complete#caching_percent(number)"{{{
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

function! neocomplcache#keyword_complete#caching_keyword(keyword)"{{{
    " Ignore too short keyword.
    if len(a:keyword) < g:NeoComplCache_MinKeywordLength
        return
    endif

    let l:source = s:sources[bufnr('%')]

    " Check cache.
    if !has_key(l:source.keyword_cache, a:keyword)
        " Append list.
        let l:filename = '[B] ' . fnamemodify(bufname('%'), ':t')
        let l:source.keyword_cache[a:keyword] = {
                    \'word' : a:keyword, 'menu' : printf('%.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename),
                    \'filename' : l:filename, 'srcname' : bufnr('%'), 'icase' : 1,
                    \'user_rank' : 1, 'rank' : 1
                    \}

        let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
        let l:source.keyword_cache[a:keyword].abbr = 
                    \ (len(a:keyword) > g:NeoComplCache_MaxKeywordWidth)? 
                    \ printf(l:abbr_pattern, a:keyword, a:keyword[-8:]) : a:keyword
    else
        let l:source.keyword_cache[a:keyword].user_rank += 1
    endif
endfunction"}}}

function! neocomplcache#keyword_complete#check_candidate(keyword)"{{{
    let l:source = s:sources[bufnr('%')]
    if !empty(s:candidates)
        " Garbage collect.
        let l:start_line = (line('.')-1)/l:source.cache_line_cnt*l:source.cache_line_cnt+1
        let l:end_line = l:start_line + l:source.cache_line_cnt
        call s:garbage_collect_candidate(l:start_line, l:end_line)
    endif

    " Check cache.
    if a:keyword != '' && !has_key(l:source.keyword_cache, a:keyword)
        " Append list.
        let l:filename = '[B] ' . fnamemodify(bufname('%'), ':t')
        let l:source.keyword_cache[a:keyword] = {
                    \'word' : a:keyword, 'menu' : printf('%.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename),
                    \'filename' : l:filename, 'srcname' : bufnr('%'), 'icase' : 1,
                    \'user_rank' : 1, 'rank' : 1
                    \}

        let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
        let l:source.keyword_cache[a:keyword].abbr = 
                    \ (len(a:keyword) > g:NeoComplCache_MaxKeywordWidth)? 
                    \ printf(l:abbr_pattern, a:keyword, a:keyword[-8:]) : a:keyword

        let s:candidates[a:keyword] = 1
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
        call extend(l:ft_list, split(g:NeoComplCache_SameFileTypeLists[&filetype], ','))
    endif

    " Set compound filetype.
    if l:ft =~ '\.'
        call extend(l:ft_list, split(l:ft, '\.'))
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
    let l:filename = '[B] ' . fnamemodify(l:source.name, ':t')

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
        let l:source.rank_cache_lines = {}
    endif

    " Clear cache line.
    let l:cache_line = (l:start_line-1) / l:source.cache_line_cnt
    let l:source.rank_cache_lines[l:cache_line] = {}

    " Buffer.
    let l:buflines = getbufline(a:srcname, l:start_line, l:end_line)
    let l:menu = printf('%.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:keyword_pattern = l:source.keyword_pattern

    let [l:line_cnt, l:max_lines, l:line_num] = [0, len(l:buflines), 0]
    while l:line_num < l:max_lines
        if l:line_cnt >= l:source.cache_line_cnt
            " Next cache line.
            let l:cache_line += 1
            let [l:source.rank_cache_lines[l:cache_line], l:line_cnt] = [{}, 0]
        endif

        let [l:line, l:rank_cache_line] = [buflines[l:line_num], l:source.rank_cache_lines[l:cache_line]]
        let [l:match_num, l:prev_word, l:prepre_word, l:line_max] =
                    \[0, '^', '', len(l:line) - g:NeoComplCache_MinKeywordLength]
        while 1
            let l:match = match(l:line, l:keyword_pattern, l:match_num)
            if l:match < 0
                break
            endif
            let l:match_str = matchstr(l:line, l:keyword_pattern, l:match)
            let l:match_num += len(l:match_str)

            " Ignore too short keyword.
            if len(l:match_str) >= g:NeoComplCache_MinKeywordLength
                if !has_key(l:rank_cache_line, l:match_str) 
                    let l:rank_cache_line[l:match_str] = { 'rank' : 1, 'prev_rank' : {}, 'prepre_rank' : {} }
                    let l:match_cache_line = l:rank_cache_line[l:match_str]

                    " Check dup.
                    if !has_key(l:source.keyword_cache, l:match_str)
                        " Append list.
                        let l:source.keyword_cache[l:match_str] = {
                                    \'word' : l:match_str, 'menu' : l:menu,
                                    \'filename' : l:filename, 'srcname' : a:srcname, 'icase' : 1,
                                    \'user_rank' : 0, 'rank' : 1
                                    \}

                        let l:source.keyword_cache[l:match_str].abbr = 
                                    \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                                    \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str
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

                " Check operator.
                let l:operator = matchstr(l:line[: l:match-1], '[!@#$%^&*=+|~:/.><-]\{1,2}\ze\s*$')
                if l:operator != ''
                    if !has_key(l:source.operator_word_list, l:operator)
                        let l:source.operator_word_list[l:operator] = {}
                    endif
                    let l:source.operator_word_list[l:operator][l:match_str] = 1
                endif
            endif

            if l:match_num > l:line_max
                break
            endif

            " Next match.
            let [l:prev_word, l:prepre_word] = [l:match_str, l:prev_word]
        endwhile

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
                \'keyword_cache' : {}, 'rank_cache_lines' : {},
                \'next_word_list' : {}, 'next_next_word_list' : {}, 'operator_word_list' : {},
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

    if a:srcname =~ '^\d'
        " Buffer.
        let l:filename = '[B] ' . fnamemodify(l:source.name, ':t')
    else
        " Dictionary.
        let l:filename = '[D] ' . fnamemodify(l:source.name, ':t')
    endif

    let l:menu = printf('%.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:keyword_pattern = l:source.keyword_pattern

    if a:srcname =~ '^\d'
        " Buffer.
        let l:buflines = getbufline(a:srcname, a:start_line, a:end_line)
    else
        " Dictionary.
        let l:buflines = readfile(split(a:srcname, ',')[1])
    endif
    let [l:max_lines, l:line_num] = [len(l:buflines), 0]

    if l:max_lines > 200
        redraw
        if a:srcname =~ '^\d'
            echo 'Caching buffer... please wait.'
        else
            echo 'Caching dictionary... please wait.'
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
            redraw
            echo printf('Caching: %d%%', l:line_num*100 / l:max_lines)
            let l:line_cnt = l:print_cache_percent
        endif
        let l:line_cnt -= 1

        let [l:line, l:match_num] = [buflines[l:line_num], 0]
        let l:match_str = matchstr(l:line, l:keyword_pattern)
        while l:match_str != ''
            " Ignore too short keyword.
            if len(l:match_str) >= g:NeoComplCache_MinKeywordLength
                        \&& !has_key(l:source.keyword_cache, l:match_str)
                " Append list.
                let l:source.keyword_cache[l:match_str] = {
                            \'word' : l:match_str, 'menu' : l:menu,
                            \'filename' : l:filename, 'srcname' : a:srcname, 'icase' : 1,
                            \'user_rank' : 0, 'rank' : 1
                            \}

                let l:source.keyword_cache[l:match_str].abbr = 
                            \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                            \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str
            endif

            let l:match_num += len(l:match_str)
            let l:match_str = matchstr(l:line, l:keyword_pattern, l:match_num)
        endwhile

        let l:line_num += 1
    endwhile

    if l:max_lines > 200
        redraw
        echo 'Caching done.'
    endif
endfunction"}}}

function! neocomplcache#keyword_complete#word_caching_current_line()"{{{
    let l:source = s:sources[bufnr('%')]

    " Buffer.
    let l:filename = '[B] ' . fnamemodify(l:source.name, ':t')

    let l:menu = printf('%.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:keyword_pattern = l:source.keyword_pattern

    " Buffer.
    let l:start_line = (line('.')-1)/l:source.cache_line_cnt*l:source.cache_line_cnt+1
    let l:end_line = l:start_line + l:source.cache_line_cnt
    let l:buflines = join(getbufline(bufnr('%'), l:start_line, l:end_line), "\<CR>")

    let l:match = match(l:buflines, l:keyword_pattern)
    let l:match_num = 0
    while l:match >= 0
        let l:match_str = matchstr(l:buflines, l:keyword_pattern, l:match)
        " Ignore too short keyword.
        if len(l:match_str) >= g:NeoComplCache_MinKeywordLength
                    \&& !has_key(l:source.keyword_cache, l:match_str)
            " Append list.
            let l:source.keyword_cache[l:match_str] = {
                        \'word' : l:match_str, 'menu' : l:menu,
                        \'filename' : l:filename, 'srcname' : bufnr('%'), 'icase' : 1,
                        \'user_rank' : 0, 'rank' : 1
                        \}

            let l:source.keyword_cache[l:match_str].abbr = 
                        \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                        \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str
        endif

        let l:match_num += len(l:match_str)
        let l:match = match(l:buflines, l:keyword_pattern, l:match_num)
    endwhile
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
    let l:cache_name = g:NeoComplCache_TemporaryDir . '/keyword_cache/' .
                \substitute(substitute(l:srcname, ':', '=-', 'g'), '[/\\]', '=+', 'g') . '='
    if getftime(l:cache_name) == -1 || getftime(l:cache_name) <= getftime(l:srcname)
        return -1
    endif

    let l:source = s:sources[a:srcname]

    if a:srcname =~ '^\d'
        " Buffer.
        let l:filename = '[B] ' . fnamemodify(l:source.name, ':t')
    else
        " Dictionary.
        let l:filename = '[D] ' . fnamemodify(l:source.name, ':t')
    endif

    let l:menu = printf('%.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:keyword_pattern = l:source.keyword_pattern

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

    redraw
    if l:max_lines > 1000
        if a:srcname =~ '^\d'
            echo 'Caching buffer... please wait.'
        else
            echo 'Caching dictionary... please wait.'
        endif
    endif

    let l:line_num = 0
    while l:line_num < l:max_lines
        " Percentage check.
        if l:line_cnt == 0
            redraw
            echo printf('Caching: %d%%', l:line_num*100 / l:max_lines)
            let l:line_cnt = l:print_cache_percent
        endif
        let l:line_cnt -= 1

        let l:match_str = buflines[l:line_num]
        " Ignore too short keyword.
        if len(l:match_str) >= g:NeoComplCache_MinKeywordLength
            " Append list.
            let l:source.keyword_cache[l:match_str] = {
                        \'word' : l:match_str, 'menu' : l:menu,
                        \'filename' : l:filename, 'srcname' : a:srcname, 'icase' : 1,
                        \'user_rank' : 0, 'rank' : 1
                        \}

            let l:source.keyword_cache[l:match_str].abbr = 
                        \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                        \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str
        endif

        let l:line_num += 1
    endwhile

    if l:max_lines > 1000
        redraw
        echo 'Caching done.'
    endif

    return 0
endfunction"}}}

function! s:garbage_collect_candidate(start_line, end_line)"{{{
    let l:source = s:sources[bufnr('%')]

    let l:buflines = join(getbufline(bufnr('%'), a:start_line, a:end_line), "\<CR>")
    let l:keyword_pattern = l:source.keyword_pattern

    let l:match = match(l:buflines, l:keyword_pattern)
    let l:match_num = 0
    while l:match >= 0
        let l:match_str = matchstr(l:buflines, l:keyword_pattern, l:match_num)
        if has_key(s:candidates, l:match_str)
            " Remove from candidate.
            call remove(s:candidates, l:match_str)

            if empty(s:candidates)
                return
            endif
        endif

        let l:match_num += len(l:match_str)
        let l:match = match(l:buflines, l:keyword_pattern, l:match_num)
    endwhile

    for l:candidate in keys(s:candidates)
        if has_key(l:source.keyword_cache, l:candidate)
            call remove(l:source.keyword_cache, l:candidate)
        endif
    endfor

    " Clear candidates.
    let s:candidates = {}
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

function! s:caching_insert_enter()"{{{
    if !has_key(s:sources, bufnr('%')) || has_key(s:caching_disable_list, bufnr('%')) || @. == ''
        return
    endif

    if s:prev_cached_count <= 0
        " Full caching.
        call s:caching(bufnr('%'), line('.'), 1)
        if g:NeoComplCache_CachingRandomize
            let l:match_end = matchend(reltimestr(reltime()), '\d\+\.')
            let s:prev_cached_count = reltimestr(reltime())[l:match_end : ] % 3
        else
            let s:prev_cached_count = 2
        endif
    else
        " Word caching.
        call neocomplcache#keyword_complete#word_caching_current_line()

        let s:prev_cached_count -= 1
    endif

    let s:candidates = {}
endfunction"}}}

function! s:output_keyword(number)"{{{
    if a:number == ''
        let l:number = bufnr('%')
    else
        let l:number = a:number
    endif

    if !has_key(s:sources, l:number)
        return
    endif

    " Output buffer.
    for l:word in values(s:sources[l:number].keyword_cache)
        silent put=l:word
    endfor
endfunction "}}}

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
    let l:cache_name = g:NeoComplCache_TemporaryDir . '/keyword_cache/' .
                \substitute(substitute(l:srcname, ':', '=-', 'g'), '[/\\]', '=+', 'g') . '='
    if getftime(l:cache_name) >= getftime(l:srcname)
        return -1
    endif

    " Output buffer.
    let l:word_list = []
    for keyword in values(s:sources[a:srcname].keyword_cache)
        call add(l:word_list, keyword.word)
    endfor
    call writefile(l:word_list, l:cache_name)
endfunction "}}}

function! s:save_all_cache()"{{{
    for l:key in keys(s:sources)
        call s:save_cache(l:key)
    endfor
endfunction"}}}

function! s:caching_buffer(number)"{{{
    if a:number == ''
        let l:number = bufnr('%')
    else
        let l:number = a:number
    endif

    if !has_key(s:sources, l:number)
        if buflisted(l:number)
            " Word caching.
            call s:word_caching(l:number, 1, '$')
        endif

        return
    elseif s:sources[l:number].cached_last_line >= s:sources[l:number].end_line
        return
    endif

    call s:caching_source(l:number, s:sources[l:number].cached_last_line, -1)

    " Disable auto caching.
    let s:sources[l:number].cached_last_line = s:sources[l:number].end_line+1
endfunction"}}}

function! s:caching_disable(number)"{{{
    if a:number == ''
        let l:number = bufnr('%')
    else
        let l:number = a:number
    endif

    let s:caching_disable_list[l:number] = 1

    if has_key(s:sources, l:number)
        " Delete source.
        call remove(s:sources, l:number)
    endif
endfunction"}}}

function! s:caching_enable(number)"{{{
    if a:number == ''
        let l:number = bufnr('%')
    else
        let l:number = a:number
    endif

    if has_key(s:caching_disable_list, l:number)
        call remove(s:caching_disable_list, l:number)
    endif
endfunction"}}}

function! s:update_tags()"{{{
    " Check tags are exists.
    if !has_key(s:sources, bufnr('%')) || !has_key(s:sources[bufnr('%')], 'ctagsed_lines')
        return
    endif

    let l:max_line = line('$')
    if abs(l:max_line - s:sources[bufnr('%')].ctagsed_lines) > l:max_line / 20
        if has_key(g:NeoComplCache_CtagsArgumentsList, &filetype)
            let l:args = g:NeoComplCache_CtagsArgumentsList[&filetype]
        else
            let l:args = g:NeoComplCache_CtagsArgumentsList['default']
        endif
        call system(printf('ctags -f %s %s -a %s', expand('%:p:h') . '/tags', l:args, expand('%')))
        let s:sources[bufnr('%')].ctagsed_lines = l:max_line
    endif
endfunction"}}}

function! s:create_tags()"{{{
    if &buftype =~ 'nofile' || !neocomplcache#keyword_complete#exists_current_source()
        return
    endif

    " Create tags.
    if has_key(g:NeoComplCache_CtagsArgumentsList, &filetype)
        let l:args = g:NeoComplCache_CtagsArgumentsList[&filetype]
    else
        let l:args = g:NeoComplCache_CtagsArgumentsList['default']
    endif

    let l:ltags = expand('%:p:h') . '/tags'
    call system(printf('ctags -f %s %s -a %s', expand('%:h') . '/tags', l:args, expand('%')))
    let s:sources[bufnr('%')].ctagsed_lines = line('$')
endfunction"}}}

function! s:garbage_collect_keyword()"{{{
    if !neocomplcache#keyword_complete#exists_current_source()
                \|| neocomplcache#keyword_complete#caching_percent('') != 100
        return
    endif

    let l:keywords = s:sources[bufnr('%')].keyword_cache
    for l:key in keys(l:keywords)
        if l:keywords[l:key].rank == 0
            let keyword = l:keywords[l:key]
            " Calc rank.
            for keyword_lines in values(s:sources[keyword.srcname].rank_cache_lines)
                if has_key(keyword_lines, keyword.word)
                    let keyword.rank += keyword_lines[keyword.word].rank
                endif
            endfor

            if keyword.rank == 0
                " Delete keyword.
                call remove(l:keywords, l:key)
            endif
        endif
    endfor
endfunction"}}}

" For debug command.
function! s:print_source(number)"{{{
    if a:number == ''
        let l:number = bufnr('%')
    else
        let l:number = a:number
    endif

    if !has_key(s:sources, l:number)
        return
    endif

    silent put=printf('Print neocomplcache %d source.', l:number)
    for l:key in keys(s:sources[l:number])
        silent put =printf('%s => %s', l:key, string(s:sources[l:number][l:key]))
    endfor
endfunction"}}}

" vim: foldmethod=marker
