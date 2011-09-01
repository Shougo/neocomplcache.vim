"=============================================================================
" FILE: filename_complete.vim
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

let s:source = {
      \ 'name' : 'filename_complete',
      \ 'kind' : 'complfunc',
      \}

function! s:source.initialize()"{{{
  " Initialize.
  let s:skip_dir = {}

  call neocomplcache#set_completion_length('filename_complete', g:neocomplcache_auto_completion_start_length)

  " Set rank.
  call neocomplcache#set_dictionary_helper(g:neocomplcache_plugin_rank, 'filename_complete', 2)
endfunction"}}}
function! s:source.finalize()"{{{
endfunction"}}}

function! s:source.get_keyword_pos(cur_text)"{{{
  let l:filetype = neocomplcache#get_context_filetype()
  if l:filetype ==# 'vimshell' || l:filetype ==# 'unite' || neocomplcache#within_comment()
    return -1
  endif

  " Not Filename pattern.
  if a:cur_text =~
        \'\*$\|\.\.\+$\|[/\\][/\\]\f*$\|/c\%[ygdrive/]$\|\\|$\|\a:[^/]*$'
    return -1
  endif

  " Check include pattern.
  let l:pattern = exists('g:neocomplcache_include_patterns') &&
        \ has_key(g:neocomplcache_include_patterns, l:filetype) ?
        \ g:neocomplcache_include_patterns[l:filetype] :
        \ getbufvar(bufnr('%'), '&include')
  if neocomplcache#is_auto_complete()
        \ && l:pattern !~ a:cur_text && a:cur_text !~ '/'
    " Skip filename completion.
    return -1
  endif

  " Filename pattern.
  let l:pattern = neocomplcache#get_keyword_pattern_end('filename')
  let [l:cur_keyword_pos, l:cur_keyword_str] = neocomplcache#match_word(a:cur_text, l:pattern)

  " Not Filename pattern.
  if neocomplcache#is_win() && l:filetype == 'tex' && l:cur_keyword_str =~ '\\'
    return -1
  endif

  " Skip directory.
  if neocomplcache#is_auto_complete()
    let l:dir = simplify(fnamemodify(l:cur_keyword_str, ':p:h'))
    if l:dir != '' && has_key(s:skip_dir, l:dir)
      return -1
    endif
  endif

  return l:cur_keyword_pos
endfunction"}}}

function! s:source.get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
  let l:filetype = neocomplcache#get_context_filetype()

  " Check include pattern.
  let l:pattern = exists('g:neocomplcache_include_patterns') &&
        \ has_key(g:neocomplcache_include_patterns, l:filetype) ?
        \ g:neocomplcache_include_patterns[l:filetype] :
        \ getbufvar(bufnr('%'), '&include')
  let l:line = neocomplcache#get_cur_text()
  return (l:pattern == '' || l:line !~ l:pattern) ?
        \ s:get_glob_files(a:cur_keyword_str, '') :
        \ s:get_include_files(a:cur_keyword_str)
endfunction"}}}

function! s:get_include_files(cur_keyword_str)"{{{
  let l:filetype = neocomplcache#get_context_filetype()

  let l:path = exists('g:neocomplcache_include_patterns') &&
        \ has_key(g:neocomplcache_include_paths, l:filetype) ?
        \ g:neocomplcache_include_paths[l:filetype] :
        \ getbufvar(bufnr('%'), '&path')

  let l:pattern = exists('g:neocomplcache_include_patterns') &&
        \ has_key(g:neocomplcache_include_patterns, l:filetype) ?
        \ g:neocomplcache_include_patterns[l:filetype] :
        \ getbufvar(bufnr('%'), '&include')
  let l:line = neocomplcache#get_cur_text()
  let l:match_end = matchend(l:line, l:pattern)
  let l:cur_keyword_str = matchstr(l:line[l:match_end :], '\f\+')

  " Path search.
  let l:glob = (l:cur_keyword_str !~ '\*$')?
        \ l:cur_keyword_str . '*' : l:cur_keyword_str
  let l:cwd = getcwd()
  let l:bufdirectory = fnamemodify(expand('%'), ':p:h')
  let l:dir_list = []
  let l:file_list = []
  for subpath in map(split(l:path, ','), 'substitute(v:val, "\\\\", "/", "g")')
    let l:dir = (subpath == '.') ? l:bufdirectory : subpath
    if !isdirectory(l:dir)
      continue
    endif
    lcd `=l:dir`

    for word in split(substitute(glob(l:glob), '\\', '/', 'g'), '\n')
      let l:dict = { 'word' : word, 'menu' : '[F]' }

      let l:abbr = l:dict.word
      if isdirectory(l:word)
        let l:abbr .= '/'
        if g:neocomplcache_enable_auto_delimiter
          let l:dict.word .= '/'
        endif
      endif
      let l:dict.abbr = l:abbr

      " Escape word.
      let l:dict.word = escape(l:dict.word, ' *?[]"={}')

      call add(isdirectory(l:word) ? l:dir_list : l:file_list, l:dict)
    endfor
  endfor
  lcd `=l:cwd`

  return neocomplcache#keyword_filter(l:dir_list, a:cur_keyword_str)
        \ + neocomplcache#keyword_filter(l:file_list, a:cur_keyword_str)
