"=============================================================================
" FILE: complete.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 12 Apr 2013.
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
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! neocomplcache#complete#manual_complete(findstart, base) "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()

  if a:findstart
    let cur_text = neocomplcache#get_cur_text()
    if !neocomplcache#is_enabled()
          \ || neocomplcache#helper#is_omni_complete(cur_text)
      call neocomplcache#_clear_result()
      let &l:completefunc = 'neocomplcache#complete#manual_complete'

      return (neocomplcache#is_prefetch()
            \ || g:neocomplcache_enable_insert_char_pre) ?
            \ -1 : -3
    endif

    " Get cur_keyword_pos.
    if neocomplcache#is_prefetch() && !empty(neocomplcache.complete_results)
      " Use prefetch results.
    else
      let neocomplcache.complete_results =
            \ neocomplcache#complete#_get_results(cur_text)
    endif
    let cur_keyword_pos =
          \ neocomplcache#complete#_get_cur_keyword_pos(neocomplcache.complete_results)

    if cur_keyword_pos < 0
      call neocomplcache#_clear_result()

      let neocomplcache = neocomplcache#get_current_neocomplcache()
      let cur_keyword_pos = (neocomplcache#is_prefetch() ||
            \ g:neocomplcache_enable_insert_char_pre ||
            \ neocomplcache#get_current_neocomplcache().skipped) ?  -1 : -3
      let neocomplcache.skipped = 0
    endif

    return cur_keyword_pos
  else
    let cur_keyword_pos = neocomplcache#complete#_get_cur_keyword_pos(
          \ neocomplcache.complete_results)
    let neocomplcache.complete_words = neocomplcache#complete#_get_words(
          \ neocomplcache.complete_results, cur_keyword_pos, a:base)
    let neocomplcache.cur_keyword_str = a:base

    if v:version > 703 || v:version == 703 && has('patch418')
      let dict = { 'words' : neocomplcache.complete_words }

      if (g:neocomplcache_enable_cursor_hold_i
            \      || v:version > 703 || v:version == 703 && has('patch561'))
            \ && (len(a:base) < g:neocomplcache_auto_completion_start_length
            \   || !empty(filter(copy(neocomplcache.complete_words),
            \          "get(v:val, 'neocomplcache__refresh', 0)"))
            \   || len(neocomplcache.complete_words) >= g:neocomplcache_max_list)
        " Note: If Vim is less than 7.3.561, it have broken register "." problem.
        let dict.refresh = 'always'
      endif
      return dict
    else
      return neocomplcache.complete_words
    endif
  endif
endfunction"}}}

function! neocomplcache#complete#sources_manual_complete(findstart, base) "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()

  if a:findstart
    if !neocomplcache#is_enabled()
      call neocomplcache#_clear_result()
      return -2
    endif

    let all_sources = neocomplcache#available_sources()
    let sources = get(a:000, 0, keys(all_sources))
    let s:use_sources = neocomplcache#_get_sources_list(type(sources) == type([]) ?
          \ sources : [sources])

    " Get cur_keyword_pos.
    let complete_results = neocomplcache#complete#_get_results(
          \ neocomplcache#get_cur_text(1), s:use_sources)
    let neocomplcache.cur_keyword_pos =
          \ neocomplcache#complete#_get_cur_keyword_pos(complete_results)

    if neocomplcache.cur_keyword_pos < 0
      call neocomplcache#_clear_result()

      return -2
    endif

    let neocomplcache.complete_results = complete_results

    return neocomplcache.cur_keyword_pos
  endif

  let neocomplcache.cur_keyword_pos =
        \ neocomplcache#complete#_get_cur_keyword_pos(
        \     neocomplcache.complete_results)
  let complete_words = neocomplcache#complete#_get_words(
        \ neocomplcache.complete_results,
        \ neocomplcache.cur_keyword_pos, a:base)

  let neocomplcache.complete_words = complete_words
  let neocomplcache.cur_keyword_str = a:base

  return complete_words
endfunction"}}}

