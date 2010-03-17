"=============================================================================
" FILE: vim_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 17 Mar 2010
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

function! neocomplcache#complfunc#vim_complete#initialize()"{{{
  " Initialize.
  let s:completion_length = neocomplcache#get_completion_length('vim_complete')

  " Set caching event.
  autocmd neocomplcache FileType vim call neocomplcache#complfunc#vim_complete#helper#script_caching_check()

  " Add command.
  command! -nargs=? -complete=buffer NeoComplCacheCachingVim call neocomplcache#complfunc#vim_complete#helper#recaching(<q-args>)
endfunction"}}}

function! neocomplcache#complfunc#vim_complete#finalize()"{{{
  delcommand NeoComplCacheCachingVim
endfunction"}}}

function! neocomplcache#complfunc#vim_complete#get_keyword_pos(cur_text)"{{{
  if &filetype != 'vim'
    return -1
  endif

  let l:cur_text = s:get_cur_text()

  if l:cur_text =~ '^\s*"'
    " Comment.
    return -1
  endif

  if g:NeoComplCache_EnableDispalyParameter"{{{
    call neocomplcache#complfunc#vim_complete#helper#print_prototype(l:cur_text)
  endif"}}}

  let l:pattern = '\.$\|' . neocomplcache#get_keyword_pattern_end('vim')
  let l:cur_keyword_pos = match(a:cur_text, l:pattern)

  if g:NeoComplCache_EnableWildCard
    " Check wildcard.
    let l:cur_keyword_pos = neocomplcache#match_wildcard(a:cur_text, l:pattern, l:cur_keyword_pos)
  endif

  return l:cur_keyword_pos
endfunction"}}}

function! neocomplcache#complfunc#vim_complete#get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
  if neocomplcache#is_auto_complete() && a:cur_keyword_str != '.'
        \&& len(a:cur_keyword_str) < s:completion_length
    return []
  endif

  let l:cur_text = s:get_cur_text()

  let l:list = []
  
  if a:cur_keyword_str =~ '^\.'
    " Dictionary.
    return []
  endif

  let l:prev_word = neocomplcache#get_prev_word(a:cur_keyword_str)
  if l:prev_word =~ '^\%(setl\%[ocal]\|setg\%[lobal]\|set\)$'
    let l:list += neocomplcache#complfunc#vim_complete#helper#option(l:cur_text, a:cur_keyword_str)
  elseif a:cur_keyword_str =~ '^&\%([gl]:\)\?'
    let l:prefix = matchstr(a:cur_keyword_str, '&\%([gl]:\)\?')
    let l:options = deepcopy(neocomplcache#complfunc#vim_complete#helper#option(l:cur_text, a:cur_keyword_str))
    for l:keyword in l:options
      let l:keyword.word = l:prefix . l:keyword.word
      let l:keyword.abbr = l:prefix . l:keyword.abbr
    endfor
    let l:list += l:options
  elseif l:cur_text =~ '\<has(''\h\w*$'
    let l:list += neocomplcache#complfunc#vim_complete#helper#feature(l:cur_text, a:cur_keyword_str)
  elseif l:cur_text =~ '\<\%(map\|cm\%[ap]\|cno\%[remap]\|im\%[ap]\|ino\%[remap]\|lm\%[ap]\|ln\%[oremap]\|nm\%[ap]\|nn\%[oremap]\|no\%[remap]\|om\%[ap]\|ono\%[remap]\|smap\|snor\%[emap]\|vm\%[ap]\|vn\%[oremap]\|xm\%[ap]\|xn\%[oremap]\)\>'
    let l:list += neocomplcache#complfunc#vim_complete#helper#mapping(l:cur_text, a:cur_keyword_str)
  elseif l:cur_text =~ '\<au\%[tocmd]!\?'
    let l:list += neocomplcache#complfunc#vim_complete#helper#autocmd_args(l:cur_text, a:cur_keyword_str)
  elseif l:cur_text =~ '\<aug\%[roup]'
    let l:list += neocomplcache#complfunc#vim_complete#helper#augroup(l:cur_text, a:cur_keyword_str)
  elseif l:cur_text =~ '\<com\%[mand]!\?'
    let l:list += neocomplcache#complfunc#vim_complete#helper#command_args(l:cur_text, a:cur_keyword_str)
  elseif l:cur_text =~ '^\$'
    let l:list += neocomplcache#complfunc#vim_complete#helper#environment(l:cur_text, a:cur_keyword_str)
  endif

  if l:cur_text =~ '\%(^\||sil\%[ent]!\?\)\s*\h\w*$\|^\s*$'
    " Commands.
    let l:list += neocomplcache#complfunc#vim_complete#helper#command(l:cur_text, a:cur_keyword_str)
  elseif l:cur_text =~ '\<let\s\+[[:alnum:]_:]*$'
    " Variables.
    let l:list += neocomplcache#complfunc#vim_complete#helper#var(l:cur_text, a:cur_keyword_str)
  elseif l:cur_text =~ 
        \'\<call\s\+\%(<[sS][iI][dD]>\|[sSgGbBwWtTlL]:\)\?\%(\i\|[#.]\|{.\{-1,}}\)*\s*(\?$'
    " Functions.
    let l:list += neocomplcache#complfunc#vim_complete#helper#function(l:cur_text, a:cur_keyword_str)
  else
    " Expressions.
    let l:list += neocomplcache#complfunc#vim_complete#helper#expression(l:cur_text, a:cur_keyword_str)
  endif

  return neocomplcache#keyword_filter(l:list, a:cur_keyword_str)
endfunction"}}}

function! neocomplcache#complfunc#vim_complete#get_rank()"{{{
  return 100
endfunction"}}}

function! s:get_cur_text()
  let l:cur_text = neocomplcache#get_cur_text()
  let l:line = line('%')
  while l:cur_text =~ '^\s*\\' && l:line > 1
    let l:cur_text = getline(l:line - 1) . substitute(l:cur_text, '^\s*\\', '', '')
    let l:line -= 1
  endwhile

  return l:cur_text
endfunction

" vim: foldmethod=marker
