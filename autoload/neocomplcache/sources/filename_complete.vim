"=============================================================================
" FILE: filename_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 20 Jun 2013.
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
      \ 'kind' : 'manual',
      \ 'mark' : '[F]',
      \ 'rank' : 3,
      \ 'min_pattern_length' :
      \        g:neocomplcache_auto_completion_start_length,
      \}

function! s:source.initialize() "{{{
endfunction"}}}
function! s:source.finalize() "{{{
endfunction"}}}

function! s:source.get_keyword_pos(cur_text) "{{{
  let filetype = neocomplcache#get_context_filetype()
  if filetype ==# 'vimshell' || filetype ==# 'unite' || filetype ==# 'int-ssh'
    return -1
  endif

  " Filename pattern.
  let pattern = neocomplcache#get_keyword_pattern_end('filename')
  let [complete_pos, complete_str] =
        \ neocomplcache#match_word(a:cur_text, pattern)
  if complete_str =~ '//' ||
        \ (neocomplcache#is_auto_complete() &&
        \    (complete_str !~ '/' ||
        \     complete_str =~#
        \          '\\[^ ;*?[]"={}'']\|\.\.\+$\|/c\%[ygdrive/]$'))
    " Not filename pattern.
    return -1
  endif

  if neocomplcache#is_sources_complete() && complete_pos < 0
    let complete_pos = len(a:cur_text)
  endif

  return complete_pos
endfunction"}}}

function! s:source.get_complete_words(complete_pos, complete_str) "{{{
  return s:get_glob_files(a:complete_str, '')
endfunction"}}}

let s:cached_files = {}

function! s:get_glob_files(complete_str, path) "{{{
  let path = ',,' . substitute(a:path, '\.\%(,\|$\)\|,,', '', 'g')

  let complete_str = neocomplcache#util#substitute_path_separator(
        \ substitute(a:complete_str, '\\\(.\)', '\1', 'g'))

  let glob = (complete_str !~ '\*$')?
        \ complete_str . '*' : complete_str

  if a:path == '' && complete_str !~ '/'
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
  endif

  let files = neocomplcache#keyword_filter(map(
        \ files, '{
        \    "word" : fnamemodify(v:val, ":t"),
        \    "orig" : v:val,
        \ }'),
        \ fnamemodify(complete_str, ':t'))

  if neocomplcache#is_auto_complete()
        \ && len(files) > g:neocomplcache_max_list
    let files = files[: g:neocomplcache_max_list - 1]
  endif

  let files = map(files, '{
        \    "word" : substitute(v:val.orig, "//", "/", "g"),
        \ }')

  if a:complete_str =~ '^\$\h\w*'
    let env = matchstr(a:complete_str, '^\$\h\w*')
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

    if a:complete_str =~ '^\~/'
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

function! neocomplcache#sources#filename_complete#get_complete_words(complete_str, path) "{{{
  if !neocomplcache#is_enabled()
    return []
  endif

  return s:get_glob_files(a:complete_str, a:path)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
