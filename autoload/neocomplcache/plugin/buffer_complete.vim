"=============================================================================
" FILE: buffer_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 23 Jun 2010
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

" Important variables.
if !exists('s:sources')
  let s:sources = {}
endif

function! neocomplcache#plugin#buffer_complete#initialize()"{{{
  augroup neocomplcache"{{{
    " Caching events
    autocmd FileType,BufWritePost * call s:check_source()
    autocmd CursorHold * call s:rank_caching_current_cache_line(1)
    autocmd CursorMoved * call s:rank_caching_current_cache_line(0)
    autocmd InsertLeave * call neocomplcache#plugin#buffer_complete#caching_current_cache_line()
    autocmd VimLeavePre * call s:save_all_cache()
  augroup END"}}}

  " Initialize script variables."{{{
  let s:sources = {}
  let s:filetype_frequencies = {}
  let s:cache_line_count = 70
  let s:rank_cache_count = 1
  let s:disable_caching_list = {}
  let s:completion_length = neocomplcache#get_auto_completion_length('buffer_complete')
  "}}}
  
  " Set rank.
  call neocomplcache#set_variable_pattern('g:neocomplcache_plugin_rank', 'buffer_complete', 4)

  " Create cache directory.
  if !isdirectory(g:neocomplcache_temporary_dir . '/buffer_cache')
    call mkdir(g:neocomplcache_temporary_dir . '/buffer_cache', 'p')
  endif

  " Add commands."{{{
  command! -nargs=? -complete=buffer NeoComplCacheCachingBuffer call s:caching_buffer(<q-args>)
  command! -nargs=? -complete=buffer NeoComplCachePrintSource call s:print_source(<q-args>)
  command! -nargs=? -complete=buffer NeoComplCacheOutputKeyword call s:output_keyword(<q-args>)
  command! -nargs=? -complete=buffer NeoComplCacheSaveCache call s:save_all_cache()
  command! -nargs=? -complete=buffer NeoComplCacheDisableCaching call s:disable_caching(<q-args>)
  command! -nargs=? -complete=buffer NeoComplCacheEnableCaching call s:enable_caching(<q-args>)
  "}}}

  " Initialize cache.
  call s:check_source()
endfunction
"}}}

function! neocomplcache#plugin#buffer_complete#finalize()"{{{
  delcommand NeoComplCacheCachingBuffer
  delcommand NeoComplCachePrintSource
  delcommand NeoComplCacheOutputKeyword
  delcommand NeoComplCacheSaveCache
  delcommand NeoComplCacheDisableCaching
  delcommand NeoComplCacheEnableCaching

  call s:save_all_cache()

  let s:sources = {}
endfunction"}}}

function! neocomplcache#plugin#buffer_complete#get_keyword_list(cur_keyword_str)"{{{
  let l:keyword_list = []

  let l:current = bufnr('%')
  if len(a:cur_keyword_str) < s:completion_length ||
        \neocomplcache#check_match_filter(a:cur_keyword_str, s:completion_length)
    for src in s:get_sources_list()
      let l:keyword_cache = neocomplcache#keyword_filter(
            \neocomplcache#unpack_dictionary_dictionary(s:sources[src].keyword_cache), a:cur_keyword_str)
      if src == l:current
        call s:calc_frequency(l:keyword_cache)
      endif
      let l:keyword_list += l:keyword_cache
    endfor
  else
    let l:key = tolower(a:cur_keyword_str[: s:completion_length-1])
    for src in s:get_sources_list()
      if has_key(s:sources[src].keyword_cache, l:key)
        let l:keyword_cache = neocomplcache#keyword_filter(values(s:sources[src].keyword_cache[l:key]), a:cur_keyword_str)

        if src == l:current
          call s:calc_frequency(l:keyword_cache)
        endif

        let l:keyword_list += l:keyword_cache
      endif
    endfor
  endif

  return l:keyword_list
endfunction"}}}

function! neocomplcache#plugin#buffer_complete#get_frequencies()"{{{
  let l:filetype = neocomplcache#get_context_filetype()
  if !has_key(s:filetype_frequencies, l:filetype)
    return {}
  endif

  return s:filetype_frequencies[l:filetype]
endfunction"}}}

function! neocomplcache#plugin#buffer_complete#exists_current_source()"{{{
  return has_key(s:sources, bufnr('%'))
endfunction"}}}

function! neocomplcache#plugin#buffer_complete#caching_current_cache_line()"{{{
  " Current line caching.
  
  if !neocomplcache#plugin#buffer_complete#exists_current_source() || has_key(s:disable_caching_list, bufnr('%'))
    return
  endif

  let l:source = s:sources[bufnr('%')]
  let l:filename = fnamemodify(l:source.name, ':t')
  let l:menu = printf('[B] %.' . g:neocomplcache_max_filename_width . 's', l:filename)
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
  if !neocomplcache#plugin#buffer_complete#exists_current_source()
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

  let l:source = s:sources[bufnr('%')]
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
        let l:pos = searchpos(neocomplcache#escape_match(l:word), 'ncw', 0, 300)
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

  let l:filetypes = neocomplcache#get_source_filetypes(neocomplcache#get_context_filetype())
  for key in keys(s:sources)
    if has_key(l:filetypes, s:sources[key].filetype) || bufnr('%') == key
      call add(l:sources_list, key)
    endif
  endfor

  return l:sources_list
endfunction"}}}

function! s:rank_caching_current_cache_line(is_force)"{{{
  if !neocomplcache#plugin#buffer_complete#exists_current_source() || has_key(s:disable_caching_list, bufnr('%'))
    return
  endif

  let l:source = s:sources[bufnr('%')]
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
  let l:menu = printf('[B] %.' . g:neocomplcache_max_filename_width . 's', l:filename)
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
endfunction"}}}

function! s:initialize_source(srcname)"{{{
  let l:filename = fnamemodify(bufname(a:srcname), ':t')

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

  let s:sources[a:srcname] = {
        \'keyword_cache' : {}, 'rank_lines' : {},
        \'name' : l:filename, 'filetype' : l:ft, 'keyword_pattern' : l:keyword_pattern, 
        \'end_line' : l:end_line , 'cache_line_cnt' : l:cache_line_cnt, 
        \'frequencies' : {}, 'check_sum' : len(join(l:buflines[:4], '\n'))
        \}
endfunction"}}}

function! s:word_caching(srcname)"{{{
  " Initialize source.
  call s:initialize_source(a:srcname)

  if s:caching_from_cache(a:srcname) == 0
    " Caching from cache.
    return
  endif

  let l:bufname = bufname(str2nr(a:srcname))
  if fnamemodify(l:bufname, ':t') ==# '[Command Line]'
    " Ignore caching.
    return
  endif

  let l:keyword_cache = s:sources[a:srcname].keyword_cache
  for l:keyword in neocomplcache#cache#load_from_file(bufname(str2nr(a:srcname)), s:sources[a:srcname].keyword_pattern, 'B')
    let l:key = tolower(l:keyword.word[: s:completion_length-1])
    if !has_key(l:keyword_cache, l:key)
      let l:keyword_cache[l:key] = {}
    endif
    let l:keyword_cache[l:key][l:keyword.word] = l:keyword
  endfor
endfunction"}}}

function! s:caching_from_cache(srcname)"{{{
  if getbufvar(a:srcname, '&buftype') =~ 'nofile'
    return -1
  endif

  let l:srcname = fnamemodify(bufname(str2nr(a:srcname)), ':p')

  if neocomplcache#cache#check_old_cache('buffer_cache', l:srcname)
    return -1
  endif

  let l:source = s:sources[a:srcname]
  for l:keyword in neocomplcache#cache#load_from_cache('buffer_cache', l:srcname)
    let l:key = tolower(l:keyword.word[: s:completion_length-1])
    if !has_key(l:source.keyword_cache, l:key)
      let l:source.keyword_cache[l:key] = {}
    endif

    let l:source.keyword_cache[l:key][l:keyword.word] = l:keyword
  endfor 

  return 0
endfunction"}}}

function! s:check_changed_buffer(bufnumber)"{{{
  let l:source = s:sources[a:bufnumber]
  
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

  return s:sources[a:bufnumber].name != fnamemodify(bufname(a:bufnumber), ':t')
        \ || s:sources[a:bufnumber].filetype != l:ft
endfunction"}}}

function! s:check_source()"{{{
  call s:check_deleted_buffer()

  let l:bufnumber = 1

  " Check new buffer.
  while l:bufnumber <= bufnr('$')
    if bufloaded(l:bufnumber)
      let l:bufname = fnamemodify(bufname(l:bufnumber), ':p')
      if (!has_key(s:sources, l:bufnumber) || s:check_changed_buffer(l:bufnumber))
            \&& !has_key(s:disable_caching_list, l:bufnumber)
            \&& (g:neocomplcache_disable_caching_buffer_name_pattern == '' || l:bufname !~ g:neocomplcache_disable_caching_buffer_name_pattern)
            \&& getfsize(l:bufname) < g:neocomplcache_caching_limit_file_size
            \&& getbufvar(l:bufnumber, '&buftype') !~# 'help'
        " Caching.
        call s:word_caching(l:bufnumber)
      endif
    endif

    let l:bufnumber += 1
  endwhile
endfunction"}}}
function! s:check_deleted_buffer()"{{{
  " Check deleted buffer.
  for key in keys(s:sources)
    if !bufloaded(str2nr(key))
      " Save cache.
      call s:save_cache(key)

      " Remove item.
      call remove(s:sources, key)
    endif
  endfor
endfunction"}}}

function! s:save_cache(srcname)"{{{
  if s:sources[a:srcname].end_line < 500
    return
  endif

  if getbufvar(a:srcname, '&buftype') =~ 'nofile'
    return
  endif

  let l:srcname = fnamemodify(bufname(str2nr(a:srcname)), ':p')
  if !filereadable(l:srcname)
    return
  endif

  let l:cache_name = neocomplcache#cache#encode_name('buffer_cache', l:srcname)
  if getftime(l:cache_name) >= getftime(l:srcname)
    return -1
  endif

  " Output buffer.
  call neocomplcache#cache#save_cache('buffer_cache', l:srcname, neocomplcache#unpack_dictionary_dictionary(s:sources[a:srcname].keyword_cache))
endfunction "}}}
function! s:save_all_cache()"{{{
  for l:key in keys(s:sources)
    call s:save_cache(l:key)
  endfor
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

  if !has_key(s:sources, l:number)
    return
  endif

  silent put=printf('Print neocomplcache %d source.', l:number)
  for l:key in keys(s:sources[l:number])
    silent put =printf('%s => %s', l:key, string(s:sources[l:number][l:key]))
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

  if !has_key(s:sources, l:number)
    return
  endif

  " Output buffer.
  for keyword in neocomplcache#unpack_dictionary_dictionary(s:sources[l:number].keyword_cache)
    silent put=string(keyword)
  endfor
endfunction "}}}
function! s:disable_caching(name)"{{{
  if a:number == ''
    let l:number = bufnr('%')
  else
    let l:number = bufnr(a:name)

    if l:number < 0
      call neocomplcache#print_error('Invalid buffer name.')
      return
    endif
  endif

  let s:disable_caching_list[l:number] = 1

  if has_key(s:sources, l:number)
    " Delete source.
    call remove(s:sources, l:number)
  endif
endfunction"}}}
function! s:enable_caching(name)"{{{
  if a:number == ''
    let l:number = bufnr('%')
  else
    let l:number = bufnr(a:number)

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

" vim: foldmethod=marker
