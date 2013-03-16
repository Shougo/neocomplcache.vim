"=============================================================================
" FILE: filename_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 16 Mar 2013.
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
      \ 'mark' : '[F]',
      \}

function! s:source.initialize() "{{{
  " Initialize.
  call neocomplcache#set_completion_length(
        \ 'filename_complete', g:neocomplcache_auto_completion_start_length)

  " Set rank.
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_source_rank',
        \ 'filename_complete', 3)
endfunction"}}}
function! s:source.finalize() "{{{
endfunction"}}}

function! s:source.get_keyword_pos(cur_text) "{{{
  let filetype = neocomplcache#get_context_filetype()
  if filetype ==# 'vimshell' || filetype ==# 'unite'
    return -1
  endif

  " Filename pattern.
  let pattern = neocomplcache#get_keyword_pattern_end('filename')
  let [cur_keyword_pos, cur_keyword_str] =
        \ neocomplcache#match_word(a:cur_text, pattern)
  if cur_keyword_str =~ '//' ||
        \ (neocomplcache#is_auto_complete() &&
        \    (cur_keyword_str !~ '/' ||
        \     cur_keyword_str =~# '\*\|\.\.\+$\|/c\%[ygdrive/]$'))
    " Not filename pattern.
    return -1
  endif

  if neocomplcache#is_sources_complete() && cur_keyword_pos < 0
    let cur_keyword_pos = len(a:cur_text)
  endif

  return cur_keyword_pos
endfunction"}}}

function! s:source.get_complete_words(cur_keyword_pos, cur_keyword_str) "{{{
  return s:get_glob_files(a:cur_keyword_str, '')
endfunction"}}}

let s:cached_files = {}

function! s:get_glob_files(cur_keyword_str, path) "{{{
  let path = ',,' . substitute(a:path, '\.\%(,\|$\)\|,,', '', 'g')

  let cur_keyword_str = neocomplcache#util#substitute_path_separator(
        \ substitute(a:cur_keyword_str, '\\\(.\)', '\1', 'g'))

  let glob = (cur_keyword_str !~ '\*$')?
        \ cur_keyword_str . '*' : cur_keyword_str

  if a:path == '' && cur_keyword_str !~ '/'
    if !has_key(s:cached_files, getcwd())
      call s:caching_current_files()
    endif

    let files = copy(s:cached_files[getcwd()])
  else
    let ftype = getftype(glob)
    if ftype != '' && ftype !=# 'dir'
      " Note: If glob() device files, Vim may freeze!
      return []
    endif

    if a:path == ''
      let files = neocomplcache#util#glob(glob)
    else
      try
        let globs = globpath(path, glob)
      catch
        return []
      endtry
      let files = split(substitute(globs, '\\', '/', 'g'), '\n')
    endif

    if empty(files)
      " Add '*' to a delimiter.
      let cur_keyword_str =
            \ substitute(cur_keyword_str, '\w\+\ze[/._-]', '\0*', 'g')
      let glob = (cur_keyword_str !~ '\*$') ?
            \ cur_keyword_str . '*' : cur_keyword_str

      try
        let globs = globpath(path, glob)
      catch
        return []
      endtry
      let files = split(substitute(globs, '\\', '/', 'g'), '\n')
    endif
  endif

  let files = neocomplcache#keyword_filter(map(
        \ files, '{
        \    "word" : fnamemodify(v:val, ":t"),
        \    "orig" : v:val,
        \ }'),
        \ fnamemodify(cur_keyword_str, ':t'))

  if neocomplcache#is_auto_complete()
        \ && len(files) > g:neocomplcache_max_list
    let files = files[: g:neocomplcache_max_list - 1]
  endif

  let files = map(files, '{
        \    "word" : substitute(v:val.orig, "//", "/", "g"),
        \ }')

  if a:cur_keyword_str =~ '^\$\h\w*'
    let env = matchstr(a:cur_keyword_str, '^\$\h\w*')
    let env_ev = eval(env)
    if neocomplcache#is_windows()
      let env_ev = substitute(env_ev, '\\', '/', 'g')
    endif
    let len_env = len(env_ev)
  else
    let len_env = 0
  endif

  let home_pattern = '^'.
        \ neocomplcache#util#substitute_path_separator(
        \ expand('~')).'/'
  let exts = escape(substitute($PATHEXT, ';', '\\|', 'g'), '.')

  let dir_list = []
  let file_list = []
  for dict in files
    call add(isdirectory(dict.word) ?
          \ dir_list : file_list, dict)

    let dict.orig = dict.word

    if len_env != 0 && dict.word[: len_env-1] == env_ev
      let dict.word = env . dict.word[len_env :]
    endif

    let abbr = dict.word
    if isdirectory(dict.word) && dict.word !~ '/$'
      let abbr .= '/'
      if g:neocomplcache_enable_auto_delimiter
        let dict.word .= '/'
      endif
    elseif neocomplcache#is_windows()
      if '.'.fnamemodify(dict.word, ':e') =~ exts
        let abbr .= '*'
      endif
    elseif executable(dict.word)
      let abbr .= '*'
    endif
    let dict.abbr = abbr

    if a:cur_keyword_str =~ '^\~/'
      let dict.word = substitute(dict.word, home_pattern, '\~/', '')
      let dict.abbr = substitute(dict.abbr, home_pattern, '\~/', '')
    endif

    " Escape word.
    let dict.word = escape(dict.word, ' ;*?[]"={}''')
  endfor

  return dir_list + file_list
endfunction"}}}
function! s:caching_current_files() "{{{
  let s:cached_files[getcwd()] = neocomplcache#util#glob('*')
  if !exists('vimproc#readdir')
    let s:cached_files[getcwd()] += neocomplcache#util#glob('.*')
  endif
endfunction"}}}

function! neocomplcache#sources#filename_complete#define() "{{{
  return s:source
endfunction"}}}

function! neocomplcache#sources#filename_complete#get_complete_words(cur_keyword_str, path) "{{{
  if !neocomplcache#is_enabled()
    return []
  endif

  return s:get_glob_files(a:cur_keyword_str, a:path)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