function! neocomplcache#complete#unite_complete(findstart, base) "{{{
  " Dummy.
  return a:findstart ? -1 : []
endfunction"}}}

function! neocomplcache#complete#auto_complete(findstart, base) "{{{
  return neocomplcache#complete#manual_complete(a:findstart, a:base)
endfunction"}}}

function! neocomplcache#complete#_get_results(cur_text, ...) "{{{
  if g:neocomplcache_enable_debug
    echomsg 'start get_complete_results'
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.start_time = reltime()

  let complete_results = call(
        \ 'neocomplcache#complete#_set_results_pos', [a:cur_text] + a:000)
  call neocomplcache#complete#_set_results_words(complete_results)

  return filter(complete_results,
        \ '!empty(v:val.complete_words)')
endfunction"}}}

function! neocomplcache#complete#_get_cur_keyword_pos(complete_results) "{{{
  if empty(a:complete_results)
    return -1
  endif

  let cur_keyword_pos = col('.')
  for result in values(a:complete_results)
    if cur_keyword_pos > result.cur_keyword_pos
      let cur_keyword_pos = result.cur_keyword_pos
    endif
  endfor

  return cur_keyword_pos
endfunction"}}}

function! neocomplcache#complete#_get_words(complete_results, cur_keyword_pos, cur_keyword_str) "{{{
  let frequencies = neocomplcache#_get_frequencies()
  if exists('*neocomplcache#sources#buffer_complete#get_frequencies')
    let frequencies = extend(copy(
          \ neocomplcache#sources#buffer_complete#get_frequencies()),
          \ frequencies)
  endif

  let sources = neocomplcache#available_sources()

  " Append prefix.
  let complete_words = []
  let len_words = 0
  for [source_name, result] in sort(items(a:complete_results),
        \ 's:compare_source_rank')
    let source = sources[source_name]

    if empty(result.complete_words)
      " Skip.
      continue
    endif

    let result.complete_words =
          \ type(result.complete_words[0]) == type('') ?
          \ map(copy(result.complete_words), "{'word': v:val}") :
          \ deepcopy(result.complete_words)

    if result.cur_keyword_pos > a:cur_keyword_pos
      let prefix = a:cur_keyword_str[: result.cur_keyword_pos
            \                            - a:cur_keyword_pos - 1]

      for keyword in result.complete_words
        let keyword.word = prefix . keyword.word
      endfor
    endif

    for keyword in result.complete_words
      if !has_key(keyword, 'menu') && has_key(source, 'mark')
        " Set default menu.
        let keyword.menu = source.mark
      endif
    endfor

    for keyword in filter(copy(result.complete_words),
          \ 'has_key(frequencies, v:val.word)')
      let keyword.rank = frequencies[keyword.word]
    endfor

    let compare_func = get(sources[source_name], 'compare_func',
          \ g:neocomplcache_compare_function)
    if compare_func !=# 'neocomplcache#compare_nothing'
      call sort(result.complete_words, compare_func)
    endif

    let complete_words += s:remove_next_keyword(
          \ source_name, result.complete_words)
    let len_words += len(result.complete_words)

    if g:neocomplcache_max_list > 0
          \ && len_words > g:neocomplcache_max_list
      break
    endif

    if neocomplcache#complete_check()
      return []
    endif
  endfor

  if g:neocomplcache_max_list > 0
    let complete_words = complete_words[: g:neocomplcache_max_list]
  endif

  " Check dup and set icase.
  let icase = g:neocomplcache_enable_ignore_case &&
        \!(g:neocomplcache_enable_smart_case && a:cur_keyword_str =~ '\u')
        \ && !neocomplcache#is_text_mode()
  for keyword in complete_words
    if has_key(keyword, 'kind') && keyword.kind == ''
      " Remove kind key.
      call remove(keyword, 'kind')
    endif

    let keyword.icase = icase
  endfor

  " Delimiter check. "{{{
  let filetype = neocomplcache#get_context_filetype()
  for delimiter in ['/'] +
        \ get(g:neocomplcache_delimiter_patterns, filetype, [])
    " Count match.
    let delim_cnt = 0
    let matchend = matchend(a:cur_keyword_str, delimiter)
    while matchend >= 0
      let matchend = matchend(a:cur_keyword_str, delimiter, matchend)
      let delim_cnt += 1
    endwhile

    for keyword in complete_words
      let split_list = split(keyword.word, delimiter.'\ze.', 1)
      if len(split_list) > 1
        let delimiter_sub = substitute(delimiter, '\\\([.^$]\)', '\1', 'g')
        let keyword.word = join(split_list[ : delim_cnt], delimiter_sub)
        let keyword.abbr = join(
              \ split(get(keyword, 'abbr', keyword.word),
              \             delimiter.'\ze.', 1)[ : delim_cnt],
              \ delimiter_sub)

        if g:neocomplcache_max_keyword_width >= 0
              \ && len(keyword.abbr) > g:neocomplcache_max_keyword_width
          let keyword.abbr = substitute(keyword.abbr,
                \ '\(\h\)\w*'.delimiter, '\1'.delimiter_sub, 'g')
        endif
        if delim_cnt+1 < len(split_list)
          let keyword.abbr .= delimiter_sub . '~'
          let keyword.dup = 0

          if g:neocomplcache_enable_auto_delimiter
            let keyword.word .= delimiter_sub
          endif
        endif
      endif
    endfor
  endfor"}}}

  if neocomplcache#complete_check()
    return []
  endif

  " Convert words.
  if neocomplcache#is_text_mode() "{{{
    let convert_candidates = filter(copy(complete_words),
          \ "get(v:val, 'neocomplcache__convertable', 1)
          \  && v:val.word =~ '^\\u\\+$\\|^\\u\\?\\l\\+$'")

    if a:cur_keyword_str =~ '^\l\+$'
      for keyword in convert_candidates
        let keyword.word = tolower(keyword.word)
        if has_key(keyword, 'abbr')
          let keyword.abbr = tolower(keyword.abbr)
        endif
      endfor
    elseif a:cur_keyword_str =~ '^\u\+$'
      for keyword in convert_candidates
        let keyword.word = toupper(keyword.word)
        if has_key(keyword, 'abbr')
          let keyword.abbr = toupper(keyword.abbr)
        endif
      endfor
    elseif a:cur_keyword_str =~ '^\u\l\+$'
      for keyword in convert_candidates
        let keyword.word = toupper(keyword.word[0]).
              \ tolower(keyword.word[1:])
        if has_key(keyword, 'abbr')
          let keyword.abbr = toupper(keyword.abbr[0]).
                \ tolower(keyword.abbr[1:])
        endif
      endfor
    endif
  endif"}}}

  if g:neocomplcache_max_keyword_width >= 0 "{{{
    " Abbr check.
    let abbr_pattern = printf('%%.%ds..%%s',
          \ g:neocomplcache_max_keyword_width-15)
    for keyword in complete_words
      let abbr = get(keyword, 'abbr', keyword.word)
      if len(abbr) > g:neocomplcache_max_keyword_width
        let len = neocomplcache#util#wcswidth(abbr)

        if len > g:neocomplcache_max_keyword_width
          let keyword.abbr = neocomplcache#util#truncate(
                \ abbr, g:neocomplcache_max_keyword_width - 2) . '..'
        endif
      endif
    endfor
  endif"}}}

  return complete_words
endfunction"}}}
function! neocomplcache#complete#_set_results_pos(cur_text, ...) "{{{
  " Set context filetype.
  call neocomplcache#context_filetype#set()

  let sources = copy(get(a:000, 0, neocomplcache#_get_sources_list()))
  if a:0 < 1
    call filter(sources, '!neocomplcache#is_plugin_locked(v:key)')
  endif

  " Try source completion. "{{{
  let complete_results = {}
  for [source_name, source] in items(sources)
    if source.kind ==# 'plugin'
      " Plugin default keyword position.
      let [cur_keyword_pos, cur_keyword_str] = neocomplcache#match_word(a:cur_text)
    else
      let pos = winsaveview()

      try
        let cur_keyword_pos = source.get_keyword_pos(a:cur_text)
      catch
        call neocomplcache#print_error(v:throwpoint)
        call neocomplcache#print_error(v:exception)
        call neocomplcache#print_error(
              \ 'Error occured in source''s get_keyword_pos()!')
        call neocomplcache#print_error(
              \ 'Source name is ' . source_name)
        return complete_results
      finally
        if winsaveview() != pos
          call winrestview(pos)
        endif
      endtry
    endif

    if cur_keyword_pos < 0
      continue
    endif

    let cur_keyword_str = a:cur_text[cur_keyword_pos :]
    if neocomplcache#is_auto_complete() &&
          \ neocomplcache#util#mb_strlen(cur_keyword_str)
          \     < neocomplcache#get_completion_length(source_name)
      " Skip.
      continue
    endif

    let complete_results[source_name] = {
          \ 'complete_words' : [],
          \ 'cur_keyword_pos' : cur_keyword_pos,
          \ 'cur_keyword_str' : cur_keyword_str,
          \ 'source' : source,
          \}
  endfor
  "}}}

  return complete_results
endfunction"}}}
function! neocomplcache#complete#_set_results_words(complete_results) "{{{
  " Try source completion.
  for [source_name, result] in items(a:complete_results)
    if neocomplcache#complete_check()
      return
    endif

    " Save options.
    let ignorecase_save = &ignorecase

    if neocomplcache#is_text_mode()
      let &ignorecase = 1
    elseif g:neocomplcache_enable_smart_case
          \ && result.cur_keyword_str =~ '\u'
      let &ignorecase = 0
    else
      let &ignorecase = g:neocomplcache_enable_ignore_case
    endif

    let pos = winsaveview()

    try
      let words = result.source.kind ==# 'plugin' ?
            \ result.source.get_keyword_list(result.cur_keyword_str) :
            \ result.source.get_complete_words(
            \   result.cur_keyword_pos, result.cur_keyword_str)
    catch
      call neocomplcache#print_error(v:throwpoint)
      call neocomplcache#print_error(v:exception)
      call neocomplcache#print_error(
            \ 'Source name is ' . source_name)
      if result.source.kind ==# 'plugin'
        call neocomplcache#print_error(
              \ 'Error occured in source''s get_keyword_list()!')
      else
        call neocomplcache#print_error(
              \ 'Error occured in source''s get_complete_words()!')
      endif
      return
    finally
      if winsaveview() != pos
        call winrestview(pos)
      endif
    endtry

    if g:neocomplcache_enable_debug
      echomsg source_name
    endif

    let &ignorecase = ignorecase_save

    let result.complete_words = words
  endfor
endfunction"}}}

function! s:remove_next_keyword(source_name, list) "{{{
  " Remove next keyword.
  let pattern = '^\%(' .
        \ (a:source_name  == 'filename_complete' ?
        \   neocomplcache#get_next_keyword_pattern('filename') :
        \   neocomplcache#get_next_keyword_pattern()) . '\m\)'

  let next_keyword_str = matchstr('a'.
        \ getline('.')[len(neocomplcache#get_cur_text(1)) :], pattern)[1:]
  if next_keyword_str == ''
    return a:list
  endif

  let next_keyword_str = substitute(
        \ substitute(escape(next_keyword_str,
        \ '~" \.^$*[]'), "'", "''", 'g'), ')$', '', '').'$'

  " No ignorecase.
  let ignorecase_save = &ignorecase
  let &ignorecase = 0

  for r in a:list
    if r.word =~ next_keyword_str
      if !has_key(r, 'abbr')
        let r.abbr = r.word
      endif

      let r.word = r.word[:match(r.word, next_keyword_str)-1]
    endif
  endfor

  let &ignorecase = ignorecase_save

  return a:list
endfunction"}}}

" Source rank order. "{{{
function! s:compare_source_rank(i1, i2)
  return neocomplcache#get_source_rank(a:i2[0]) -
        \ neocomplcache#get_source_rank(a:i1[0])
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
