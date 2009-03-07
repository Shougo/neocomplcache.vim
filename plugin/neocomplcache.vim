"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 07 Mar 2009
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
" Version: 1.52, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.52:
"     - Fixed syntax keyword bug.
"     - Improved syntax keyword.
"     - Implemented similar completion.
"   1.51:
"     - Added g:NeoComplCache_PartialCompletionStartLength option.
"     - Fixed syntax keyword bug.
"   1.50:
"     - Deleted g:NeoComplCache_CompleteFuncLists.
"     - Set filetype 'nothing' if filetype is empty.
"     - Implemented omni completion.
"     - Added debug command.
"     - Improved syntax keyword.
"   1.49:
"     - Fixed g:NeoComplCache_MFUDirectory error.
"     - Changed g:NeoComplCache_KeywordPatterns['default'] value.
"   1.48:
"     - Implemented NeoCompleCacheSetBufferDictionary command.
"     - Implemented 2-gram MFU.
"     - Improved syntax completion.
"     - Fixed "complete from same filetype buffer" bug.
"   1.47:
"     - Implemented 2-gram completion.
"     - Improved ruby keyword.
"   1.46:
"     - Complete from same filetype buffer.
"   1.45:
"     - Fixed g:NeoComplCache_MFUDirectory bug.
"     - Improved syntax keyword.
"     - Deleted g:NeoComplCache_FirstCurrentBufferWords option.
"     - Implemented previous keyword completion.
"   1.44:
"     - Improved most frequently used dictionary.
"     - Improved if bufname changed.
"     - Restore wildcard substitution '.\+' into '.*'.
"     - Fixed next keyword completion bug.
"   1.43:
"     - Refactoring when caching source.
"     - Initialize source if bufname changed.
"     - Implemented most frequently used dictionary.
"   1.42:
"     - Caching when InsertLeave event.
"     - Changed g:NeoComplCache_CacheLineCount value.
"     - Changed wildcard substitution '.*' into '.\+'.
"     - Allow word's tail '*' if g:NeoComplCache_EnableAsterisk.
"     - Allow word's head '*' on lisp.
"     - Allow word's head '&' on perl.
"     - Optimized global options definition.
"   1.41:
"     - Added g:NeoComplCache_SmartCase option.
"     - Optimized on completion and caching.
"     - Fixed g:NeoComplCache_ManualCompleteFunc bug.
"   1.40:
"     - Fixed freeze bug when many - inputed.
"     - Improved next keyword completion.
"     - Improved caching.
"     - Fixed next keyword completion bug.
"   1.39:
"     - Fixed filename completion bug.
"     - Fixed dup bug.
"     - Implemented next keyword completion.
"   1.38:
"     - Fixed PHP completion bug.
"     - Improved filetype detection.
"     - Added space between keyword and file name.
"     - Implemented randomize rank calculation.
"     - Added g:NeoComplCache_CalcRankRandomize option.
"   1.37:
"     - Improved file complete.
"     - Fixed file complete bug.
"   1.36:
"     - Added g:NeoComplCache_FirstHeadMatching option.
"     - Fixed list order bug.
"     - Changed g:NeoComplCache_QuickMatchMaxLists default value.
"     - Optimized when buffer renamed.
"   1.35:
"     - Improved syntax complete.
"     - Improved NeoCompleCacheToggle.
"   1.34:
"     - Fixed g:NeoComplCache_FirstCurrentBufferWords bug.
"     - Fixed quick match bug.
"     - Not change lazyredraw.
"   1.33:
"     - Added g:NeoComplCache_QuickMatchMaxLists option.
"     - Changed g:NeoComplCache_QuickMatch into g:NeoComplCache_QuickMatchEnable.
"     - Implemented two digits quick match.
"   1.32:
"     - Improved completion cancel.
"     - Improved syntax keyword vim, sh, zsh, vimshell.
"     - Implemented g:NeoComplCache_NonBufferFileTypeDetect option.
"   1.31:
"     - Added g:NeoComplCache_MinKeywordLength option.
"     - Caching keyword_pattern.
"     - Fixed current buffer filtering bug.
"     - Fixed rank calculation bug.
"     - Optimized keyword caching.
"     - Fixed lazyredraw bug.
"   1.30:
"     - Added NeoCompleCachingTags, NeoCompleCacheDictionary command.
"     - Renamed NeoCompleCachingBuffer command.
"   1.29:
"     - Added NeoCompleCacheLock, NeoCompleCacheUnlock command.
"     - Dup check when quick match.
"     - Fixed error when manual complete.
"   1.28:
"     - Improved filetype detection.
"     - Changed g:NeoComplCache_MaxFilenameWidth default value.
"     - Improved list.
"   1.27:
"     - Improved syntax keyword.
"     - Improved calc rank timing.
"     - Fixed keyword filtering bug.
"   1.26:
"     - Ignore if dictionary file doesn't exists.
"     - Due to optimize, filtering len(cur_keyword_str) >.
"     - Auto complete when InsertEnter.
"   1.25:
"     - Exclude cur_keyword_str from keyword lists.
"   1.24:
"     - Due to optimize, filtering len(cur_keyword_str) >=.
"     - Fixed buffer dictionary bug.
"   1.23:
"     - Fixed on lazyredraw bug.
"     - Optimized when no dictionary and tags.
"     - Not echo calculation time.
"   1.22:
"     - Optimized source.
"   1.21:
"     - Fixed overwrite completefunc bug.
"   1.20:
"     - Implemented buffer dictionary.
"   1.10:
"     - Implemented customizable complete function.
"   1.00:
"     - Renamed.
"     - Initial version.
" ChangeLog AltAutoComplPop: "{{{
"   2.62:
"     - Set lazyredraw at auto complete.
"     - Added g:AltAutoComplPop_CalcRankMaxLists option.
"     - Improved calc rank timing.
"     - Improved filetype check.
"   2.61:
"     - Improved keyword patterns.
"     - Changed g:AltAutoComplPop_CacheLineCount default value.
"     - Implemented :Neco command.
"   2.60:
"     - Cleanuped code.
"     - Show '[T]' or '[D]' at completing.
"     - Implemented tab pages tags completion.
"     - Fixed error when tab created.
"     - Changed g:AltAutoComplPop_CalcRankCount default value.
"   2.50:
"     - Implemented filetype dictionary completion.
"   2.14:
"     - Fixed 'Undefined Variable: s:cur_keyword_pos' bug.
"     - Implemented tags completion.
"   2.13:
"     - Added g:AltAutoComplPop_DictionaryLists option.
"     - Implemented dictionary completion.
"   2.12:
"     - Added g:AltAutoComplPop_CalcRankCount option.
"   2.11:
"     - Added g:AltAutoComplPop_SlowCompleteSkip option.
"     - Removed g:AltAutoComplPop_OptimiseLevel option.
"   2.10:
"     - Added g:AltAutoComplPop_QuickMatch option.
"     - Changed g:AltAutoComplPop_MaxList default value.
"     - Don't cache help file.
"   2.09:
"     - Added g:AltAutoComplPop_EnableAsterisk option.
"     - Fixed next cache line cleared bug.
"   2.08:
"     - Added g:AltAutoComplPop_OptimiseLevel option.
"       If list has many keyword, will optimise complete. 
"     - Added g:AltAutoComplPop_DisableAutoComplete option.
"   2.07:
"     - Fixed caching miss when BufRead.
"   2.06:
"     - Improved and customizable keyword patterns.
"   2.05:
"     - Added g:AltAutoComplPop_DeleteRank0 option.
"     - Implemented lazy caching.
"     - Cleanuped code.
"   2.04:
"     - Fixed caching bug.
"   2.03:
"     - Fixed rank calculation bug.
"   2.02:
"     - Fixed GVim problem at ATOK X3
"   2.01:
"     - Fixed rank calculation bug.
"     - Faster at caching.
"   2.0:
"     - Implemented Updates current buffer cache at InsertEnter.
"   1.13:
"     - Licence changed.
"     - Fix many bugs.
"   1.1:
"     - Implemented smart completion.
"       It works in vim, c, cpp, ruby, ...
"     - Implemented file completion.
"   1.0:
"     - Initial version.
""}}}
"
" }}}
"-----------------------------------------------------------------------------
" TODO: "{{{
"     - Load plugin.
""}}}
" Bugs"{{{
"     - Nothing.
""}}}
"=============================================================================

