"=============================================================================
" FILE: util.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 19 May 2012.
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

let s:V = vital#of('neocomplcache')

function! neocomplcache#util#truncate_smart(...)"{{{
  return call(s:V.truncate_smart, a:000)
endfunction"}}}

function! neocomplcache#util#truncate(...)"{{{
  return call(s:V.truncate, a:000)
endfunction"}}}

function! neocomplcache#util#strchars(...)"{{{
  return call(s:V.strchars, a:000)
endfunction"}}}
function! neocomplcache#util#wcswidth(...)"{{{
  return call(s:V.wcswidth, a:000)
endfunction"}}}
function! neocomplcache#util#strwidthpart(...)"{{{
  return call(s:V.strwidthpart, a:000)
endfunction"}}}
function! neocomplcache#util#strwidthpart_reverse(...)"{{{
  return call(s:V.strwidthpart_reverse, a:000)
endfunction"}}}

function! neocomplcache#util#substitute_path_separator(...)"{{{
  return call(s:V.substitute_path_separator, a:000)
endfunction"}}}
function! neocomplcache#util#mb_strlen(...)"{{{
  return call(s:V.strchars, a:000)
endfunction"}}}
function! neocomplcache#util#uniq(list)"{{{
  let dict = {}
  for item in a:list
    if !has_key(dict, item)
      let dict[item] = item
    endif
  endfor

  return values(dict)
endfunction"}}}
function! neocomplcache#util#system(...)"{{{
  return call(s:V.system, a:000)
endfunction"}}}
function! neocomplcache#util#has_vimproc(...)"{{{
  return call(s:V.has_vimproc, a:000)
endfunction"}}}
function! neocomplcache#util#is_windows(...)"{{{
  return call(s:V.is_windows, a:000)
endfunction"}}}
function! neocomplcache#util#is_mac(...)"{{{
  return call(s:V.is_mac, a:000)
endfunction"}}}
function! neocomplcache#util#get_last_status(...)"{{{
  return call(s:V.get_last_status, a:000)
endfunction"}}}
function! neocomplcache#util#escape_pattern(...)"{{{
  return call(s:V.escape_pattern, a:000)
endfunction"}}}

function! neocomplcache#util#glob(pattern, ...)"{{{
  if a:pattern =~ "'"
    " Use glob('*').
    let cwd = getcwd()
    let base = neocomplcache#util#substitute_path_separator(
          \ fnamemodify(a:pattern, ':h'))
    lcd `=base`

    let files = map(split(neocomplcache#util#substitute_path_separator(
          \ glob('*')), '\n'), "base . '/' . v:val")

    lcd `=cwd`

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
function! neocomplcache#util#expand(path)"{{{
  return expand(escape(a:path, '*?[]"={}'), 1)
endfunction"}}}
function! neocomplcache#util#set_default_dictionary_helper(variable, keys, value)"{{{
  for key in split(a:keys, '\s*,\s*')
    if !has_key(a:variable, key)
      let a:variable[key] = a:value
    endif
  endfor
endfunction"}}}
function! neocomplcache#util#set_dictionary_helper(variable, keys, value)"{{{
  for key in split(a:keys, '\s*,\s*')
    let a:variable[key] = a:value
  endfor
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
