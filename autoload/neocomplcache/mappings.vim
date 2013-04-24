"=============================================================================
" FILE: mappings.vim
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

function! neocomplcache#mappings#define_default_mappings() "{{{
  inoremap <expr><silent> <Plug>(neocomplcache_start_unite_complete)
        \ unite#sources#neocomplcache#start_complete()
  inoremap <expr><silent> <Plug>(neocomplcache_start_unite_quick_match)
        \ unite#sources#neocomplcache#start_quick_match()
  inoremap <silent> <Plug>(neocomplcache_start_auto_complete)
        \ <C-x><C-u><C-r>=neocomplcache#mappings#popup_post()<CR>
  inoremap <silent> <Plug>(neocomplcache_start_auto_complete_no_select)
        \ <C-x><C-u><C-p>
  " \ <C-x><C-u><C-p>
  inoremap <silent> <Plug>(neocomplcache_start_omni_complete)
        \ <C-x><C-o><C-p>
endfunction"}}}

function! neocomplcache#mappings#smart_close_popup() "{{{
  return g:neocomplcache_enable_auto_select ?
        \ neocomplcache#mappings#cancel_popup() :
        \ neocomplcache#mappings#close_popup()
endfunction
"}}}
function! neocomplcache#mappings#close_popup() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.complete_str = ''
  let neocomplcache.skip_next_complete = 2
  let neocomplcache.candidates = []

  return pumvisible() ? "\<C-y>" : ''
endfunction
"}}}
function! neocomplcache#mappings#cancel_popup() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.skip_next_complete = 1
  call neocomplcache#helper#clear_result()

  return pumvisible() ? "\<C-e>" : ''
endfunction
"}}}

function! neocomplcache#mappings#popup_post() "{{{
  return  !pumvisible() ? "" :
        \ g:neocomplcache_enable_auto_select ? "\<C-p>\<Down>" :
        \ "\<C-p>"
endfunction"}}}

function! neocomplcache#mappings#undo_completion() "{{{
  if !exists(':NeoComplCacheDisable')
    return ''
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  " Get cursor word.
  let [complete_pos, complete_str] =
        \ neocomplcache#match_word(neocomplcache#get_cur_text(1))
  let old_keyword_str = neocomplcache.complete_str
  let neocomplcache.complete_str = complete_str

  return (!pumvisible() ? '' :
        \ complete_str ==# old_keyword_str ? "\<C-e>" : "\<C-y>")
        \. repeat("\<BS>", len(complete_str)) . old_keyword_str
endfunction"}}}

function! neocomplcache#mappings#complete_common_string() "{{{
  if !exists(':NeoComplCacheDisable')
    return ''
  endif

  " Save options.
  let ignorecase_save = &ignorecase

  " Get cursor word.
  let [complete_pos, complete_str] =
        \ neocomplcache#match_word(neocomplcache#get_cur_text(1))

  if neocomplcache#is_text_mode()
    let &ignorecase = 1
  elseif g:neocomplcache_enable_smart_case && complete_str =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase = g:neocomplcache_enable_ignore_case
  endif

  let is_fuzzy = g:neocomplcache_enable_fuzzy_completion

  try
    let g:neocomplcache_enable_fuzzy_completion = 0
    let neocomplcache = neocomplcache#get_current_neocomplcache()
    let candidates = neocomplcache#keyword_filter(
          \ copy(neocomplcache.candidates), complete_str)
  finally
    let g:neocomplcache_enable_fuzzy_completion = is_fuzzy
  endtry

  if empty(candidates)
    let &ignorecase = ignorecase_save

    return ''
  endif

  let common_str = candidates[0].word
  for keyword in candidates[1:]
    while !neocomplcache#head_match(keyword.word, common_str)
      let common_str = common_str[: -2]
    endwhile
  endfor
  if &ignorecase
    let common_str = tolower(common_str)
  endif

  let &ignorecase = ignorecase_save

  if common_str == ''
    return ''
  endif

  return (pumvisible() ? "\<C-e>" : '')
        \ . repeat("\<BS>", len(complete_str)) . common_str
endfunction"}}}

" Manual complete wrapper.
function! neocomplcache#mappings#start_manual_complete(...) "{{{
  if !neocomplcache#is_enabled()
    return ''
  endif

  " Set context filetype.
  call neocomplcache#context_filetype#set()

  " Set function.
  let &l:completefunc = 'neocomplcache#complete#sources_manual_complete'

  " Start complete.
  return "\<C-x>\<C-u>\<C-p>"
endfunction"}}}

function! neocomplcache#mappings#start_manual_complete_list(complete_pos, complete_str, candidates) "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let [neocomplcache.complete_pos,
        \ neocomplcache.complete_str, neocomplcache.candidates] =
        \ [a:complete_pos, a:complete_str, a:candidates]

  " Set function.
  let &l:completefunc = 'neocomplcache#complete#auto_complete'

  " Start complete.
  return "\<C-x>\<C-u>\<C-p>"
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
