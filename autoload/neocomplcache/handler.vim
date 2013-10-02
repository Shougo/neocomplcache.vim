"=============================================================================
" FILE: handler.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 02 Oct 2013.
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

function! neocomplcache#handler#_on_moved_i() "{{{
  " Get cursor word.
  let cur_text = neocomplcache#get_cur_text(1)

  call s:close_preview_window()
endfunction"}}}
function! neocomplcache#handler#_on_insert_enter() "{{{
  if &l:foldmethod ==# 'expr' && foldlevel('.') != 0
    foldopen
  endif
endfunction"}}}
function! neocomplcache#handler#_on_insert_leave() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()

  let neocomplcache.cur_text = ''
  let neocomplcache.old_cur_text = ''

  call s:close_preview_window()
endfunction"}}}
function! neocomplcache#handler#_on_write_post() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()

  " Restore foldinfo.
  for winnr in filter(range(1, winnr('$')),
        \ "!empty(getwinvar(v:val, 'neocomplcache_foldinfo'))")
    let neocomplcache_foldinfo =
          \ getwinvar(winnr, 'neocomplcache_foldinfo')
    call setwinvar(winnr, '&foldmethod',
          \ neocomplcache_foldinfo.foldmethod)
    call setwinvar(winnr, '&foldexpr',
          \ neocomplcache_foldinfo.foldexpr)
    call setwinvar(winnr,
          \ 'neocomplcache_foldinfo', {})
  endfor
endfunction"}}}
function! neocomplcache#handler#_on_complete_done() "{{{
  " Get cursor word.
  let [_, candidate] = neocomplcache#match_word(
        \ neocomplcache#get_cur_text(1))
  if candidate == ''
    return
  endif

  let frequencies = neocomplcache#variables#get_frequencies()
  if !has_key(frequencies, candidate)
    let frequencies[candidate] = 20
  else
    let frequencies[candidate] += 20
  endif
endfunction"}}}
function! neocomplcache#handler#_change_update_time() "{{{
  if &updatetime > g:neocomplcache_cursor_hold_i_time
    " Change updatetime.
    let neocomplcache = neocomplcache#get_current_neocomplcache()
    let neocomplcache.update_time_save = &updatetime
    let &updatetime = g:neocomplcache_cursor_hold_i_time
  endif
endfunction"}}}
function! neocomplcache#handler#_restore_update_time() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  if &updatetime < neocomplcache.update_time_save
    " Restore updatetime.
    let &updatetime = neocomplcache.update_time_save
  endif
endfunction"}}}

function! neocomplcache#handler#_do_auto_complete(event) "{{{
  if s:check_in_do_auto_complete()
    return
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.skipped = 0
  let neocomplcache.event = a:event

  let cur_text = neocomplcache#get_cur_text(1)

  if g:neocomplcache_enable_debug
    echomsg 'cur_text = ' . cur_text
  endif

  " Prevent infinity loop.
  if s:is_skip_auto_complete(cur_text)
    " Make cache.
    if cur_text =~ '^\s*$\|\s\+$'
      if neocomplcache#is_enabled_source('buffer_complete')
        " Caching current cache line.
        call neocomplcache#sources#buffer_complete#caching_current_line()
      endif
      if neocomplcache#is_enabled_source('member_complete')
        " Caching current cache line.
        call neocomplcache#sources#member_complete#caching_current_line()
      endif
    endif

    if g:neocomplcache_enable_debug
      echomsg 'Skipped.'
    endif

    call neocomplcache#helper#clear_result()
    return
  endif

  let neocomplcache.old_cur_text = cur_text

  if neocomplcache#helper#is_omni_complete(cur_text)
    call feedkeys("\<Plug>(neocomplcache_start_omni_complete)")
    return
  endif

  " Check multibyte input or eskk.
  if neocomplcache#is_eskk_enabled()
        \ || neocomplcache#is_multibyte_input(cur_text)
    if g:neocomplcache_enable_debug
      echomsg 'Skipped.'
    endif

    return
  endif

  " Check complete position.
  let complete_results = neocomplcache#complete#_set_results_pos(cur_text)
  if empty(complete_results)
    if g:neocomplcache_enable_debug
      echomsg 'Skipped.'
    endif

    return
  endif

  let &l:completefunc = 'neocomplcache#complete#auto_complete'

  if neocomplcache#is_prefetch()
    " Do prefetch.
    let neocomplcache.complete_results =
          \ neocomplcache#complete#_get_results(cur_text)

    if empty(neocomplcache.complete_results)
      if g:neocomplcache_enable_debug
        echomsg 'Skipped.'
      endif

      " Skip completion.
      let &l:completefunc = 'neocomplcache#complete#manual_complete'
      call neocomplcache#helper#clear_result()
      return
    endif
  endif

  call s:save_foldinfo()

  " Set options.
  set completeopt-=menu
  set completeopt-=longest
  set completeopt+=menuone

  " Start auto complete.
  call feedkeys(&l:formatoptions !~ 'a' ?
        \ "\<Plug>(neocomplcache_start_auto_complete)":
        \ "\<Plug>(neocomplcache_start_auto_complete_no_select)")
