"=============================================================================
" FILE: complete.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Apr 2013.
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
      call neocomplcache#helper#clear_result()
      let &l:completefunc = 'neocomplcache#complete#manual_complete'

      return (neocomplcache#is_prefetch()
            \ || g:neocomplcache_enable_insert_char_pre) ?
            \ -1 : -3
    endif

    " Get complete_pos.
    if neocomplcache#is_prefetch() && !empty(neocomplcache.complete_results)
      " Use prefetch results.
    else
      let neocomplcache.complete_results =
            \ neocomplcache#complete#_get_results(cur_text)
    endif
    let complete_pos =
          \ neocomplcache#complete#_get_complete_pos(neocomplcache.complete_results)

    if complete_pos < 0
      call neocomplcache#helper#clear_result()

      let neocomplcache = neocomplcache#get_current_neocomplcache()
      let complete_pos = (neocomplcache#is_prefetch() ||
            \ g:neocomplcache_enable_insert_char_pre ||
            \ neocomplcache#get_current_neocomplcache().skipped) ?  -1 : -3
      let neocomplcache.skipped = 0
    endif

    return complete_pos
  else
    let complete_pos = neocomplcache#complete#_get_complete_pos(
          \ neocomplcache.complete_results)
    let neocomplcache.candidates = neocomplcache#complete#_get_words(
          \ neocomplcache.complete_results, complete_pos, a:base)
    let neocomplcache.complete_str = a:base

    if v:version > 703 || v:version == 703 && has('patch418')
      let dict = { 'words' : neocomplcache.candidates }

      if (g:neocomplcache_enable_cursor_hold_i
            \      || v:version > 703 || v:version == 703 && has('patch561'))
            \ && (len(a:base) < g:neocomplcache_auto_completion_start_length
            \   || !empty(filter(copy(neocomplcache.candidates),
            \          "get(v:val, 'neocomplcache__refresh', 0)"))
            \   || len(neocomplcache.candidates) >= g:neocomplcache_max_list)
        " Note: If Vim is less than 7.3.561, it have broken register "." problem.
        let dict.refresh = 'always'
      endif
      return dict
    else
      return neocomplcache.candidates
    endif
  endif
endfunction"}}}

function! neocomplcache#complete#sources_manual_complete(findstart, base) "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()

  if a:findstart
    if !neocomplcache#is_enabled()
      call neocomplcache#helper#clear_result()
      return -2
    endif

    let all_sources = neocomplcache#available_sources()
    let sources = get(a:000, 0, keys(all_sources))
    let s:use_sources = neocomplcache#helper#get_sources_list(
          \ type(sources) == type([]) ? sources : [sources])

    " Get complete_pos.
    let complete_results = neocomplcache#complete#_get_results(
          \ neocomplcache#get_cur_text(1), s:use_sources)
    let neocomplcache.complete_pos =
          \ neocomplcache#complete#_get_complete_pos(complete_results)

    if neocomplcache.complete_pos < 0
      call neocomplcache#helper#clear_result()

      return -2
    endif

    let neocomplcache.complete_results = complete_results

    return neocomplcache.complete_pos
  endif

  let neocomplcache.complete_pos =
        \ neocomplcache#complete#_get_complete_pos(
        \     neocomplcache.complete_results)
  let candidates = neocomplcache#complete#_get_words(
        \ neocomplcache.complete_results,
        \ neocomplcache.complete_pos, a:base)

  let neocomplcache.candidates = candidates
  let neocomplcache.complete_str = a:base

  return candidates
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
        \ '!empty(v:val.neocomplcache__context.candidates)')
endfunction"}}}

function! neocomplcache#complete#_get_complete_pos(sources) "{{{
  if empty(a:sources)
    return -1
  endif

  return min([col('.')] + map(copy(a:sources),
        \ 'v:val.neocomplcache__context.complete_pos'))
endfunction"}}}

