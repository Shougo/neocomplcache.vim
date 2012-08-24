"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Aug 2012.
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
" Version: 7.1, for Vim 7.2
" GetLatestVimScripts: 2620 1 :AutoInstall: neocomplcache
"=============================================================================

if exists('g:loaded_neocomplcache')
  finish
elseif v:version < 702
  echoerr 'neocomplcache does not work this version of Vim (' . v:version . ').'
  finish
elseif $SUDO_USER != '' && $USER !=# $SUDO_USER
      \ && $HOME !=# expand('~'.$USER)
  echoerr '"sudo vim" and $HOME is not same to /root are detected.'
        \.'Please use sudo.vim plugin instead of sudo command or set always_set_home in sudoers.'
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=0 -bar NeoComplCacheEnable
      \ call neocomplcache#enable()
command! -nargs=0 -bar NeoComplCacheDisable
      \ call neocomplcache#disable()
command! -nargs=0 -bar NeoComplCacheLock
      \ call neocomplcache#lock()
command! -nargs=0 -bar NeoComplCacheUnlock
      \ call neocomplcache#unlock()
command! -nargs=0 -bar NeoComplCacheToggle
      \ call neocomplcache#toggle_lock()
command! -nargs=1 -bar NeoComplCacheLockSource
      \ call neocomplcache#lock_source(<q-args>)
command! -nargs=1 -bar NeoComplCacheUnlockSource
      \ call neocomplcache#unlock_source(<q-args>)
if v:version >= 703
  command! -nargs=1 -bar -complete=filetype NeoComplCacheSetFileType
        \ call neocomplcache#set_file_type(<q-args>)
else
  command! -nargs=1 -bar NeoComplCacheSetFileType
        \ call neocomplcache#set_file_type(<q-args>)
endif

