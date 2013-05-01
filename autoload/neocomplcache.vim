"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 01 May 2013.
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

if !exists('g:loaded_neocomplcache')
  runtime! plugin/neocomplcache.vim
endif

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

function! neocomplcache#initialize() "{{{
  return neocomplcache#init#enable()
endfunction"}}}

function! neocomplcache#get_current_neocomplcache() "{{{
  if !exists('b:neocomplcache')
    call neocomplcache#init#_current_neocomplcache()
  endif

  return b:neocomplcache
endfunction"}}}
function! neocomplcache#get_context() "{{{
  return neocomplcache#get_current_neocomplcache().context
endfunction"}}}

" Source helper. "{{{
function! neocomplcache#define_source(source) "{{{
  let sources = neocomplcache#variables#get_sources()
  for source in neocomplcache#util#convert2list(a:source)
    let sources[source.name] = neocomplcache#init#_source(source)
  endfor
endfunction"}}}
function! neocomplcache#define_filter(filter) "{{{
  let filters = neocomplcache#variables#get_filters()
  for filter in neocomplcache#util#convert2list(a:filter)
    let filters[filter.name] = neocomplcache#init#_filter(filter)
  endfor
endfunction"}}}
function! neocomplcache#available_sources() "{{{
  return copy(neocomplcache#variables#get_sources())
endfunction"}}}
function! neocomplcache#custom_source(source_name, option_name, value) "{{{
  let custom_sources = neocomplcache#variables#get_custom().sources

  for key in split(a:source_name, '\s*,\s*')
    if !has_key(custom_sources, key)
      let custom_sources[key] = {}
    endif

    let custom_sources[key][a:option_name] = a:value
  endfor
endfunction"}}}

function! neocomplcache#is_enabled_source(source_name) "{{{
  return neocomplcache#helper#is_enabled_source(a:source_name)
endfunction"}}}
function! neocomplcache#is_disabled_source(source_name) "{{{
  let filetype = neocomplcache#get_context_filetype()

  let disabled_sources = get(
        \ g:neocomplcache_disabled_sources_list, filetype,
        \   get(g:neocomplcache_disabled_sources_list, '_', []))
  return index(disabled_sources, a:source_name) >= 0
endfunction"}}}
function! neocomplcache#keyword_escape(complete_str) "{{{
  return neocomplcache#helper#keyword_escape(a:complete_str)
endfunction"}}}
function! neocomplcache#keyword_filter(list, complete_str) "{{{
  return neocomplcache#filters#keyword_filter(a:list, a:complete_str)
endfunction"}}}
function! neocomplcache#dup_filter(list) "{{{
  return neocomplcache#util#dup_filter(a:list)
endfunction"}}}
function! neocomplcache#check_match_filter(complete_str) "{{{
  return neocomplcache#keyword_escape(a:complete_str) =~ '[^\\]\*\|\\+'
endfunction"}}}
function! neocomplcache#check_completion_length_match(complete_str, completion_length) "{{{
  return neocomplcache#keyword_escape(
        \ a:complete_str[: a:completion_length-1]) =~
        \'[^\\]\*\|\\+\|\\%(\|\\|'
endfunction"}}}
function! neocomplcache#dictionary_filter(dictionary, complete_str) "{{{
  return neocomplcache#filters#dictionary_filter(a:dictionary, a:complete_str)
endfunction"}}}
function! neocomplcache#unpack_dictionary(dict) "{{{
  let ret = []
  let values = values(a:dict)
  for l in (type(values) == type([]) ?
        \ values : values(values))
    let ret += (type(l) == type([])) ? copy(l) : values(l)
  endfor

  return ret
endfunction"}}}
function! neocomplcache#pack_dictionary(list) "{{{
  let completion_length = 2
  let ret = {}
  for candidate in a:list
    let key = tolower(candidate.word[: completion_length-1])
    if !has_key(ret, key)
      let ret[key] = {}
    endif

    let ret[key][candidate.word] = candidate
  endfor

  return ret
endfunction"}}}
function! neocomplcache#add_dictionaries(dictionaries) "{{{
  if empty(a:dictionaries)
    return {}
  endif

  let ret = a:dictionaries[0]
  for dict in a:dictionaries[1:]
    for [key, value] in items(dict)
      if has_key(ret, key)
        let ret[key] += value
      else
        let ret[key] = value
      endif
    endfor
  endfor

  return ret
endfunction"}}}

function! neocomplcache#system(...) "{{{
  let V = vital#of('neocomplcache')
  return call(V.system, a:000)
endfunction"}}}
function! neocomplcache#has_vimproc() "{{{
  return neocomplcache#util#has_vimproc()
endfunction"}}}

function! neocomplcache#get_cur_text(...) "{{{
  " Return cached text.
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  return (a:0 == 0 && mode() ==# 'i' &&
        \  neocomplcache.cur_text != '') ?
        \ neocomplcache.cur_text : neocomplcache#helper#get_cur_text()
endfunction"}}}
function! neocomplcache#get_next_keyword() "{{{
  " Get next keyword.
  let pattern = '^\%(' . neocomplcache#get_next_keyword_pattern() . '\m\)'

  return matchstr('a'.getline('.')[len(neocomplcache#get_cur_text()) :], pattern)[1:]
endfunction"}}}
function! neocomplcache#get_completion_length(source_name) "{{{
  let sources = neocomplcache#variables#get_sources()
  if !has_key(sources, a:source_name)
    " Unknown.
    return -1
  endif

  if neocomplcache#is_auto_complete()
        \ && neocomplcache#get_current_neocomplcache().completion_length >= 0
    return neocomplcache#get_current_neocomplcache().completion_length
  else
    return sources[a:source_name].min_pattern_length
  endif
endfunction"}}}
function! neocomplcache#set_completion_length(source_name, length) "{{{
  let custom = neocomplcache#variables#get_custom().sources
  if !has_key(custom, a:source_name)
    let custom[a:source_name] = {}
  endif

  if !has_key(custom[a:source_name], 'min_pattern_length')
    let custom[a:source_name].min_pattern_length = a:length
  endif
endfunction"}}}
function! neocomplcache#get_keyword_pattern(...) "{{{
  let filetype = a:0 != 0? a:000[0] : neocomplcache#get_context_filetype()

  return neocomplcache#helper#unite_patterns(
        \ g:neocomplcache_keyword_patterns, filetype)
endfunction"}}}
function! neocomplcache#get_next_keyword_pattern(...) "{{{
  let filetype = a:0 != 0? a:000[0] : neocomplcache#get_context_filetype()
  let next_pattern = neocomplcache#helper#unite_patterns(
        \ g:neocomplcache_next_keyword_patterns, filetype)

  return (next_pattern == '' ? '' : next_pattern.'\m\|')
        \ . neocomplcache#get_keyword_pattern(filetype)
endfunction"}}}
function! neocomplcache#get_keyword_pattern_end(...) "{{{
  let filetype = a:0 != 0? a:000[0] : neocomplcache#get_context_filetype()

  return '\%('.neocomplcache#get_keyword_pattern(filetype).'\m\)$'
endfunction"}}}
function! neocomplcache#match_word(...) "{{{
  return call('neocomplcache#helper#match_word', a:000)
endfunction"}}}
function! neocomplcache#is_enabled() "{{{
  return neocomplcache#init#is_enabled()
endfunction"}}}
function! neocomplcache#is_locked(...) "{{{
  let bufnr = a:0 > 0 ? a:1 : bufnr('%')
  return !neocomplcache#is_enabled() || &paste
        \ || g:neocomplcache_disable_auto_complete
        \ || neocomplcache#get_current_neocomplcache().lock
        \ || (g:neocomplcache_lock_buffer_name_pattern != '' &&
        \   bufname(bufnr) =~ g:neocomplcache_lock_buffer_name_pattern)
        \ || &l:omnifunc ==# 'fuf#onComplete'
endfunction"}}}
function! neocomplcache#is_plugin_locked(source_name) "{{{
  if !neocomplcache#is_enabled()
    return 1
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  return get(neocomplcache.lock_sources, a:source_name, 0)
endfunction"}}}
function! neocomplcache#is_auto_select() "{{{
  return g:neocomplcache_enable_auto_select && !neocomplcache#is_eskk_enabled()
endfunction"}}}
function! neocomplcache#is_auto_complete() "{{{
  return &l:completefunc == 'neocomplcache#complete#auto_complete'
endfunction"}}}
function! neocomplcache#is_sources_complete() "{{{
  return &l:completefunc == 'neocomplcache#complete#sources_manual_complete'
endfunction"}}}
function! neocomplcache#is_eskk_enabled() "{{{
  return exists('*eskk#is_enabled') && eskk#is_enabled()
endfunction"}}}
function! neocomplcache#is_eskk_convertion(cur_text) "{{{
  return neocomplcache#is_eskk_enabled()
        \   && eskk#get_preedit().get_henkan_phase() !=#
        \             g:eskk#preedit#PHASE_NORMAL
endfunction"}}}
function! neocomplcache#is_multibyte_input(cur_text) "{{{
  return (exists('b:skk_on') && b:skk_on)
        \     || char2nr(split(a:cur_text, '\zs')[-1]) > 0x80
endfunction"}}}
function! neocomplcache#is_text_mode() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  return get(g:neocomplcache_text_mode_filetypes,
        \ neocomplcache.context_filetype, 0)
endfunction"}}}
function! neocomplcache#is_windows() "{{{
  return neocomplcache#util#is_windows()
endfunction"}}}
function! neocomplcache#is_win() "{{{
  return neocomplcache#util#is_windows()
endfunction"}}}
function! neocomplcache#is_prefetch() "{{{
  return !neocomplcache#is_locked() &&
        \ (g:neocomplcache_enable_prefetch || &l:formatoptions =~# 'a')
endfunction"}}}
function! neocomplcache#exists_echodoc() "{{{
  return exists('g:loaded_echodoc') && g:loaded_echodoc
endfunction"}}}
function! neocomplcache#within_comment() "{{{
  return neocomplcache#helper#get_syn_name(1) ==# 'Comment'
endfunction"}}}
function! neocomplcache#print_caching(string) "{{{
  if g:neocomplcache_enable_caching_message
    redraw
    echon a:string
  endif
endfunction"}}}
function! neocomplcache#print_error(string) "{{{
  echohl Error | echomsg a:string | echohl None
endfunction"}}}
function! neocomplcache#print_warning(string) "{{{
  echohl WarningMsg | echomsg a:string | echohl None
endfunction"}}}
function! neocomplcache#head_match(checkstr, headstr) "{{{
  let checkstr = &ignorecase ?
        \ tolower(a:checkstr) : a:checkstr
  let headstr = &ignorecase ?
        \ tolower(a:headstr) : a:headstr
  return stridx(checkstr, headstr) == 0
endfunction"}}}
function! neocomplcache#get_source_filetypes(filetype) "{{{
  return neocomplcache#helper#get_source_filetypes(a:filetype)
endfunction"}}}
function! neocomplcache#get_sources_list(dictionary, filetype) "{{{
  return neocomplcache#helper#ftdictionary2list(a:dictionary, a:filetype)
endfunction"}}}
function! neocomplcache#escape_match(str) "{{{
  return escape(a:str, '~"*\.^$[]')
endfunction"}}}
function! neocomplcache#get_context_filetype(...) "{{{
  if !neocomplcache#is_enabled()
    return &filetype
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  if a:0 != 0 || mode() !=# 'i' ||
        \ neocomplcache.context_filetype == ''
    call neocomplcache#context_filetype#set()
  endif

  return neocomplcache.context_filetype
endfunction"}}}
function! neocomplcache#get_context_filetype_range(...) "{{{
  if !neocomplcache#is_enabled()
    return [[1, 1], [line('$'), len(getline('$'))+1]]
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  if a:0 != 0 || mode() !=# 'i' ||
        \ neocomplcache.context_filetype == ''
    call neocomplcache#context_filetype#set()
  endif

  if neocomplcache.context_filetype ==# &filetype
    return [[1, 1], [line('$'), len(getline('$'))+1]]
  endif

  return neocomplcache.context_filetype_range
endfunction"}}}
function! neocomplcache#print_debug(expr) "{{{
  if g:neocomplcache_enable_debug
    echomsg string(a:expr)
  endif
endfunction"}}}
function! neocomplcache#get_temporary_directory() "{{{
  let directory = neocomplcache#util#substitute_path_separator(
        \ neocomplcache#util#expand(g:neocomplcache_temporary_dir))
  if !isdirectory(directory)
    call mkdir(directory, 'p')
  endif

  return directory
endfunction"}}}
function! neocomplcache#complete_check() "{{{
  return neocomplcache#helper#complete_check()
endfunction"}}}
function! neocomplcache#check_invalid_omnifunc(omnifunc) "{{{
  return a:omnifunc == '' || (a:omnifunc !~ '#' && !exists('*' . a:omnifunc))
endfunction"}}}

function! neocomplcache#set_dictionary_helper(variable, keys, value) "{{{
  return neocomplcache#util#set_dictionary_helper(
        \ a:variable, a:keys, a:value)
endfunction"}}}
function! neocomplcache#disable_default_dictionary(variable) "{{{
  return neocomplcache#util#disable_default_dictionary(a:variable)
endfunction"}}}
function! neocomplcache#filetype_complete(arglead, cmdline, cursorpos) "{{{
  return neocomplcache#helper#filetype_complete(a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}
"}}}

" Key mapping functions. "{{{
function! neocomplcache#smart_close_popup()
  return neocomplcache#mappings#smart_close_popup()
endfunction
function! neocomplcache#close_popup()
  return neocomplcache#mappings#close_popup()
endfunction
function! neocomplcache#cancel_popup()
  return neocomplcache#mappings#cancel_popup()
endfunction
function! neocomplcache#undo_completion()
  return neocomplcache#mappings#undo_completion()
endfunction
function! neocomplcache#complete_common_string()
  return neocomplcache#mappings#complete_common_string()
endfunction
function! neocomplcache#start_manual_complete(...)
  return call('neocomplcache#mappings#start_manual_complete', a:000)
endfunction
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
