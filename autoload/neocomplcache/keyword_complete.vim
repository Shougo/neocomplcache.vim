"=============================================================================
" FILE: keyword_complete.vim
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
" Version: 2.33, for Vim 7.0
"=============================================================================

function! neocomplcache#keyword_complete#initialize()"{{{
    augroup neocomplecache"{{{
        " Caching events
        autocmd BufEnter,BufWritePost,CursorHold * call s:update_source(2, 6)
        autocmd BufAdd * call s:check_source(3)
        " Caching current buffer events
        autocmd InsertEnter * call s:caching_cache_line()
        " Garbage collect.
        autocmd BufWritePost * call s:garbage_collect()
    augroup END"}}}

    if g:NeoComplCache_TagsAutoUpdate
        augroup neocomplecache
            autocmd BufWritePost * call s:update_tags()
        augroup END
    endif

    " Initialize"{{{
    let s:sources = {}
    let s:rank_cache_count = 1
    let s:prev_cached_count = 0
    "}}}

    " Initialize dictionary and tags."{{{
    if !exists('g:NeoComplCache_DictionaryFileTypeLists')
        let g:NeoComplCache_DictionaryFileTypeLists = {}
    endif
    if !has_key(g:NeoComplCache_DictionaryFileTypeLists, 'default')
        let g:NeoComplCache_DictionaryFileTypeLists['default'] = ''
    endif
    if !exists('g:NeoComplCache_DictionaryBufferLists')
        let g:NeoComplCache_DictionaryBufferLists = {}
    endif
    " For test.
    "let g:NeoComplCache_DictionaryFileTypeLists['vim'] = 'CSApprox.vim,LargeFile.vim'
    "let g:NeoComplCache_DictionaryBufferLists[1] = '256colors2.pl'"}}}

    " Add commands."{{{
    command! -nargs=? NeoCompleCacheCachingBuffer call s:caching_buffer(<q-args>)
    command! -nargs=0 NeoCompleCacheCachingDictionary call s:caching_dictionary()
    command! -nargs=* -complete=file NeoCompleCacheSetBufferDictionary call s:set_buffer_dictionary(<q-args>)
    command! -nargs=? NeoCompleCachePrintSource call s:print_source(<q-args>)
    command! -nargs=? NeoCompleCacheOutputKeyword call s:output_keyword(<q-args>)
    command! -nargs=? NeoCompleCacheCreateTags call s:create_tags()
    "}}}

    " Initialize ctags arguments.
    if !exists('g:NeoComplCache_CtagsArgumentsList')
        let g:NeoComplCache_CtagsArgumentsList = {}
    endif
    let g:NeoComplCache_CtagsArgumentsList['default'] = ''

    " Initialize cache.
    call s:check_source(3)
endfunction"}}}

function! neocomplcache#keyword_complete#finalize()"{{{
    delcommand NeoCompleCacheCachingBuffer
    delcommand NeoCompleCacheCachingDictionary
    delcommand NeoCompleCacheSetBufferDictionary
    delcommand NeoCompleCachePrintSource
    delcommand NeoCompleCacheOutputKeyword
    delcommand NeoCompleCacheCreateTags
endfunction"}}}

function! neocomplcache#keyword_complete#get_keyword_list(cur_keyword_str)"{{{
    let l:keyword_escape = neocomplcache#keyword_escape(a:cur_keyword_str)

    " Keyword filter."{{{
    let l:cur_len = len(a:cur_keyword_str)
    if g:NeoComplCache_PartialMatch && !neocomplcache#skipped() && len(a:cur_keyword_str) >= g:NeoComplCache_PartialCompletionStartLength
        " Partial match.
        let l:pattern = printf("len(v:val.word) > l:cur_len && v:val.word =~ '%s'", l:keyword_escape)
    else
        " Head match.
        let l:pattern = printf("len(v:val.word) > l:cur_len && v:val.word =~ '^%s'", l:keyword_escape)
    endif"}}}

    let l:keyword_list = []
    for src in s:get_sources_list()
        call extend(l:keyword_list, filter(values(s:sources[src].keyword_cache), l:pattern))
    endfor
    return l:keyword_list
endfunction"}}}

function! neocomplcache#keyword_complete#calc_rank(cache_keyword_buffer_list)"{{{
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
        if !has_key(keyword, 'rank') || s:rank_cache_count <= 0
            " Set rank.
            let keyword.rank = 0
            for keyword_lines in values(s:sources[keyword.srcname].rank_cache_lines)
                if has_key(keyword_lines, keyword.word)
                    let keyword.rank += keyword_lines[keyword.word].rank
                endif
            endfor
        endif

        if s:rank_cache_count <= 0
            " Reset count.
            let s:rank_cache_count = (g:NeoComplCache_CalcRankRandomize)? 
                        \ reltimestr(reltime())[l:match_end : ] % l:calc_cnt + 1 : l:calc_cnt

            if g:NeoComplCache_EnableInfo
                " Create info.
                let keyword.info = join(keyword.info_list, "\n")
            endif
        else
            let s:rank_cache_count -= 1
        endif
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
        if !empty(a:prepre_word) && has_key(s:sources[src].next_next_word_list, a:prepre_word)
            let l:source_next_next[src] = s:sources[src].next_next_word_list[a:prepre_word]
        endif
        if !empty(l:operator) && has_key(s:sources[src].operator_word_list, l:operator)
            let l:operator_list[src] = s:sources[src].operator_word_list[l:operator]
        endif
    endfor

    " Calc previous rank.
    for keyword in a:cache_keyword_buffer_list
        let [keyword.prev_rank, keyword.prepre_rank] = [0, 0]
        if has_key(l:source_next, keyword.srcname)
                    \&& has_key(l:source_next[keyword.srcname], keyword.word)
            " Set prev rank.
            for keyword_lines in values(s:sources[keyword.srcname].rank_cache_lines)
                if has_key(keyword_lines, keyword.word)
                            \&& has_key(keyword_lines[keyword.word].prev_rank, a:prev_word)
                    let keyword.prev_rank += keyword_lines[keyword.word].prev_rank[a:prev_word]
                endif
            endfor
            let keyword.prev_rank = keyword.prev_rank * 12
        endif
        if has_key(l:source_next_next, keyword.srcname)
                    \&& has_key(l:source_next_next[keyword.srcname], keyword.word)
            " Set prepre rank.
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
    if empty(a:number)
        let l:number = bufnr('%')
    else
        let l:number = a:number
    endif
    if !has_key(s:sources, l:number)
        return 0
    elseif s:sources[l:number].cached_last_line >= s:sources[l:number].end_line
        return 100
    else
        return s:sources[l:number].cached_last_line*100 / s:sources[l:number].end_line
    endif
endfunction"}}}

function! s:get_sources_list()"{{{
    " Set buffer filetype.
    if empty(&filetype)
        let l:ft = 'nothing'
    else
        let l:ft = &filetype
    endif

    " Check dictionaries are exists.
    if !empty(&filetype) && has_key(g:NeoComplCache_DictionaryFileTypeLists, &filetype)
        let l:ft_dict = '^' . l:ft
    elseif !empty(g:NeoComplCache_DictionaryFileTypeLists['default'])
        let l:ft_dict = '^default'
    else
        " Dummy pattern.
        let l:ft_dict = '^$'
    endif

    if has_key(g:NeoComplCache_DictionaryBufferLists, bufnr('%'))
        let l:buf_dict = '^dict:' . bufnr('%')
    else
        " Dummy pattern.
        let l:buf_dict = '^$'
    endif

    let l:sources_list = []
    for key in keys(s:sources)
        if (key =~ '^\d' && l:ft == s:sources[key].filetype)
                    \|| key =~ l:ft_dict || key =~ l:buf_dict 
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
        if !empty(l:t) && has_key(g:NeoComplCache_DictionaryFileTypeLists, l:t)
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
        " Initialize source.
        call s:initialize_source(a:srcname)
    elseif a:srcname =~ '^\d' && s:check_changed_buffer(a:srcname)
        " Initialize source if bufname changed.
        call s:initialize_source(a:srcname)
        return
    endif

    let l:source = s:sources[a:srcname]
    if a:srcname =~ '^\d'
        " Buffer.
        
        if empty(l:source.name)
            let l:filename = '[NoName]'
        else
            let l:filename = l:source.name
        endif

        let l:is_dictionary = 0
    else
        " Dictionary.
        if a:srcname =~ '^dict:'
            let l:prefix = '[B] '
            let l:is_dictionary = 0
        else
            let l:prefix = '[F] '
            let l:is_dictionary = 1
        endif
        let l:filename = l:prefix . fnamemodify(l:source.name, ':t')
    endif

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

    if a:srcname =~ '^\d'
        " Buffer.
        let l:buflines = getbufline(a:srcname, l:start_line, l:end_line)
    else
        if l:end_line == '$'
            let l:end_line = l:source.end_line
        endif
        " Dictionary.
        let l:buflines = readfile(l:source.name)[l:start_line : l:end_line]
    endif
    let l:menu = printf(' %.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
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
        let [l:match_num, l:prev_word, l:prepre_word, l:info_line, l:line_max] =
                    \[0, '^', '', substitute(l:line, '^\s\+', '', '')[:100],
                    \ len(l:line) - g:NeoComplCache_MinKeywordLength]
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
                                    \'filename' : l:filename, 'srcname' : a:srcname, 'info_list' : [l:info_line]
                                    \}

                        let l:source.keyword_cache[l:match_str].abbr_save = 
                                    \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                                    \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str
                    endif
                else
                    let l:match_cache_line = l:rank_cache_line[l:match_str]
                    let l:match_cache_line.rank += 1

                    if len(l:source.keyword_cache[l:match_str].info_list) < g:NeoComplCache_MaxInfoList
                        cal add(l:source.keyword_cache[l:match_str].info_list, l:info_line)
                    endif
                endif

                " Calc previous keyword rank.
                if !l:is_dictionary
                    if !empty(l:prepre_word)
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
                endif

                " Check operator.
                let l:operator = matchstr(l:line[: l:match-1], '[!@#$%^&*(=+\\|`~[{:;/?.><-]\{1,2}\ze\s*$')
                if !empty(l:operator)
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
            let l:cache_line_cnt = g:NeoComplCache_CacheLineCount / 15
        endif
        "echo cnt
        "echo l:cache_line_cnt

        let l:ft = getbufvar(a:srcname, '&filetype')
        if empty(l:ft)
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
        if empty(l:keyword_pattern)
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

function! s:check_changed_buffer(bufname)"{{{
    let l:ft = getbufvar(a:bufname, '&filetype')
    if empty(l:ft)
        let l:ft = 'nothing'
    endif

    return s:sources[a:bufname].name != fnamemodify(bufname(a:bufname), ':t')
                \ || s:sources[a:bufname].filetype != l:ft
endfunction"}}}

function! s:caching_source(srcname, start_line, end_cache_cnt)"{{{
    if !has_key(s:sources, a:srcname)
        " Initialize source.
        call s:initialize_source(a:srcname)
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

function! s:check_source(caching_num)"{{{
    call s:check_deleted_buffer()

    let l:bufnumber = 1
    let l:caching_num = 0

    let l:ft_dicts = []
    call add(l:ft_dicts, 'default')

    " Check new buffer.
    while l:bufnumber <= bufnr('$')
        if buflisted(l:bufnumber)
            if !has_key(s:sources, l:bufnumber)
                " Caching.
                call s:caching_source(l:bufnumber, '^', a:caching_num)

                " Check buffer dictionary.
                if has_key(g:NeoComplCache_DictionaryBufferLists, l:bufnumber)
                    let l:dict_lists = split(g:NeoComplCache_DictionaryBufferLists[l:bufnumber], ',')
                    for dict in l:dict_lists
                        let l:dict_name = printf('dict:%s,%s', l:bufnumber, dict)
                        if !has_key(s:sources, l:dict_name) && filereadable(dict)
                            " Caching.
                            call s:caching_source(l:dict_name, '^', a:caching_num)
                        endif
                    endfor
                endif
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
        if !empty(l:ft_dict)
            for dict in split(g:NeoComplCache_DictionaryFileTypeLists[l:ft_dict], ',')
                let l:dict_name = printf('%s,%s', l:ft_dict, dict)
                if !has_key(s:sources, l:dict_name) && filereadable(dict)
                    " Caching.
                    call s:caching_source(l:dict_name, '^', a:caching_num)
                endif
            endfor
        endif
    endfor
endfunction"}}}
function! s:update_source(caching_num, caching_max)"{{{
    let l:caching_num = 0
    for source_name in keys(s:sources)
        " Lazy caching.
        let name = (source_name =~ '^\d')? str2nr(source_name) : source_name

        if s:caching_source(name, '^', a:caching_num) == 0
            let l:caching_num += a:caching_num

            if l:caching_num >= a:caching_max
                break
            endif
        endif
    endfor

    " Caching current cache line.
    if !has_key(s:sources, bufnr('%'))
        " Initialize source.
        call s:initialize_source(bufnr('%'))   
    endif
    call s:caching(bufnr('%'), line('.'), 1)
endfunction"}}}
function! s:check_deleted_buffer()"{{{
    " Check deleted buffer.
    for key in keys(s:sources)
        if key =~ '^\d' && !buflisted(str2nr(key))
            " Remove item.
            call remove(s:sources, key)
        endif
    endfor
endfunction"}}}

function! s:caching_cache_line()"{{{
    if !has_key(s:sources, bufnr('%'))
        " Initialize source.
        call s:initialize_source(bufnr('%'))   
    endif

    let l:source = s:sources[bufnr('%')]
    let l:start_line = (line('.')-1)/l:source.cache_line_cnt*l:source.cache_line_cnt+1
    let l:cache_line = (l:start_line-1) / l:source.cache_line_cnt
    if !has_key(l:source.rank_cache_lines, l:cache_line) || !s:prev_cached_count
        call s:caching(bufnr('%'), line('.'), 1)
        if g:NeoComplCache_CachingRandomize
            let l:match_end = matchend(reltimestr(reltime()), '\d\+\.') + 1
            let s:prev_cached_count = reltimestr(reltime())[l:match_end : ] % 3
        else
            let s:prev_cached_count = 1
        endif
    else
        let s:prev_cached_count = 0
    endif
endfunction"}}}

function! s:output_keyword(number)"{{{
    if empty(a:number)
        let l:number = bufnr('%')
    else
        let l:number = a:number
    endif

    if !has_key(s:sources, l:number)
        return
    endif

    let l:keyword_dict = {}
    let l:prev_word = {}
    let l:prepre_word = {}
    for keyword in values(s:sources[l:number].keyword_cache)
        if has_key(keyword, 'rank')
            let l:keyword_dict[keyword.word] = { 'word' : keyword.word, 'rank' : keyword.rank, }
        else
            let l:keyword_dict[keyword.word] = { 'word' : keyword.word, 'rank' : 0, }
        endif
        if has_key(keyword, 'prev_word')
            let l:prev_word[keyword.word] = keyword.prev_word
        endif
        if has_key(keyword, 'prepre_word')
            let l:prepre_word[keyword.word] = keyword.prepre_word
        endif
    endfor

    " Output buffer.
    let l:keywords = []
    for dict in sort(values(l:keyword_dict), 'neocomplcache#compare_rank')
        call add(l:keywords, printf('$ %s %s' , dict.word, dict.rank))
    endfor
    for prevs_key in keys(l:prev_word)
        for prev in keys(l:prev_word[prevs_key])
            if prev == '^' 
                call add(l:keywords, printf('%s', prevs_key))
            else
                call add(l:keywords, printf('%s %s', prev, prevs_key))
            endif
        endfor
    endfor
    for prevs_key in keys(l:prepre_word)
        for prev in keys(l:prepre_word[prevs_key])
            if prev == '^' 
                call add(l:keywords, printf('x %s', prevs_key))
            else
                call add(l:keywords, printf('%s x %s', prev, prevs_key))
            endif
        endfor
    endfor

    for l:word in l:keywords
        silent put=l:word
    endfor
endfunction "}}}

function! s:set_buffer_dictionary(files)"{{{
    let l:files = substitute(substitute(a:files, '\\\s', ';', 'g'), '\s\+', ',', 'g')
    silent execute printf("let g:NeoComplCache_DictionaryBufferLists[%d] = '%s'", 
                \bufnr('%') , substitute(l:files, ';', ' ', 'g'))
    " Caching.
    call s:check_source(3)
endfunction "}}}

function! s:caching_buffer(number)"{{{
    if empty(a:number)
        let l:number = bufnr('%')
    else
        let l:number = a:number
    endif
    call s:caching_source(l:number, 1, -1)

    " Disable auto caching.
    let s:sources[l:number].cached_last_line = s:sources[l:number].end_line+1

    " Calc rank.
    call neocomplcache#get_complete_words('')
endfunction"}}}

function! s:caching_dictionary()"{{{
    " Create source.
    call neocomplcache#keyword_complete#check_source(3)

    " Check dictionaries are exists.
    if !empty(&filetype) && has_key(g:NeoComplCache_DictionaryFileTypeLists, &filetype)
        let l:ft_dict = '^' . &filetype
    elseif !empty(g:NeoComplCache_DictionaryFileTypeLists['default'])
        let l:ft_dict = '^default'
    else
        " Dummy pattern.
        let l:ft_dict = '^$'
    endif
    if has_key(g:NeoComplCache_DictionaryBufferLists, bufnr('%'))
        let l:buf_dict = '^dict:' . bufnr('%')
    else
        " Dummy pattern.
        let l:buf_dict = '^$'
    endif
    let l:cache_keyword_buffer_filtered = []
    for key in keys(s:sources)
        if key =~ l:ft_dict || key =~ l:buf_dict
            call s:caching_source(key, '^', -1)

            " Disable auto caching.
            let s:sources[key].cached_last_line = s:sources[key].end_line+1
        endif
    endfor
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

function! s:garbage_collect()"{{{
    if !neocomplcache#keyword_complete#exists_current_source()
                \|| neocomplcache#keyword_complete#caching_percent('') != 100
        return
    endif

    let l:keywords = s:sources[bufnr('%')].keyword_cache
    for l:key in keys(l:keywords)
        if has_key(l:keywords[l:key], 'rank') && l:keywords[l:key].rank < 2
            " Delete keyword.
            call remove(l:keywords, l:key)
        endif
    endfor
endfunction"}}}

" For debug command.
function! s:print_source(number)"{{{
    if empty(a:number)
        let l:number = bufnr('%')
    else
        let l:number = a:number
    endif

    silent put=printf('Print neocomplcache %d source.', l:number)
    for l:key in keys(s:sources[l:number])
        silent put =printf('%s => %s', l:key, string(s:sources[l:number][l:key]))
    endfor
endfunction"}}}

" vim: foldmethod=marker