endfunction"}}}

let s:cached_files = {}

function! s:get_glob_files(cur_keyword_str, path)"{{{
  let l:path = ',,' . substitute(a:path, '\.\%(,\|$\)\|,,', '', 'g')

  let l:cur_keyword_str = a:cur_keyword_str
  let l:cur_keyword_str = escape(a:cur_keyword_str, '[]')
  let l:cur_keyword_str = substitute(l:cur_keyword_str, '\\ ', ' ', 'g')

  let l:glob = (l:cur_keyword_str !~ '\*$')?  l:cur_keyword_str . '*' : l:cur_keyword_str

  if a:path == '' && l:cur_keyword_str !~ '/'
    if !has_key(s:cached_files, getcwd())
      call s:caching_current_files()
    endif

    let l:files = copy(s:cached_files[getcwd()])
  else
    try
      let l:globs = globpath(l:path, l:glob)
    catch
      return []
    endtry
    let l:files = split(substitute(l:globs, '\\', '/', 'g'), '\n')

    if empty(l:files)
      " Add '*' to a delimiter.
      let l:cur_keyword_str = substitute(l:cur_keyword_str, '\w\+\ze[/._-]', '\0*', 'g')
      let l:glob = (l:cur_keyword_str !~ '\*$')?  l:cur_keyword_str . '*' : l:cur_keyword_str

      try
        let l:globs = globpath(l:path, l:glob)
      catch
        return []
      endtry
      let l:files = split(substitute(l:globs, '\\', '/', 'g'), '\n')
    endif
  endif

  let l:files = neocomplcache#keyword_filter(map(
        \ l:files, '{
        \    "word" : fnamemodify(v:val, ":t"),
        \    "orig" : v:val,
        \ }'),
        \ fnamemodify(a:cur_keyword_str, ':t'))

  if (neocomplcache#is_auto_complete() && len(l:files) > g:neocomplcache_max_list)
    let l:files = l:files[: g:neocomplcache_max_list - 1]
  endif

  let l:files = map(l:files, '{
        \    "word" : substitute(v:val.orig, "//", "/", "g"),
        \ }')

  if a:cur_keyword_str =~ '^\$\h\w*'
    let l:env = matchstr(a:cur_keyword_str, '^\$\h\w*')
    let l:env_ev = eval(l:env)
    if neocomplcache#is_win()
      let l:env_ev = substitute(l:env_ev, '\\', '/', 'g')
    endif
    let l:len_env = len(l:env_ev)
  else
    let l:len_env = 0
  endif

  let l:home_pattern = '^'.substitute($HOME, '\\', '/', 'g').'/'
  let l:exts = escape(substitute($PATHEXT, ';', '\\|', 'g'), '.')

  let l:dir_list = []
  let l:file_list = []
  for l:dict in l:files
    let l:dict.menu = '[F]'
    let l:dict.orig = l:dict.word

    if l:len_env != 0 && l:dict.word[: l:len_env-1] == l:env_ev
      let l:dict.word = l:env . l:dict.word[l:len_env :]
    elseif a:cur_keyword_str =~ '^\~/'
      let l:dict.word = substitute(l:dict.word, l:home_pattern, '\~/', '')
    endif

    let l:abbr = l:dict.word
    if isdirectory(expand(l:dict.word))
      let l:abbr .= '/'
      if g:neocomplcache_enable_auto_delimiter
        let l:dict.word .= '/'
      endif
    elseif neocomplcache#is_win()
      if '.'.fnamemodify(l:dict.word, ':e') =~ l:exts
        let l:abbr .= '*'
      endif
    elseif executable(l:dict.word)
      let l:abbr .= '*'
    endif
    let l:dict.abbr = l:abbr

    " Escape word.
    let l:dict.word = escape(l:dict.word, ' *?[]"={}')

    call add(isdirectory(l:dict.word) ? l:dir_list : l:file_list, l:dict)
  endfor

  return l:dir_list + l:file_list
endfunction"}}}
function! s:caching_current_files()
  let s:cached_files[getcwd()] =
        \ split(substitute(glob('*') . "\n" . glob('.*'), '\\', '/', 'g'), '\n')
endfunction

function! neocomplcache#sources#filename_complete#define()"{{{
  return s:source
endfunction"}}}

function! neocomplcache#sources#filename_complete#get_complete_words(cur_keyword_str, path)"{{{
  return s:get_glob_files(a:cur_keyword_str, a:path)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
