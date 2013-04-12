"=============================================================================
" FILE: commands.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 12 Apr 2013.
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

function! neocomplcache#commands#_initialize() "{{{
  command! -nargs=? Neco call s:display_neco(<q-args>)
  command! -nargs=1 NeoComplCacheAutoCompletionLength
        \ call s:set_auto_completion_length(<args>)
endfunction"}}}

function! neocomplcache#commands#_toggle_lock() "{{{
  if neocomplcache#get_current_neocomplcache().lock
    echo 'neocomplcache is unlocked!'
    call neocomplcache#commands#_unlock()
  else
    echo 'neocomplcache is locked!'
    call neocomplcache#commands#_lock()
  endif
endfunction"}}}

function! neocomplcache#commands#_lock() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.lock = 1
endfunction"}}}

function! neocomplcache#commands#_unlock() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.lock = 0
endfunction"}}}

function! neocomplcache#commands#_lock_source(source_name) "{{{
  if !neocomplcache#is_enabled()
    call neocomplcache#print_warning(
          \ 'neocomplcache is disabled! This command is ignored.')
    return
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  let neocomplcache.lock_sources[a:source_name] = 1
endfunction"}}}

function! neocomplcache#commands#_unlock_source(source_name) "{{{
  if !neocomplcache#is_enabled()
    call neocomplcache#print_warning(
          \ 'neocomplcache is disabled! This command is ignored.')
    return
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  let neocomplcache.lock_sources[a:source_name] = 1
endfunction"}}}

function! neocomplcache#commands#_clean() "{{{
  " Delete cache files.
  for directory in filter(neocomplcache#util#glob(
        \ g:neocomplcache_temporary_dir.'/*'), 'isdirectory(v:val)')
    for filename in filter(neocomplcache#util#glob(directory.'/*'),
          \ '!isdirectory(v:val)')
      call delete(filename)
    endfor
  endfor

  echo 'Cleaned cache files in: ' . g:neocomplcache_temporary_dir
endfunction"}}}

function! neocomplcache#commands#_set_file_type(filetype) "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.filetype = a:filetype
endfunction"}}}

function! s:display_neco(number) "{{{
  let cmdheight_save = &cmdheight

  let animation = [
    \[
        \[
        \ "   A A",
        \ "~(-'_'-)"
        \],
        \[
        \ "      A A",
        \ "   ~(-'_'-)",
        \],
        \[
        \ "        A A",
        \ "     ~(-'_'-)",
        \],
        \[
        \ "          A A  ",
        \ "       ~(-'_'-)",
        \],
        \[
        \ "             A A",
        \ "          ~(-^_^-)",
        \],
    \],
    \[
        \[
        \ "   A A",
        \ "~(-'_'-)",
        \],
        \[
        \ "      A A",
        \ "   ~(-'_'-)",
        \],
        \[
        \ "        A A",
        \ "     ~(-'_'-)",
        \],
        \[
        \ "          A A  ",
        \ "       ~(-'_'-)",
        \],
        \[
        \ "             A A",
        \ "          ~(-'_'-)",
        \],
        \[
        \ "          A A  ",
        \ "       ~(-'_'-)"
        \],
        \[
        \ "        A A",
        \ "     ~(-'_'-)"
        \],
        \[
        \ "      A A",
        \ "   ~(-'_'-)"
        \],
        \[
        \ "   A A",
        \ "~(-'_'-)"
        \],
    \],
    \[
        \[
        \ "   A A",
        \ "~(-'_'-)",
        \],
        \[
        \ "        A A",
        \ "     ~(-'_'-)",
        \],
        \[
        \ "             A A",
        \ "          ~(-'_'-)",
        \],
        \[
        \ "                  A A",
        \ "               ~(-'_'-)",
        \],
        \[
        \ "                       A A",
        \ "                    ~(-'_'-)",
        \],
        \["                           A A",
        \ "                        ~(-'_'-)",
        \],
    \],
    \[
        \[
        \ "",
        \ "   A A",
        \ "~(-'_'-)",
        \],
        \["      A A",
        \ "   ~(-'_'-)",
        \ "",
        \],
        \[
        \ "",
        \ "        A A",
        \ "     ~(-'_'-)",
        \],
        \[
        \ "          A A  ",
        \ "       ~(-'_'-)",
        \ "",
        \],
        \[
        \ "",
        \ "             A A",
        \ "          ~(-^_^-)",
        \],
    \],
    \[
        \[
        \ "   A A        A A",
        \ "~(-'_'-)  -8(*'_'*)"
        \],
        \[
        \ "     A A        A A",
        \ "  ~(-'_'-)  -8(*'_'*)"
        \],
        \[
        \ "       A A        A A",
        \ "    ~(-'_'-)  -8(*'_'*)"
        \],
        \[
        \ "     A A        A A",
        \ "  ~(-'_'-)  -8(*'_'*)"
        \],
        \[
        \ "   A A        A A",
        \ "~(-'_'-)  -8(*'_'*)"
        \],
    \],
    \[
        \[
        \ "  A\\_A\\",
        \ "(=' .' ) ~w",
        \ "(,(\")(\")",
        \],
    \],
  \]

  let number = (a:number != '') ? a:number : len(animation)
  let anim = get(animation, number, animation[s:rand(len(animation) - 1)])
  let &cmdheight = len(anim[0])

  for frame in anim
    echo repeat("\n", &cmdheight-2)
    redraw
    echon join(frame, "\n")
    sleep 300m
  endfor
  redraw

  let &cmdheight = cmdheight_save
endfunction"}}}

function! s:rand(max) "{{{
  if !has('reltime')
    " Same value.
    return 0
  endif

  let time = reltime()[1]
  return (time < 0 ? -time : time)% (a:max + 1)
endfunction"}}}

function! s:set_auto_completion_length(len) "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.completion_length = a:len
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
