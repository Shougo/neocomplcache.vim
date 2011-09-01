"=============================================================================
" FILE: buffer_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 01 Sep 2011.
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

" Important variables.
if !exists('s:buffer_sources')
  let s:buffer_sources = {}
endif

let s:source = {
      \ 'name' : 'buffer_complete',
      \ 'kind' : 'complfunc',
      \}

function! s:source.initialize()"{{{
  augroup neocomplcache"{{{
    " Caching events
    autocmd InsertEnter * call s:check_source()
    autocmd CursorHold * call s:rank_caching_current_cache_line(1)
    autocmd CursorHold * call s:check_deleted_buffer()
    autocmd InsertEnter,CursorHoldI * call s:rank_caching_current_cache_line(0)
    autocmd InsertLeave * call neocomplcache#sources#buffer_complete#caching_current_cache_line()
    autocmd VimLeavePre * call s:save_all_cache()
  augroup END"}}}

  " Set rank.
  call neocomplcache#set_dictionary_helper(g:neocomplcache_plugin_rank, 'buffer_complete', 4)

  " Set completion length.
  call neocomplcache#set_completion_length('buffer_complete', 0)

  " Create cache directory.
  if !isdirectory(g:neocomplcache_temporary_dir . '/buffer_cache')
    call mkdir(g:neocomplcache_temporary_dir . '/buffer_cache', 'p')
  endif

  " Initialize script variables."{{{
  let s:buffer_sources = {}
  let s:filetype_frequencies = {}
  let s:cache_line_count = 70
  let s:rank_cache_count = 1
  let s:disable_caching_list = {}
  let s:completion_length = g:neocomplcache_auto_completion_start_length
  "}}}

  " Add commands."{{{
  command! -nargs=? -complete=buffer NeoComplCacheCachingBuffer call s:caching_buffer(<q-args>)
  command! -nargs=? -complete=buffer NeoComplCachePrintSource call s:print_source(<q-args>)
  command! -nargs=? -complete=buffer NeoComplCacheOutputKeyword call s:output_keyword(<q-args>)
  command! -nargs=? -complete=buffer NeoComplCacheSaveCache call s:save_all_cache()
  command! -nargs=? -complete=buffer NeoComplCacheDisableCaching call s:disable_caching(<q-args>)
  command! -nargs=? -complete=buffer NeoComplCacheEnableCaching call s:enable_caching(<q-args>)
  "}}}
endfunction
"}}}

function! s:source.finalize()"{{{
  delcommand NeoComplCacheCachingBuffer
  delcommand NeoComplCachePrintSource
  delcommand NeoComplCacheOutputKeyword
  delcommand NeoComplCacheSaveCache
  delcommand NeoComplCacheDisableCaching
  delcommand NeoComplCacheEnableCaching

  call s:save_all_cache()

  let s:buffer_sources = {}
endfunction"}}}

function! s:source.get_keyword_pos(cur_text)"{{{
  " Check member prefix pattern.
  let l:filetype = neocomplcache#get_context_filetype()
  if has_key(g:neocomplcache_member_prefix_patterns, l:filetype)
        \ && g:neocomplcache_member_prefix_patterns[l:filetype] != ''
    let l:var_pos = match(a:cur_text, '\%(\h\w*\%(()\?\)\?\%(' .
          \ g:neocomplcache_member_prefix_patterns[l:filetype] . '\m\)\)\+$')
  else
    let l:var_pos = -1
  endif

  let [l:cur_keyword_pos, l:cur_keyword_str] = neocomplcache#match_word(a:cur_text)
  if l:var_pos >= 0 ||
        \ (neocomplcache#is_auto_complete()
        \ && neocomplcache#util#mb_strlen(l:cur_keyword_str)
        \      < g:neocomplcache_auto_completion_start_length)
    return -1
  endif

  return l:cur_keyword_pos
endfunction"}}}

function! s:source.get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
  " Check member prefix pattern.
  let l:filetype = neocomplcache#get_context_filetype()
  if has_key(g:neocomplcache_member_prefix_patterns, l:filetype)
        \ && g:neocomplcache_member_prefix_patterns[l:filetype] != ''
    let l:cur_text = neocomplcache#get_cur_text()
    let l:var_name = matchstr(l:cur_text, '\%(\h\w*\%(()\?\)\?\%(' .
          \ g:neocomplcache_member_prefix_patterns[l:filetype] . '\m\)\)\+$')
    if l:var_name != ''
      return s:get_member_list(l:cur_text, l:var_name)
    endif
  endif

  let l:keyword_list = []
  for src in s:get_sources_list()
    let l:keyword_cache = neocomplcache#dictionary_filter(
          \ s:buffer_sources[src].keyword_cache, a:cur_keyword_str, s:completion_length)

    if src == bufnr('%')
      call s:calc_frequency(l:keyword_cache)
    endif

    let l:keyword_list += l:keyword_cache
  endfor

  return l:keyword_list
endfunction"}}}

function! neocomplcache#sources#buffer_complete#define()"{{{
  return s:source
endfunction"}}}

function! neocomplcache#sources#buffer_complete#get_frequencies()"{{{
  let l:filetype = neocomplcache#get_context_filetype()
  if !has_key(s:filetype_frequencies, l:filetype)
    return {}
  endif

  return s:filetype_frequencies[l:filetype]
endfunction"}}}

function! neocomplcache#sources#buffer_complete#caching_current_cache_line()"{{{
  " Current line caching.

  if !s:exists_current_source() || has_key(s:disable_caching_list, bufnr('%'))
    return
  endif

  let l:source = s:buffer_sources[bufnr('%')]
  let l:filename = fnamemodify(l:source.name, ':t')
  let l:menu = '[B] ' . neocomplcache#util#strwidthpart(
        \ l:filename, g:neocomplcache_max_filename_width)
  let l:keyword_pattern = l:source.keyword_pattern
  let l:keyword_pattern2 = '^\%('.l:keyword_pattern.'\m\)'
  let l:keywords = l:source.keyword_cache

  let l:line = join(getline(line('.')-1, line('.')+1))
  let l:match = match(l:line, l:keyword_pattern)
  while l:match >= 0"{{{
    let l:match_str = matchstr(l:line, l:keyword_pattern2, l:match)

    " Ignore too short keyword.
    if len(l:match_str) >= g:neocomplcache_min_keyword_length"{{{
      " Check dup.
      let l:key = tolower(l:match_str[: s:completion_length-1])
      if !has_key(l:keywords, l:key)
        let l:keywords[l:key] = {}
      endif
      if !has_key(l:keywords[l:key], l:match_str)
        " Append list.
        let l:keywords[l:key][l:match_str] = { 'word' : l:match_str, 'menu' : l:menu }
      endif
    endif"}}}

    " Next match.
    let l:match = match(l:line, l:keyword_pattern, l:match + len(l:match_str))
  endwhile"}}}
endfunction"}}}

function! s:calc_frequency(list)"{{{
  if !s:exists_current_source()
    return
  endif

  let l:list_len = len(a:list)

  if l:list_len > g:neocomplcache_max_list * 5
    let l:calc_cnt = 15
  elseif l:list_len > g:neocomplcache_max_list * 3
    let l:calc_cnt = 13
  elseif l:list_len > g:neocomplcache_max_list
    let l:calc_cnt = 10
  elseif l:list_len > g:neocomplcache_max_list / 2
    let l:calc_cnt = 8
  elseif l:list_len > g:neocomplcache_max_list / 3
    let l:calc_cnt = 5
  elseif l:list_len > g:neocomplcache_max_list / 4
    let l:calc_cnt = 4
  else
    let l:calc_cnt = 3
  endif

  let l:source = s:buffer_sources[bufnr('%')]
  let l:frequencies = l:source.frequencies
  let l:filetype = neocomplcache#get_context_filetype()
  if !has_key(s:filetype_frequencies, l:filetype)
    let s:filetype_frequencies[l:filetype] = {}
  endif
  let l:filetype_frequencies = s:filetype_frequencies[l:filetype]
  
  for keyword in a:list
    if s:rank_cache_count <= 0
      " Set rank.
      
      let l:word = keyword.word
      let l:frequency = 0
      for rank_lines in values(l:source.rank_lines)
        if has_key(rank_lines, l:word)
          let l:frequency += rank_lines[l:word]
        endif
      endfor
      
      if !has_key(l:filetype_frequencies, l:word)
        let l:filetype_frequencies[l:word] = 0
      endif
      if has_key(l:frequencies, l:word)
        let l:filetype_frequencies[l:word] -= l:frequencies[l:word]
      endif
      if l:frequency == 0
        " Garbage collect
        let l:ignorecase_save = &ignorecase
        let &ignorecase = 0
        let l:pos = searchpos(neocomplcache#escape_match(l:word), 'ncw', 0)
        let &ignorecase = l:ignorecase_save
        
        if l:pos[0] == 0
          " Delete.
          let l:key = tolower(l:word[: s:completion_length-1])
          if has_key(l:source.keyword_cache[l:key], l:word)
            call remove(l:source.keyword_cache[l:key], l:word)
          endif
          if has_key(l:source.frequencies, l:word)
            call remove(l:source.frequencies, l:word)
          endif
          if l:filetype_frequencies[l:word] == 0
            call remove(l:filetype_frequencies, l:word)
          endif
        else
          let l:frequencies[l:word] = 1
          let l:filetype_frequencies[l:word] += 1
        endif
      else
        let l:frequencies[l:word] = l:frequency
        let l:filetype_frequencies[l:word] += l:frequency
      endif

      " Reset count.
      let s:rank_cache_count = neocomplcache#rand(l:calc_cnt)
    endif

    let s:rank_cache_count -= 1
  endfor
endfunction"}}}

function! s:get_sources_list()"{{{
  let l:sources_list = []

  let l:filetypes_dict = {}
  for l:filetype in neocomplcache#get_source_filetypes(neocomplcache#get_context_filetype())
    let l:filetypes_dict[l:filetype] = 1
  endfor

  for key in keys(s:buffer_sources)
    if has_key(l:filetypes_dict, s:buffer_sources[key].filetype) || bufnr('%') == key
          \ || (bufname('%') ==# '[Command Line]' && bufnr('#') == key)
      call add(l:sources_list, key)
    endif
  endfor

  return l:sources_list
endfunction"}}}

function! s:get_member_list(cur_text, var_name)"{{{
  let l:keyword_list = []
  for src in s:get_sources_list()
    if has_key(s:buffer_sources[src].member_cache, a:var_name)
      let l:keyword_list += values(s:buffer_sources[src].member_cache[a:var_name])
    endif
  endfor

  return l:keyword_list
endfunction"}}}

function! s:rank_caching_current_cache_line(is_force)"{{{
  if !s:exists_current_source() || neocomplcache#is_locked()
    return
  endif

  let l:source = s:buffer_sources[bufnr('%')]
  let l:filename = fnamemodify(l:source.name, ':t')

  let l:start_line = (line('.')-1)/l:source.cache_line_cnt*l:source.cache_line_cnt+1
  let l:end_line = l:start_line + l:source.cache_line_cnt-1
  let l:cache_num = (l:start_line-1) / l:source.cache_line_cnt

  " For debugging.
  "echomsg printf("start=%d, end=%d", l:start_line, l:end_line)

  if !a:is_force && has_key(l:source.rank_lines, l:cache_num)
    return
  endif

  " Clear cache line.
  let l:source.rank_lines[l:cache_num] = {}
  let l:rank_lines = l:source.rank_lines[l:cache_num]

  let l:buflines = getline(l:start_line, l:end_line)
  let l:menu = '[B] ' . neocomplcache#util#strwidthpart(
        \ l:filename, g:neocomplcache_max_filename_width)
  let l:keyword_pattern = l:source.keyword_pattern
  let l:keyword_pattern2 = '^\%('.l:keyword_pattern.'\m\)'

  let [l:line_num, l:max_lines] = [0, len(l:buflines)]
  while l:line_num < l:max_lines
    let l:line = buflines[l:line_num]
    let l:match = match(l:line, l:keyword_pattern)

    while l:match >= 0"{{{
      let l:match_str = matchstr(l:line, l:keyword_pattern2, l:match)

      " Ignore too short keyword.
      if len(l:match_str) >= g:neocomplcache_min_keyword_length"{{{
        if !has_key(l:rank_lines, l:match_str)
          let l:rank_lines[l:match_str] = 1
        else
          let l:rank_lines[l:match_str] += 1
        endif
      endif"}}}

      " Next match.
      let l:match = match(l:line, l:keyword_pattern, l:match + len(l:match_str))
    endwhile"}}}

    let l:line_num += 1
  endwhile

  let l:filetype = neocomplcache#get_context_filetype(1)
  if !has_key(g:neocomplcache_member_prefix_patterns, l:filetype)
        \ || g:neocomplcache_member_prefix_patterns[l:filetype] == ''
    return
  endif

  let l:menu = '[B] member'
  let l:keyword_pattern = '\%(\h\w*\%(()\?\)\?\%(' . g:neocomplcache_member_prefix_patterns[l:filetype] . '\m\)\)\+\h\w*\%(()\?\)\?'
  let l:keyword_pattern2 = '^'.l:keyword_pattern
  let l:member_pattern = '\h\w*\%(()\?\)\?$'

  " Cache member pattern.
  let [l:line_num, l:max_lines] = [0, len(l:buflines)]
  while l:line_num < l:max_lines
    let l:line = buflines[l:line_num]
    let l:match = match(l:line, l:keyword_pattern)

    while l:match >= 0"{{{
      let l:match_str = matchstr(l:line, l:keyword_pattern2, l:match)

      " Next match.
      let l:match = matchend(l:line, l:keyword_pattern, l:match + len(l:match_str))

      while l:match_str != ''
        let l:member_name = matchstr(l:match_str, l:member_pattern)
        let l:var_name = l:match_str[ : -len(l:member_name)-1]

        if !has_key(l:source.member_cache, l:var_name)
          let l:source.member_cache[l:var_name] = {}
        endif
        if !has_key(l:source.member_cache[l:var_name], l:member_name)
          let l:source.member_cache[l:var_name][l:member_name] = { 'word' : l:member_name, 'menu' : l:menu }
        endif

        let l:match_str = matchstr(l:var_name, l:keyword_pattern2)
      endwhile
    endwhile"}}}

    let l:line_num += 1
  endwhile
endfunction"}}}

function! s:initialize_source(srcname)"{{{
  let l:path = fnamemodify(bufname(a:srcname), ':p')
  let l:filename = fnamemodify(l:path, ':t')
  if l:filename == ''
    let l:filename = '[No Name]'
    let l:path .= '/[No Name]'
  endif

  " Set cache line count.
  let l:buflines = getbufline(a:srcname, 1, '$')
  let l:end_line = len(l:buflines)

  if l:end_line > 150
    let cnt = 0
    for line in l:buflines[50:150] 
      let cnt += len(line)
    endfor

    if cnt <= 3000
      let l:cache_line_cnt = s:cache_line_count
    elseif cnt <= 4000
      let l:cache_line_cnt = s:cache_line_count*7 / 10
    elseif cnt <= 5000
      let l:cache_line_cnt = s:cache_line_count / 2
    elseif cnt <= 7500
      let l:cache_line_cnt = s:cache_line_count / 3
    elseif cnt <= 10000
      let l:cache_line_cnt = s:cache_line_count / 5
    elseif cnt <= 12000
      let l:cache_line_cnt = s:cache_line_count / 7
    elseif cnt <= 14000
      let l:cache_line_cnt = s:cache_line_count / 10
    else
      let l:cache_line_cnt = s:cache_line_count / 13
    endif
  elseif l:end_line > 100
    let l:cache_line_cnt = s:cache_line_count / 3
  else
    let l:cache_line_cnt = s:cache_line_count / 5
  endif

  let l:ft = getbufvar(a:srcname, '&filetype')
  if l:ft == ''
    let l:ft = 'nothing'
  endif

  let l:keyword_pattern = neocomplcache#get_keyword_pattern(l:ft)

  let s:buffer_sources[a:srcname] = {
        \ 'keyword_cache' : {}, 'rank_lines' : {}, 'member_cache' : {},
        \ 'name' : l:filename, 'filetype' : l:ft, 'keyword_pattern' : l:keyword_pattern,
        \ 'end_line' : l:end_line , 'cache_line_cnt' : l:cache_line_cnt,
        \ 'frequencies' : {}, 'check_sum' : len(join(l:buflines[:4], '\n')),
        \ 'path' : l:path, 'loaded_cache' : 0,
        \ 'cache_name' : neocomplcache#cache#encode_name('buffer_cache', l:path),
        \}
endfunction"}}}

function! s:word_caching(srcname)"{{{
  " Initialize source.
  call s:initialize_source(a:srcname)

  let l:source = s:buffer_sources[a:srcname]
  let l:srcname = fnamemodify(l:source.name, ':p')

  if neocomplcache#cache#check_old_cache('buffer_cache', l:srcname)
    if l:source.name ==# '[Command Line]'
          \ || getbufvar(a:srcname, '&buftype') =~ 'nofile'
      " Ignore caching.
      return
    endif

    let l:source.cache_name =
          \ neocomplcache#cache#async_load_from_file('buffer_cache', l:source.path, l:source.keyword_pattern, 'B')
  endif
endfunction"}}}

function! s:check_changed_buffer(bufnumber)"{{{
  let l:source = s:buffer_sources[a:bufnumber]

  if getbufvar(a:bufnumber, '&buftype') =~ 'nofile'
    " Check buffer changed.
    let l:check_sum = len(join(getbufline(a:bufnumber, 1, 5), '\n'))
    if l:check_sum != l:source.check_sum
      " Recaching.
      return 1
    endif
  endif

  let l:ft = getbufvar(a:bufnumber, '&filetype')
  if l:ft == ''
    let l:ft = 'nothing'
  endif

  let l:filename = fnamemodify(bufname(a:bufnumber), ':t')
  if l:filename == ''
    let l:filename = '[No Name]'
  endif

  return s:buffer_sources[a:bufnumber].name != l:filename
        \ || s:buffer_sources[a:bufnumber].filetype != l:ft
endfunction"}}}

function! s:check_source()"{{{
  let l:bufnumber = bufnr('%')

  " Check new buffer.
  let l:bufname = fnamemodify(bufname(l:bufnumber), ':p')
  if (!has_key(s:buffer_sources, l:bufnumber) || s:check_changed_buffer(l:bufnumber))
        \ && !has_key(s:disable_caching_list, l:bufnumber)
        \ && !neocomplcache#is_locked(l:bufnumber)
        \ && !getwinvar(bufwinnr(l:bufnumber), '&previewwindow')
        \ && getfsize(l:bufname) < g:neocomplcache_caching_limit_file_size
        \ && (g:neocomplcache_force_caching_buffer_name_pattern == ''
        \       || l:bufname !~ g:neocomplcache_force_caching_buffer_name_pattern)

    " Caching.
    call s:word_caching(l:bufnumber)
  endif

  if has_key(s:buffer_sources, l:bufnumber)
        \ && !s:buffer_sources[l:bufnumber].loaded_cache
    let l:source = s:buffer_sources[l:bufnumber]

    if filereadable(l:source.cache_name)
      " Caching from cache.
      call neocomplcache#cache#list2index(
            \ neocomplcache#cache#load_from_cache('buffer_cache', l:source.path),
            \ l:source.keyword_cache,
            \ s:completion_length)

      let l:source.loaded_cache = 1
    endif
  endif
endfunction"}}}
function! s:check_deleted_buffer()"{{{
  " Check deleted buffer.
  for key in keys(s:buffer_sources)
    if !bufloaded(str2nr(key))
      " Save cache.
      call s:save_cache(key)

      " Remove item.
      call remove(s:buffer_sources, key)
    endif
  endfor
endfunction"}}}

function! s:exists_current_source()"{{{
  return has_key(s:buffer_sources, bufnr('%'))
endfunction"}}}

function! s:save_cache(srcname)"{{{
  if s:buffer_sources[a:srcname].end_line < 500
    return
  endif

  if getbufvar(a:srcname, '&buftype') =~ 'nofile'
    return
  endif

  let l:srcname = fnamemodify(bufname(str2nr(a:srcname)), ':p')
  if !filereadable(l:srcname) ||
        \ (g:neocomplcache_disable_caching_file_path_pattern != ''
        \   && l:srcname =~ g:neocomplcache_disable_caching_file_path_pattern)
    return
  endif

  let l:cache_name = neocomplcache#cache#encode_name('buffer_cache', l:srcname)

  if filereadable(l:cache_name) &&
        \ (g:neocomplcache_disable_caching_file_path_pattern != ''
        \   && l:srcname =~ g:neocomplcache_disable_caching_file_path_pattern)
    " Delete cache file.
    call delete(l:cache_name)
    return
  endif

  if getftime(l:cache_name) >= getftime(l:srcname)
    return
  endif

  " Output buffer.
  call neocomplcache#cache#save_cache('buffer_cache', l:srcname, neocomplcache#unpack_dictionary(s:buffer_sources[a:srcname].keyword_cache))
endfunction "}}}
function! s:save_all_cache()"{{{
  try
    for l:key in keys(s:buffer_sources)
      call s:save_cache(l:key)
    endfor
  catch
    call neocomplcache#print_error('Error occured while saving cache!')
    let l:error_file = g:neocomplcache_temporary_dir . strftime('/error-%Y-%m-%d.log')
    call writefile([v:exception . ' ' . v:throwpoint], l:error_file)
    call neocomplcache#print_error('Please check error file: ' . l:error_file)
  endtry
endfunction"}}}

" Command functions."{{{
function! s:caching_buffer(name)"{{{
  if a:name == ''
    let l:number = bufnr('%')
  else
    let l:number = bufnr(a:name)

    if l:number < 0
      call neocomplcache#print_error('Invalid buffer name.')
      return
    endif
  endif

  " Word recaching.
  call s:word_caching(l:number)
endfunction"}}}
function! s:print_source(name)"{{{
  if a:name == ''
    let l:number = bufnr('%')
  else
    let l:number = bufnr(a:name)

    if l:number < 0
      call neocomplcache#print_error('Invalid buffer name.')
      return
    endif
  endif

  if !has_key(s:buffer_sources, l:number)
    return
  endif

  silent put=printf('Print neocomplcache %d source.', l:number)
  for l:key in keys(s:buffer_sources[l:number])
    silent put =printf('%s => %s', l:key, string(s:buffer_sources[l:number][l:key]))
  endfor
endfunction"}}}
function! s:output_keyword(name)"{{{
  if a:name == ''
    let l:number = bufnr('%')
  else
    let l:number = bufnr(a:name)

    if l:number < 0
      call neocomplcache#print_error('Invalid buffer name.')
      return
    endif
  endif

  if !has_key(s:buffer_sources, l:number)
    return
  endif

  " Output buffer.
  for keyword in neocomplcache#unpack_dictionary(s:buffer_sources[l:number].keyword_cache)
    silent put=string(keyword)
  endfor
endfunction "}}}
function! s:disable_caching(name)"{{{
  if a:name == ''
    let l:number = bufnr('%')
  else
    let l:number = bufnr(a:name)

    if l:number < 0
      call neocomplcache#print_error('Invalid buffer name.')
      return
    endif
  endif

  let s:disable_caching_list[l:number] = 1

  if has_key(s:buffer_sources, l:number)
    " Delete source.
    call remove(s:buffer_sources, l:number)
  endif
endfunction"}}}
function! s:enable_caching(name)"{{{
  if a:name == ''
    let l:number = bufnr('%')
  else
    let l:number = bufnr(a:name)

    if l:number < 0
      call neocomplcache#print_error('Invalid buffer name.')
      return
    endif
  endif

  if has_key(s:disable_caching_list, l:number)
    call remove(s:disable_caching_list, l:number)
  endif
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
