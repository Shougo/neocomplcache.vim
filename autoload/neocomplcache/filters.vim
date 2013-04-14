"=============================================================================
" FILE: filters.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 14 Apr 2013.
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

function! neocomplcache#filters#keyword_filter(list, cur_keyword_str) "{{{
  let cur_keyword_str = a:cur_keyword_str

  if g:neocomplcache_enable_debug
    echomsg len(a:list)
  endif

  " Delimiter check.
  let filetype = neocomplcache#get_context_filetype()
  for delimiter in get(g:neocomplcache_delimiter_patterns, filetype, [])
    let cur_keyword_str = substitute(cur_keyword_str,
          \ delimiter, '*' . delimiter, 'g')
  endfor

  if cur_keyword_str == '' ||
        \ &l:completefunc ==# 'neocomplcache#complete#unite_complete' ||
        \ empty(a:list)
    return a:list
  elseif neocomplcache#check_match_filter(cur_keyword_str)
    " Match filter.
    let word = type(a:list[0]) == type('') ? 'v:val' : 'v:val.word'

    let expr = printf('%s =~ %s',
          \ word, string('^' .
          \ neocomplcache#keyword_escape(cur_keyword_str)))
    if neocomplcache#is_auto_complete()
      " Don't complete cursor word.
      let expr .= printf(' && %s !=? a:cur_keyword_str', word)
    endif

    " Check head character.
    if cur_keyword_str[0] != '\' && cur_keyword_str[0] != '.'
      let expr = word.'[0] == ' .
            \ string(cur_keyword_str[0]) .' && ' . expr
    endif

    call neocomplcache#print_debug(expr)

    return filter(a:list, expr)
  elseif neocomplcache#util#has_lua()
    return s:lua_filter(a:list, cur_keyword_str)
  else
    " Use fast filter.
    return s:head_filter(a:list, cur_keyword_str)
  endif
endfunction"}}}

function! s:head_filter(list, cur_keyword_str) "{{{
  let word = type(a:list[0]) == type('') ? 'v:val' : 'v:val.word'

  if &ignorecase
   let expr = printf('!stridx(tolower(%s), %s)',
          \ word, string(tolower(a:cur_keyword_str)))
  else
    let expr = printf('!stridx(%s, %s)',
          \ word, string(a:cur_keyword_str))
  endif

  if neocomplcache#is_auto_complete()
    " Don't complete cursor word.
    let expr .= printf(' && %s !=? a:cur_keyword_str', word)
  endif

  return filter(a:list, expr)
endfunction"}}}
function! s:lua_filter(list, cur_keyword_str) "{{{
  lua << EOF
  do
    local input = vim.eval('a:cur_keyword_str')
    local candidates = vim.eval('a:list')
    if (vim.eval('&ignorecase') ~= 0) then
      input = string.lower(input)
      for i = #candidates-1, 0, -1 do
        local word = vim.type(candidates[i]) == 'dict' and
          string.lower(candidates[i].word) or string.lower(candidates[i])
        if (string.find(word, input, 1, true) == nil) and word ~= input then
          candidates[i] = nil
        end
      end
    else
      for i = #candidates-1, 0, -1 do
        local word = vim.type(candidates[i]) == 'dict' and
          candidates[i].word or candidates[i]
        if (string.find(word, input, 1, true) == nil) and word ~= input then
          candidates[i] = nil
        end
      end
    end
  end
EOF

  return a:list
endfunction"}}}

function! neocomplcache#filters#dictionary_filter(dictionary, cur_keyword_str) "{{{
  if empty(a:dictionary)
    return []
  endif

  let completion_length = 2
  if len(a:cur_keyword_str) < completion_length ||
        \ neocomplcache#check_completion_length_match(
        \         a:cur_keyword_str, completion_length) ||
        \ &l:completefunc ==# 'neocomplcache#cunite_complete'
    return neocomplcache#keyword_filter(
          \ neocomplcache#unpack_dictionary(a:dictionary), a:cur_keyword_str)
  endif

  let key = tolower(a:cur_keyword_str[: completion_length-1])

  if !has_key(a:dictionary, key)
    return []
  endif

  let list = a:dictionary[key]
  if type(list) == type({})
    " Convert dictionary dictionary.
    unlet list
    let list = values(a:dictionary[key])
  else
    let list = copy(list)
  endif

  return (len(a:cur_keyword_str) == completion_length && &ignorecase
        \ && !neocomplcache#check_completion_length_match(
        \   a:cur_keyword_str, completion_length)) ?
        \ list : neocomplcache#keyword_filter(list, a:cur_keyword_str)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
