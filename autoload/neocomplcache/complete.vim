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
          \ || neocomplcache#is_omni_complete(cur_text)
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
            \ neocomplcache#get_complete_results(cur_text)
    endif
    let cur_keyword_pos =
          \ neocomplcache#get_cur_keyword_pos(neocomplcache.complete_results)

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
    let cur_keyword_pos = neocomplcache#get_cur_keyword_pos(
          \ neocomplcache.complete_results)
    let neocomplcache.complete_words = neocomplcache#get_complete_words(
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
    let s:use_sources = s:get_sources_list(type(sources) == type([]) ?
          \ sources : [sources])

    " Get cur_keyword_pos.
    let complete_results = neocomplcache#get_complete_results(
          \ neocomplcache#get_cur_text(1), s:use_sources)
    let neocomplcache.cur_keyword_pos =
          \ neocomplcache#get_cur_keyword_pos(complete_results)

    if neocomplcache.cur_keyword_pos < 0
      call neocomplcache#_clear_result()

      return -2
    endif

    let neocomplcache.complete_results = complete_results

    return neocomplcache.cur_keyword_pos
  endif

  let neocomplcache.cur_keyword_pos =
        \ neocomplcache#get_cur_keyword_pos(neocomplcache.complete_results)
  let complete_words = neocomplcache#get_complete_words(
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

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
