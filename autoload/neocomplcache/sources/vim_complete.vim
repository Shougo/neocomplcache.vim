"=============================================================================
" FILE: vim_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 30 Aug 2011.
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
      \ 'kind' : 'ftplugin',
      \ 'filetypes' : { 'vim' : 1, },
      \}

function! s:source.initialize()"{{{
  " Initialize.

  " Initialize complete function list."{{{
  if !exists('g:neocomplcache_vim_completefuncs')
    let g:neocomplcache_vim_completefuncs = {}
  endif
  "}}}

  " Set rank.
  call neocomplcache#set_dictionary_helper(g:neocomplcache_plugin_rank, 'vim_complete', 100)

  " Call caching event.
  autocmd neocomplcache FileType * call neocomplcache#sources#vim_complete#helper#on_filetype()

  " Initialize check.
  call neocomplcache#sources#vim_complete#helper#on_filetype()

  " Add command.
  command! -nargs=? -complete=buffer NeoComplCacheCachingVim call neocomplcache#sources#vim_complete#helper#recaching(<q-args>)
endfunction"}}}

function! s:source.finalize()"{{{
  delcommand NeoComplCacheCachingVim

  if neocomplcache#exists_echodoc()
    call echodoc#unregister('vim_complete')
  endif
endfunction"}}}

function! s:source.get_keyword_pos(cur_text)"{{{
  let l:cur_text = neocomplcache#sources#vim_complete#get_cur_text()

  if l:cur_text =~ '^\s*"'
    " Comment.
    return -1
  endif

  let l:pattern = '\.\%(\h\w*\)\?$\|' . neocomplcache#get_keyword_pattern_end('vim')
  if l:cur_text != '' && l:cur_text !~ '^[[:digit:],[:space:][:tab:]$''<>]*\h\w*$'
    let l:command_completion = neocomplcache#sources#vim_complete#helper#get_completion_name(
          \ neocomplcache#sources#vim_complete#get_command(l:cur_text))
    if l:command_completion =~ '\%(dir\|file\|shellcmd\)'
      let l:pattern = neocomplcache#get_keyword_pattern_end('filename')
    endif
  endif

  let [l:cur_keyword_pos, l:cur_keyword_str] = neocomplcache#match_word(a:cur_text, l:pattern)
  if a:cur_text !~ '\.\%(\h\w*\)\?$' && neocomplcache#is_auto_complete()
        \ && neocomplcache#util#mb_strlen(l:cur_keyword_str)
        \      < g:neocomplcache_auto_completion_start_length
    return -1
  endif

  return l:cur_keyword_pos
endfunction"}}}

function! s:source.get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
  let l:cur_text = neocomplcache#sources#vim_complete#get_cur_text()
  if (neocomplcache#is_auto_complete() && l:cur_text !~ '\h\w*\.\%(\h\w*\)\?$'
        \&& len(a:cur_keyword_str) < g:neocomplcache_auto_completion_start_length)
    return []
  endif

  if l:cur_text =~ '\h\w*\.\%(\h\w*\)\?$'
    " Dictionary.
    let l:cur_keyword_str = matchstr(l:cur_text, '.\%(\h\w*\)\?$')
    let l:list = neocomplcache#sources#vim_complete#helper#var_dictionary(l:cur_text, l:cur_keyword_str)
    return neocomplcache#keyword_filter(l:list, l:cur_keyword_str)
  elseif a:cur_keyword_str =~# '^&\%([gl]:\)\?'
    " Options.
    let l:prefix = matchstr(a:cur_keyword_str, '&\%([gl]:\)\?')
    let l:list = deepcopy(neocomplcache#sources#vim_complete#helper#option(l:cur_text, a:cur_keyword_str))
    for l:keyword in l:list
      let l:keyword.word = l:prefix . l:keyword.word
      let l:keyword.abbr = l:prefix . l:keyword.abbr
    endfor
  elseif a:cur_keyword_str =~? '^\c<sid>'
    " SID functions.
    let l:prefix = matchstr(a:cur_keyword_str, '^\c<sid>')
    let l:cur_keyword_str = substitute(a:cur_keyword_str, '^\c<sid>', 's:', '')
    let l:list = deepcopy(neocomplcache#sources#vim_complete#helper#function(l:cur_text, l:cur_keyword_str))
    for l:keyword in l:list
      let l:keyword.word = l:prefix . l:keyword.word[2:]
      let l:keyword.abbr = l:prefix . l:keyword.abbr[2:]
    endfor
  elseif l:cur_text =~# '\<has([''"]\w*$'
    " Features.
    let l:list = neocomplcache#sources#vim_complete#helper#feature(l:cur_text, a:cur_keyword_str)
  elseif l:cur_text =~# '\<expand([''"][<>[:alnum:]]*$'
    " Expand.
    let l:list = neocomplcache#sources#vim_complete#helper#expand(l:cur_text, a:cur_keyword_str)
  elseif a:cur_keyword_str =~ '^\$'
    " Environment.
    let l:list = neocomplcache#sources#vim_complete#helper#environment(l:cur_text, a:cur_keyword_str)
  elseif l:cur_text =~ '^[[:digit:],[:space:][:tab:]$''<>]*!\s*\f\+$'
    " Shell commands.
    let l:list = neocomplcache#sources#vim_complete#helper#shellcmd(l:cur_text, a:cur_keyword_str)
  else
    " Commands.
    let l:list = neocomplcache#sources#vim_complete#helper#command(l:cur_text, a:cur_keyword_str)
  endif

  return neocomplcache#keyword_filter(l:list, a:cur_keyword_str)
endfunction"}}}

function! neocomplcache#sources#vim_complete#define()"{{{
  return s:source
endfunction"}}}

function! neocomplcache#sources#vim_complete#get_cur_text()"{{{
  let l:cur_text = neocomplcache#get_cur_text()
  if &filetype == 'vimshell' && exists('*vimshell#get_secondary_prompt')
    return l:cur_text[len(vimshell#get_secondary_prompt()) :]
  endif

  let l:line = line('.')
  let l:cnt = 0
  while l:cur_text =~ '^\s*\\' && l:line > 1 && l:cnt < 5
    let l:cur_text = getline(l:line - 1) . substitute(l:cur_text, '^\s*\\', '', '')
    let l:line -= 1
    let l:cnt += 1
  endwhile

  return split(l:cur_text, '\s\+|\s\+\|<bar>', 1)[-1]
endfunction"}}}
function! neocomplcache#sources#vim_complete#get_command(cur_text)"{{{
  return matchstr(a:cur_text, '\<\%(\d\+\)\?\zs\h\w*\ze!\?\|\<\%([[:digit:],[:space:]$''<>]\+\)\?\zs\h\w*\ze/.*')
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