" Warning if using obsolute mappings."{{{
silent! inoremap <unique> <Plug>(neocomplcache_snippets_expand)
      \ <C-o>:echoerr <SID>print_snippets_complete_error()<CR>
silent! snoremap <unique> <Plug>(neocomplcache_snippets_expand)
      \ :<C-u>:echoerr <SID>print_snippets_complete_error()<CR>
silent! inoremap <unique> <Plug>(neocomplcache_snippets_jump)
      \ <C-o>:echoerr <SID>print_snippets_complete_error()<CR>
silent! snoremap <unique> <Plug>(neocomplcache_snippets_jump)
      \ :<C-u>:echoerr <SID>print_snippets_complete_error()<CR>
silent! inoremap <unique> <Plug>(neocomplcache_snippets_force_expand)
      \ <C-o>:echoerr <SID>print_snippets_complete_error()<CR>
silent! snoremap <unique> <Plug>(neocomplcache_snippets_force_expand)
      \ :<C-u>:echoerr <SID>print_snippets_complete_error()<CR>
silent! inoremap <unique> <Plug>(neocomplcache_snippets_force_jump)
      \ <C-o>:echoerr <SID>print_snippets_complete_error()<CR>
silent! snoremap <unique> <Plug>(neocomplcache_snippets_force_jump)
      \ :<C-u>:echoerr <SID>print_snippets_complete_error()<CR>
function! s:print_snippets_complete_error()
  return 'Warning: neocomplcache snippets source was splitted!'
      \ .' You should install snippets_complete source from'
      \ .' "https://github.com/Shougo/neocomplcache-snippets-complete"'
endfunction"}}}

" Global options definition."{{{
let g:neocomplcache_max_list =
      \ get(g:, 'neocomplcache_max_list', 100)
let g:neocomplcache_max_keyword_width =
      \ get(g:, 'neocomplcache_max_keyword_width', 50)
let g:neocomplcache_max_menu_width =
      \ get(g:, 'neocomplcache_max_menu_width', 15)
let g:neocomplcache_auto_completion_start_length =
      \ get(g:, 'neocomplcache_auto_completion_start_length', 2)
let g:neocomplcache_manual_completion_start_length =
      \ get(g:, 'neocomplcache_manual_completion_start_length', 0)
let g:neocomplcache_min_keyword_length =
      \ get(g:, 'neocomplcache_min_keyword_length', 4)
let g:neocomplcache_enable_ignore_case =
      \ get(g:, 'neocomplcache_enable_ignore_case', &ignorecase)
let g:neocomplcache_enable_smart_case =
      \ get(g:, 'neocomplcache_enable_smart_case', &infercase)
let g:neocomplcache_disable_auto_complete =
      \ get(g:, 'neocomplcache_disable_auto_complete', 0)
let g:neocomplcache_enable_wildcard =
      \ get(g:, 'neocomplcache_enable_wildcard', 1)
let g:neocomplcache_enable_camel_case_completion =
      \ get(g:, 'neocomplcache_enable_camel_case_completion', 0)
let g:neocomplcache_enable_underbar_completion =
      \ get(g:, 'neocomplcache_enable_underbar_completion', 0)
let g:neocomplcache_enable_fuzzy_completion =
      \ get(g:, 'neocomplcache_enable_fuzzy_completion', 0)
let g:neocomplcache_fuzzy_completion_start_length =
      \ get(g:, 'neocomplcache_fuzzy_completion_start_length', 3)
let g:neocomplcache_enable_caching_message =
      \ get(g:, 'neocomplcache_enable_caching_message', 1)
let g:neocomplcache_enable_insert_char_pre =
      \ get(g:, 'neocomplcache_enable_insert_char_pre', 0)
let g:neocomplcache_enable_cursor_hold_i =
      \ get(g:, 'neocomplcache_enable_cursor_hold_i', 0)
let g:neocomplcache_cursor_hold_i_time =
      \ get(g:, 'neocomplcache_cursor_hold_i_time', 300)
let g:neocomplcache_enable_auto_select =
      \ get(g:, 'neocomplcache_enable_auto_select', 0)
let g:neocomplcache_enable_auto_delimiter =
      \ get(g:, 'neocomplcache_enable_auto_delimiter', 0)
let g:neocomplcache_caching_limit_file_size =
      \ get(g:, 'neocomplcache_caching_limit_file_size', 500000)
let g:neocomplcache_disable_caching_file_path_pattern =
      \ get(g:, 'neocomplcache_disable_caching_file_path_pattern', '')
let g:neocomplcache_lock_buffer_name_pattern =
      \ get(g:, 'neocomplcache_lock_buffer_name_pattern', '')
let g:neocomplcache_compare_function =
      \ get(g:, 'neocomplcache_compare_function', 'neocomplcache#compare_rank')
let g:neocomplcache_ctags_program =
      \ get(g:, 'neocomplcache_ctags_program', 'ctags')
let g:neocomplcache_force_overwrite_completefunc =
      \ get(g:, 'neocomplcache_force_overwrite_completefunc', 0)
let g:neocomplcache_enable_prefetch =
      \ get(g:, 'neocomplcache_enable_prefetch',
      \  !(v:version > 703 || v:version == 703 && has('patch519'))
      \ || (has('gui_running') && has('xim'))
      \ )
let g:neocomplcache_lock_iminsert =
      \ get(g:, 'neocomplcache_lock_iminsert', 0)
let g:neocomplcache_release_cache_time =
      \ get(g:, 'neocomplcache_release_cache_time', 900)

if exists('g:neocomplcache_plugin_disable')
  let g:neocomplcache_source_disable =
        \ g:neocomplcache_plugin_disable
endif
let g:neocomplcache_source_disable =
      \ get(g:, 'neocomplcache_source_disable', {})
if exists('g:neocomplcache_plugin_completion_length')
  let g:neocomplcache_source_completion_length =
        \ g:neocomplcache_plugin_completion_length
endif
let g:neocomplcache_source_completion_length =
      \ get(g:, 'neocomplcache_source_completion_length', {})
if exists('g:neocomplcache_plugin_rank')
  let g:neocomplcache_source_rank = g:neocomplcache_plugin_rank
endif
let g:neocomplcache_source_rank =
      \ get(g:, 'neocomplcache_source_rank', {})

let g:neocomplcache_temporary_dir =
      \ get(g:, 'neocomplcache_temporary_dir', expand('~/.neocon'))
let g:neocomplcache_enable_debug =
      \ get(g:, 'neocomplcache_enable_debug', 0)
if exists('g:neocomplcache_enable_at_startup') && g:neocomplcache_enable_at_startup
  augroup neocomplcache
    autocmd!
    " Enable startup.
    autocmd VimEnter * call neocomplcache#enable()
  augroup END
endif"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_neocomplcache = 1

" vim: foldmethod=marker