if exists('g:loaded_neocomplcache') || v:version < 700
  finish
endif

let s:disable_neocomplcache = 1

let s:NeoComplCache = {}

command! -nargs=0 NeoCompleCacheEnable call s:NeoComplCache.Enable()
command! -nargs=0 NeoCompleCacheDisable call s:NeoComplCache.Disable()
command! -nargs=0 NeoCompleCacheToggle call s:NeoComplCache.Toggle()

function! s:NeoComplCache.Complete()"{{{
    if pumvisible() || &paste || s:complete_lock || g:NeoComplCache_DisableAutoComplete
                \|| &l:completefunc != 'g:NeoComplCache_ManualCompleteFunc'
        return
    endif

    " Get cursor word.
    let l:cur_text = strpart(getline('.'), 0, col('.') - 1) 
    " Prevent infinity loop.
    if l:cur_text == s:old_text
        return
    endif
    let s:old_text = l:cur_text

    " Not complete multi byte character for ATOK X3.
    if char2nr(l:cur_text[-1]) >= 0x80
        return
    endif

    if exists('&l:omnifunc') && !empty(&l:omnifunc) 
                \&& has_key(g:NeoComplCache_OmniPatterns, &filetype)
                \&& !empty(g:NeoComplCache_OmniPatterns[&filetype])
        if l:cur_text =~ g:NeoComplCache_OmniPatterns[&filetype] . '$'
            call feedkeys("\<C-x>\<C-o>\<C-p>", 'n')
            return
        endif
    endif

    let l:pattern = s:source[bufnr('%')].keyword_pattern . '$'
    let l:cur_keyword_pos = match(l:cur_text, l:pattern)
    let l:cur_keyword_str = matchstr(l:cur_text, l:pattern)
    "echo l:cur_keyword_str

    if g:NeoComplCache_EnableAsterisk
        " Check *.
        let [l:cur_keyword_pos, l:cur_keyword_str] = s:CheckAsterisk(l:cur_text, l:pattern, l:cur_keyword_pos, l:cur_keyword_str)
    endif

    if l:cur_keyword_pos < 0 || len(cur_keyword_str) < g:NeoComplCache_KeywordCompletionStartLength
        " Try filename completion.
        "
        let l:PATH_SEPARATOR = (has('win32') || has('win64')) ? '/\\' : '/'
        " Filename pattern.
        "let l:pattern = printf('\f[%s]\f\{%d,}$', l:PATH_SEPARATOR, g:NeoComplCache_FilenameCompletionStartLength)
        let l:pattern = printf('[/~]\=\f\+[%s]\f*$', l:PATH_SEPARATOR)
        " Not Filename pattern.
        let l:exclude_pattern = '[*/\\][/\\]\f*$\|[^[:print:]]\f*$'

        " Check filename completion.
        if match(l:cur_text, l:pattern) >= 0 && match(l:cur_text, l:exclude_pattern) < 0
                    \ && len(matchstr(l:cur_text, l:pattern)) >= g:NeoComplCache_KeywordCompletionStartLength
            call feedkeys("\<C-x>\<C-f>\<C-p>", 'n')
        endif

        return
    endif

    " Save options.
    let s:ignorecase_save = &l:ignorecase

    " Set function.
    let &l:completefunc = 'g:NeoComplCache_AutoCompleteFunc'

    " Extract complete words.
    if g:NeoComplCache_SmartCase && l:cur_keyword_str =~ '\u'
        let &l:ignorecase = 0
    else
        let &l:ignorecase = g:NeoComplCache_IgnoreCase
    endif

    let s:complete_words = g:NeoComplCache_NormalComplete(l:cur_keyword_str)

    " Prevent filcker.
    if empty(s:complete_words)
        " Restore options
        let &l:completefunc = 'g:NeoComplCache_ManualCompleteFunc'
        let &l:ignorecase = s:ignorecase_save

        return
    endif

    " Lock auto complete.
    let s:complete_lock = 1

    " Start original complete.
    let s:cur_keyword_pos = l:cur_keyword_pos
    let s:cur_keyword_str = l:cur_keyword_str
    call feedkeys("\<C-x>\<C-u>\<C-p>", 'n')
endfunction"}}}

function! s:CheckAsterisk(cur_text, pattern, cur_keyword_pos, cur_keyword_str)"{{{
    let l:cur_keyword_pos = a:cur_keyword_pos
    let l:cur_keyword_str = a:cur_keyword_str

    while l:cur_keyword_pos > 1 && a:cur_text[l:cur_keyword_pos - 1] == '*'
        let l:left_text = strpart(a:cur_text, 0, l:cur_keyword_pos - 1) 
        let l:left_keyword_str = matchstr(l:left_text, a:pattern)

        let l:cur_keyword_pos = match(l:left_text, a:pattern)
        let l:cur_keyword_str = l:left_keyword_str . '*' . l:cur_keyword_str
    endwhile

    return [l:cur_keyword_pos, l:cur_keyword_str]
endfunction"}}}

function! g:NeoComplCache_AutoCompleteFunc(findstart, base)"{{{
    if a:findstart
        return s:cur_keyword_pos
    endif

    " Prevent multiplex call.
    if !s:complete_lock
        return []
    endif

    " Restore options.
    let &l:completefunc = 'g:NeoComplCache_ManualCompleteFunc'
    let &l:ignorecase = s:ignorecase_save
    " Unlock auto complete.
    let s:complete_lock = 0

    return s:complete_words
endfunction"}}}

function! g:NeoComplCache_ManualCompleteFunc(findstart, base)"{{{
    if a:findstart
        " Get cursor word.
        let l:cur = col('.') - 1
        let l:cur_text = strpart(getline('.'), 0, l:cur)

        let l:pattern = s:source[bufnr('%')].keyword_pattern . '$'
        let l:cur_keyword_pos = match(l:cur_text, l:pattern)
        if l:cur_keyword_pos < 0
            return -1
        endif
        let l:cur_keyword_str = matchstr(l:cur_text, l:pattern)

        if g:NeoComplCache_EnableAsterisk
            " Check *.
            let [l:cur_keyword_pos, l:cur_keyword_str] = s:CheckAsterisk(l:cur_text, l:pattern, l:cur_keyword_pos, l:cur_keyword_str)
        endif
        
        return l:cur_keyword_pos
    endif

    " Save options.
    let l:ignorecase_save = &l:ignorecase

    " Complete.
    if g:NeoComplCache_SmartCase && a:base =~ '\u'
        let &l:ignorecase = 0
    else
        let &l:ignorecase = g:NeoComplCache_IgnoreCase
    endif

    let l:complete_words = g:NeoComplCache_NormalComplete(a:base)

    " Restore options.
    let &l:ignorecase = l:ignorecase_save

    return l:complete_words
endfunction"}}}

" RankOrder.
function! s:CompareRank(i1, i2)
    return a:i1.rank < a:i2.rank ? 1 : a:i1.rank == a:i2.rank ? 0 : -1
endfunction
" AlphabeticalOrder.
function! s:CompareWords(i1, i2)
    return a:i1.word > a:i2.word ? 1 : a:i1.word == a:i2.word ? 0 : -1
