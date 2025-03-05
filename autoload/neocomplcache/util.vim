"=============================================================================
" FILE: util.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 26 Sep 2013.
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

function! neocomplcache#util#get_vital() abort "{{{
  if !exists('s:V')
    let s:V = vital#of('neocomplcache').import('Prelude')
  endif
  return s:V
endfunction"}}}
function! neocomplcache#util#truncate_smart(...) "{{{
  return call(neocomplcache#util#get_vital().truncate_skipping, a:000)
endfunction"}}}

function! neocomplcache#util#truncate(...) "{{{
  return call(neocomplcache#util#get_vital().truncate, a:000)
endfunction"}}}

function! neocomplcache#util#strchars(str) "{{{
  return s:strchars(a:str)
endfunction"}}}
function! neocomplcache#util#wcswidth(...) "{{{
  return call(neocomplcache#util#get_vital().wcswidth, a:000)
endfunction"}}}
function! neocomplcache#util#strwidthpart(...) "{{{
  return call(neocomplcache#util#get_vital().strwidthpart, a:000)
endfunction"}}}
function! neocomplcache#util#strwidthpart_reverse(...) "{{{
  return call(neocomplcache#util#get_vital().strwidthpart_reverse, a:000)
endfunction"}}}

function! neocomplcache#util#substitute_path_separator(...) "{{{
  return call(neocomplcache#util#get_vital().substitute_path_separator, a:000)
endfunction"}}}
function! neocomplcache#util#mb_strlen(str) "{{{
  return s:strchars(a:str)
endfunction"}}}
function! neocomplcache#util#system(...) "{{{
  return call(neocomplcache#util#get_vital().system, a:000)
endfunction"}}}
function! neocomplcache#util#has_vimproc(...) "{{{
  return call(neocomplcache#util#get_vital().has_vimproc, a:000)
endfunction"}}}
function! neocomplcache#util#has_lua() "{{{
  " Note: Disabled if_lua feature if less than 7.3.885.
  " Because if_lua has double free problem.
  return has('lua') && (v:version > 703 || v:version == 703 && has('patch885'))
endfunction"}}}
function! neocomplcache#util#is_windows(...) "{{{
  return call(neocomplcache#util#get_vital().is_windows, a:000)
endfunction"}}}
function! neocomplcache#util#is_mac(...) "{{{
  return call(neocomplcache#util#get_vital().is_mac, a:000)
endfunction"}}}
function! neocomplcache#util#get_last_status(...) "{{{
  return call(neocomplcache#util#get_vital().get_last_status, a:000)
endfunction"}}}
function! neocomplcache#util#escape_pattern(...) "{{{
  return call(neocomplcache#util#get_vital().escape_pattern, a:000)
endfunction"}}}
function! neocomplcache#util#iconv(...) "{{{
  return call(neocomplcache#util#get_vital().iconv, a:000)
endfunction"}}}
function! neocomplcache#util#uniq(list, ...) "{{{
  let list = a:0 ? map(copy(a:list), printf('[v:val, %s]', a:1)) : copy(a:list)
  let i = 0
  let seen = {}
  while i < len(list)
    let key = string(a:0 ? list[i][1] : list[i])
    if has_key(seen, key)
      call remove(list, i)
    else
      let seen[key] = 1
      let i += 1
    endif
  endwhile
  return a:0 ? map(list, 'v:val[0]') : list
endfunction"}}}
function! neocomplcache#util#sort_by(list, expr) "{{{
  let pairs = map(a:list, printf('[v:val, %s]', a:expr))
  return map(s:sort(pairs,
  \      'a:a[1] ==# a:b[1] ? 0 : a:a[1] ># a:b[1] ? 1 : -1'), 'v:val[0]')
endfunction"}}}

" Sudo check.
function! neocomplcache#util#is_sudo() "{{{
  return $SUDO_USER != '' && $USER !=# $SUDO_USER
      \ && $HOME !=# expand('~'.$USER)
      \ && $HOME ==# expand('~'.$SUDO_USER)
endfunction"}}}

function! neocomplcache#util#glob(pattern, ...) "{{{
  if a:pattern =~ "'"
    " Use glob('*').
    let cwd = getcwd()
    let base = neocomplcache#util#substitute_path_separator(
          \ fnamemodify(a:pattern, ':h'))
    execute 'lcd' fnameescape(base)

    let files = map(split(neocomplcache#util#substitute_path_separator(
          \ glob('*')), '\n'), "base . '/' . v:val")

    execute 'lcd' fnameescape(cwd)

    return files
  endif

  " let is_force_glob = get(a:000, 0, 0)
  let is_force_glob = get(a:000, 0, 1)

  if !is_force_glob && a:pattern =~ '^[^\\*]\+/\*'
        \ && neocomplcache#util#has_vimproc() && exists('*vimproc#readdir')
    return filter(vimproc#readdir(a:pattern[: -2]), 'v:val !~ "/\\.\\.\\?$"')
  else
    " Escape [.
    if neocomplcache#util#is_windows()
      let glob = substitute(a:pattern, '\[', '\\[[]', 'g')
    else
      let glob = escape(a:pattern, '[')
    endif

    return split(neocomplcache#util#substitute_path_separator(glob(glob)), '\n')
  endif
endfunction"}}}
function! neocomplcache#util#expand(path) "{{{
  return expand(escape(a:path, '*?[]"={}'), 1)
endfunction"}}}

function! neocomplcache#util#set_default(var, val, ...)  "{{{
  if !exists(a:var) || type({a:var}) != type(a:val)
    let alternate_var = get(a:000, 0, '')

    let {a:var} = exists(alternate_var) ?
          \ {alternate_var} : a:val
  endif
endfunction"}}}
function! neocomplcache#util#set_dictionary_helper(variable, keys, pattern) "{{{
  for key in split(a:keys, '\s*,\s*')
    if !has_key(a:variable, key)
      let a:variable[key] = a:pattern
    endif
  endfor
endfunction"}}}

function! neocomplcache#util#set_default_dictionary(variable, keys, value) "{{{
  if !exists('s:disable_dictionaries')
    let s:disable_dictionaries = {}
  endif

  if has_key(s:disable_dictionaries, a:variable)
    return
  endif

  call neocomplcache#util#set_dictionary_helper({a:variable}, a:keys, a:value)
endfunction"}}}
function! neocomplcache#util#disable_default_dictionary(variable) "{{{
  if !exists('s:disable_dictionaries')
    let s:disable_dictionaries = {}
  endif

  let s:disable_dictionaries[a:variable] = 1
endfunction"}}}

function! neocomplcache#util#split_rtp(...) "{{{
  let rtp = a:0 ? a:1 : &runtimepath
  if type(rtp) == type([])
    return rtp
  endif

  if rtp !~ '\\'
    return split(rtp, ',')
  endif

  let split = split(rtp, '\\\@<!\%(\\\\\)*\zs,')
  return map(split,'substitute(v:val, ''\\\([\\,]\)'', "\\1", "g")')
endfunction"}}}
function! neocomplcache#util#join_rtp(list) "{{{
  return join(map(copy(a:list), 's:escape(v:val)'), ',')
endfunction"}}}
" Escape a path for runtimepath.
function! s:escape(path)"{{{
  return substitute(a:path, ',\|\\,\@=', '\\\0', 'g')
endfunction"}}}

function! neocomplcache#util#has_vimproc() "{{{
  " Initialize.
  if !exists('g:neocomplcache_use_vimproc')
    " Check vimproc.
    try
      call vimproc#version()
      let exists_vimproc = 1
    catch
      let exists_vimproc = 0
    endtry

    let g:neocomplcache_use_vimproc = exists_vimproc
  endif

  return g:neocomplcache_use_vimproc
endfunction"}}}

function! neocomplcache#util#dup_filter(list) "{{{
  let dict = {}
  for keyword in a:list
    if !has_key(dict, keyword.word)
      let dict[keyword.word] = keyword
    endif
  endfor

  return values(dict)
endfunction"}}}

function! neocomplcache#util#convert2list(expr) "{{{
  return type(a:expr) ==# type([]) ? a:expr : [a:expr]
endfunction"}}}

" Returns the number of character in a:str.
" NOTE: This returns proper value
" even if a:str contains multibyte character(s).
" s:strchars(str) {{{
if exists('*strchars')
  function! s:strchars(str)
    return strchars(a:str)
  endfunction
else
  function! s:strchars(str)
    return strlen(substitute(copy(a:str), '.', 'x', 'g'))
  endfunction
endif "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
