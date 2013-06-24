"=============================================================================
" FILE: vim_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Jun 2013.
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
      \ 'name' : 'vim_complete',
      \ 'kind' : 'manual',
      \ 'filetypes' : { 'vim' : 1, 'vimconsole' : 1, },
      \ 'mark' : '[vim]',
      \ 'rank' : 300,
      \}

function! s:source.initialize() "{{{
  " Initialize.

  " Initialize complete function list. "{{{
  if !exists('g:neocomplcache_vim_completefuncs')
    let g:neocomplcache_vim_completefuncs = {}
  endif
  "}}}

  " Call caching event.
  autocmd neocomplcache FileType *
        \ call neocomplcache#sources#vim_complete#helper#on_filetype()

  " Initialize check.
  call neocomplcache#sources#vim_complete#helper#on_filetype()

  " Add command.
  command! -nargs=? -complete=buffer NeoComplCacheCachingVim
        \ call neocomplcache#sources#vim_complete#helper#recaching(<q-args>)
endfunction"}}}

function! s:source.finalize() "{{{
  delcommand NeoComplCacheCachingVim

  if neocomplcache#exists_echodoc()
    call echodoc#unregister('vim_complete')
  endif
endfunction"}}}

function! s:source.get_keyword_pos(cur_text) "{{{
  let cur_text = neocomplcache#sources#vim_complete#get_cur_text()

  if cur_text =~ '^\s*"'
    " Comment.
    return -1
  endif

  let pattern = '\.\%(\h\w*\)\?$\|' .
        \ neocomplcache#get_keyword_pattern_end('vim')
  if cur_text != '' && cur_text !~
        \ '^[[:digit:],[:space:][:tab:]$''<>]*\h\w*$'
    let command_completion =
          \ neocomplcache#sources#vim_complete#helper#get_completion_name(
          \   neocomplcache#sources#vim_complete#get_command(cur_text))
    if command_completion =~ '\%(dir\|file\|shellcmd\)'
      let pattern = neocomplcache#get_keyword_pattern_end('filename')
    endif
  endif

  let [complete_pos, complete_str] =
        \ neocomplcache#match_word(a:cur_text, pattern)
  if complete_pos < 0
    " Use args pattern.
    let [complete_pos, complete_str] =
          \ neocomplcache#match_word(a:cur_text, '\S\+$')
  endif

  if a:cur_text !~ '\.\%(\h\w*\)\?$' && neocomplcache#is_auto_complete()
        \ && bufname('%') !=# '[Command Line]'
        \ && neocomplcache#util#mb_strlen(complete_str)
        \      < g:neocomplcache_auto_completion_start_length
    return -1
  endif

  return complete_pos
endfunction"}}}

function! s:source.get_complete_words(complete_pos, complete_str) "{{{
  let cur_text = neocomplcache#sources#vim_complete#get_cur_text()
  if neocomplcache#is_auto_complete() && cur_text !~ '\h\w*\.\%(\h\w*\)\?$'
        \ && len(a:complete_str) < g:neocomplcache_auto_completion_start_length
        \ && bufname('%') !=# '[Command Line]'
    return []
  endif

  if cur_text =~ '\h\w*\.\%(\h\w*\)\?$'
    " Dictionary.
    let complete_str = matchstr(cur_text, '.\%(\h\w*\)\?$')
    let list = neocomplcache#sources#vim_complete#helper#var_dictionary(
          \ cur_text, complete_str)
    return neocomplcache#keyword_filter(list, complete_str)
  elseif a:complete_str =~# '^&\%([gl]:\)\?'
    " Options.
    let prefix = matchstr(a:complete_str, '&\%([gl]:\)\?')
    let list = deepcopy(
          \ neocomplcache#sources#vim_complete#helper#option(
          \   cur_text, a:complete_str))
    for keyword in list
      let keyword.word =
            \ prefix . keyword.word
      let keyword.abbr = prefix .
            \ get(keyword, 'abbr', keyword.word)
    endfor
  elseif a:complete_str =~? '^\c<sid>'
    " SID functions.
    let prefix = matchstr(a:complete_str, '^\c<sid>')
    let complete_str = substitute(a:complete_str, '^\c<sid>', 's:', '')
    let list = deepcopy(
          \ neocomplcache#sources#vim_complete#helper#function(
          \     cur_text, complete_str))
    for keyword in list
      let keyword.word = prefix . keyword.word[2:]
      let keyword.abbr = prefix .
            \ get(keyword, 'abbr', keyword.word)[2:]
    endfor
  elseif cur_text =~# '\<has([''"]\w*$'
    " Features.
    let list = neocomplcache#sources#vim_complete#helper#feature(
          \ cur_text, a:complete_str)
  elseif cur_text =~# '\<expand([''"][<>[:alnum:]]*$'
    " Expand.
    let list = neocomplcache#sources#vim_complete#helper#expand(
          \ cur_text, a:complete_str)
  elseif a:complete_str =~ '^\$'
    " Environment.
    let list = neocomplcache#sources#vim_complete#helper#environment(
          \ cur_text, a:complete_str)
  elseif cur_text =~ '^[[:digit:],[:space:][:tab:]$''<>]*!\s*\f\+$'
    " Shell commands.
    let list = neocomplcache#sources#vim_complete#helper#shellcmd(
          \ cur_text, a:complete_str)
  else
    " Commands.
    let list = neocomplcache#sources#vim_complete#helper#command(
          \ cur_text, a:complete_str)
  endif

  return neocomplcache#keyword_filter(copy(list), a:complete_str)
endfunction"}}}

function! neocomplcache#sources#vim_complete#define() "{{{
  return s:source
endfunction"}}}

function! neocomplcache#sources#vim_complete#get_cur_text() "{{{
  let cur_text = neocomplcache#get_cur_text(1)
  if &filetype == 'vimshell' && exists('*vimshell#get_secondary_prompt')
        \   && empty(b:vimshell.continuation)
    return cur_text[len(vimshell#get_secondary_prompt()) :]
  endif

  let line = line('.')
  let cnt = 0
  while cur_text =~ '^\s*\\' && line > 1 && cnt < 5
    let cur_text = getline(line - 1) .
          \ substitute(cur_text, '^\s*\\', '', '')
    let line -= 1
    let cnt += 1
  endwhile

  return split(cur_text, '\s\+|\s\+\|<bar>', 1)[-1]
endfunction"}}}
function! neocomplcache#sources#vim_complete#get_command(cur_text) "{{{
  return matchstr(a:cur_text, '\<\%(\d\+\)\?\zs\h\w*\ze!\?\|'.
        \ '\<\%([[:digit:],[:space:]$''<>]\+\)\?\zs\h\w*\ze/.*')
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