endfunction
" PrevWordRankOrder.
function! s:ComparePrevWordRank(i1, i2)
    if has_key(a:i1.prev_rank, s:prev_word) && has_key(a:i2.prev_rank, s:prev_word)
        return a:i1.prev_rank[s:prev_word] < a:i2.prev_rank[s:prev_word] ? 1 
                    \: a:i1.prev_rank[s:prev_word] == a:i2.prev_rank[s:prev_word] ? 0 : -1
    else
        return a:i1.rank < a:i2.rank ? 1 : a:i1.rank == a:i2.rank ? 0 : -1
    endif
endfunction

function! s:CalcLeven(str1, str2)"{{{
    let [l:p1, l:p2, l:l1, l:l2] = [[], [], len(a:str1), len(a:str2)]

    for l:i in range(l:l2+1) 
        call add(l:p1, l:i)
    endfor 
    for l:i in range(l:l2+1) 
        call add(l:p2, 0)
    endfor 

    for l:i in range(l:l1)
        let l:p2[0] = l:p1[0] + 1
        for l:j in range(l:l2)
            let l:p2[l:j+1] = min([l:p1[l:j] + ((a:str1[l:i] == a:str2[l:j]) ? 0 : 1), 
                        \l:p1[l:j+1] + 1, l:p2[l:j]+1])
        endfor
        let [l:p1, l:p2] = [l:p2, l:p1]
    endfor

    return l:p1[l:l2]
endfunction"}}}

function! s:NormalComplete_GetKeywordList()"{{{
    " Check dictionaries and tags are exists.
    if !empty(&filetype) && has_key(g:NeoComplCache_DictionaryFileTypeLists, &filetype)
        let l:ft_dict = '^' . &filetype
    elseif !empty(g:NeoComplCache_DictionaryFileTypeLists['default'])
        let l:ft_dict = '^default'
    else
        " Dummy pattern.
        let l:ft_dict = '^$'
    endif
    if has_key(g:NeoComplCache_TagsLists, tabpagenr())
        let l:tags = '^tags:' . tabpagenr()
    elseif !empty(g:NeoComplCache_TagsLists['default'])
        let l:tags = '^tags:default'
    else
        " Dummy pattern.
        let l:tags = '^$'
    endif
    if has_key(g:NeoComplCache_DictionaryBufferLists, bufnr('%'))
        let l:buf_dict = '^dict:' . bufnr('%')
    else
        " Dummy pattern.
        let l:buf_dict = '^$'
    endif
    if g:NeoComplCache_EnableMFU
        let l:mfu_dict = '^mfu:' . &filetype
    else
        " Dummy pattern.
        let l:mfu_dict = '^$'
    endif

    " Set buffer filetype.
    if empty(&filetype)
        let l:ft = 'nothing'
    else
        let l:ft = &filetype
    endif

    let l:keyword_list = []
    for key in keys(s:source)
        if (key =~ '^\d' && l:ft == s:source[key].filetype)
                    \|| key =~ l:ft_dict || key =~ l:tags || key =~ l:buf_dict || key =~ l:mfu_dict
            call extend(l:keyword_list, values(s:source[key].keyword_cache))
        endif
    endfor

    return l:keyword_list
endfunction"}}}

