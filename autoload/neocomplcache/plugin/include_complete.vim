"=============================================================================
" FILE: include_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 Jun 2010
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

let s:include_info = {}
function! neocomplcache#plugin#include_complete#initialize()"{{{
  " Initialize
  let s:include_info = {}
  let s:include_cache = {}
  let s:cached_pattern = {}
  let s:completion_length = neocomplcache#get_auto_completion_length('include_complete')

  augroup neocomplcache
    " Caching events
    autocmd FileType * call s:check_buffer_all()
  augroup END

  " Initialize include pattern."{{{
  call neocomplcache#set_variable_pattern('g:neocomplcache_include_patterns', 'java,haskell', '^import')
  "}}}
  " Initialize expr pattern."{{{
  call neocomplcache#set_variable_pattern('g:neocomplcache_include_exprs', 'haskell',
        \'substitute(v:fname,''\\.'',''/'',''g'')')
  "}}}
  " Initialize path pattern."{{{
  "}}}
  " Initialize suffixes pattern."{{{
  call neocomplcache#set_variable_pattern('g:neocomplcache_include_suffixes', 'haskell', '.hs')
  "}}}

  " Create cache directory.
  if !isdirectory(g:neocomplcache_temporary_dir . '/include_cache')
    call mkdir(g:neocomplcache_temporary_dir . '/include_cache', 'p')
  endif

  " Add command.
  command! -nargs=? -complete=buffer NeoComplCacheCachingInclude call s:check_buffer(<q-args>)
endfunction"}}}

function! neocomplcache#plugin#include_complete#finalize()"{{{
  delcommand NeoComplCacheCachingInclude
endfunction"}}}

function! neocomplcache#plugin#include_complete#get_keyword_list(cur_keyword_str)"{{{
  if !has_key(s:include_info, bufnr('%'))
    return []
  endif

  let l:keyword_list = []
  if len(a:cur_keyword_str) < s:completion_length ||
        \neocomplcache#check_match_filter(a:cur_keyword_str, s:completion_length)
    for l:include in s:include_info[bufnr('%')].include_files
      if !bufloaded(l:include)
        let l:keyword_list += neocomplcache#unpack_dictionary(s:include_cache[l:include])
      endif
    endfor
  else
    let l:key = tolower(a:cur_keyword_str[: s:completion_length-1])
    for l:include in s:include_info[bufnr('%')].include_files
      if !bufloaded(l:include) && has_key(s:include_cache[l:include], l:key)
        let l:keyword_list += s:include_cache[l:include][l:key]
      endif
    endfor
  endif

  return neocomplcache#member_filter(l:keyword_list, a:cur_keyword_str)
endfunction"}}}

function! neocomplcache#plugin#include_complete#get_include_files(bufnumber)"{{{
  if has_key(s:include_info, a:bufnumber)
    return s:include_info[a:bufnumber].include_files
  else
    return []
  endif
endfunction"}}}

function! s:check_buffer_all()"{{{
  let l:bufnumber = 1

  " Check buffer.
  while l:bufnumber <= bufnr('$')
    if bufloaded(l:bufnumber) && !has_key(s:include_info, l:bufnumber)
      call s:check_buffer(bufname(l:bufnumber))
    endif

    let l:bufnumber += 1
  endwhile
endfunction"}}}
function! s:check_buffer(bufname)"{{{
  let l:bufname = fnamemodify((a:bufname == '')? a:bufname : bufname('%'), ':p')
  let l:bufnumber = bufnr(l:bufname)
  let s:include_info[l:bufnumber] = {}
  if (g:neocomplcache_disable_caching_buffer_name_pattern == '' || l:bufname !~ g:neocomplcache_disable_caching_buffer_name_pattern)
        \&& getbufvar(l:bufnumber, '&readonly') == 0
    let l:filetype = getbufvar(l:bufnumber, '&filetype')
    if l:filetype == ''
      let l:filetype = 'nothing'
    endif

    " Check include.
    let l:include_files = s:get_buffer_include_files(l:bufnumber)
    for l:filename in l:include_files
      if !has_key(s:include_cache, l:filename)
        " Caching.
        let s:include_cache[l:filename] = s:load_from_tags(l:filename, l:filetype)
      endif
    endfor

    let s:include_info[l:bufnumber].include_files = l:include_files
  else
    let s:include_info[l:bufnumber].include_files = []
  endif
endfunction"}}}
function! s:get_buffer_include_files(bufnumber)"{{{
  let l:filetype = getbufvar(a:bufnumber, '&filetype')
  if l:filetype == ''
    return []
  endif

  if l:filetype == 'python'
        \&& !has_key(g:neocomplcache_include_paths, 'python')
        \&& executable('python')
    " Initialize python path pattern.
    call neocomplcache#set_variable_pattern('g:neocomplcache_include_paths', 'python',
          \neocomplcache#system('python -', 'import sys;sys.stdout.write(",".join(sys.path))'))
  endif

  let l:pattern = has_key(g:neocomplcache_include_patterns, l:filetype) ? 
        \g:neocomplcache_include_patterns[l:filetype] : getbufvar(a:bufnumber, '&include')
  if l:pattern == ''
    return []
  endif
  let l:path = has_key(g:neocomplcache_include_paths, l:filetype) ? 
        \g:neocomplcache_include_paths[l:filetype] : getbufvar(a:bufnumber, '&path')
  let l:expr = has_key(g:neocomplcache_include_exprs, l:filetype) ? 
        \g:neocomplcache_include_exprs[l:filetype] : getbufvar(a:bufnumber, '&includeexpr')
  if has_key(g:neocomplcache_include_suffixes, l:filetype)
    let l:suffixes = &l:suffixesadd
  endif

  " Change current directory.
  let l:cwd_save = getcwd()
  if isdirectory(fnamemodify(bufname(a:bufnumber), ':p:h'))
    lcd `=fnamemodify(bufname(a:bufnumber), ':p:h')`
  endif

  let l:include_files = s:get_include_files(0, getbufline(a:bufnumber, 1, 100), l:filetype, l:pattern, l:path, l:expr)

  lcd `=l:cwd_save`

  " Restore option.
  if has_key(g:neocomplcache_include_suffixes, l:filetype)
    let &l:suffixesadd = l:suffixes
  endif

  return l:include_files
endfunction"}}}
function! s:get_include_files(nestlevel, lines, filetype, pattern, path, expr)"{{{
  let l:include_files = []
  for l:line in a:lines"{{{
    if l:line =~ a:pattern
      let l:match_end = matchend(l:line, a:pattern)
      if a:expr != ''
        let l:eval = substitute(a:expr, 'v:fname', string(matchstr(l:line[l:match_end :], '\f\+')), 'g')
        let l:filename = fnamemodify(findfile(eval(l:eval), a:path), ':p')
      else
        let l:filename = fnamemodify(findfile(matchstr(l:line[l:match_end :], '\f\+'), a:path), ':p')
      endif
      if filereadable(l:filename) && getfsize(l:filename) < g:neocomplcache_caching_limit_file_size
        call add(l:include_files, l:filename)

        if (a:filetype == 'c' || a:filetype == 'cpp') && a:nestlevel < 1
          let l:include_files += s:get_include_files(a:nestlevel + 1, readfile(l:filename)[:100],
                \a:filetype, a:pattern, a:path, a:expr)
        endif
      endif
    endif
  endfor"}}}

  return l:include_files
endfunction"}}}

function! s:load_from_tags(filename, filetype)"{{{
  " Initialize include list from tags.

  let l:keyword_lists = s:load_from_cache(a:filename)
  if !empty(l:keyword_lists) || getfsize(neocomplcache#cache#encode_name('include_cache', a:filename)) == 0
    return l:keyword_lists
  endif

  if !executable(g:neocomplcache_ctags_program)
    return s:load_from_file(a:filename, a:filetype)
  endif

  let l:args = has_key(g:neocomplcache_ctags_arguments_list, a:filetype) ? 
        \g:neocomplcache_ctags_arguments_list[a:filetype] : g:neocomplcache_ctags_arguments_list['default']
  let l:command = has('win32') || has('win64') ? 
        \printf('%s -f - %s %s', g:neocomplcache_ctags_program, l:args, fnamemodify(a:filename, ':p:.')) : 
        \printf('%s -f /dev/stdout 2>/dev/null %s %s', g:neocomplcache_ctags_program, l:args, fnamemodify(a:filename, ':p:.'))
  let l:lines = split(neocomplcache#system(l:command), '\n')

  if !empty(l:lines)
    " Save ctags file.
    call neocomplcache#cache#writefile('include_tags', a:filename, l:lines)
  endif

  let l:keyword_lists = {}

  for l:keyword in neocomplcache#cache#load_from_tags('include_cache', a:filename, l:lines, 'I', a:filetype)
    let l:key = tolower(l:keyword.word[: s:completion_length-1])
    if !has_key(l:keyword_lists, l:key)
      let l:keyword_lists[l:key] = []
    endif

    call add(l:keyword_lists[l:key], l:keyword)
  endfor 

  call neocomplcache#cache#save_cache('include_cache', a:filename, neocomplcache#unpack_dictionary(l:keyword_lists))

  if empty(l:keyword_lists)
    return s:load_from_file(a:filename, a:filetype)
  endif

  return l:keyword_lists
endfunction"}}}
function! s:load_from_file(filename, filetype)"{{{
  " Initialize include list from file.

  let l:keyword_lists = {}
  let l:loaded_list = neocomplcache#cache#load_from_file(a:filename, neocomplcache#get_keyword_pattern(), 'I')
  if len(l:loaded_list) > 300
    call neocomplcache#cache#save_cache('include_cache', a:filename, l:loaded_list)
  endif

  for l:keyword in l:loaded_list
    let l:key = tolower(l:keyword.word[: s:completion_length-1])
    if !has_key(l:keyword_lists, l:key)
      let l:keyword_lists[l:key] = []
    endif
    call add(l:keyword_lists[l:key], l:keyword)
  endfor"}}}

  return l:keyword_lists
endfunction"}}}
function! s:load_from_cache(filename)"{{{
  let l:keyword_lists = {}

  for l:keyword in neocomplcache#cache#load_from_cache('include_cache', a:filename)
    let l:key = tolower(l:keyword.word[: s:completion_length-1])
    if !has_key(l:keyword_lists, l:key)
      let l:keyword_lists[l:key] = []
    endif
    call add(l:keyword_lists[l:key], l:keyword)
  endfor 

  return l:keyword_lists
endfunction"}}}

" Global options definition."{{{
if !exists('g:neocomplcache_include_patterns')
  let g:neocomplcache_include_patterns = {}
endif
if !exists('g:neocomplcache_include_exprs')
  let g:neocomplcache_include_exprs = {}
endif
if !exists('g:neocomplcache_include_paths')
  let g:neocomplcache_include_paths = {}
endif
if !exists('g:neocomplcache_include_suffixes')
  let g:neocomplcache_include_suffixes = {}
endif
"}}}

" vim: foldmethod=marker
