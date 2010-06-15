"=============================================================================
" FILE: cache.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 15 Jun 2010
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditionneocomplcache#cache#
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

" Cache loader.
function! neocomplcache#cache#load_from_cache(cache_dir, filename)"{{{
  if neocomplcache#cache#check_old_cache(a:cache_dir, a:filename)
    return []
  endif

  let l:keyword_lists = []
  let l:lines = readfile(neocomplcache#cache#encode_name(a:cache_dir, a:filename))
  let l:max_lines = len(l:lines)

  if empty(l:lines)
    return []
  endif

  if l:max_lines > 3000
    call neocomplcache#print_caching('Caching from cache "' . a:filename . '"... please wait.')
  endif
  if l:max_lines > 10000
    let l:print_cache_percent = l:max_lines / 5
  elseif l:max_lines > 5000
    let l:print_cache_percent = l:max_lines / 4
  elseif l:max_lines > 3000
    let l:print_cache_percent = l:max_lines / 3
  else
    let l:print_cache_percent = -1
  endif
  let l:line_cnt = l:print_cache_percent

  try
    let l:line_num = 1
    for l:line in l:lines"{{{
      " Percentage check."{{{
      if l:print_cache_percent > 0
        if l:line_cnt == 0
          call neocomplcache#print_caching(printf('Caching(%s): %d%%', a:filename, l:line_num*100 / l:max_lines))
          let l:line_cnt = l:print_cache_percent
        endif
        let l:line_cnt -= 1
        
        let l:line_num += 1
      endif
      "}}}

      let l:cache = split(l:line, '|||', 1)
      let l:keyword = {
            \ 'word' : l:cache[0], 'abbr' : l:cache[1], 'menu' : l:cache[2],
            \}
      if l:cache[3] != ''
        let l:keyword.kind = l:cache[3]
      endif
      if l:cache[4] != ''
        let l:keyword.class = l:cache[4]
      endif

      call add(l:keyword_lists, l:keyword)
    endfor"}}}
  catch /E684:/
    call neocomplcache#print_error(v:exception)
    call neocomplcache#print_error('Error occured while analyzing cache!')
    let l:cache_dir = g:neocomplcache_temporary_dir . '/' . a:cache_dir
    call neocomplcache#print_error('Please delete cache directory: ' . l:cache_dir)
    return []
  endtry

  if l:max_lines > 3000
    call neocomplcache#print_caching('Caching done.')
  endif

  return l:keyword_lists
endfunction"}}}
function! neocomplcache#cache#index_load_from_cache(cache_dir, filename, completion_length)"{{{
  let l:keyword_lists = {}

  for l:keyword in neocomplcache#cache#load_from_cache(a:cache_dir, a:filename)
    let l:key = tolower(l:keyword.word[: a:completion_length-1])
    if !has_key(l:keyword_lists, l:key)
      let l:keyword_lists[l:key] = []
    endif
    call add(l:keyword_lists[l:key], l:keyword)
  endfor 

  return l:keyword_lists
endfunction"}}}
function! neocomplcache#cache#load_from_file(filename, pattern, mark)"{{{
  if bufloaded(a:filename)
    let l:lines = getbufline(bufnr(a:filename), 1, '$')
  elseif filereadable(a:filename)
    let l:lines = readfile(a:filename)
  else
    " File not found.
    return []
  endif
  
  let l:max_lines = len(l:lines)
  let l:menu = printf('[%s] %.' . g:neocomplcache_max_filename_width . 's', a:mark, fnamemodify(a:filename, ':t'))

  if l:max_lines > 1000
    call neocomplcache#print_caching('Caching from file "' . a:filename . '"... please wait.')
  endif
  if l:max_lines > 10000
    let l:print_cache_percent = l:max_lines / 9
  elseif l:max_lines > 7000
    let l:print_cache_percent = l:max_lines / 6
  elseif l:max_lines > 5000
    let l:print_cache_percent = l:max_lines / 5
  elseif l:max_lines > 3000
    let l:print_cache_percent = l:max_lines / 4
  elseif l:max_lines > 2000
    let l:print_cache_percent = l:max_lines / 3
  elseif l:max_lines > 1000
    let l:print_cache_percent = l:max_lines / 2
  else
    return s:load_from_file_fast(l:lines, a:pattern, l:menu)
  endif
  let l:line_cnt = l:print_cache_percent

  let l:line_num = 1
  let l:keyword_lists = []
  let l:dup_check = {}
  let l:keyword_pattern2 = '^\%('.a:pattern.'\m\)'

  for l:line in l:lines"{{{
    " Percentage check."{{{
    if l:print_cache_percent > 0
      if l:line_cnt == 0
        call neocomplcache#print_caching(printf('Caching(%s): %d%%', a:filename, l:line_num*100 / l:max_lines))
        let l:line_cnt = l:print_cache_percent
      endif
      let l:line_cnt -= 1

      let l:line_num += 1
    endif
    "}}}

    let l:match = match(l:line, a:pattern)
    while l:match >= 0"{{{
      let l:match_str = matchstr(l:line, l:keyword_pattern2, l:match)

      " Ignore too short keyword.
      if !has_key(l:dup_check, l:match_str) && len(l:match_str) >= g:neocomplcache_min_keyword_length
        " Append list.
        call add(l:keyword_lists, { 'word' : l:match_str, 'menu' : l:menu })

        let l:dup_check[l:match_str] = 1
      endif

      let l:match = match(l:line, a:pattern, l:match + len(l:match_str))
    endwhile"}}}
  endfor"}}}

  if l:max_lines > 1000
    call neocomplcache#print_caching('Caching done.')
  endif

  return l:keyword_lists
endfunction"}}}
function! s:load_from_file_fast(lines, pattern, menu)"{{{
  let l:line_num = 1
  let l:keyword_lists = []
  let l:dup_check = {}
  let l:keyword_pattern2 = '^\%('.a:pattern.'\m\)'
  let l:line = join(a:lines)

  let l:match = match(l:line, a:pattern)
  while l:match >= 0"{{{
    let l:match_str = matchstr(l:line, l:keyword_pattern2, l:match)

    " Ignore too short keyword.
    if !has_key(l:dup_check, l:match_str) && len(l:match_str) >= g:neocomplcache_min_keyword_length
      " Append list.
      call add(l:keyword_lists, { 'word' : l:match_str, 'menu' : a:menu })

      let l:dup_check[l:match_str] = 1
    endif

    let l:match = match(l:line, a:pattern, l:match + len(l:match_str))
  endwhile"}}}

  return l:keyword_lists
endfunction"}}}
function! neocomplcache#cache#load_from_tags(cache_dir, filename, tags_list, mark, filetype)"{{{
  let l:max_lines = len(a:tags_list)

  if l:max_lines > 1000
    call neocomplcache#print_caching('Caching from tags "' . a:filename . '"... please wait.')
  endif
  if l:max_lines > 10000
    let l:print_cache_percent = l:max_lines / 9
  elseif l:max_lines > 7000
    let l:print_cache_percent = l:max_lines / 6
  elseif l:max_lines > 5000
    let l:print_cache_percent = l:max_lines / 5
  elseif l:max_lines > 3000
    let l:print_cache_percent = l:max_lines / 4
  elseif l:max_lines > 2000
    let l:print_cache_percent = l:max_lines / 3
  elseif l:max_lines > 1000
    let l:print_cache_percent = l:max_lines / 2
  else
    let l:print_cache_percent = -1
  endif
  let l:line_cnt = l:print_cache_percent

  let l:menu_pattern = printf('[%s] %%.%ds %%.%ds', a:mark, g:neocomplcache_max_filename_width, g:neocomplcache_max_filename_width)
  let l:keyword_lists = []
  let l:dup_check = {}
  let l:line_num = 1

  try
    for l:line in a:tags_list"{{{
      " Percentage check."{{{
      if l:line_cnt == 0
        call neocomplcache#print_caching(printf('Caching(%s): %d%%', a:filename, l:line_num*100 / l:max_lines))
        let l:line_cnt = l:print_cache_percent
      endif
      let l:line_cnt -= 1"}}}

      let l:tag = split(substitute(l:line, "\<CR>", '', 'g'), '\t', 1)
      " Add keywords.
      if l:line !~ '^!' && len(l:tag) >= 3 && len(l:tag[0]) >= g:neocomplcache_min_keyword_length
            \&& !has_key(l:dup_check, l:tag[0])
        let l:option = {
              \ 'cmd' : substitute(substitute(l:tag[2], '^\%([/?]\^\)\?\s*\|\%(\$\?[/?]\)\?;"$', '', 'g'), '\\\\', '\\', 'g'), 
              \ 'kind' : ''
              \}
        if l:option.cmd =~ '\d\+'
          let l:option.cmd = l:tag[0]
        endif

        for l:opt in l:tag[3:]
          let l:key = matchstr(l:opt, '^\h\w*\ze:')
          if l:key == ''
            let l:option['kind'] = l:opt
          else
            let l:option[l:key] = matchstr(l:opt, '^\h\w*:\zs.*')
          endif
        endfor

        if has_key(l:option, 'file') || (has_key(l:option, 'access') && l:option.access != 'public')
          let l:line_num += 1
          continue
        endif

        let l:abbr = (l:option['kind'] == 'd' || l:option['cmd'] == '')?  l:tag[0] : l:option['cmd']
        let l:keyword = {
              \ 'word' : l:tag[0], 'abbr' : l:abbr, 'kind' : l:option['kind']
              \}
        if has_key(l:option, 'struct')
          let keyword.menu = printf(l:menu_pattern, fnamemodify(l:tag[1], ':t'), l:option.struct)
          let keyword.class = l:option.struct
        elseif has_key(l:option, 'class')
          let keyword.menu = printf(l:menu_pattern, fnamemodify(l:tag[1], ':t'), l:option.class)
          let keyword.class = l:option.class
        elseif has_key(l:option, 'enum')
          let keyword.menu = printf(l:menu_pattern, fnamemodify(l:tag[1], ':t'), l:option.enum)
          let keyword.class = l:option.enum
        else
          let keyword.menu = printf(l:menu_pattern, fnamemodify(l:tag[1], ':t'), '')
          let keyword.class = ''
        endif

        call add(l:keyword_lists, l:keyword)
        let l:dup_check[l:tag[0]] = 1
      endif

      let l:line_num += 1
    endfor"}}}
  catch /E684:/
    echohl WarningMsg | echomsg 'Error occured while analyzing tags!' | echohl None
    echohl WarningMsg | echomsg v:exception | echohl None
    let l:log_file = g:neocomplcache_temporary_dir . '/' . a:cache_dir . '/error_log'
    echohl WarningMsg | echomsg 'Please look tags file: ' . l:log_file | echohl None
    call writefile(a:tags_list, l:log_file)
    return []
  endtry

  if l:max_lines > 1000
    call neocomplcache#print_caching('Caching done.')
  endif

  if a:filetype != '' && has_key(g:neocomplcache_tags_filter_patterns, a:filetype)
    call filter(l:keyword_lists, g:neocomplcache_tags_filter_patterns[a:filetype])
  endif

  return l:keyword_lists
endfunction"}}}

function! neocomplcache#cache#save_cache(cache_dir, filename, keyword_list)"{{{
  " Create cache directory.
  call neocomplcache#cache#check_dir(a:cache_dir)

  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)

  " Create dictionary key.
  for keyword in a:keyword_list
    if !has_key(keyword, 'kind')
      let keyword.kind = ''
    endif
    if !has_key(keyword, 'class')
      let keyword.class = ''
    endif
    if !has_key(keyword, 'abbr')
      let keyword.abbr = keyword.word
    endif
  endfor

  " Output cache.
  let l:word_list = []
  for keyword in a:keyword_list
    call add(l:word_list, printf('%s|||%s|||%s|||%s|||%s', 
          \keyword.word, keyword.abbr, keyword.menu, keyword.kind, keyword.class))
  endfor

  call writefile(l:word_list, l:cache_name)
endfunction"}}}

" Cache helper.
function! neocomplcache#cache#getfilename(cache_dir, filename)"{{{
  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  return l:cache_name
endfunction"}}}
function! neocomplcache#cache#filereadable(cache_dir, filename)"{{{
  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  return filereadable(l:cache_name)
endfunction"}}}
function! neocomplcache#cache#readfile(cache_dir, filename)"{{{
  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  return filereadable(l:cache_name) ? readfile(l:cache_name) : []
endfunction"}}}
function! neocomplcache#cache#writefile(cache_dir, filename, list)"{{{
  call neocomplcache#cache#check_dir(a:cache_dir)

  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)

  call writefile(a:list, l:cache_name)
endfunction"}}}
function! neocomplcache#cache#encode_name(cache_dir, filename)
  let l:dir = printf('%s/%s/', g:neocomplcache_temporary_dir, a:cache_dir) 
  return l:dir . s:create_hash(l:dir, a:filename)
endfunction
function! neocomplcache#cache#check_dir(cache_dir)"{{{
  " Check cache directory.
  let l:cache_dir = g:neocomplcache_temporary_dir . '/' . a:cache_dir
  if !isdirectory(l:cache_dir)
    call mkdir(l:cache_dir, 'p')
  endif
endfunction"}}}
function! neocomplcache#cache#check_old_cache(cache_dir, filename)"{{{
  " Check old cache file.
  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  return getftime(l:cache_name) == -1 || getftime(l:cache_name) <= getftime(a:filename)
endfunction"}}}

" Check md5.
let s:is_md5 = exists('*md5#md5')
function! s:create_hash(dir, str)
  if len(a:dir) + len(a:str) < 150
    let l:hash = substitute(substitute(a:str, ':', '=-', 'g'), '[/\\]', '=+', 'g')
  elseif s:is_md5
    " Use md5.vim.
    let l:hash = md5#md5(a:str)
  else
    " Use simple hash.
    let l:sum = 0
    for i in range(len(a:str))
      let l:sum += char2nr(a:str[i]) * 2
    endfor

    let l:hash = printf('%x', l:sum)
  endif

  return l:hash
endfunction
" vim: foldmethod=marker
