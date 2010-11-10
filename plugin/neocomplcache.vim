"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 10 Oct 2010
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
" Version: 5.3, for Vim 7.0
" GetLatestVimScripts: 2620 1 :AutoInstall: neocomplcache
"=============================================================================

if v:version < 700
  echoerr 'neocomplcache does not work this version of Vim (' . v:version . ').'
  finish
elseif exists('g:loaded_neocomplcache')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=0 NeoComplCacheEnable call neocomplcache#enable()

" Obsolute options check."{{{
if exists('g:NeoComplCache_EnableAtStartup')
  echoerr 'g:NeoComplCache_EnableAtStartup option does not work this version of neocomplcache.'
endif
if exists('g:NeoComplCache_KeywordPatterns')
  echoerr 'g:NeoComplCache_KeywordPatterns option does not work this version of neocomplcache.'
endif
if exists('g:NeoComplCache_DictionaryFileTypeLists')
  echoerr 'g:NeoComplCache_DictionaryFileTypeLists option does not work this version of neocomplcache.'
endif
if exists('g:NeoComplCache_KeywordCompletionStartLength')
  echoerr 'g:NeoComplCache_KeywordCompletionStartLength option does not work this version of neocomplcache.'
endif
"}}}
" Global options definition."{{{
if !exists('g:neocomplcache_max_list')
  let g:neocomplcache_max_list = 100
endif
if !exists('g:neocomplcache_max_keyword_width')
  let g:neocomplcache_max_keyword_width = 50
endif
if !exists('g:neocomplcache_max_filename_width')
  let g:neocomplcache_max_filename_width = 15
endif
if !exists('g:neocomplcache_auto_completion_start_length')
  let g:neocomplcache_auto_completion_start_length = 2
endif
if !exists('g:neocomplcache_manual_completion_start_length')
  let g:neocomplcache_manual_completion_start_length = 2
endif
if !exists('g:neocomplcache_min_keyword_length')
  let g:neocomplcache_min_keyword_length = 4
endif
if !exists('g:neocomplcache_enable_ignore_case')
  let g:neocomplcache_enable_ignore_case = &ignorecase
endif
if !exists('g:neocomplcache_enable_smart_case')
  let g:neocomplcache_enable_smart_case = 0
endif
if !exists('g:neocomplcache_disable_auto_complete')
  let g:neocomplcache_disable_auto_complete = 0
endif
if !exists('g:neocomplcache_enable_wildcard')
  let g:neocomplcache_enable_wildcard = 1
endif
if !exists('g:neocomplcache_enable_quick_match')
  let g:neocomplcache_enable_quick_match = 0
endif
if !exists('g:neocomplcache_enable_camel_case_completion')
  let g:neocomplcache_enable_camel_case_completion = 0
endif
if !exists('g:neocomplcache_enable_underbar_completion')
  let g:neocomplcache_enable_underbar_completion = 0
endif
if !exists('g:neocomplcache_enable_caching_message')
  let g:neocomplcache_enable_caching_message = 1
endif
if !exists('g:neocomplcache_enable_cursor_hold_i')
  let g:neocomplcache_enable_cursor_hold_i = 0
endif
if !exists('g:neocomplcache_cursor_hold_i_time')
  let g:neocomplcache_cursor_hold_i_time = 300
endif
if !exists('g:neocomplcache_enable_auto_select')
  let g:neocomplcache_enable_auto_select = 0
endif
if !exists('g:neocomplcache_enable_auto_delimiter')
  let g:neocomplcache_enable_auto_delimiter = 0
endif
if !exists('g:neocomplcache_caching_limit_file_size')
  let g:neocomplcache_caching_limit_file_size = 500000
endif
if !exists('g:neocomplcache_disable_caching_buffer_name_pattern')
  let g:neocomplcache_disable_caching_buffer_name_pattern = ''
endif
if !exists('g:neocomplcache_lock_buffer_name_pattern')
  let g:neocomplcache_lock_buffer_name_pattern = ''
endif
if !exists('g:neocomplcache_force_caching_buffer_name_pattern')
  let g:neocomplcache_force_caching_buffer_name_pattern = ''
endif
if !exists('g:neocomplcache_disable_auto_select_buffer_name_pattern')
  let g:neocomplcache_disable_auto_select_buffer_name_pattern = ''
endif
if !exists('g:neocomplcache_ctags_program')
  let g:neocomplcache_ctags_program = 'ctags'
endif
if !exists('g:neocomplcache_plugin_disable')
  let g:neocomplcache_plugin_disable = {}
endif
if !exists('g:neocomplcache_plugin_completion_length')
  let g:neocomplcache_plugin_completion_length = {}
endif
if !exists('g:neocomplcache_plugin_rank')
  let g:neocomplcache_plugin_rank = {}
endif
if !exists('g:neocomplcache_temporary_dir')
  let g:neocomplcache_temporary_dir = '~/.neocon'
endif
let g:neocomplcache_temporary_dir = expand(g:neocomplcache_temporary_dir)
if !isdirectory(g:neocomplcache_temporary_dir)
  call mkdir(g:neocomplcache_temporary_dir, 'p')
endif
if !exists('g:neocomplcache_quick_match_table')
  let g:neocomplcache_quick_match_table = {
        \'a' : 0, 's' : 1, 'd' : 2, 'f' : 3, 'g' : 4, 'h' : 5, 'j' : 6, 'k' : 7, 'l' : 8, ';' : 9,
        \'q' : 10, 'w' : 11, 'e' : 12, 'r' : 13, 't' : 14, 'y' : 15, 'u' : 16, 'i' : 17, 'o' : 18, 'p' : 19, 
        \}
endif
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
