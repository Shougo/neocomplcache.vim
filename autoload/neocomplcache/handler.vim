"=============================================================================
" FILE: handler.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 11 Apr 2013.
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
  let cur_text = neocomplcache#get_cur_text()

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

  if g:neocomplcache_enable_auto_close_preview &&
        \ bufname('%') !=# '[Command Line]'
    " Close preview window.
    pclose!
  endif
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

  " Restore foldinfo.
  " Note: settabwinvar() in insert mode has bug before 7.3.768.
  for tabnr in (v:version > 703 || (v:version == 703 && has('patch768')) ?
        \ range(1, tabpagenr('$')) : [tabpagenr()])
    for winnr in filter(range(1, tabpagewinnr(tabnr, '$')),
          \ "!empty(gettabwinvar(tabnr, v:val, 'neocomplcache_foldinfo'))")
      let neocomplcache_foldinfo =
            \ gettabwinvar(tabnr, winnr, 'neocomplcache_foldinfo')
      " Note: To disabled restore foldinfo is too heavy.
      " call settabwinvar(tabnr, winnr, '&foldmethod',
      "       \ neocomplcache_foldinfo.foldmethod)
      " call settabwinvar(tabnr, winnr, '&foldexpr',
      "       \ neocomplcache_foldinfo.foldexpr)
      call settabwinvar(tabnr, winnr,
            \ 'neocomplcache_foldinfo', {})
    endfor
  endfor

  if g:neocomplcache_enable_auto_close_preview &&
        \ bufname('%') !=# '[Command Line]'
    " Close preview window.
    pclose!
  endif
endfunction"}}}
function! neocomplcache#handler#_save_foldinfo() "{{{
  if line('$') < 1000
    return
  endif

  " Save foldinfo.
  " Note: settabwinvar() in insert mode has bug before 7.3.768.
  for tabnr in filter((v:version > 703 || (v:version == 703 && has('patch768')) ?
        \ range(1, tabpagenr('$')) : [tabpagenr()]),
        \ "index(tabpagebuflist(v:val), bufnr('%')) >= 0")
    let winnrs = range(1, tabpagewinnr(tabnr, '$'))
    if tabnr == tabpagenr()
      call filter(winnrs, "winbufnr(v:val) == bufnr('%')")
    endif

    " Note: for foldmethod=expr or syntax.
    call filter(winnrs, "
          \  (gettabwinvar(tabnr, v:val, '&foldmethod') ==# 'expr' ||
          \   gettabwinvar(tabnr, v:val, '&foldmethod') ==# 'syntax') &&
          \  gettabwinvar(tabnr, v:val, '&modifiable')")
    for winnr in winnrs
      call settabwinvar(tabnr, winnr, 'neocomplcache_foldinfo', {
            \ 'foldmethod' : gettabwinvar(tabnr, winnr, '&foldmethod'),
            \ 'foldexpr'   : gettabwinvar(tabnr, winnr, '&foldexpr')
            \ })
      call settabwinvar(tabnr, winnr, '&foldmethod', 'manual')
      call settabwinvar(tabnr, winnr, '&foldexpr', 0)
    endfor
  endfor
endfunction"}}}
function! neocomplcache#handler#_on_complete_done() "{{{
  " Get cursor word.
  let [_, candidate] = neocomplcache#match_word(
        \ neocomplcache#get_cur_text(1))
  if candidate == ''
    return
  endif

  let frequencies = neocomplcache#_get_frequencies()
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

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