function! g:NeoComplCache_NormalComplete(cur_keyword_str)"{{{
    if g:NeoComplCache_SlowCompleteSkip && &l:completefunc == 'g:NeoComplCache_AutoCompleteFunc'
        let l:start_time = reltime()
    endif

    if g:NeoComplCache_EnableAsterisk
        let l:keyword_escape = substitute(substitute(escape(a:cur_keyword_str, '" \ . ^ $'), "'", "''", 'g'), '\*', '.*', 'g')
        "let l:keyword_escape = substitute(substitute(escape(a:cur_keyword_str, '" \ . ^ $'), "'", "''", 'g'), '\*', '.\\+', 'g')
    else
        let l:keyword_escape = escape(substitute(a:cur_keyword_str, '" \ . ^ $ *'), "'", "''", 'g')
    endif

    " Keyword filter.
    if g:NeoComplCache_PartialMatch && len(a:cur_keyword_str) >= g:NeoComplCache_PartialCompletionStartLength
        " Partial match.
        " Filtering len(a:cur_keyword_str).
        let l:pattern = printf("len(v:val.word) > %d && v:val.word =~ '%s'", len(a:cur_keyword_str), l:keyword_escape)
        let l:is_partial = 1
    else
        " Normal match.
        " Filtering len(a:cur_keyword_str).
        let l:pattern = printf("len(v:val.word) > %d && v:val.word =~ '^%s'", len(a:cur_keyword_str), l:keyword_escape)
        let l:is_partial = 0
    endif

    let l:all_keyword_list = s:NormalComplete_GetKeywordList()
    let l:cache_keyword_buffer_list = filter(copy(l:all_keyword_list), l:pattern)
    
    " Similar filter.
    if g:NeoComplCache_SimilarMatch && len(a:cur_keyword_str) >= g:NeoComplCache_SimilarCompletionStartLength
        let l:threthold = len(a:cur_keyword_str) / 3
        if l:is_partial
            let l:pattern = printf("%d <= len(v:val.word) && len(v:val.word) <= %d && v:val.word !~ '%s' && s:CalcLeven(v:val.word, a:cur_keyword_str) <= %d",
                        \len(a:cur_keyword_str)-l:threthold, len(a:cur_keyword_str)+l:threthold, l:keyword_escape, l:threthold)
        else
            let l:pattern = printf("%d <= len(v:val.word) && len(v:val.word) <= %d && v:val.word !~ '^%s' && s:CalcLeven(v:val.word, a:cur_keyword_str) <= %d",
                        \len(a:cur_keyword_str)-l:threthold, len(a:cur_keyword_str)+l:threthold, l:keyword_escape, l:threthold)
            let l:is_partial = 1
        endif
        call extend(l:cache_keyword_buffer_list, filter(l:all_keyword_list, l:pattern))
    endif

    if g:NeoComplCache_AlphabeticalOrder 
        " Not calc rank.
        let l:order_func = 's:CompareWords'
    else
        " Calc rank."{{{
        let l:menu_pattern = ' %.' . g:NeoComplCache_MaxFilenameWidth . 's %3d'
        let l:list_len = len(l:cache_keyword_buffer_list)

        if l:list_len > g:NeoComplCache_CalcRankMaxLists
            let l:calc_cnt = 5
        elseif l:list_len > g:NeoComplCache_CalcRankMaxLists / 2
            let l:calc_cnt = 4
        elseif l:list_len > g:NeoComplCache_CalcRankMaxLists / 4
            let l:calc_cnt = 3
        else
            let l:calc_cnt = 2
        endif

        if g:NeoComplCache_CalcRankRandomize
            let l:match_end = matchend(reltimestr(reltime()), '\d\+\.') + 1
        endif
        for keyword in l:cache_keyword_buffer_list
            if !has_key(keyword, 'rank') || s:rank_cache_count <= 0
                " Reset count.
                if g:NeoComplCache_CalcRankRandomize
                    let [s:rank_cache_count, keyword.rank] = [reltimestr(reltime())[l:match_end : ] % l:calc_cnt, 0]
                else 
                    let [s:rank_cache_count, keyword.rank] = [l:calc_cnt, 0]
                endif

                " Set rank.
                for keyword_lines in values(s:source[keyword.srcname].rank_cache_lines)
                    if has_key(keyword_lines, keyword.word)
                        let keyword.rank += keyword_lines[keyword.word]
                    endif
                endfor
                let l:keyword_match = s:source[keyword.srcname].keyword_cache[keyword.word]
                let keyword.prev_rank = {}
                for prev_word in keys(l:keyword.prev_word)
                    let keyword.prev_rank[prev_word] = 0
                    for prev_rank_lines in values(l:keyword_match.prev_rank_lines)
                        if has_key(prev_rank_lines, prev_word)
                            let keyword.prev_rank[prev_word] += prev_rank_lines[prev_word]
                        endif
                    endfor
                endfor

                if g:NeoComplCache_DrawWordsRank
                    let keyword.menu = printf(l:menu_pattern, keyword.filename, keyword.rank)
                endif
            else
                let s:rank_cache_count -= 1
            endif
        endfor

        if g:NeoComplCache_DeleteRank0
            " Delete element if rank is 0.
            call filter(l:cache_keyword_buffer_list, 'v:val.rank > 0')
        endif

        let l:order_func = 's:CompareRank'"}}}
    endif

    if exists('l:start_time')
        "let l:end_time = split(reltimestr(reltime(l:start_time)))[0]
        if split(reltimestr(reltime(l:start_time)))[0] > '0.2'
            " Skip completion if takes too much time.
            echo 'Too many items'
            return []
        endif

        "echo l:end_time
    endif

    let l:cache_keyword_buffer_filtered = []

    " Previous keyword completion.
    if g:NeoComplCache_PreviousKeywordCompletion
        let l:keyword_pattern = s:source[bufnr('%')].keyword_pattern
        let l:line_part = strpart(getline('.'), 0, col('.')-1 - len(a:cur_keyword_str))
        let l:prev_word_end = matchend(l:line_part, l:keyword_pattern)
        if l:prev_word_end > 0
            let l:word_end = l:prev_word_end
            while l:word_end >= 0
                let l:prev_word_end = l:word_end
                let l:word_end = matchend(l:line_part, l:keyword_pattern, l:prev_word_end)
            endwhile
            let l:prev_word = matchstr(l:line_part[: l:prev_word_end-1], l:keyword_pattern . '$')
        else
            let l:prev_word = '^'
        endif
        "echo l:prev_word

        " Sort.
        let l:prev = filter(copy(l:cache_keyword_buffer_list), "has_key(v:val.prev_word, '" . l:prev_word . "')")
        if l:is_partial && g:NeoComplCache_FirstHeadMatching
            let l:partial = filter(copy(l:prev), "v:val.word =~ '^".l:keyword_escape."'")
            call extend(l:cache_keyword_buffer_filtered, sort(l:partial, l:order_func))
            call filter(l:prev, "v:val.word !~ '^".l:keyword_escape."'")
        endif
        if !g:NeoComplCache_AlphabeticalOrder
            let s:prev_word = l:prev_word
            call extend(l:cache_keyword_buffer_filtered, sort(l:prev, 's:ComparePrevWordRank'))
        else
            call extend(l:cache_keyword_buffer_filtered, sort(l:prev, l:order_func))
        endif
        call filter(l:cache_keyword_buffer_list, "!has_key(v:val.prev_word, '" . l:prev_word . "')")
    endif

    " Sort.
    " Head match filtering.
    if l:is_partial && g:NeoComplCache_FirstHeadMatching
        let l:partial = filter(copy(l:cache_keyword_buffer_list), "v:val.word =~ '^".l:keyword_escape."'")
        call extend(l:cache_keyword_buffer_filtered, sort(l:partial, l:order_func))

        call filter(l:cache_keyword_buffer_list, "v:val.word !~ '^".l:keyword_escape."'")
    endif
    call extend(l:cache_keyword_buffer_filtered, sort(l:cache_keyword_buffer_list, l:order_func))

    if g:NeoComplCache_QuickMatchEnable
        " Append numbered list.
        if match(l:keyword_escape, '\d$') >= 0
            " Get numbered list.
            let l:numbered = get(s:prev_numbered_list, str2nr(matchstr(l:keyword_escape, '\d$')))
            if type(l:numbered) == type({})
                call insert(l:cache_keyword_buffer_filtered, l:numbered)
            endif

            " Get next numbered list.
            if match(l:keyword_escape, '\d\d$') >= 0
                let l:num = str2nr(matchstr(l:keyword_escape, '\d\d$'))-10
                if l:num >= 0
                    unlet l:numbered
                    let l:numbered = get(s:prepre_numbered_list, l:num)
                    if type(l:numbered) == type({})
                        call insert(l:cache_keyword_buffer_filtered, l:numbered)
                    endif
                endif
            endif
        endif
    endif

    " Trunk too many item.
    let l:cache_keyword_buffer_filtered = l:cache_keyword_buffer_filtered[:g:NeoComplCache_MaxList-1]

    if g:NeoComplCache_QuickMatchEnable
        " Check dup.
        let l:dup_check = {}
        let l:num = 0
        let l:numbered_ret = []
        for keyword in l:cache_keyword_buffer_filtered[:g:NeoComplCache_QuickMatchMaxLists]
            if !has_key(l:dup_check, keyword.word)
                let l:dup_check[keyword.word] = 1

                call add(l:numbered_ret, keyword)
            endif
            let l:num += 1
        endfor

        " Add number.
        let l:abbr_pattern_d = '%2d: %.' . g:NeoComplCache_MaxKeywordWidth . 's'
        let l:num = 0
        for keyword in l:numbered_ret
            let keyword.abbr = printf(l:abbr_pattern_d, l:num, keyword.word)

            let l:num += 1
        endfor
        let l:abbr_pattern_n = '    %.' . g:NeoComplCache_MaxKeywordWidth . 's'
        let l:cache_keyword_buffer_filtered = l:cache_keyword_buffer_filtered[g:NeoComplCache_QuickMatchMaxLists :]
        for keyword in l:cache_keyword_buffer_filtered
            let keyword.abbr = printf(l:abbr_pattern_n, keyword.word)
        endfor

        " Append list.
        let l:cache_keyword_buffer_filtered = extend(l:numbered_ret, l:cache_keyword_buffer_filtered)

        " Save numbered lists.
        let s:prepre_numbered_list = s:prev_numbered_list[10:g:NeoComplCache_QuickMatchMaxLists-1]
        let s:prev_numbered_list = l:numbered_ret[:g:NeoComplCache_QuickMatchMaxLists-1]
    endif

    " Remove next keyword.
    let l:next_keyword_str = matchstr('a'.strpart(getline('.'), col('.')-1), '^'.s:source[bufnr('%')].keyword_pattern)[1:]
    if !empty(l:next_keyword_str)
        let l:next_keyword_str .= '$'
        let l:cache_keyword_buffer_filtered = deepcopy(l:cache_keyword_buffer_filtered[:g:NeoComplCache_MaxList-1])
        for r in l:cache_keyword_buffer_filtered
            if r.word =~ l:next_keyword_str
                let r.word = strpart(r.word, 0, match(r.word, l:next_keyword_str))
                let r.dup = 1
            endif
        endfor
    endif

    return l:cache_keyword_buffer_filtered
endfunction"}}}

function! s:NeoComplCache.Caching(srcname, start_line, end_line)"{{{
    let l:start_line = (a:start_line == '%')? line('.') : a:start_line
    let l:start_line = (l:start_line-1)/g:NeoComplCache_CacheLineCount*g:NeoComplCache_CacheLineCount+1
    let l:end_line = (a:end_line < 0)? '$' : 
                \ (l:start_line + a:end_line + g:NeoComplCache_CacheLineCount-2)/g:NeoComplCache_CacheLineCount*g:NeoComplCache_CacheLineCount

    " Check exists s:source.
    if !has_key(s:source, a:srcname)
        " Initialize source.
        call s:InitializeSource(a:srcname)
    elseif a:srcname =~ '^\d' && 
                \(s:source[a:srcname].name != fnamemodify(bufname(a:srcname), ':t')
                \||s:source[a:srcname].filetype != getbufvar(a:srcname, '&filetype'))
        " Initialize source if bufname changed.
        call s:InitializeSource(a:srcname)
        let l:start_line = 1
        if a:end_line < 0
            " Whole buffer.
            let s:source[a:srcname].cached_last_line = s:source[a:srcname].end_line + 1
        else
            let s:source[a:srcname].cached_last_line = a:end_line
        endif
    endif

    let l:source = s:source[a:srcname]
    if a:srcname =~ '^\d'
        " Buffer.
        
        if empty(l:source.name)
            let l:filename = '[NoName]'
        else
            let l:filename = l:source.name
        endif
    else
        " Dictionary or tags.
        if a:srcname =~ '^tags:'
            let l:prefix = '[T] '
        elseif a:srcname =~ '^dict:'
            let l:prefix = '[B] '
        elseif a:srcname =~ '^mfu:'
            let l:prefix = '[M] '
        else
            let l:prefix = '[F] '
        endif
        let l:filename = l:prefix . fnamemodify(l:source.name, ':t')
    endif
    let l:cache_line = (l:start_line-1) / g:NeoComplCache_CacheLineCount
    let l:line_cnt = 0

    " For debugging.
    "if l:end_line == '$'
        "echomsg printf("%s: start=%d, end=%d", l:filename, l:start_line, l:source.end_line)
    "else
        "echomsg printf("%s: start=%d, end=%d", l:filename, l:start_line, l:end_line)
    "endif

    if a:start_line == 1 && a:end_line < 0
        " Cache clear if whole buffer.
        let l:source.keyword_cache = {}
        let l:source.rank_cache_lines = {}
    endif

    " Clear cache line.
    let l:source.rank_cache_lines[l:cache_line] = {}

    if a:srcname =~ '^\d'
        " Buffer.
        let l:buflines = getbufline(a:srcname, l:start_line, l:end_line)
    else
        if l:end_line == '$'
            let l:end_line = l:source.end_line
        endif
        " Dictionary or tags.
        let l:buflines = readfile(l:source.name)[l:start_line : l:end_line]
    endif
    if !g:NeoComplCache_DrawWordsRank
        let l:menu = printf(' %.' . g:NeoComplCache_MaxFilenameWidth . 's', l:filename)
    else
        let l:menu = ''
    endif
    let l:abbr_pattern = '%.' . g:NeoComplCache_MaxKeywordWidth . 's'
    let l:keyword_pattern = l:source.keyword_pattern

    let [l:max_line, l:line_num] = [len(l:buflines), 0]
    while l:line_num < l:max_line
        if l:line_cnt >= g:NeoComplCache_CacheLineCount
            " Next cache line.
            let l:cache_line += 1
            let l:source.rank_cache_lines[l:cache_line] = {}
            let l:line_cnt = 0
        endif

        let l:line = buflines[l:line_num]
        let [l:match_num, l:match_end, l:prev_word] = [match(l:line, l:keyword_pattern), matchend(l:line, l:keyword_pattern), '']
        while l:match_num >= 0
            let l:match_str = matchstr(l:line, l:keyword_pattern, l:match_num)

            " Ignore too short keyword.
            if len(l:match_str) >= g:NeoComplCache_MinKeywordLength
                if !has_key(l:source.rank_cache_lines[l:cache_line], l:match_str) 
                    let l:source.rank_cache_lines[l:cache_line][l:match_str] = 1

                    " Check dup.
                    if !has_key(l:source.keyword_cache, l:match_str)
                        " Append list.
                        let l:source.keyword_cache[l:match_str] = { 'word' : l:match_str, 'abbr' : printf(l:abbr_pattern, l:match_str), 'menu' : l:menu,  'dup' : 0, 'filename' : l:filename, 'srcname' : a:srcname, 'prev_word' : {}, 'prev_rank' : {}, 'prev_rank_lines' : {} }
                    endif
                else
                    let l:source.rank_cache_lines[l:cache_line][l:match_str] += 1
                endif

                let l:keyword_match = l:source.keyword_cache[l:match_str]

                " Save previous keyword.
                if !empty(l:prev_word) || l:line !~ '^\$\s'
                    if empty(l:prev_word)
                        let l:prev_word = '^'
                    endif
                    let l:keyword_match.prev_word[l:prev_word] = 1

                    " Calc previous keyword.
                    if !has_key(l:keyword_match.prev_rank_lines, l:cache_line)
                        let l:keyword_match.prev_rank_lines[l:cache_line] = {}
                    endif
                    if !has_key(l:keyword_match.prev_rank_lines[l:cache_line], l:prev_word)
                        let l:keyword_match.prev_rank_lines[l:cache_line][l:prev_word] = 1
                    else
                        let l:keyword_match.prev_rank_lines[l:cache_line][l:prev_word] += 1
                    endif
                endif
            endif

            " Next match.
            let [l:match_num, l:match_end, l:prev_word] = [l:match_end, matchend(l:line, l:keyword_pattern, l:match_end), l:match_str]
        endwhile

        let l:line_num += 1
        let l:line_cnt += 1
    endwhile
endfunction"}}}

function! s:InitializeSource(srcname)"{{{
    if a:srcname =~ '^\d'
        " Buffer.
        let l:filename = fnamemodify(bufname(a:srcname), ':t')

        if a:srcname == bufnr('%')
            " Current buffer.
            let l:end_line = line('$')
        else
            let l:end_line = len(getbufline(a:srcname, 1, '$'))
        endif

        let l:ft = getbufvar(a:srcname, '&filetype')
        if empty(l:ft)
            let l:ft = 'nothing'
        endif

        if !has_key(g:NeoComplCache_KeywordPatterns, l:ft)
            let l:keyword_pattern = s:AssumePattern(bufname(a:srcname))
            if empty(l:keyword_pattern)
                " Assuming failed.
                let l:keyword_pattern = g:NeoComplCache_KeywordPatterns['default']
            endif
        else
            let l:keyword_pattern = g:NeoComplCache_KeywordPatterns[l:ft]
        endif
    else
        " Dictionary or tags.
        let l:filename = split(a:srcname, ',')[1]
        let l:end_line = len(readfile(l:filename))

        " Assuming filetype.
        if a:srcname =~ '^tags:' || a:srcname =~ '^dict:'
            " Current buffer filetype.
            let l:ft = &filetype
        elseif a:srcname =~ '^mfu:'
            " Embeded filetype.
            let l:ft = substitute(split(a:srcname, ',')[0], '^mfu:', '', '')
        else
            " Embeded filetype.
            let l:ft = split(a:srcname, ',')[0]
        endif

        let l:keyword_pattern = s:AssumePattern(split(a:srcname, ',')[1])
        if empty(l:keyword_pattern)
            " Assuming failed.
            let l:keyword_pattern = has_key(g:NeoComplCache_KeywordPatterns, l:ft)? 
                        \g:NeoComplCache_KeywordPatterns[l:ft] : g:NeoComplCache_KeywordPatterns['default']
        endif
    endif

    let s:source[a:srcname] = { 'keyword_cache' : {}, 'rank_cache_lines' : {},
                \'name' : l:filename, 'filetype' : l:ft, 'keyword_pattern' : l:keyword_pattern, 
                \'end_line' : l:end_line , 'cached_last_line' : 1 }
endfunction"}}}

function! s:NeoComplCache.CachingSource(srcname, start_line, end_line)"{{{
    if !has_key(s:source, a:srcname)
        " Initialize source.
        call s:InitializeSource(a:srcname)
    endif

    if a:start_line == '^'
        let l:source = s:source[a:srcname]

        let l:start_line = l:source.cached_last_line
        " Check overflow.
        if l:start_line > l:source.end_line && a:srcname =~ '^\d'
                    \&& fnamemodify(bufname(a:srcname), ':t') == l:source.name
            " Caching end.
            return -1
        endif

        let l:source.cached_last_line += a:end_line
    else
        let l:start_line = a:start_line
    endif

    call s:NeoComplCache.Caching(a:srcname, l:start_line, a:end_line)

    return 0
endfunction"}}}

function! s:NeoComplCache.CheckSource(caching_num)"{{{
    let l:bufnumber = 1
    let l:max_buf = bufnr('$')
    let l:caching_num = 0

    let l:ft_dicts = []
    call add(l:ft_dicts, 'default')

    " Check deleted buffer.
    for key in keys(s:source)
        if key =~ '^\d' && !buflisted(str2nr(key))
            if g:NeoComplCache_EnableMFU
                " Save MFU.
                call s:NeoComplCache.SaveMFU(key)
                return
            endif
            
            " Remove item.
            call remove(s:source, key)
        endif
    endfor

    " Check new buffer.
    while l:bufnumber <= l:max_buf
        if buflisted(l:bufnumber)
            if !has_key(s:source, l:bufnumber) ||
                        \getbufvar(l:bufnumber, '&filetype') != s:source[l:bufnumber].filetype
                " Caching.
                call s:NeoComplCache.CachingSource(l:bufnumber, '^', a:caching_num)

                " Check buffer dictionary.
                if has_key(g:NeoComplCache_DictionaryBufferLists, l:bufnumber)
                    let l:dict_lists = split(g:NeoComplCache_DictionaryBufferLists[l:bufnumber], ',')
                    for dict in l:dict_lists
                        let l:dict_name = printf('dict:%s,%s', l:bufnumber, dict)
                        if !has_key(s:source, l:dict_name) && filereadable(dict)
                            " Caching.
                            call s:NeoComplCache.CachingSource(l:dict_name, '^', a:caching_num)
                        endif
                    endfor
                endif
            endif

            if has_key(g:NeoComplCache_DictionaryFileTypeLists, getbufvar(l:bufnumber, '&filetype'))
                call add(l:ft_dicts, getbufvar(l:bufnumber, '&filetype'))
            endif

            " Check MFU.
            if g:NeoComplCache_EnableMFU
                let l:mfu_path = printf('%s/%s.mfu', g:NeoComplCache_MFUDirectory, &filetype)
                if g:NeoComplCache_EnableMFU && filereadable(l:mfu_path)
                    " Load MFU
                    let l:dict_name = printf('mfu:%s,%s', &filetype, l:mfu_path)
                    if !has_key(s:source, l:dict_name)
                        " Caching.
                        call s:NeoComplCache.CachingSource(l:dict_name, '^', a:caching_num)
                    endif
                endif
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
                if !has_key(s:source, l:dict_name) && filereadable(dict)
                    " Caching.
                    call s:NeoComplCache.CachingSource(l:dict_name, '^', a:caching_num)
                endif
            endfor
        endif
    endfor

    " Check tags.
    let l:current_tags = (has_key(g:NeoComplCache_TagsLists, tabpagenr()))? tabpagenr() : 'default'
    " Ignore if empty.
    if !empty(l:current_tags)
        let l:tags_lists = split(g:NeoComplCache_TagsLists[l:current_tags], ',')
        for tags in l:tags_lists
            let l:tags_name = printf('tags:%d,%s', l:current_tags, tags)
            if !has_key(s:source, l:tags_name) && filereadable(tags)
                " Caching.
                call s:NeoComplCache.CachingSource(l:tags_name, '^', a:caching_num)
            endif
        endfor
    endif
endfunction"}}}
function! s:NeoComplCache.UpdateSource(caching_num, caching_max)"{{{
    let l:caching_num = 0
    for source_name in keys(s:source)
        " Lazy caching.
        let name = (source_name =~ '^\d')? str2nr(source_name) : source_name

        if s:NeoComplCache.CachingSource(name, '^', a:caching_num) == 0
            let l:caching_num += a:caching_num

            if l:caching_num > a:caching_max
                return
            endif
        endif
    endfor
endfunction"}}}

function! s:NeoComplCache.SaveAllMFU()"{{{
    if !g:NeoComplCache_EnableMFU
        return
    endif

    for key in keys(s:source)
        if key =~ '^\d'
            call s:NeoComplCache.SaveMFU(key)
        endif
    endfor
endfunction "}}}
function! s:NeoComplCache.SaveMFU(key)"{{{
    let l:ft = getbufvar(str2nr(a:key), '&filetype')
    if !empty(l:ft)
        let l:mfu_dict = {}
        let l:prev_word = {}
        let l:mfu_path = printf('%s/%s.mfu', g:NeoComplCache_MFUDirectory, l:ft)
        if filereadable(l:mfu_path)
            for line in readfile(l:mfu_path)
                let l = split(line)
                if len(line) == 3 
                    if line =~ '^$ '
                        let l:mfu_dict[l[1]] = { 'word' : l[1], 'rank' : l[2], 'found' : 0 }
                    else
                        if !has_key(l:prev_word, l[1])
                            let l:prev_word[l[1]] = {}
                        endif
                        let l:prev_word[l[1]][l[0]] = l[2]
                    endif
                elseif len(line) == 2
                    if !has_key(l:prev_word, l[0])
                        let l:prev_word[l[0]] = {}
                    endif
                    let l:prev_word[l[0]]['^'] = l[1]
                endif
            endfor
        endif
        for keyword in values(s:source[a:key].keyword_cache)
            if has_key(keyword, 'rank') && keyword.rank*2 >= g:NeoComplCache_MFUThreshold
                if !has_key(l:mfu_dict, keyword.word) || keyword.rank > l:mfu_dict[keyword.word].rank
                    let l:mfu_dict[keyword.word] = { 'word' : keyword.word, 'rank' : keyword.rank*2, 'found' : 1 }
                endif

                if has_key(keyword, 'prev_rank') && !has_key(l:prev_word, keyword.word) 
                    let l:prev_word[keyword.word] = keyword.prev_rank
                endif
            elseif has_key(l:mfu_dict, keyword.word)
                " Found.
                let l:mfu_dict[keyword.word].found = 1

                if has_key(keyword, 'prev_rank') && !has_key(l:prev_word, keyword.word) 
                    let l:prev_word[keyword.word] = keyword.prev_rank
                endif
            endif
        endfor

        if s:source[a:key].end_line > 100
            " Reduce rank if word is not found.
            for key in keys(l:mfu_dict)
                if !l:mfu_dict[key].found
                    " rank *= 0.9
                    let l:mfu_dict[key].rank -= l:mfu_dict[key].rank / 10
                    if l:mfu_dict[key].rank < g:NeoComplCache_MFUThreshold
                        " Delete word.
                        call remove(l:mfu_dict, key)
                        call remove(l:prev_word, key)
                    endif
                endif
            endfor
        endif

        " Save MFU.
        let l:mfu_word = []
        for dict in sort(values(l:mfu_dict), 's:CompareRank')
            call add(l:mfu_word, printf('$ %s %s' , dict.word, dict.rank))
        endfor
        for prevs_key in keys(l:prev_word)
            for prev in keys(l:prev_word[prevs_key])
                if prev == '^' 
                    call add(l:mfu_word, printf('%s %s', prevs_key, l:prev_word[prevs_key]['^']))
                else
                    call add(l:mfu_word, printf('%s %s %s', prev, prevs_key,  l:prev_word[prevs_key][prev]))
                endif
            endfor
        endfor
        call writefile(l:mfu_word[: g:NeoComplCache_MFUMax-1], l:mfu_path)
    endif
endfunction "}}}

function! s:NeoComplCache.SetBufferDictionary(files)"{{{
    silent execute printf("let g:NeoComplCache_DictionaryBufferLists[%d] = '%s'", bufnr('%') , a:files)
endfunction "}}}

" Assume filetype pattern.
function! s:AssumePattern(bufname)"{{{
    " Extract extention.
    let l:ext = fnamemodify(a:bufname, ':e')
    if empty(l:ext)
        let l:ext = fnamemodify(a:bufname, ':t')
    endif

    if has_key(g:NeoComplCache_NonBufferFileTypeDetect, l:ext)
        return g:NeoComplCache_NonBufferFileTypeDetect[l:ext]
    elseif has_key(g:NeoComplCache_KeywordPatterns, l:ext)
        return g:NeoComplCache_KeywordPatterns[l:ext]
    else
        " Not found.
        return ''
    endif
endfunction "}}}
function! s:SetKeywordPattern(filetype, pattern)"{{{
    for ft in split(a:filetype, ',')
        if !has_key(g:NeoComplCache_KeywordPatterns, a:filetype) 
            let g:NeoComplCache_KeywordPatterns[ft] = a:pattern
        endif
    endfor
endfunction"}}}

function! s:SetOmniPattern(filetype, pattern)"{{{
    for ft in split(a:filetype, ',')
        if !has_key(g:NeoComplCache_OmniPatterns, a:filetype) 
            let g:NeoComplCache_OmniPatterns[ft] = a:pattern
        endif
    endfor
endfunction"}}}

function! s:NeoComplCache.Enable()"{{{
    augroup NeoCompleCache"{{{
        autocmd!
        " Caching events
        autocmd BufEnter,BufWritePost,CursorHold * call s:NeoComplCache.UpdateSource(g:NeoComplCache_CacheLineCount*10, 
                    \ g:NeoComplCache_CacheLineCount*30)
        autocmd Filetype * call s:NeoComplCache.CheckSource(g:NeoComplCache_CacheLineCount*10)
        " Caching current buffer events
        autocmd InsertEnter * call s:NeoComplCache.Caching(bufnr('%'), '%', g:NeoComplCache_CacheLineCount*2)
        autocmd InsertLeave * call s:NeoComplCache.Caching(bufnr('%'), '%', g:NeoComplCache_CacheLineCount)
        " Auto complete events
        autocmd CursorMovedI,InsertEnter * call s:NeoComplCache.Complete()
        " MFU events.
        autocmd VimLeavePre * call s:NeoComplCache.SaveAllMFU()
    augroup END"}}}

    " Initialize"{{{
    let s:complete_lock = 0
    let s:old_text = ''
    let s:source = {}
    let s:prev_numbered_list = []
    let s:rank_cache_count = 1
    "}}}

    " Initialize keyword pattern match like intellisense."{{{
    if !exists('g:NeoComplCache_KeywordPatterns')
        let g:NeoComplCache_KeywordPatterns = {}
    endif
    call s:SetKeywordPattern('default', '\k\+')
    call s:SetKeywordPattern('lisp,scheme', 
                \'(\=[[:alpha:]*/@$%^&_=<>~.][[:alnum:]+*/@$%^&_=<>~.-]*[!?]\=')
    call s:SetKeywordPattern('ruby', '\([:@]\{1,2}\h\w*\|[.$]\=\h\w*[!?(]\=\)')
    call s:SetKeywordPattern('php', '\(\$\|->\|::\)\=\h\w*(\=')
    call s:SetKeywordPattern('perl',
                \'\(<\h\w*>\=\|->\h\w*(\=\|::\h\w*\|[$@%&*]\h\w*\|\h\w*(\=\)')
    call s:SetKeywordPattern('vim', '\([.$]\h\w*(\=\|&\=\h[[:alnum:]#_:]*(\=\)')
    call s:SetKeywordPattern('tex', '\(\\[[:alpha:]_@][[:alnum:]_@]*\*\=[[{]\=\|\h\w*\)')
    call s:SetKeywordPattern('sh,zsh,vimshell', '\($\w\+\|[[:alpha:]_.-][[:alnum:]_.-]*(\=\)')
    call s:SetKeywordPattern('ps1', '\($\w\+\|[[:alpha:]_.-][[:alnum:]_.-]*(\=\)')
    call s:SetKeywordPattern('c', '\([[:alpha:]_#]\w*\|\.\h\w*(\=\)')
    call s:SetKeywordPattern('cpp', '\(->\|::\|[.#]\)\=\h\w*[(<]\=')
    call s:SetKeywordPattern('d', '\.\=\h\w*!\=(\=')
    call s:SetKeywordPattern('python', '\.\=\h\w*(\=')
    call s:SetKeywordPattern('cs,java,javascript', '\.\=\h\w*(\=')
    call s:SetKeywordPattern('awk', '\h\w*(\=')
    call s:SetKeywordPattern('haskell', '\.\=\h\w*')
    call s:SetKeywordPattern('ocaml', "[.#]\\=[[:alpha:]_'][[:alnum:]_']*")
    call s:SetKeywordPattern('html,xhtml,xml',
                \'\(<\/[^>]\+>\|<\h[[:alnum:]_-]*\(\s*/\=>\)\=\|&\h\w*;\|\h[[:alnum:]_-]*\(="\)\=\)')
    "}}}

    " Initialize assume file type lists.
    if !exists('g:NeoComplCache_NonBufferFileTypeDetect')
        let g:NeoComplCache_NonBufferFileTypeDetect = {}
    endif
    " For test.
    "let g:NeoComplCache_NonBufferFileTypeDetect['rb'] = 'ruby'

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
    if !exists('g:NeoComplCache_TagsLists')
        let g:NeoComplCache_TagsLists = {}
    endif
    if !has_key(g:NeoComplCache_TagsLists, 'default')
        let g:NeoComplCache_TagsLists['default'] = ''
    endif
    " For test.
    "let g:NeoComplCache_DictionaryFileTypeLists['vim'] = 'CSApprox.vim,LargeFile.vim'
    "let g:NeoComplCache_TagsLists[1] = 'tags,'.$DOTVIM.'\doc\tags'
    "let g:NeoComplCache_DictionaryBufferLists[1] = '256colors2.pl'"}}}
    
    " Initialize omni completion pattern."{{{
    if !exists('g:NeoComplCache_OmniPatterns')
        let g:NeoComplCache_OmniPatterns = {}
    endif
    if has('ruby')
        call s:SetOmniPattern('ruby', '\(\(^\|[^:]\):\|[^. \t]\(\.\|::\)\)')
    endif
    if has('python')
        call s:SetOmniPattern('python', '[^. \t]\.')
    endif
    call s:SetOmniPattern('html,xhtml,xml', '\(<\|<\/\|<[^>]\+\|<[^>]\+="\)')
    call s:SetOmniPattern('css', '\(\(^\s\|[;{]\)\s*\|[:@!]\s*\)')
    call s:SetOmniPattern('javascript', '[^. \t]\.')
    call s:SetOmniPattern('c', '[^. \t]\(\.\|->\)')
    call s:SetOmniPattern('cpp', '[^. \t]\(\.\|->\|::\)')
    call s:SetOmniPattern('php', '[^. \t]\(->\|::\)')
    call s:SetOmniPattern('java', '[^. \t]\.')
    "}}}
    
    " Add commands."{{{
    command! -nargs=0 NeoCompleCacheCachingBuffer call s:NeoComplCache.CachingCurrentBuffer()
    command! -nargs=0 NeoCompleCacheCachingTags call s:NeoComplCache.CachingTags()
    command! -nargs=0 NeoCompleCacheCachingDictionary call s:NeoComplCache.CachingDictionary()
    command! -nargs=0 Neco echo "   A A\n~(-'_'-)"
    command! -nargs=0 NeoCompleCacheLock call s:NeoComplCache.Lock()
    command! -nargs=0 NeoCompleCacheUnlock call s:NeoComplCache.Unlock()
    command! -nargs=0 NeoCompleCacheSaveMFU call s:NeoComplCache.SaveAllMFU()
    command! -nargs=* NeoCompleCacheSetBufferDictionary call s:NeoComplCache.SetBufferDictionary(<q-args>)
    command! -nargs=* NeoCompleCachePrintSource call s:NeoComplCache.PrintSource(<q-args>)
    "}}}

    " Must g:NeoComplCache_StartCharLength > 1.
    if g:NeoComplCache_KeywordCompletionStartLength < 1
        g:NeoComplCache_KeywordCompletionStartLength = 1
    endif
    " Must g:NeoComplCache_MinKeywordLength > 1.
    if g:NeoComplCache_MinKeywordLength < 1
        g:NeoComplCache_MinKeywordLength = 1
    endif

    " Save options.
    let s:completefunc_save = &completefunc

    " Set completefunc.
    let &completefunc = 'g:NeoComplCache_ManualCompleteFunc'

    " Initialize cache.
    call s:NeoComplCache.CheckSource(g:NeoComplCache_CacheLineCount*10)
endfunction"}}}

function! s:NeoComplCache.Disable()"{{{
    " Restore options.
    let &completefunc = s:completefunc_save
    
    augroup NeoCompleCache
        autocmd!
    augroup END

    delcommand NeoCompleCacheCachingBuffer
    delcommand NeoCompleCacheCachingTags
    delcommand NeoCompleCacheCachingDictionary
    delcommand Neco
    delcommand NeoCompleCacheLock
    delcommand NeoCompleCacheUnlock
    delcommand NeoCompleCacheSaveMFU
    delcommand NeoCompleCacheSetBufferDictionary
    delcommand NeoCompleCachePrintSource
endfunction"}}}

function! s:NeoComplCache.Toggle()"{{{
    if &completefunc == 'g:NeoComplCache_ManualCompleteFunc'
        call s:NeoComplCache.Disable()
    else
        call s:NeoComplCache.Enable()
    endif
endfunction"}}}

function! s:NeoComplCache.CachingCurrentBuffer()"{{{
    let l:current_buf = bufnr('%')
    call s:NeoComplCache.CachingSource(l:current_buf, 1, -1)

    " Disable auto caching.
    let s:source[l:current_buf].cached_last_line = s:source[l:current_buf].end_line+1
endfunction"}}}

function! s:NeoComplCache.CachingTags()"{{{
    " Create source.
    call s:NeoComplCache.CheckSource(g:NeoComplCache_CacheLineCount*10)
    
    " Check tags are exists.
    if has_key(g:NeoComplCache_TagsLists, tabpagenr())
        let l:tags = '^tags:' . tabpagenr()
    elseif !empty(g:NeoComplCache_TagsLists['default'])
        let l:tags = '^tags:default'
    else
        " Dummy pattern.
        let l:tags = '^$'
    endif
    let l:cache_keyword_buffer_filtered = []
    for key in keys(s:source)
        if key =~ l:tags
            call s:NeoComplCache.CachingSource(key, '^', -1)

            " Disable auto caching.
            let s:source[key].cached_last_line = s:source[key].end_line+1
        endif
    endfor
endfunction"}}}

function! s:NeoComplCache.CachingDictionary()"{{{
    " Create source.
    call s:NeoComplCache.CheckSource(g:NeoComplCache_CacheLineCount*10)

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
    if g:NeoComplCache_EnableMFU
        let l:mfu_dict = '^mfu:' . &filetype
    else
        " Dummy pattern.
        let l:mfu_dict = '^$'
    endif
    let l:cache_keyword_buffer_filtered = []
    for key in keys(s:source)
        if key =~ l:ft_dict || key =~ l:buf_dict || key =~ l:mfu_dict
            call s:NeoComplCache.CachingSource(key, '^', -1)

            " Disable auto caching.
            let s:source[key].cached_last_line = s:source[key].end_line+1
        endif
    endfor
endfunction"}}}

function! s:NeoComplCache.Lock()"{{{
    let s:complete_lock = 1
endfunction"}}}

function! s:NeoComplCache.Unlock()"{{{
    let s:complete_lock = 0
endfunction"}}}

" For debug command.
function! s:NeoComplCache.PrintSource(number)"{{{
    if empty(a:number)
        let l:number = bufnr('%')
    else
        let l:number = a:number
    endif

    silent put=printf('Print neocomplcache %d source.', l:number)
    for l:key in keys(s:source[l:number])
        silent put =printf('%s => %s', l:key, string(s:source[l:number][l:key]))
    endfor
endfunction"}}}

" Global options definition."{{{
if !exists('g:NeoComplCache_MaxList')
    let g:NeoComplCache_MaxList = 100
endif
if !exists('g:NeoComplCache_MaxKeywordWidth')
    let g:NeoComplCache_MaxKeywordWidth = 50
endif
if !exists('g:NeoComplCache_MaxFilenameWidth')
    let g:NeoComplCache_MaxFilenameWidth = 15
endif
if !exists('g:NeoComplCache_PartialMatch')
    let g:NeoComplCache_PartialMatch = 1
endif
if !exists('g:NeoComplCache_SimilarMatch')
    let g:NeoComplCache_SimilarMatch = 0
endif
if !exists('g:NeoComplCache_KeywordCompletionStartLength')
    let g:NeoComplCache_KeywordCompletionStartLength = 2
endif
if !exists('g:NeoComplCache_PartialCompletionStartLength')
    let g:NeoComplCache_PartialCompletionStartLength = 3
endif
if !exists('g:NeoComplCache_SimilarCompletionStartLength')
    let g:NeoComplCache_SimilarCompletionStartLength = 4
endif
if !exists('g:NeoComplCache_MinKeywordLength')
    let g:NeoComplCache_MinKeywordLength = 4
endif
if !exists('g:NeoComplCache_FilenameCompletionStartLength')
    let g:NeoComplCache_FilenameCompletionStartLength = 0
endif
if !exists('g:NeoComplCache_IgnoreCase')
    let g:NeoComplCache_IgnoreCase = 1
endif
if !exists('g:NeoComplCache_SmartCase')
    let g:NeoComplCache_SmartCase = 0
endif
if !exists('g:NeoComplCache_DrawWordsRank')
    let g:NeoComplCache_DrawWordsRank = 1
endif
if !exists('g:NeoComplCache_AlphabeticalOrder')
    let g:NeoComplCache_AlphabeticalOrder = 0
endif
if !exists('g:NeoComplCache_FirstHeadMatching')
    let g:NeoComplCache_FirstHeadMatching = 1
endif
if !exists('g:NeoComplCache_CacheLineCount')
    let g:NeoComplCache_CacheLineCount = 10
endif
if !exists('g:NeoComplCache_DeleteRank0')
    let g:NeoComplCache_DeleteRank0 = 0
endif
if !exists('g:NeoComplCache_DisableAutoComplete')
    let g:NeoComplCache_DisableAutoComplete = 0
endif
if !exists('g:NeoComplCache_EnableAsterisk')
    let g:NeoComplCache_EnableAsterisk = 1
endif
if !exists('g:NeoComplCache_QuickMatchEnable')
    let g:NeoComplCache_QuickMatchEnable = 1
endif
if !exists('g:NeoComplCache_CalcRankRandomize')
    let g:NeoComplCache_CalcRankRandomize = has('reltime')
endif
if !exists('g:NeoComplCache_CalcRankMaxLists')
    let g:NeoComplCache_CalcRankMaxLists = 40
endif
if !exists('g:NeoComplCache_QuickMatchMaxLists')
    let g:NeoComplCache_QuickMatchMaxLists = 100
endif
if !exists('g:NeoComplCache_SlowCompleteSkip')
    let g:NeoComplCache_SlowCompleteSkip = has('reltime')
endif
if !exists('g:NeoComplCache_PreviousKeywordCompletion')
    let g:NeoComplCache_PreviousKeywordCompletion = 0
endif
if !exists('g:NeoComplCache_EnableMFU')
    let g:NeoComplCache_EnableMFU = 0
elseif g:NeoComplCache_EnableMFU
    " Most frequently used settings.
    
    if !exists('g:NeoComplCache_MFUDirectory')
        let g:NeoComplCache_MFUDirectory = $HOME . '/.vim_mfu'
    endif
    if !isdirectory(g:NeoComplCache_MFUDirectory)
        call mkdir(g:NeoComplCache_MFUDirectory, 'p')
    endif

    if !exists('g:NeoComplCache_MFUThreshold')
        let g:NeoComplCache_MFUThreshold = 20
    endif
    if !exists('g:NeoComplCache_MFUMax')
        let g:NeoComplCache_MFUMax = 200
    endif
endif
if exists('g:NeoComplCache_EnableAtStartup') && g:NeoComplCache_EnableAtStartup
    " Enable startup.
    call s:NeoComplCache.Enable()
endif"}}}

let g:loaded_neocomplcache = 1

" vim: foldmethod=marker
