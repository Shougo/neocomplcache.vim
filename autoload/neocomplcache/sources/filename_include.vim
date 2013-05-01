"=============================================================================
" FILE: filename_include.vim
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

let s:save_cpo = &cpo
set cpo&vim

" Global options definition. "{{{
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

let s:source = {
      \ 'name' : 'filename_include',
      \ 'kind' : 'manual',
      \ 'mark' : '[FI]',
      \ 'rank' : 10,
      \ 'min_pattern_length' :
      \        g:neocomplcache_auto_completion_start_length,
      \}

function! s:source.initialize() "{{{
  " Initialize.

  " Initialize filename include expr. "{{{
  let g:neocomplcache_filename_include_exprs =
        \ get(g:, 'neocomplcache_filename_include_exprs', {})
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_filename_include_exprs',
        \ 'perl',
        \ 'fnamemodify(substitute(v:fname, "/", "::", "g"), ":r")')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_filename_include_exprs',
        \ 'ruby,python,java,d',
        \ 'fnamemodify(substitute(v:fname, "/", ".", "g"), ":r")')
  "}}}

  " Initialize filename include extensions. "{{{
  let g:neocomplcache_filename_include_exts =
        \ get(g:, 'neocomplcache_filename_include_exts', {})
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_filename_include_exts',
        \ 'c', ['h'])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_filename_include_exts',
        \ 'cpp', ['', 'h', 'hpp', 'hxx'])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_filename_include_exts',
        \ 'perl', ['pm'])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_filename_include_exts',
        \ 'java', ['java'])
  "}}}
endfunction"}}}
function! s:source.finalize() "{{{
endfunction"}}}

function! s:source.get_keyword_pos(cur_text) "{{{
  let filetype = neocomplcache#get_context_filetype()

  " Not Filename pattern.
  if exists('g:neocomplcache_include_patterns')
    let pattern = get(g:neocomplcache_include_patterns, filetype,
        \      getbufvar(bufnr('%'), '&include'))
  else
    let pattern = ''
  endif
  if neocomplcache#is_auto_complete()
        \ && (pattern == '' || a:cur_text !~ pattern)
        \ && a:cur_text =~ '\*$\|\.\.\+$\|/c\%[ygdrive/]$'
    " Skip filename completion.
    return -1
  endif

  " Check include pattern.
  let pattern = get(g:neocomplcache_include_patterns, filetype,
        \ getbufvar(bufnr('%'), '&include'))
  if pattern == '' || a:cur_text !~ pattern
    return -1
  endif

  let match_end = matchend(a:cur_text, pattern)
  let complete_str = matchstr(a:cur_text[match_end :], '\f\+')

  let expr = get(g:neocomplcache_include_exprs, filetype,
        \ getbufvar(bufnr('%'), '&includeexpr'))
  if expr != ''
    let cur_text =
          \ substitute(eval(substitute(expr,
          \ 'v:fname', string(complete_str), 'g')),
          \  '\.\w*$', '', '')
  endif

  let complete_pos = len(a:cur_text) - len(complete_str)
  if neocomplcache#is_sources_complete() && complete_pos < 0
    let complete_pos = len(a:cur_text)
  endif

  return complete_pos
endfunction"}}}

function! s:source.get_complete_words(complete_pos, complete_str) "{{{
  return s:get_include_files(a:complete_str)
endfunction"}}}

function! s:get_include_files(complete_str) "{{{
  let filetype = neocomplcache#get_context_filetype()

  let path = neocomplcache#util#substitute_path_separator(
        \ get(g:neocomplcache_include_paths, filetype,
        \   getbufvar(bufnr('%'), '&path')))
  let pattern = get(g:neocomplcache_include_patterns, filetype,
        \ getbufvar(bufnr('%'), '&include'))
  let expr = get(g:neocomplcache_include_exprs, filetype,
        \ getbufvar(bufnr('%'), '&includeexpr'))
  let reverse_expr = get(g:neocomplcache_filename_include_exprs, filetype,
        \ '')
  let exts = get(g:neocomplcache_filename_include_exts, filetype,
        \ [])

  let line = neocomplcache#get_cur_text()
  if line =~ '^\s*\<require_relative\>' && &filetype =~# 'ruby'
    " For require_relative.
    let path = '.'
  endif

  let match_end = matchend(line, pattern)
  let complete_str = matchstr(line[match_end :], '\f\+')
  if expr != ''
    let complete_str =
          \ substitute(eval(substitute(expr,
          \ 'v:fname', string(complete_str), 'g')), '\.\w*$', '', '')
  endif

  " Path search.
  let glob = (complete_str !~ '\*$')?
        \ complete_str . '*' : complete_str
  let cwd = getcwd()
  let bufdirectory = neocomplcache#util#substitute_path_separator(
        \ fnamemodify(expand('%'), ':p:h'))
  let dir_list = []
  let file_list = s:get_default_include_files(filetype)
  for subpath in split(path, '[,;]')
    let dir = (subpath == '.') ? bufdirectory : subpath
    if !isdirectory(dir)
      continue
    endif

    execute 'lcd' fnameescape(dir)

    for word in split(
          \ neocomplcache#util#substitute_path_separator(
          \   glob(glob)), '\n')
      let dict = { 'word' : word }

      call add(isdirectory(word) ? dir_list : file_list, dict)

      let abbr = dict.word
      if isdirectory(word)
        let abbr .= '/'
        if g:neocomplcache_enable_auto_delimiter
          let dict.word .= '/'
        endif
      elseif !empty(exts) &&
            \ index(exts, fnamemodify(dict.word, ':e')) < 0
        " Skip.
        continue
      endif
      let dict.abbr = abbr

      if reverse_expr != ''
        " Convert filename.
        let dict.word = eval(substitute(reverse_expr,
              \ 'v:fname', string(dict.word), 'g'))
        let dict.abbr = eval(substitute(reverse_expr,
              \ 'v:fname', string(dict.abbr), 'g'))
      else
        " Escape word.
        let dict.word = escape(dict.word, ' ;*?[]"={}''')
      endif
    endfor
  endfor
  execute 'lcd' fnameescape(cwd)

  return neocomplcache#keyword_filter(dir_list, a:complete_str)
        \ + neocomplcache#keyword_filter(file_list, a:complete_str)
endfunction"}}}

function! s:get_default_include_files(filetype) "{{{
  let files = []

  if a:filetype ==# 'python' || a:filetype ==# 'python3'
    let files = ['sys']
  endif

  return map(files, "{ 'word' : v:val }")
endfunction"}}}

function! neocomplcache#sources#filename_include#define() "{{{
  return s:source
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
