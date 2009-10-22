"=============================================================================
" FILE: keyword_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 22 Oct 2009
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
" Version: 3.05, for Vim 7.0
"-----------------------------------------------------------------------------
" TODO: "{{{
"     - Nothing.
""}}}
" Bugs"{{{
"     - Nothing.
""}}}
"=============================================================================

function! neocomplcache#complfunc#keyword_complete#initialize()"{{{
    let s:plugins_func_table = {}

    " Initialize plugins table."{{{
    " Search autoload.
    let l:plugin_list = split(globpath(&runtimepath, 'autoload/neocomplcache/plugin/*.vim'), '\n')
    for list in l:plugin_list
        let l:func_name = fnamemodify(list, ':t:r')
        let s:plugins_func_table[l:func_name] = 'neocomplcache#plugin#' . l:func_name . '#'
    endfor"}}}

    " Initialize.
    for l:plugin in values(s:plugins_func_table)
        call call(l:plugin . 'initialize', [])
    endfor
endfunction"}}}
function! neocomplcache#complfunc#keyword_complete#finalize()"{{{
    for l:plugin in values(s:plugins_func_table)
        call call(l:plugin . 'finalize', [])
    endfor
endfunction"}}}

function! neocomplcache#complfunc#keyword_complete#get_keyword_pos(cur_text)"{{{
    let l:pattern = '\v%(' .  neocomplcache#plugin#buffer_complete#current_keyword_pattern() . ')$'
    let l:cur_keyword_pos = match(a:cur_text, l:pattern)
    let l:cur_keyword_str = matchstr(a:cur_text, l:pattern)

    if len(l:cur_keyword_str) >= g:NeoComplCache_MinKeywordLength && l:cur_keyword_str !~ '\d\+$'
        " Check candidate.
        call neocomplcache#plugin#buffer_complete#check_candidate(l:cur_keyword_str)
    endif

    if g:NeoComplCache_EnableWildCard
        " Check wildcard.
        let [l:cur_keyword_pos, l:cur_keyword_str] = neocomplcache#complfunc#keyword_complete#check_wildcard(a:cur_text, l:pattern, l:cur_keyword_pos, l:cur_keyword_str)
    endif

    if l:cur_keyword_pos < 0 || len(l:cur_keyword_str) < g:NeoComplCache_KeywordCompletionStartLength
        if g:NeoComplCache_EnableQuickMatch
            " Search quick match.
            let l:pattern = '\v\d{1,2}$'
            let l:cur_keyword_pos = match(a:cur_text, l:pattern)
            let l:cur_keyword_str = matchstr(a:cur_text, l:pattern)

            if l:cur_keyword_str == ''
                return -1
            endif
        else
            return -1
        endif
    endif

    return l:cur_keyword_pos
endfunction"}}}

function! neocomplcache#complfunc#keyword_complete#get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
    if g:NeoComplCache_EnableSkipCompletion && &l:completefunc == 'neocomplcache#auto_complete'
        let l:start_time = reltime()
    else
        let l:start_time = 0
    endif

    " Load plugin.
    let l:loaded_plugins = copy(s:plugins_func_table)

    " Get keyword list.
    let l:cache_keyword_lists = {}
    let l:is_empty = 1
    for l:plugin in keys(l:loaded_plugins)
        if has_key(g:NeoComplCache_PluginCompletionLength, l:plugin)
        \&& len(a:cur_keyword_str) < g:NeoComplCache_PluginCompletionLength[l:plugin]
            call remove(l:loaded_plugins, l:plugin)
            let l:cache_keyword_lists[l:plugin] = []
        else
            let l:cache_keyword_lists[l:plugin] = deepcopy(call(l:loaded_plugins[l:plugin] . 'get_keyword_list', [a:cur_keyword_str]))
        endif

        if !empty(l:cache_keyword_lists[l:plugin])
            let l:is_empty = 0
        endif
    endfor
    if l:is_empty && (!g:NeoComplCache_EnableQuickMatch || match(a:cur_keyword_str, '\d$') < 0)
        return []
    endif

    if g:NeoComplCache_AlphabeticalOrder
        " Not calc rank.
        let l:order_func = 'neocomplcache#compare_words'
    else
        " Calc rank."{{{
        for l:plugin in keys(l:loaded_plugins)
            call call(l:loaded_plugins[l:plugin] . 'calc_rank', [l:cache_keyword_lists[l:plugin]])

            " Skip completion if takes too much time."{{{
            if neocomplcache#check_skip_time(l:start_time)
                echo 'Skipped auto completion'
                let s:skipped = 1
                return []
            endif"}}}
        endfor

        let l:order_func = 'neocomplcache#compare_rank'"}}}
    endif

    let l:cache_keyword_filtered = []

    " Get next keyword.
    let l:next_keyword_str = matchstr('a'.getline('.')[col('.')-1 :],
        \'\v^%(' . neocomplcache#plugin#buffer_complete#current_keyword_pattern() . ')')[1:]
    let l:next_keyword_str = substitute(escape(l:next_keyword_str, '~" \.^$*[]'), "'", "''", 'g')

    " Previous keyword completion.
    if g:NeoComplCache_PreviousKeywordCompletion && !g:NeoComplCache_AlphabeticalOrder "{{{
        let [l:prev_word, l:prepre_word] = s:get_prev_word(a:cur_keyword_str)
        for l:plugin in keys(l:loaded_plugins)
            let l:cache_keyword_list = l:cache_keyword_lists[l:plugin]
            call call(l:loaded_plugins[l:plugin] . 'calc_prev_rank', [l:cache_keyword_list, l:prev_word, l:prepre_word])

            " Add rank if match next keyword."{{{
            if l:next_keyword_str != ''
                " No ignorecase.
                let l:save_ignorecase = &ignorecase
                let &ignorecase = 0

                let l:pattern = l:next_keyword_str . '$'
                for l:keyword in filter(copy(l:cache_keyword_list), 'v:val.word =~ l:pattern')
                    let l:keyword.rank = l:keyword.rank * 10
                    let l:keyword.prev_rank = l:keyword.prev_rank * 10
                    let l:keyword.prepre_rank = l:keyword.prepre_rank * 10
                endfor

                let &ignorecase = l:save_ignorecase
            endif"}}}

            " Sort.
            let l:cache_keyword_filtered += sort(
                \filter(copy(l:cache_keyword_list), 'v:val.prev_rank > 0 || v:val.prepre_rank > 0'), 'neocomplcache#compare_prev_rank')

            call filter(l:cache_keyword_lists[l:plugin], 'v:val.prev_rank == 0 && v:val.prepre_rank == 0')
        endfor
    endif"}}}

    " Extend list.
    let l:cache_keyword_list = []
    for l:plugin in keys(l:loaded_plugins)
        let l:cache_keyword_list += l:cache_keyword_lists[l:plugin]
    endfor

    " Add rank if match next keyword."{{{
    if l:next_keyword_str != ''
        " No ignorecase.
        let l:save_ignorecase = &ignorecase
        let &ignorecase = 0

        let l:pattern = l:next_keyword_str . '$'
        for l:keyword in filter(copy(l:cache_keyword_list), 'v:val.word =~ l:pattern')
            let l:keyword.rank = l:keyword.rank * 10
        endfor

        let &ignorecase = l:save_ignorecase
    endif"}}}

    " Sort.
    let l:cache_keyword_filtered = sort(l:cache_keyword_list, l:order_func)

    " Trunk too many item.
    let l:cache_keyword_filtered = l:cache_keyword_filtered[:g:NeoComplCache_MaxList-1]

    " Quick match.
    let l:cache_keyword_filtered = neocomplcache#get_quickmatch_list(l:cache_keyword_filtered, a:cur_keyword_pos,
                    \a:cur_keyword_str, 'keyword_complete')

    " Remove next keyword.
    let l:cache_keyword_filtered = neocomplcache#remove_next_keyword(l:cache_keyword_filtered)

    return l:cache_keyword_filtered
endfunction"}}}

function! neocomplcache#complfunc#keyword_complete#manual_complete()"{{{
    if !exists(':NeoComplCacheDisable')
        return ''
    endif

    if !neocomplcache#plugin#buffer_complete#exists_current_source()
        return ''
    endif

    " Get cursor word.
    let l:cur_text = neocomplcache#get_cur_text()
    let l:pattern = '\v%(' .  neocomplcache#plugin#buffer_complete#current_keyword_pattern() . ')$'
    let l:cur_keyword_pos = match(l:cur_text, l:pattern)
    let l:cur_keyword_str = matchstr(l:cur_text, l:pattern)

    if g:NeoComplCache_EnableWildCard
        " Check wildcard.
        let [l:cur_keyword_pos, l:cur_keyword_str] = neocomplcache#complfunc#keyword_complete#check_wildcard(l:cur_text, l:pattern, l:cur_keyword_pos, l:cur_keyword_str)
    endif

    if len(l:cur_keyword_str) < g:NeoComplCache_ManualCompletionStartLength
        return ''
    endif

    " Save options.
    let l:ignorecase_save = &ignorecase

    if g:NeoComplCache_SmartCase && l:cur_keyword_str =~ '\u'
        let &ignorecase = 0
    else
        let &ignorecase = g:NeoComplCache_IgnoreCase
    endif

    " Set function.
    let &l:completefunc = 'neocomplcache#manual_complete'

    let l:complete_words = neocomplcache#get_quickmatch_list(neocomplcache#complfunc#keyword_complete#get_complete_words(l:cur_keyword_pos, l:cur_keyword_str),
                \ l:cur_keyword_pos, l:cur_keyword_str, 'keyword_complete')
    let l:complete_words = neocomplcache#remove_next_keyword(l:complete_words)

    " Restore option.
    let &ignorecase = l:ignorecase_save

    " Start complete.
    return neocomplcache#start_manual_complete(l:complete_words, l:cur_keyword_pos, l:cur_keyword_str)
endfunction"}}}

function! neocomplcache#complfunc#keyword_complete#check_wildcard(cur_text, pattern, cur_keyword_pos, cur_keyword_str)"{{{
    let l:cur_keyword_pos = a:cur_keyword_pos
    let l:cur_keyword_str = a:cur_keyword_str

    while l:cur_keyword_pos > 1 && a:cur_text[l:cur_keyword_pos - 1] =~ '[*-]'
        let l:left_text = a:cur_text[: l:cur_keyword_pos - 2]
        let l:left_keyword_str = matchstr(l:left_text, a:pattern)
        if l:left_keyword_str == ''
            break
        endif

        let l:cur_keyword_str = l:left_keyword_str . a:cur_text[l:cur_keyword_pos - 1] . l:cur_keyword_str
        let l:cur_keyword_pos = match(l:left_text, a:pattern)
    endwhile

    if l:cur_keyword_str == ''
        " Get cursor word.
        let l:cur_text = (col('.') < 2)? '' : getline('.')[: col('.')-2]
        let l:pattern = '\%(^\|\W\)\S[*-]$'
        let [l:cur_keyword_pos, l:cur_keyword_str] = [match(l:cur_text, l:pattern), matchstr(l:cur_text, l:pattern)]
    endif
    return [l:cur_keyword_pos, l:cur_keyword_str]
endfunction"}}}

function! s:get_prev_word(cur_keyword_str)"{{{
    let l:keyword_pattern = neocomplcache#plugin#buffer_complete#current_keyword_pattern()
    let l:line_part = getline('.')[: col('.')-1 - len(a:cur_keyword_str)]
    let l:prev_word_end = matchend(l:line_part, l:keyword_pattern)
    if l:prev_word_end > 0
        let l:word_end = matchend(l:line_part, l:keyword_pattern, l:prev_word_end)
        if l:word_end >= 0
            while l:word_end >= 0
                let l:prepre_word_end = l:prev_word_end
                let l:prev_word_end = l:word_end
                let l:word_end = matchend(l:line_part, l:keyword_pattern, l:prev_word_end)
            endwhile
            let l:prepre_word = matchstr(l:line_part[: l:prepre_word_end-1], l:keyword_pattern . '$')
        else
            let l:prepre_word = '^'
        endif

        let l:prev_word = matchstr(l:line_part[: l:prev_word_end-1], l:keyword_pattern . '$')
    else
        let l:prepre_word = ''
        let l:prev_word = '^'
    endif
    return [l:prev_word, l:prepre_word]
    "echo printf('prepre = %s, pre = %s', l:prepre_word, l:prev_word)
endfunction"}}}


" vim: foldmethod=marker