function! neocomplcache#complete#_get_words(sources, complete_pos, complete_str) "{{{
  let frequencies = neocomplcache#variables#get_frequencies()
  if exists('*neocomplcache#sources#buffer_complete#get_frequencies')
    let frequencies = extend(copy(
          \ neocomplcache#sources#buffer_complete#get_frequencies()),
          \ frequencies)
  endif

  " Append prefix.
  let candidates = []
  let len_words = 0
  for source in sort(filter(copy(a:sources),
        \ '!empty(v:val.neocomplcache__context.candidates)'),
        \  's:compare_source_rank')
    let context = source.neocomplcache__context
    let words =
          \ type(context.candidates[0]) == type('') ?
          \ map(copy(context.candidates), "{'word': v:val}") :
          \ deepcopy(context.candidates)

    if context.complete_pos > a:complete_pos
      let prefix = a:complete_str[: context.complete_pos
            \                            - a:complete_pos - 1]

      for candidate in words
        let candidate.word = prefix . candidate.word
      endfor
    endif

    for candidate in words
      if !has_key(candidate, 'menu') && has_key(source, 'mark')
        " Set default menu.
        let candidate.menu = source.mark
      endif
    endfor

    for candidate in filter(copy(words),
          \ 'has_key(frequencies, v:val.word)')
      let candidate.rank = frequencies[candidate.word]
    endfor

    let compare_func = get(source, 'compare_func',
          \ g:neocomplcache_compare_function)
    if compare_func !=# 'neocomplcache#compare_nothing'
      call sort(words, compare_func)
    endif

    let candidates += s:remove_next_keyword(source.name, words)
    let len_words += len(words)

    if g:neocomplcache_max_list > 0
          \ && len_words > g:neocomplcache_max_list
      break
    endif

    if neocomplcache#complete_check()
      return []
    endif
  endfor

  if g:neocomplcache_max_list > 0
    let candidates = candidates[: g:neocomplcache_max_list]
  endif

  " Check dup and set icase.
  let icase = g:neocomplcache_enable_ignore_case &&
        \!(g:neocomplcache_enable_smart_case && a:complete_str =~ '\u')
        \ && !neocomplcache#is_text_mode()
  for candidate in candidates
    if has_key(candidate, 'kind') && candidate.kind == ''
      " Remove kind key.
      call remove(candidate, 'kind')
    endif

    let candidate.icase = icase
  endfor

  " Delimiter check. "{{{
  let filetype = neocomplcache#get_context_filetype()
  for delimiter in ['/'] +
        \ get(g:neocomplcache_delimiter_patterns, filetype, [])
    " Count match.
    let delim_cnt = 0
    let matchend = matchend(a:complete_str, delimiter)
    while matchend >= 0
      let matchend = matchend(a:complete_str, delimiter, matchend)
      let delim_cnt += 1
    endwhile

    for candidate in candidates
      let split_list = split(candidate.word, delimiter.'\ze.', 1)
      if len(split_list) > 1
        let delimiter_sub = substitute(delimiter, '\\\([.^$]\)', '\1', 'g')
        let candidate.word = join(split_list[ : delim_cnt], delimiter_sub)
        let candidate.abbr = join(
              \ split(get(candidate, 'abbr', candidate.word),
              \             delimiter.'\ze.', 1)[ : delim_cnt],
              \ delimiter_sub)

        if g:neocomplcache_max_keyword_width >= 0
              \ && len(candidate.abbr) > g:neocomplcache_max_keyword_width
          let candidate.abbr = substitute(candidate.abbr,
                \ '\(\h\)\w*'.delimiter, '\1'.delimiter_sub, 'g')
        endif
        if delim_cnt+1 < len(split_list)
          let candidate.abbr .= delimiter_sub . '~'
          let candidate.dup = 0

          if g:neocomplcache_enable_auto_delimiter
            let candidate.word .= delimiter_sub
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
    let convert_candidates = filter(copy(candidates),
          \ "get(v:val, 'neocomplcache__convertable', 1)
          \  && v:val.word =~ '^\\u\\+$\\|^\\u\\?\\l\\+$'")

    if a:complete_str =~ '^\l\+$'
      for candidate in convert_candidates
        let candidate.word = tolower(candidate.word)
        if has_key(candidate, 'abbr')
          let candidate.abbr = tolower(candidate.abbr)
        endif
      endfor
    elseif a:complete_str =~ '^\u\+$'
      for candidate in convert_candidates
        let candidate.word = toupper(candidate.word)
        if has_key(candidate, 'abbr')
          let candidate.abbr = toupper(candidate.abbr)
        endif
      endfor
    elseif a:complete_str =~ '^\u\l\+$'
      for candidate in convert_candidates
        let candidate.word = toupper(candidate.word[0]).
              \ tolower(candidate.word[1:])
        if has_key(candidate, 'abbr')
          let candidate.abbr = toupper(candidate.abbr[0]).
                \ tolower(candidate.abbr[1:])
        endif
      endfor
    endif
  endif"}}}

  if g:neocomplcache_max_keyword_width >= 0 "{{{
    " Abbr check.
    for candidate in candidates
      let abbr = get(candidate, 'abbr', candidate.word)
      if len(abbr) > g:neocomplcache_max_keyword_width
        let len = neocomplcache#util#wcswidth(abbr)

        if len > g:neocomplcache_max_keyword_width
          let candidate.abbr = neocomplcache#util#truncate_smart(
                \ abbr, g:neocomplcache_max_keyword_width,
                \ g:neocomplcache_max_keyword_width/2, '..')
        endif
      endif
    endfor
  endif"}}}

  return candidates
endfunction"}}}
function! neocomplcache#complete#_set_results_pos(cur_text, ...) "{{{
  " Set context filetype.
  call neocomplcache#context_filetype#set()

  " Initialize sources.
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  for source in filter(values(neocomplcache#variables#get_sources()),
        \ '!v:val.loaded && (empty(v:val.filetypes) ||
        \       get(v:val.filetypes,
        \             neocomplcache.context_filetype, 0))')
    call neocomplcache#helper#call_hook(source, 'on_init', {})
    let source.loaded = 1
  endfor

  let sources = filter(copy(get(a:000, 0,
        \ neocomplcache#helper#get_sources_list())), 'v:val.loaded')
  if a:0 < 1
    call filter(sources, '!neocomplcache#is_plugin_locked(v:key)')
  endif

  " Try source completion. "{{{
  let complete_sources = []
  for source in values(sources)
    let context = source.neocomplcache__context
    let context.input = a:cur_text
    let context.complete_pos = -1
    let context.complete_str = ''
    let context.candidates = []

    let pos = winsaveview()

    try
      let complete_pos =
            \ has_key(source, 'get_keyword_pos') ?
            \ source.get_keyword_pos(context.input) :
            \ has_key(source, 'get_complete_position') ?
            \ source.get_complete_position(context) :
            \ neocomplcache#match_word(context.input)[0]
    catch
      call neocomplcache#print_error(v:throwpoint)
      call neocomplcache#print_error(v:exception)
      call neocomplcache#print_error(
            \ 'Error occured in source''s get_complete_position()!')
      call neocomplcache#print_error(
            \ 'Source name is ' . source.name)
      return complete_results
    finally
      if winsaveview() != pos
        call winrestview(pos)
      endif
    endtry

    if complete_pos < 0
      continue
    endif

    let complete_str = context.input[complete_pos :]
    if neocomplcache#is_auto_complete() &&
          \ neocomplcache#util#mb_strlen(complete_str)
          \     < neocomplcache#get_completion_length(source.name)
      " Skip.
      continue
    endif

    let context.complete_pos = complete_pos
    let context.complete_str = complete_str
    call add(complete_sources, source)
  endfor
  "}}}

  return complete_sources
endfunction"}}}
function! neocomplcache#complete#_set_results_words(sources) "{{{
  " Try source completion.
  for source in a:sources
    if neocomplcache#complete_check()
      return
    endif

    " Save options.
    let ignorecase_save = &ignorecase

    if neocomplcache#is_text_mode()
      let &ignorecase = 1
    elseif g:neocomplcache_enable_smart_case
          \ && result.complete_str =~ '\u'
      let &ignorecase = 0
    else
      let &ignorecase = g:neocomplcache_enable_ignore_case
    endif

    let pos = winsaveview()

    let context = source.neocomplcache__context

    try
      let context.candidates = has_key(source, 'get_keyword_list') ?
            \ source.get_keyword_list(context.complete_str) :
            \  has_key(source, 'get_complete_words') ?
            \ source.get_complete_words(
            \   context.complete_pos, context.complete_str) :
            \ source.gather_candidates(context)
    catch
      call neocomplcache#print_error(v:throwpoint)
      call neocomplcache#print_error(v:exception)
      call neocomplcache#print_error(
            \ 'Source name is ' . source.name)
      call neocomplcache#print_error(
            \ 'Error occured in source''s gather_candidates()!')
      return
    finally
      if winsaveview() != pos
        call winrestview(pos)
      endif
    endtry

    if g:neocomplcache_enable_debug
      echomsg source.name
    endif

    let &ignorecase = ignorecase_save
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
  return neocomplcache#get_source_rank(a:i2.name) -
        \ neocomplcache#get_source_rank(a:i1.name)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
