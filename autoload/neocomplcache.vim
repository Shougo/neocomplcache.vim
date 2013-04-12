"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
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

if !exists('g:loaded_neocomplcache')
  runtime! plugin/neocomplcache.vim
endif

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

function! s:initialize_script_variables() "{{{
  let s:is_enabled = 1
  let s:complfunc_sources = {}
  let s:plugin_sources = {}
  let s:ftplugin_sources = {}
  let s:loaded_ftplugin_sources = {}
  let s:loaded_source_files = {}
  let s:use_sources = {}
  let s:filetype_frequencies = {}
  let s:loaded_all_sources = 0
  let s:runtimepath_save = ''
endfunction"}}}

function! s:initialize_autocmds() "{{{
  augroup neocomplcache
    autocmd!
    autocmd InsertEnter *
          \ call neocomplcache#handler#_on_insert_enter()
    autocmd InsertLeave *
          \ call neocomplcache#handler#_on_insert_leave()
    autocmd CursorMovedI *
          \ call neocomplcache#handler#_on_moved_i()
    autocmd BufWritePost *
          \ call neocomplcache#handler#_on_write_post()
  augroup END

  if g:neocomplcache_enable_insert_char_pre
        \ && (v:version > 703 || v:version == 703 && has('patch418'))
    autocmd neocomplcache InsertCharPre *
          \ call neocomplcache#handler#_do_auto_complete('InsertCharPre')
  elseif g:neocomplcache_enable_cursor_hold_i
    augroup neocomplcache
      autocmd CursorHoldI *
            \ call neocomplcache#handler#_do_auto_complete('CursorHoldI')
      autocmd InsertEnter *
            \ call neocomplcache#handler#_change_update_time()
      autocmd InsertLeave *
            \ call neocomplcache#handler#_restore_update_time()
    augroup END
  else
    autocmd neocomplcache CursorMovedI *
          \ call neocomplcache#handler#_do_auto_complete('CursorMovedI')
  endif

  if (v:version > 703 || v:version == 703 && has('patch598'))
    autocmd neocomplcache CompleteDone *
          \ call neocomplcache#handler#_on_complete_done()
  endif
endfunction"}}}

function! s:initialize_others() "{{{
  call neocomplcache#init#_initialize_variables()

  call neocomplcache#context_filetype#initialize()

  call neocomplcache#commands#_initialize()

  " Save options.
  let s:completefunc_save = &completefunc
  let s:completeopt_save = &completeopt

  " Set completefunc.
  let &completefunc = 'neocomplcache#complete#manual_complete'
  let &l:completefunc = 'neocomplcache#complete#manual_complete'

  " For auto complete keymappings.
  call neocomplcache#mappings#define_default_mappings()

  " Detect set paste.
  if &paste
    redir => output
    99verbose set paste
    redir END
    call neocomplcache#print_error(output)
    call neocomplcache#print_error(
          \ 'Detected set paste! Disabled neocomplcache.')
  endif
endfunction"}}}

if !exists('s:is_enabled')
  call s:initialize_script_variables()
  let s:is_enabled = 0
endif

function! neocomplcache#initialize() "{{{
  call neocomplcache#enable()
  call neocomplcache#_initialize_sources(get(g:neocomplcache_sources_list,
        \ neocomplcache#get_context_filetype(), ['_']))
endfunction"}}}

function! neocomplcache#lazy_initialize() "{{{
  if !exists('s:lazy_progress')
    let s:lazy_progress = 0
  endif

  if s:lazy_progress == 0
    call s:initialize_script_variables()
    let s:is_enabled = 0
  elseif s:lazy_progress == 1
    call s:initialize_others()
  else
    call s:initialize_autocmds()
    call neocomplcache#_initialize_sources(get(g:neocomplcache_sources_list,
          \ neocomplcache#get_context_filetype(), ['_']))
    let s:is_enabled = 1
  endif

  let s:lazy_progress += 1
endfunction"}}}

function! neocomplcache#enable() "{{{
  if neocomplcache#is_enabled()
    return
  endif

  command! -nargs=0 -bar NeoComplCacheDisable
        \ call neocomplcache#disable()

  call s:initialize_script_variables()
  call s:initialize_autocmds()
  call s:initialize_others()
endfunction"}}}