endfunction"}}}

function! s:save_foldinfo() "{{{
  " Save foldinfo.
  let winnrs = filter(range(1, winnr('$')),
        \ "winbufnr(v:val) == bufnr('%')")

  " Note: for foldmethod=expr or syntax.
  call filter(winnrs, "
        \  (getwinvar(v:val, '&foldmethod') ==# 'expr' ||
        \   getwinvar(v:val, '&foldmethod') ==# 'syntax') &&
        \  getwinvar(v:val, '&modifiable')")
  for winnr in winnrs
    call setwinvar(winnr, 'neocomplcache_foldinfo', {
          \ 'foldmethod' : getwinvar(winnr, '&foldmethod'),
          \ 'foldexpr'   : getwinvar(winnr, '&foldexpr')
          \ })
    call setwinvar(winnr, '&foldmethod', 'manual')
    call setwinvar(winnr, '&foldexpr', 0)
  endfor
endfunction"}}}
function! s:check_in_do_auto_complete() "{{{
  if neocomplcache#is_locked()
    return 1
  endif

  if &l:completefunc == ''
    let &l:completefunc = 'neocomplcache#complete#manual_complete'
  endif

  " Detect completefunc.
  if &l:completefunc !~# '^neocomplcache#'
    if &l:buftype =~ 'nofile'
      return 1
    endif

    if g:neocomplcache_force_overwrite_completefunc
      " Set completefunc.
      let &l:completefunc = 'neocomplcache#complete#manual_complete'
    else
      " Warning.
      redir => output
      99verbose setl completefunc?
      redir END
      call neocomplcache#print_error(output)
      call neocomplcache#print_error(
            \ 'Another plugin set completefunc! Disabled neocomplcache.')
      NeoComplCacheLock
      return 1
    endif
  endif

  " Detect AutoComplPop.
  if exists('g:acp_enableAtStartup') && g:acp_enableAtStartup
    call neocomplcache#print_error(
          \ 'Detected enabled AutoComplPop! Disabled neocomplcache.')
    NeoComplCacheLock
    return 1
  endif
endfunction"}}}
function! s:is_skip_auto_complete(cur_text) "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()

  if a:cur_text =~ '^\s*$\|\s\+$'
        \ || a:cur_text == neocomplcache.old_cur_text
        \ || (g:neocomplcache_lock_iminsert && &l:iminsert)
        \ || (&l:formatoptions =~# '[tc]' && &l:textwidth > 0
        \     && neocomplcache#util#wcswidth(a:cur_text) >= &l:textwidth)
    return 1
  endif

  if !neocomplcache.skip_next_complete
    return 0
  endif

  " Check delimiter pattern.
  let is_delimiter = 0
  let filetype = neocomplcache#get_context_filetype()

  for delimiter in ['/', '\.'] +
        \ get(g:neocomplcache_delimiter_patterns, filetype, [])
    if a:cur_text =~ delimiter . '$'
      let is_delimiter = 1
      break
    endif
  endfor

  if is_delimiter && neocomplcache.skip_next_complete == 2
    let neocomplcache.skip_next_complete = 0
    return 0
  endif

  let neocomplcache.skip_next_complete = 0
  let neocomplcache.cur_text = ''
  let neocomplcache.old_cur_text = ''

  return 1
endfunction"}}}
function! s:close_preview_window() "{{{
  if g:neocomplcache_enable_auto_close_preview &&
        \ bufname('%') !=# '[Command Line]' &&
        \ winnr('$') != 1 && !&l:previewwindow
    " Close preview window.
    pclose!
  endif
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
