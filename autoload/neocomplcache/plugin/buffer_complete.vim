"=============================================================================
" FILE: buffer_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 01 Feb 2010
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
" Version: 4.08, for Vim 7.0
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

    " Initialize script variables."{{{
    let s:sources = {}
    let s:rank_cache_count = 1
    let s:caching_disable_list = {}
    let s:completion_length = neocomplcache#get_completion_length('buffer_complete')
    let s:prev_frequencies = {}
    "}}}

    " Create cache directory.
    if !isdirectory(g:NeoComplCache_TemporaryDir . '/buffer_cache')
        call mkdir(g:NeoComplCache_TemporaryDir . '/buffer_cache', 'p')
    endif

    " Add commands."{{{
    command! -nargs=? -complete=buffer NeoComplCacheCachingBuffer call s:caching_buffer(<q-args>)
    command! -nargs=? -complete=buffer NeoComplCachePrintSource call s:print_source(<q-args>)
    command! -nargs=? -complete=buffer NeoComplCacheOutputKeyword call s:output_keyword(<q-args>)
    command! -nargs=? -complete=buffer NeoComplCacheSaveCache call s:save_all_cache()
    command! -nargs=? -complete=buffer NeoComplCacheCachingDisable call s:caching_disable(<q-args>)
    command! -nargs=? -complete=buffer NeoComplCacheCachingEnable call s:caching_enable(<q-args>)
    "}}}

    " Initialize cache.
    call s:check_source()
endfunction
"}}}

function! neocomplcache#plugin#buffer_complete#finalize()"{{{
    delcommand NeoComplCacheCachingBuffer
    delcommand NeoComplCachePrintSource
    delcommand NeoComplCacheOutputKeyword
    delcommand NeoComplCacheSaveCache
    delcommand NeoComplCacheCachingDisable
    delcommand NeoComplCacheCachingEnable

    call s:save_all_cache()
    
    let s:sources = {}
endfunction"}}}

function! neocomplcache#plugin#buffer_complete#get_keyword_list(cur_keyword_str)"{{{
    let l:keyword_list = []

    let l:current = bufnr('%')
    if len(a:cur_keyword_str) < s:completion_length ||
                \neocomplcache#check_match_filter(a:cur_keyword_str, s:completion_length)
        for src in s:get_sources_list()
            let l:keyword_cache = neocomplcache#keyword_filter(
                        \neocomplcache#unpack_dictionary_dictionary(s:sources[src].keyword_cache), a:cur_keyword_str)
            if src == l:current
                call s:calc_frequency(l:keyword_cache)
                call s:calc_prev_frequencies(l:keyword_cache, a:cur_keyword_str)
            endif
            let l:keyword_list += l:keyword_cache
        endfor
    else
        let l:key = tolower(a:cur_keyword_str[: s:completion_length-1])
        for src in s:get_sources_list()
            if has_key(s:sources[src].keyword_cache, l:key)
                let l:keyword_cache = values(s:sources[src].keyword_cache[l:key])
                if len(a:cur_keyword_str) != s:completion_length
                    let l:keyword_cache = neocomplcache#keyword_filter(l:keyword_cache, a:cur_keyword_str)
                endif
                
                if src == l:current
                    call s:calc_frequency(l:keyword_cache)
                    call s:calc_prev_frequencies(l:keyword_cache, a:cur_keyword_str)
                endif
                
                let l:keyword_list += l:keyword_cache
            endif
        endfor
    endif

    return l:keyword_list
endfunction"}}}

function! neocomplcache#plugin#buffer_complete#get_frequencies()"{{{
    if !neocomplcache#plugin#buffer_complete#exists_current_source()
        return {}
    endif

    return s:sources[bufnr('%')].frequencies
endfunction"}}}
function! neocomplcache#plugin#buffer_complete#get_prev_frequencies()"{{{
    if !neocomplcache#plugin#buffer_complete#exists_current_source()
        return {}
    endif
    
    return s:prev_frequencies
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

function! s:calc_frequency(list)"{{{
    if !neocomplcache#plugin#buffer_complete#exists_current_source() || g:NeoComplCache_AlphabeticalOrder
        return
    endif
    
    let l:list_len = len(a:list)

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

    let l:source = s:sources[bufnr('%')]
    for keyword in a:list
        if s:rank_cache_count <= 0
            " Set rank.
            let l:frequencies = l:source.frequencies
            let l:word = keyword.word
            let l:frequencies[l:word] = 0
            for cache_lines in values(l:source.cache_lines)
                if has_key(cache_lines.keywords, l:word)
                    let l:frequencies[l:word] += cache_lines.keywords[l:word].rank
                endif
            endfor

            " Reset count.
            let s:rank_cache_count = (g:NeoComplCache_EnableRandomize)? 
                        \ neocomplcache#rand(l:calc_cnt) : l:calc_cnt
        endif

        let s:rank_cache_count -= 1
    endfor
endfunction"}}}
function! s:calc_prev_frequencies(list, cur_keyword_str)"{{{
    if !neocomplcache#plugin#buffer_complete#exists_current_source() || g:NeoComplCache_AlphabeticalOrder
        return
    endif

    let l:prev_word = neocomplcache#get_prev_word(a:cur_keyword_str)
    
    " Get next keyword list.
    let l:source = s:sources[bufnr('%')]
    let l:source_next = has_key(l:source.next_word_list, l:prev_word)? 
                \ l:source.next_word_list[l:prev_word] : {}

    let s:prev_frequencies = {}
    " Calc previous rank.
    for keyword in a:list
        let l:word = keyword.word
        if has_key(l:source_next, l:word)
            " Set prev rank.
            let s:prev_frequencies[l:word] = 0
            for cache_lines in values(l:source.cache_lines)
                if has_key(cache_lines.keywords, l:word)
                            \&& has_key(cache_lines.keywords[l:word].prev_rank, l:prev_word)
                    let s:prev_frequencies[l:word] += cache_lines.keywords[l:word].prev_rank[l:prev_word]
                endif
            endfor
            let s:prev_frequencies[l:word] = s:prev_frequencies[l:word] * 20
        endif
    endfor
endfunction"}}}

function! s:update_source()"{{{
    let l:caching_num = 0
    for source_name in keys(s:sources)
        " Lazy caching.
        if s:caching_source(str2nr(source_name), '^', 2) == 0
            let l:caching_num += 2

            if l:caching_num >= 6
                break
            endif
        endif
    endfor
endfunction"}}}

function! s:get_sources_list()"{{{
    let l:sources_list = []
    
    let l:filetypes = neocomplcache#get_source_filetypes(&filetype)
    for key in keys(s:sources)
        if has_key(l:filetypes, s:sources[key].filetype)
            call add(l:sources_list, key)
        endif
    endfor

    return l:sources_list
endfunction"}}}

function! s:caching(srcname, start_line, end_cache_cnt)"{{{
    " Check exists s:sources.
    if !has_key(s:sources, a:srcname)
        call s:word_caching(a:srcname)
    endif

    let l:source = s:sources[a:srcname]
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
        let l:source.cache_lines = {}
    endif

    " Clear cache line.
    let l:cache_num = (l:start_line-1) / l:source.cache_line_cnt
    let l:source.cache_lines[l:cache_num] = { 'keywords' : {} }

    let l:buflines = getbufline(a:srcname, l:start_line, l:end_line)
    let l:menu = printf('[B] %.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:keyword_pattern = l:source.keyword_pattern

    let [l:line_cnt, l:max_lines, l:line_num] = [0, len(l:buflines), 0]
    while l:line_num < l:max_lines
        if l:line_cnt >= l:source.cache_line_cnt
            " Next cache line.
            let l:cache_num += 1
            let [l:source.cache_lines[l:cache_num], l:line_cnt] = [{ 'keywords' : {} }, 0]
        endif

        let [l:line, l:keywords] = [buflines[l:line_num], l:source.cache_lines[l:cache_num].keywords]
        let [l:match_num, l:prev_word, l:match] = [0, '^', match(l:line, l:keyword_pattern)]

        while l:match >= 0"{{{
            let l:match_str = matchstr(l:line, l:keyword_pattern, l:match)

            " Ignore too short keyword.
            if len(l:match_str) >= g:NeoComplCache_MinKeywordLength"{{{
                if !has_key(l:keywords, l:match_str) 
                    let l:keywords[l:match_str] = { 'rank' : 1, 'prev_rank' : {} }
                    let l:line_keyword = l:keywords[l:match_str]

                    " Check dup.
                    let l:key = tolower(l:match_str[: s:completion_length-1])
                    if !has_key(l:source.keyword_cache, l:key)
                        let l:source.keyword_cache[l:key] = {}
                    endif
                    
                    if !has_key(l:source.keyword_cache[l:key], l:match_str)
                        " Append list.
                        let l:keyword = {
                                    \'word' : l:match_str, 'menu' : l:menu,
                                    \'icase' : 1, 'rank' : 1
                                    \}

                        let l:keyword.abbr = 
                                    \ (len(l:match_str) > g:NeoComplCache_MaxKeywordWidth)? 
                                    \ printf(l:abbr_pattern, l:match_str, l:match_str[-8:]) : l:match_str

                        let l:source.keyword_cache[l:key][l:match_str] = l:keyword
                    endif
                else
                    let l:line_keyword = l:keywords[l:match_str]
                    let l:line_keyword.rank += 1
                endif

                " Calc previous keyword rank.
                if !has_key(l:source.next_word_list, l:prev_word)
                    let l:source.next_word_list[l:prev_word] = {}
                    let l:source.next_word_list[l:prev_word][l:match_str] = 1
                elseif !has_key(l:source.next_word_list[l:prev_word], l:match_str)
                    let l:source.next_word_list[l:prev_word][l:match_str] = 1
                endif

                if has_key(l:line_keyword.prev_rank, l:prev_word)
                    let l:line_keyword.prev_rank[l:prev_word] += 1
                else
                    let l:line_keyword.prev_rank[l:prev_word] = 1
                endif
            endif"}}}

            let l:match_num = l:match + len(l:match_str)

            " Next match.
            let [l:prev_word, l:match] = [l:match_str, match(l:line, l:keyword_pattern, l:match_num)]
        endwhile"}}}

        let l:line_num += 1
        let l:line_cnt += 1
    endwhile
endfunction"}}}

function! s:initialize_source(srcname)"{{{
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

    let l:ft = getbufvar(a:srcname, '&filetype')
    if l:ft == ''
        let l:ft = 'nothing'
    endif

    let l:keyword_pattern = neocomplcache#get_keyword_pattern(l:ft)

    let s:sources[a:srcname] = {
                \'keyword_cache' : {}, 'cache_lines' : {}, 'next_word_list' : {}, 
                \'name' : l:filename, 'filetype' : l:ft, 'keyword_pattern' : l:keyword_pattern, 
                \'end_line' : l:end_line , 'cached_last_line' : 1, 'cache_line_cnt' : l:cache_line_cnt, 
                \'frequencies' : {}
                \}
endfunction"}}}

function! s:word_caching(srcname)"{{{
    " Initialize source.
    call s:initialize_source(a:srcname)

    if s:caching_from_cache(a:srcname) == 0
        " Caching from cache.
        return
    endif

    let l:source = s:sources[a:srcname]

    let l:filename = fnamemodify(bufname(str2nr(a:srcname)), ':p')

    for l:keyword in neocomplcache#cache#load_from_file(l:filename, l:source.keyword_pattern, 'B')
        let l:key = tolower(l:keyword.word[: s:completion_length-1])
        if !has_key(l:source.keyword_cache, l:key)
            let l:source.keyword_cache[l:key] = {}
        endif
        let l:source.keyword_cache[l:key][l:keyword.word] = l:keyword
    endfor"}}}
endfunction"}}}

function! s:caching_from_cache(srcname)"{{{
    if getbufvar(a:srcname, '&buftype') =~ 'nofile'
        return -1
    endif

    let l:srcname = fnamemodify(bufname(str2nr(a:srcname)), ':p')
    
    if neocomplcache#cache#check_old_cache('buffer_cache', l:srcname)
        return -1
    endif

    let l:source = s:sources[a:srcname]
    for l:keyword in neocomplcache#cache#load_from_cache('buffer_cache', l:srcname)
        let l:key = tolower(l:keyword.word[: s:completion_length-1])
        if !has_key(l:source.keyword_cache, l:key)
            let l:source.keyword_cache[l:key] = {}
        endif
        
        let l:source.keyword_cache[l:key][l:keyword.word] = l:keyword
    endfor 

    return 0
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
        if a:srcname == bufnr('%')
            " Update endline.
            let l:source.end_line = line('$')
        endif
        
        " Check overflow.
        if l:start_line > l:source.end_line && !s:check_changed_buffer(a:srcname)
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
    call s:check_deleted_buffer()
    call s:garbage_collect(bufnr('%'))
    
    let l:bufnumber = 1

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
                call s:word_caching(l:bufnumber)
            endif
        endif

        let l:bufnumber += 1
    endwhile
endfunction"}}}
function! s:check_deleted_buffer()"{{{
    " Check deleted buffer.
    for key in keys(s:sources)
        if !buflisted(str2nr(key))
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

    " Full caching.
    call s:caching(bufnr('%'), line('.'), 1)
endfunction"}}}

function! s:save_cache(srcname)"{{{
    if s:sources[a:srcname].end_line < 500
        return
    endif

    if getbufvar(a:srcname, '&buftype') =~ 'nofile'
        return
    endif

    let l:srcname = fnamemodify(bufname(str2nr(a:srcname)), ':p')
    if !filereadable(l:srcname)
        return
    endif
    
    let l:cache_name = neocomplcache#cache#encode_name('buffer_cache', l:srcname)
    if getftime(l:cache_name) >= getftime(l:srcname)
        return -1
    endif

    call s:garbage_collect(a:srcname)

    " Output buffer.
    call neocomplcache#cache#save_cache('buffer_cache', l:srcname, neocomplcache#unpack_dictionary_dictionary(s:sources[a:srcname].keyword_cache))
endfunction "}}}
function! s:save_all_cache()"{{{
    for l:key in keys(s:sources)
        call s:save_cache(l:key)
    endfor
endfunction"}}}
function! s:garbage_collect(srcname)"{{{
    " Garbage collect.
    if neocomplcache#plugin#buffer_complete#caching_percent(a:srcname) == 100
        let l:source = s:sources[a:srcname]
        for [l:word, l:frequency] in items(l:source.frequencies)
            if l:frequency == 0
                " Calc frequency.
                for cache_lines in values(l:source.cache_lines)
                    if has_key(cache_lines.keywords, l:word)
                        let l:frequency += cache_lines.keywords[l:word].rank
                    endif
                endfor
                
                if l:frequency == 0
                    " Delete.
                    let l:key = tolower(l:word[: s:completion_length-1])
                    "echomsg l:word
                    if has_key(l:source.keyword_cache[l:key], l:word)
                        call remove(l:source.keyword_cache[l:key], l:word)
                        call remove(l:source.frequencies, l:word)
                    endif
                else
                    let l:source.frequencies[l:word] = l:frequency
                endif
            endif
        endfor
    endif
endfunction"}}}

" Command functions."{{{
function! s:caching_buffer(name)"{{{
    if a:name == ''
        let l:number = bufnr('%')
    else
        let l:number = bufnr(a:name)

        if l:number < 0
            call neocomplcache#print_error('Invalid buffer name.')
            return
        endif
    endif

    if !has_key(s:sources, l:number)
        if buflisted(l:number)
            " Word caching.
            call s:word_caching(l:number)
        endif

        return
    elseif s:sources[l:number].cached_last_line >= s:sources[l:number].end_line
        " Word recaching.
        call s:word_caching(l:number)
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
            call neocomplcache#print_error('Invalid buffer name.')
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
    if a:name == ''
        let l:number = bufnr('%')
    else
        let l:number = bufnr(a:name)

        if l:number < 0
            call neocomplcache#print_error('Invalid buffer name.')
            return
        endif
    endif

    if !has_key(s:sources, l:number)
        return
    endif

    " Output buffer.
    for keyword in neocomplcache#unpack_dictionary_dictionary(s:sources[l:number].keyword_cache)
        silent put=string(keyword)
    endfor
endfunction "}}}
function! s:caching_disable(name)"{{{
    if a:number == ''
        let l:number = bufnr('%')
    else
        let l:number = bufnr(a:name)

        if l:number < 0
            call neocomplcache#print_error('Invalid buffer name.')
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
            call neocomplcache#print_error('Invalid buffer name.')
            return
        endif
    endif

    if has_key(s:caching_disable_list, l:number)
        call remove(s:caching_disable_list, l:number)
    endif
endfunction"}}}
"}}}

" vim: foldmethod=marker