function! neocomplcache#disable() "{{{
  if !neocomplcache#is_enabled()
    call neocomplcache#print_warning(
          \ 'neocomplcache is disabled! This command is ignored.')
    return
  endif

  let s:is_enabled = 0

  " Restore options.
  let &completefunc = s:completefunc_save
  let &completeopt = s:completeopt_save

  augroup neocomplcache
    autocmd!
  augroup END

  delcommand NeoComplCacheDisable

  for source in values(neocomplcache#available_sources())
    if !has_key(source, 'finalize') || !source.loaded
      continue
    endif

    try
      call source.finalize()
    catch
      call neocomplcache#print_error(v:throwpoint)
      call neocomplcache#print_error(v:exception)
      call neocomplcache#print_error(
            \ 'Error occured in source''s finalize()!')
      call neocomplcache#print_error(
            \ 'Source name is ' . source.name)
    endtry
  endfor
endfunction"}}}

" Source helper. "{{{
function! neocomplcache#available_ftplugins() "{{{
  return s:ftplugin_sources
endfunction"}}}
function! neocomplcache#available_sources() "{{{
  call neocomplcache#context_filetype#set()
  return extend(extend(copy(s:complfunc_sources),
        \ s:ftplugin_sources), s:plugin_sources)
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
function! neocomplcache#keyword_escape(cur_keyword_str) "{{{
  return neocomplcache#helper#keyword_escape(a:cur_keyword_str)
endfunction"}}}
function! neocomplcache#keyword_filter(list, cur_keyword_str) "{{{
  let cur_keyword_str = a:cur_keyword_str

  if g:neocomplcache_enable_debug
    echomsg len(a:list)
  endif

  " Delimiter check.
  let filetype = neocomplcache#get_context_filetype()
  for delimiter in get(g:neocomplcache_delimiter_patterns, filetype, [])
    let cur_keyword_str = substitute(cur_keyword_str,
          \ delimiter, '*' . delimiter, 'g')
  endfor

  if cur_keyword_str == '' ||
        \ &l:completefunc ==# 'neocomplcache#complete#unite_complete' ||
        \ empty(a:list)
    return a:list
  elseif neocomplcache#check_match_filter(cur_keyword_str)
    " Match filter.
    let word = type(a:list[0]) == type('') ? 'v:val' : 'v:val.word'

    let expr = printf('%s =~ %s',
          \ word, string('^' .
          \ neocomplcache#keyword_escape(cur_keyword_str)))
    if neocomplcache#is_auto_complete()
      " Don't complete cursor word.
      let expr .= printf(' && %s !=? a:cur_keyword_str', word)
    endif

    " Check head character.
    if cur_keyword_str[0] != '\' && cur_keyword_str[0] != '.'
      let expr = word.'[0] == ' .
            \ string(cur_keyword_str[0]) .' && ' . expr
    endif

    call neocomplcache#print_debug(expr)

    return filter(a:list, expr)
  elseif neocomplcache#util#has_lua()
    return neocomplcache#lua_filter(a:list, cur_keyword_str)
  else
    " Use fast filter.
    return neocomplcache#head_filter(a:list, cur_keyword_str)
  endif
endfunction"}}}
function! neocomplcache#dup_filter(list) "{{{
  let dict = {}
  for keyword in a:list
    if !has_key(dict, keyword.word)
      let dict[keyword.word] = keyword
    endif
  endfor

  return values(dict)
endfunction"}}}
function! neocomplcache#check_match_filter(cur_keyword_str) "{{{
  return neocomplcache#keyword_escape(a:cur_keyword_str) =~ '[^\\]\*\|\\+'
endfunction"}}}
function! neocomplcache#check_completion_length_match(cur_keyword_str, completion_length) "{{{
  return neocomplcache#keyword_escape(
        \ a:cur_keyword_str[: a:completion_length-1]) =~
        \'[^\\]\*\|\\+\|\\%(\|\\|'
endfunction"}}}
function! neocomplcache#head_filter(list, cur_keyword_str) "{{{
  let word = type(a:list[0]) == type('') ? 'v:val' : 'v:val.word'

  if &ignorecase
   let expr = printf('!stridx(tolower(%s), %s)',
          \ word, string(tolower(a:cur_keyword_str)))
  else
    let expr = printf('!stridx(%s, %s)',
          \ word, string(a:cur_keyword_str))
  endif

  if neocomplcache#is_auto_complete()
    " Don't complete cursor word.
    let expr .= printf(' && %s !=? a:cur_keyword_str', word)
  endif

  return filter(a:list, expr)
endfunction"}}}
function! neocomplcache#lua_filter(list, cur_keyword_str) "{{{
  lua << EOF
  do
    local input = vim.eval('a:cur_keyword_str')
    local candidates = vim.eval('a:list')
    if (vim.eval('&ignorecase') ~= 0) then
      input = string.lower(input)
      for i = #candidates-1, 0, -1 do
        local word = vim.type(candidates[i]) == 'dict' and
          string.lower(candidates[i].word) or string.lower(candidates[i])
        if (string.find(word, input, 1, true) == nil) and word ~= input then
          candidates[i] = nil
        end
      end
    else
      for i = #candidates-1, 0, -1 do
        local word = vim.type(candidates[i]) == 'dict' and
          candidates[i].word or candidates[i]
        if (string.find(word, input, 1, true) == nil) and word ~= input then
          candidates[i] = nil
        end
      end
    end
  end
EOF

  return a:list
endfunction"}}}
function! neocomplcache#dictionary_filter(dictionary, cur_keyword_str) "{{{
  if empty(a:dictionary)
    return []
  endif

  let completion_length = 2
  if len(a:cur_keyword_str) < completion_length ||
        \ neocomplcache#check_completion_length_match(
        \         a:cur_keyword_str, completion_length) ||
        \ &l:completefunc ==# 'neocomplcache#cunite_complete'
    return neocomplcache#keyword_filter(
          \ neocomplcache#unpack_dictionary(a:dictionary), a:cur_keyword_str)
  endif

  let key = tolower(a:cur_keyword_str[: completion_length-1])

  if !has_key(a:dictionary, key)
    return []
  endif

  let list = a:dictionary[key]
  if type(list) == type({})
    " Convert dictionary dictionary.
    unlet list
    let list = values(a:dictionary[key])
  else
    let list = copy(list)
  endif

  return (len(a:cur_keyword_str) == completion_length && &ignorecase
        \ && !neocomplcache#check_completion_length_match(
        \   a:cur_keyword_str, completion_length)) ?
        \ list : neocomplcache#keyword_filter(list, a:cur_keyword_str)
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

" Rank order. "{{{
function! neocomplcache#compare_rank(i1, i2)
  let diff = (get(a:i2, 'rank', 0) - get(a:i1, 'rank', 0))
  return (diff != 0) ? diff : (a:i1.word ># a:i2.word) ? 1 : -1
endfunction"}}}
" Word order. "{{{
function! neocomplcache#compare_word(i1, i2)
  return (a:i1.word ># a:i2.word) ? 1 : -1
endfunction"}}}
" Nothing order. "{{{
function! neocomplcache#compare_nothing(i1, i2)
  return 0
endfunction"}}}
" Human order. "{{{
function! neocomplcache#compare_human(i1, i2)
  let words_1 = map(split(a:i1.word, '\D\zs\ze\d'),
        \ "v:val =~ '^\\d' ? str2nr(v:val) : v:val")
  let words_2 = map(split(a:i2.word, '\D\zs\ze\d'),
        \ "v:val =~ '^\\d' ? str2nr(v:val) : v:val")
  let words_1_len = len(words_1)
  let words_2_len = len(words_2)

  for i in range(0, min([words_1_len, words_2_len])-1)
    if words_1[i] ># words_2[i]
      return 1
    elseif words_1[i] <# words_2[i]
      return -1
    endif
  endfor

  return words_1_len - words_2_len
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
function! neocomplcache#get_completion_length(plugin_name) "{{{
  if neocomplcache#is_auto_complete()
        \ && neocomplcache#get_current_neocomplcache().completion_length >= 0
    return neocomplcache#get_current_neocomplcache().completion_length
  elseif has_key(g:neocomplcache_source_completion_length,
        \ a:plugin_name)
    return g:neocomplcache_source_completion_length[a:plugin_name]
  elseif has_key(s:ftplugin_sources, a:plugin_name)
        \ || has_key(s:complfunc_sources, a:plugin_name)
    return 0
  elseif neocomplcache#is_auto_complete()
    return g:neocomplcache_auto_completion_start_length
  else
    return g:neocomplcache_manual_completion_start_length
  endif
endfunction"}}}
function! neocomplcache#set_completion_length(plugin_name, length) "{{{
  if !has_key(g:neocomplcache_source_completion_length, a:plugin_name)
    let g:neocomplcache_source_completion_length[a:plugin_name] = a:length
  endif
endfunction"}}}
function! neocomplcache#get_auto_completion_length(plugin_name) "{{{
  if has_key(g:neocomplcache_source_completion_length, a:plugin_name)
    return g:neocomplcache_source_completion_length[a:plugin_name]
  elseif g:neocomplcache_enable_fuzzy_completion
    return 1
  else
    return g:neocomplcache_auto_completion_start_length
  endif
endfunction"}}}
function! neocomplcache#get_keyword_pattern(...) "{{{
  let filetype = a:0 != 0? a:000[0] : neocomplcache#get_context_filetype()

  return s:unite_patterns(g:neocomplcache_keyword_patterns, filetype)
endfunction"}}}
function! neocomplcache#get_next_keyword_pattern(...) "{{{
  let filetype = a:0 != 0? a:000[0] : neocomplcache#get_context_filetype()
  let next_pattern = s:unite_patterns(g:neocomplcache_next_keyword_patterns, filetype)

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
  return s:is_enabled
endfunction"}}}
function! neocomplcache#is_locked(...) "{{{
  let bufnr = a:0 > 0 ? a:1 : bufnr('%')
  return !s:is_enabled || &paste
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
  let list = []
  for filetype in neocomplcache#get_source_filetypes(a:filetype)
    if has_key(a:dictionary, filetype)
      call add(list, a:dictionary[filetype])
    endif
  endfor

  return list
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
function! neocomplcache#get_source_rank(plugin_name) "{{{
  if has_key(g:neocomplcache_source_rank, a:plugin_name)
    return g:neocomplcache_source_rank[a:plugin_name]
  elseif has_key(s:complfunc_sources, a:plugin_name)
    return 10
  elseif has_key(s:ftplugin_sources, a:plugin_name)
    return 100
  elseif has_key(s:plugin_sources, a:plugin_name)
    return 5
  else
    " unknown.
    return 1
  endif
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
function! neocomplcache#skip_next_complete() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.skip_next_complete = 1
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

" Event functions. "{{{
function! neocomplcache#_clear_result()
  let neocomplcache = neocomplcache#get_current_neocomplcache()

  let neocomplcache.cur_keyword_str = ''
  let neocomplcache.complete_words = []
  let neocomplcache.complete_results = {}
  let neocomplcache.cur_keyword_pos = -1
endfunction
"}}}

" Internal helper functions. "{{{
function! s:unite_patterns(pattern_var, filetype) "{{{
  let keyword_patterns = []
  let dup_check = {}

  " Composite filetype.
  for ft in split(a:filetype, '\.')
    if has_key(a:pattern_var, ft) && !has_key(dup_check, ft)
      let dup_check[ft] = 1
      call add(keyword_patterns, a:pattern_var[ft])
    endif

    " Same filetype.
    if has_key(g:neocomplcache_same_filetype_lists, ft)
      for ft in split(g:neocomplcache_same_filetype_lists[ft], ',')
        if has_key(a:pattern_var, ft) && !has_key(dup_check, ft)
          let dup_check[ft] = 1
          call add(keyword_patterns, a:pattern_var[ft])
        endif
      endfor
    endif
  endfor

  if empty(keyword_patterns)
    let default = get(a:pattern_var, '_', get(a:pattern_var, 'default', ''))
    if default != ''
      call add(keyword_patterns, default)
    endif
  endif

  return join(keyword_patterns, '\m\|')
endfunction"}}}
function! neocomplcache#_get_frequencies() "{{{
  let filetype = neocomplcache#get_context_filetype()
  if !has_key(s:filetype_frequencies, filetype)
    let s:filetype_frequencies[filetype] = {}
  endif

  let frequencies = s:filetype_frequencies[filetype]

  return frequencies
endfunction"}}}
function! neocomplcache#get_current_neocomplcache() "{{{
  if !exists('b:neocomplcache')
    let b:neocomplcache = {
          \ 'lock' : 0,
          \ 'skip_next_complete' : 0,
          \ 'filetype' : '',
          \ 'context_filetype' : '',
          \ 'context_filetype_range' :
          \    [[1, 1], [line('$'), len(getline('$'))+1]],
          \ 'completion_length' : -1,
          \ 'update_time_save' : &updatetime,
          \ 'foldinfo' : [],
          \ 'lock_sources' : {},
          \ 'skipped' : 0,
          \ 'event' : '',
          \ 'cur_text' : '',
          \ 'old_cur_text' : '',
          \ 'cur_keyword_str' : '',
          \ 'cur_keyword_pos' : -1,
          \ 'complete_words' : [],
          \ 'complete_results' : {},
          \ 'start_time' : reltime(),
          \}
  endif

  return b:neocomplcache
endfunction"}}}
function! neocomplcache#_initialize_sources(source_names) "{{{
  " Initialize sources table.
  if s:loaded_all_sources && &runtimepath ==# s:runtimepath_save
    return
  endif

  let runtimepath_save = neocomplcache#util#split_rtp(s:runtimepath_save)
  let runtimepath = neocomplcache#util#join_rtp(
        \ filter(neocomplcache#util#split_rtp(),
        \ 'index(runtimepath_save, v:val) < 0'))

  for name in a:source_names
    if has_key(s:complfunc_sources, name)
            \ || has_key(s:ftplugin_sources, name)
            \ || has_key(s:plugin_sources, name)
      continue
    endif

    " Search autoload.
    for source_name in map(split(globpath(runtimepath,
          \ 'autoload/neocomplcache/sources/*.vim'), '\n'),
          \ "fnamemodify(v:val, ':t:r')")
      if has_key(s:loaded_source_files, source_name)
        continue
      endif

      let s:loaded_source_files[source_name] = 1

      let source = neocomplcache#sources#{source_name}#define()
      if empty(source)
        " Ignore.
        continue
      endif

      if source.kind ==# 'complfunc'
        let s:complfunc_sources[source_name] = source
        let source.loaded = 1
      elseif source.kind ==# 'ftplugin'
        let s:ftplugin_sources[source_name] = source

        " Clear loaded flag.
        let s:ftplugin_sources[source_name].loaded = 0
      elseif source.kind ==# 'plugin'
        let s:plugin_sources[source_name] = source
        let source.loaded = 1
      endif

      if (source.kind ==# 'complfunc' || source.kind ==# 'plugin')
            \ && has_key(source, 'initialize')
        try
          call source.initialize()
        catch
          call neocomplcache#print_error(v:throwpoint)
          call neocomplcache#print_error(v:exception)
          call neocomplcache#print_error(
                \ 'Error occured in source''s initialize()!')
          call neocomplcache#print_error(
                \ 'Source name is ' . source.name)
        endtry
      endif
    endfor

    if name == '_'
      let s:loaded_all_sources = 1
      let s:runtimepath_save = &runtimepath
    endif
  endfor
endfunction"}}}
function! neocomplcache#_get_sources_list(...) "{{{
  let filetype = neocomplcache#get_context_filetype()

  let source_names = exists('b:neocomplcache_sources_list') ?
        \ b:neocomplcache_sources_list :
        \ get(a:000, 0,
        \   get(g:neocomplcache_sources_list, filetype,
        \     get(g:neocomplcache_sources_list, '_', ['_'])))
  let disabled_sources = get(
        \ g:neocomplcache_disabled_sources_list, filetype,
        \   get(g:neocomplcache_disabled_sources_list, '_', []))
  call neocomplcache#_initialize_sources(source_names)

  let all_sources = neocomplcache#available_sources()
  let sources = {}
  for source_name in source_names
    if source_name ==# '_'
      " All sources.
      let sources = all_sources
      break
    endif

    if !has_key(all_sources, source_name)
      call neocomplcache#print_warning(printf(
            \ 'Invalid source name "%s" is given.', source_name))
      continue
    endif

    let sources[source_name] = all_sources[source_name]
  endfor

  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.sources = filter(sources, "
        \ index(disabled_sources, v:val.name) < 0 &&
        \   (v:val.kind !=# 'ftplugin' ||
        \    get(v:val.filetypes, neocomplcache.context_filetype, 0))")

  return neocomplcache.sources
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
