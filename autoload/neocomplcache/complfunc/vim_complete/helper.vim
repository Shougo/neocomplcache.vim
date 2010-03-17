"=============================================================================
" FILE: helper.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 16 Mar 2010
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

if !exists('s:internal_candidates_list')
  let s:internal_candidates_list = {}
  let s:global_candidates_list = {}
  let s:script_candidates_list = {}
  let s:local_candidates_list = {}
endif

function! neocomplcache#complfunc#vim_complete#helper#script_caching_check()"{{{
  if empty(s:global_candidates_list)
    " Global caching.
    call s:global_caching()
  endif

  " Caching script candidates.

  let l:bufnumber = 1

  " Check buffer.
  while l:bufnumber <= bufnr('$')
    if getbufvar(l:bufnumber, '&filetype') == 'vim' && buflisted(l:bufnumber)
          \&& !has_key(s:script_candidates_list, l:bufnumber)
      let s:script_candidates_list[l:bufnumber] = s:get_script_candidates(l:bufnumber)
    endif

    let l:bufnumber += 1
  endwhile
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#recaching(bufname)"{{{
  " Caching script candidates.

  let l:bufnumber = a:bufname != '' ? bufnr(a:bufname) : bufnr('%')

  " Caching.
  let s:global_candidates_list.commands = s:get_cmdlist()
  let s:global_candidates_list.variables = s:get_variablelist()
  let s:global_candidates_list.functions = s:get_functionlist()
  let s:global_candidates_list.augroups = s:get_augrouplist()
  let s:global_candidates_list.mappings = s:get_mappinglist()

  if getbufvar(l:bufnumber, '&filetype') == 'vim' && buflisted(l:bufnumber)
    let s:script_candidates_list[l:bufnumber] = s:get_script_candidates(l:bufnumber)
  endif
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#print_prototype(cur_text)"{{{
  " Echo prototype.
  let l:script_candidates_list = has_key(s:script_candidates_list, bufnr('%')) ?
        \ s:script_candidates_list[bufnr('%')] : { 'functions' : [], 'variables' : [], 'functions_prototype' : {} }

  let l:prototype_name = matchstr(a:cur_text, 
        \'\%(<[sS][iI][dD]>\|[sSgGbBwWtTlL]:\)\=\%(\i\|[#.]\|{.\{-1,}}\)*\s*(\ze\%([^(]\|(.\{-})\)*$')
  if l:prototype_name != ''
    if has_key(s:internal_candidates_list.functions_prototype, l:prototype_name)
      echo s:internal_candidates_list.functions_prototype[l:prototype_name]
    elseif has_key(s:global_candidates_list.functions_prototype, l:prototype_name)
      echo s:global_candidates_list.functions_prototype[l:prototype_name]
    elseif has_key(l:script_candidates_list.functions_prototype, l:prototype_name)
      echo l:script_candidates_list.functions_prototype[l:prototype_name]
    endif
  else
    " Search command name.
    let l:prototype_name = matchstr(a:cur_text, '\<\h\w*')
    if has_key(s:internal_candidates_list.commands_prototype, l:prototype_name)
      echo s:internal_candidates_list.commands_prototype[l:prototype_name]
    elseif has_key(s:global_candidates_list.commands_prototype, l:prototype_name)
      echo s:global_candidates_list.commands_prototype[l:prototype_name]
    endif
  endif
endfunction"}}}

function! neocomplcache#complfunc#vim_complete#helper#autocmd_args(cur_text, cur_keyword_str)"{{{
  return s:internal_candidates_list.autocmds + s:global_candidates_list.augroups
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#augroup(cur_text, cur_keyword_str)"{{{
  return s:global_candidates_list.augroups
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#buffer(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#command(cur_text, cur_keyword_str)"{{{
  let l:list = neocomplcache#keyword_filter(s:internal_candidates_list.commands, a:cur_keyword_str)
  let l:list += neocomplcache#keyword_filter(s:global_candidates_list.commands, a:cur_keyword_str)

  if a:cur_keyword_str =~ '^en\%[d]'
    let l:list += s:get_endlist()
  endif

  return l:list
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#command_args(cur_text, cur_keyword_str)"{{{
  return s:internal_candidates_list.command_args + s:internal_candidates_list.command_replaces
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#dir(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#environment(cur_text, cur_keyword_str)"{{{
  return s:global_candidates_list.environments
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#event(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#expression(cur_text, cur_keyword_str)"{{{
  return neocomplcache#complfunc#vim_complete#helper#function(a:cur_text, a:cur_keyword_str)
        \+ neocomplcache#complfunc#vim_complete#helper#var(a:cur_text, a:cur_keyword_str)
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#feature(cur_text, cur_keyword_str)"{{{
  return s:internal_candidates_list.features
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#file(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#function(cur_text, cur_keyword_str)"{{{
  let l:list = []
  let l:script_candidates_list = has_key(s:script_candidates_list, bufnr('%')) ?
        \ s:script_candidates_list[bufnr('%')] : { 'functions' : [], 'variables' : [], 'functions_prototype' : {} }

  if a:cur_keyword_str =~ '^s:'
    let l:list += l:script_candidates_list.functions
  elseif a:cur_keyword_str =~ '^\a:'
    let l:functions = deepcopy(l:script_candidates_list.functions)
    for l:keyword in l:functions
      let l:keyword.word = '<SID>' . l:keyword.word[2:]
      let l:keyword.abbr = '<SID>' . l:keyword.abbr[2:]
    endfor
    let l:list += l:functions
  else
    let l:list += s:internal_candidates_list.functions
    let l:list += s:global_candidates_list.functions
  endif

  return l:list
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#help(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#highlight(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#mapping(cur_text, cur_keyword_str)"{{{
  return s:internal_candidates_list.mappings + s:global_candidates_list.mappings
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#menu(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#option(cur_text, cur_keyword_str)"{{{
  return s:internal_candidates_list.options
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#shellcmd(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#tag(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#tag_listfiles(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#var(cur_text, cur_keyword_str)"{{{
  let l:list = []
  if a:cur_keyword_str =~ '^s:'
    let l:script_candidates_list = has_key(s:script_candidates_list, bufnr('%')) ?
          \ s:script_candidates_list[bufnr('%')] : { 'functions' : [], 'variables' : [], 'functions_prototype' : {} }

    let l:list += l:script_candidates_list.variables
  elseif a:cur_keyword_str =~ '^\a:'
    let l:list += s:global_candidates_list.variables
  endif

  let l:list += s:get_local_variables()

  return l:list
endfunction"}}}

function! neocomplcache#complfunc#vim_complete#helper#custom(cur_text, cur_keyword_str, funcname)"{{{
  return []
endfunction"}}}
function! neocomplcache#complfunc#vim_complete#helper#customlist(cur_text, cur_keyword_str, funcname)"{{{
  return []
endfunction"}}}

function! s:global_caching()"{{{
  " Caching.

  let s:global_candidates_list.commands = s:get_cmdlist()
  let s:global_candidates_list.variables = s:get_variablelist()
  let s:global_candidates_list.functions = s:get_functionlist()
  let s:global_candidates_list.augroups = s:get_augrouplist()
  let s:global_candidates_list.mappings = s:get_mappinglist()
  let s:global_candidates_list.environments = s:get_envlist()

  let s:internal_candidates_list.functions = s:caching_from_dict('functions', 'f')
  let s:internal_candidates_list.options = s:caching_from_dict('options', 'o')
  let s:internal_candidates_list.features = s:caching_from_dict('features', '')
  let s:internal_candidates_list.mappings = s:caching_from_dict('mappings', '')
  let s:internal_candidates_list.commands = s:caching_from_dict('commands', 'c')
  let s:internal_candidates_list.command_args = s:caching_from_dict('command_args', '')
  let s:internal_candidates_list.autocmds = s:caching_from_dict('autocmds', '')
  let s:internal_candidates_list.command_replaces = s:caching_from_dict('command_replaces', '')

  for l:keyword in deepcopy(s:internal_candidates_list.options)
    let l:keyword.word = 'no' . l:keyword.word
    let l:keyword.abbr = 'no' . l:keyword.abbr
    call add(s:internal_candidates_list.options, l:keyword)
  endfor

  let l:functions_prototype = {}
  for function in s:internal_candidates_list.functions
    let l:functions_prototype[function.word] = function.abbr
  endfor
  let s:internal_candidates_list.functions_prototype = l:functions_prototype

  let l:commands_prototype = {}
  for command in s:internal_candidates_list.commands
    let l:commands_prototype[command.word] = command.abbr
  endfor
  let s:internal_candidates_list.commands_prototype = l:commands_prototype
endfunction"}}}

function! s:get_local_variables()"{{{
  " Get local variable list.

  let l:keyword_dict = {}
  let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
  let l:menu_pattern = '[V] variable'

  " Search function.
  let l:line_num = line('.') - 1
  let l:end_line = (line('.') > 100) ? line('.') - 100 : 1
  while l:line_num >= l:end_line
    let l:line = getline(l:line_num)
    if l:line =~ '\<endf\%[nction]\>'
      break
    elseif l:line =~ '\<fu\%[nction]!\?\s\+'
      " Get function arguments.
      for l:arg in split(matchstr(l:line, '^[^(]*(\zs[^)]*'), '\s*,\s*')
        let l:word = 'a:' . (l:arg == '...' ?  '000' : l:arg)
        let l:keyword =  {
              \ 'word' : l:word, 'menu' : l:menu_pattern, 'icase' : 1, 
              \ 'kind' : (l:arg == '...' ?  '[]' : '')
              \}
        let l:keyword.abbr =  (len(l:word) > g:NeoComplCache_MaxKeywordWidth)? 
              \ printf(l:abbr_pattern, l:word, l:word[-8:]) : l:word

        let l:keyword_dict[l:word] = l:keyword
      endfor
      if l:line =~ '\.\.\.)'
        " Extra arguments.
        for l:arg in range(5)
          let l:word = 'a:' . l:arg
          let l:keyword =  {
                \ 'word' : l:word, 'menu' : l:menu_pattern, 'icase' : 1, 
                \ 'kind' : (l:arg == 0 ?  '0' : '')
                \}
          let l:keyword.abbr = (len(l:word) > g:NeoComplCache_MaxKeywordWidth)? 
                \ printf(l:abbr_pattern, l:word, l:word[-8:]) : l:word

          let l:keyword_dict[l:word] = l:keyword
        endfor
      endif

      break
    endif

    let l:line_num -= 1
  endwhile
  let l:line_num += 1

  let l:end_line = line('.') - 1
  while l:line_num <= l:end_line
    let l:line = getline(l:line_num)

    if l:line =~ '\<\%(let\|for\)\s\+\a[[:alnum:]_:]*'
      let l:word = 
            \matchstr(l:line, '\<\%(let\|for\)\s\+\zs\a[[:alnum:]_:]*')
      if !has_key(l:keyword_dict, l:word) 
        let l:expression = matchstr(l:line, '\<let\s\+\a[[:alnum:]_:]*\s*=\zs.*$')
        let l:keyword =  {
              \ 'word' : l:word, 'menu' : l:menu_pattern, 'icase' : 1,
              \ 'kind' : s:get_variable_type(l:expression)
              \}
        let l:keyword.abbr =  (len(l:word) > g:NeoComplCache_MaxKeywordWidth)? 
              \ printf(l:abbr_pattern, l:word, l:word[-8:]) : l:word

        let l:keyword_dict[l:word] = l:keyword
      endif
    endif

    let l:line_num += 1
  endwhile

  return values(l:keyword_dict)
endfunction"}}}

function! s:get_script_candidates(bufnumber)"{{{
  " Get script candidate list.

  let l:function_dict = {}
  let l:variable_dict = {}
  let l:functions_prototype = {}

  let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
  let l:menu_pattern_func = '[V] function'
  let l:menu_pattern_var = '[V] variable'
  let l:keyword_pattern = '^\%('.neocomplcache#get_keyword_pattern('vim').'\m\)'

  if g:NeoComplCache_CachingPercentInStatusline
    let l:statusline_save = &l:statusline
  endif
  call neocomplcache#print_caching('Caching vim from '. bufname(a:bufnumber) .' ... please wait.')

  for l:line in getbufline(a:bufnumber, 1, '$')
    if l:line =~ '\<fu\%[nction]!\?\s\+s:'
      " Get script function.
      let l:line = substitute(matchstr(l:line, '\<fu\%[nction]!\?\s\+\zs.*'), '".*$', '', '')
      let l:orig_line = l:line
      let l:word = matchstr(l:line, l:keyword_pattern)
      if !has_key(l:function_dict, l:word) 
        let l:keyword =  {
              \ 'word' : l:word, 'menu' : l:menu_pattern_func, 'icase' : 1, 'kind' : 'f'
              \}
        if len(l:line) > g:NeoComplCache_MaxKeywordWidth
          let l:line = substitute(l:line, '\(\h\)\w*#', '\1.\~', 'g')
          if len(l:line) > g:NeoComplCache_MaxKeywordWidth
            let l:args = split(matchstr(l:line, '(\zs[^)]*\ze)'), '\s*,\s*')
            let l:line = substitute(l:line, '(\zs[^)]*\ze)', join(map(l:args, 'v:val[:5]'), ', '), '')
          endif
        endif
        if len(l:word) > g:NeoComplCache_MaxKeywordWidth
          let l:keyword.abbr = printf(l:abbr_pattern, l:word, l:word[-8:])
        else
          let keyword.abbr = l:word
        endif

        let l:function_dict[l:word] = l:keyword
        let l:functions_prototype[l:word] = l:orig_line
      endif
    elseif l:line =~ '\<let\s\+s:*'
      " Get script variable.
      let l:word = matchstr(l:line, '\<let\s\+\zs\a[[:alnum:]_:]*')
      if !has_key(l:variable_dict, l:word) 
        let l:expression = matchstr(l:line, '\<let\s\+\a[[:alnum:]_:]*\s*=\zs.*$')
        let l:keyword =  {
              \ 'word' : l:word, 'menu' : l:menu_pattern_var, 'icase' : 1,
              \ 'kind' : s:get_variable_type(l:expression)
              \}
        let l:keyword.abbr =  (len(l:word) > g:NeoComplCache_MaxKeywordWidth)? 
              \ printf(l:abbr_pattern, l:word, l:word[-8:]) : l:word

        let l:variable_dict[l:word] = l:keyword
      endif
    endif
  endfor

  call neocomplcache#print_caching('Caching done.')
  if g:NeoComplCache_CachingPercentInStatusline
    let &l:statusline = l:statusline_save
  endif

  return { 'functions' : values(l:function_dict), 'variables' : values(l:variable_dict), 'functions_prototype' : l:functions_prototype }
endfunction"}}}

function! s:caching_from_dict(dict_name, kind)"{{{
  let l:dict_files = split(globpath(&runtimepath, 'autoload/neocomplcache/complfunc/vim_complete/'.a:dict_name.'.dict'), '\n')
  if empty(l:dict_files)
    return []
  endif

  let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
  let l:menu_pattern = '[V] '.a:dict_name[: -2]
  let l:keyword_pattern = '^\%('.neocomplcache#get_keyword_pattern('vim').'\m\)'
  let l:keyword_list = []
  for line in readfile(l:dict_files[-1])
    let l:keyword =  {
          \ 'word' : matchstr(line, l:keyword_pattern), 'menu' : l:menu_pattern, 'icase' : 1, 'kind' : a:kind
          \}
    let l:keyword.abbr =  (len(line) > g:NeoComplCache_MaxKeywordWidth)? 
          \ printf(l:abbr_pattern, line, line[-8:]) : line

    call add(l:keyword_list, l:keyword)
  endfor

  return l:keyword_list
endfunction"}}}

function! s:get_cmdlist()"{{{
  " Get command list.
  redir => l:redir
  silent! command
  redir END

  let l:keyword_list = []
  let l:commands_prototype = {}
  let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
  let l:menu_pattern = '[V] command'
  for line in split(l:redir, '\n')[1:]
    let l:word = matchstr(line, '\a\w*')
    let l:keyword =  {
          \ 'word' : l:word, 'menu' : l:menu_pattern, 'icase' : 1, 
          \ 'kind' : 'c'
          \}
    let l:keyword.abbr =  (len(l:word) > g:NeoComplCache_MaxKeywordWidth)? 
          \ printf(l:abbr_pattern, l:word, l:word[-8:]) : l:word

    call add(l:keyword_list, l:keyword)
    let l:commands_prototype[l:word] = l:word
  endfor
  let s:global_candidates_list.commands_prototype = l:commands_prototype

  return l:keyword_list
endfunction"}}}
function! s:get_variablelist()"{{{
  " Get variable list.
  redir => l:redir
  silent! let
  redir END

  let l:keyword_list = []
  let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
  let l:menu_pattern = '[V] variable'
  let l:kind_dict = ['0', '""', '()', '[]', '{}', '.']
  for line in split(l:redir, '\n')
    let l:word = matchstr(line, '^\a[[:alnum:]_:]*')
    if l:word !~ '^\a:'
      let l:word = 'g:' . l:word
    elseif l:word =~ '[^gv]:'
      continue
    endif
    let l:keyword =  {
          \ 'word' : l:word, 'menu' : l:menu_pattern, 'icase' : 1,
          \ 'kind' : exists(l:word)? l:kind_dict[type(eval(l:word))] : ''
          \}
    let l:keyword.abbr =  (len(l:word) > g:NeoComplCache_MaxKeywordWidth)? 
          \ printf(l:abbr_pattern, l:word, l:word[-8:]) : l:word

    call add(l:keyword_list, l:keyword)
  endfor
  return l:keyword_list
endfunction"}}}
function! s:get_functionlist()"{{{
  " Get function list.
  redir => l:redir
  silent! function
  redir END

  let l:keyword_list = []
  let l:functions_prototype = {}
  let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
  let l:menu_pattern = '[V] function'
  let l:keyword_pattern = '^\%('.neocomplcache#get_keyword_pattern('vim').'\m\)'
  for l:line in split(l:redir, '\n')
    let l:line = l:line[9:]
    let l:orig_line = l:line
    let l:word = matchstr(l:line, l:keyword_pattern)
    if l:word =~ '^<SNR>'
      continue
    endif
    let l:keyword =  {
          \ 'word' : l:word, 'menu' : l:menu_pattern, 'icase' : 1
          \}
    if len(l:line) > g:NeoComplCache_MaxKeywordWidth
      let l:line = substitute(l:line, '\(\h\)\w*#', '\1.\~', 'g')
      if len(l:line) > g:NeoComplCache_MaxKeywordWidth
        let l:args = split(matchstr(l:line, '(\zs[^)]*\ze)'), '\s*,\s*')
        let l:line = substitute(l:line, '(\zs[^)]*\ze)', join(map(l:args, 'v:val[:5]'), ', '), '')
      endif
    endif
    if len(l:line) > g:NeoComplCache_MaxKeywordWidth
      let l:keyword.abbr = printf(l:abbr_pattern, l:line, l:line[-8:])
    else
      let keyword.abbr = l:line
    endif

    call add(l:keyword_list, l:keyword)

    let l:functions_prototype[l:word] = l:orig_line
  endfor

  let s:global_candidates_list.functions_prototype = l:functions_prototype

  return l:keyword_list
endfunction"}}}
function! s:get_augrouplist()"{{{
  " Get function list.
  redir => l:redir
  silent! augroup
  redir END

  let l:keyword_list = []
  let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
  let l:menu_pattern = '[V] augroup'
  for l:group in split(l:redir, '\s')
    let l:keyword =  {
          \ 'word' : l:group, 'menu' : l:menu_pattern, 'icase' : 1
          \}
    let l:keyword.abbr =  (len(l:group) > g:NeoComplCache_MaxKeywordWidth)? 
          \ printf(l:abbr_pattern, l:group, l:group[-8:]) : l:group

    call add(l:keyword_list, l:keyword)
  endfor
  return l:keyword_list
endfunction"}}}
function! s:get_mappinglist()"{{{
  " Get function list.
  redir => l:redir
  silent! map
  redir END

  let l:keyword_list = []
  let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
  let l:menu_pattern = '[V] mapping'
  for line in split(l:redir, '\n')
    let l:map = matchstr(line, '^\a*\s*\zs\S\+')
    if l:map !~ '^<'
      continue
    endif
    let l:keyword =  {
          \ 'word' : l:map, 'menu' : l:menu_pattern, 'icase' : 1
          \}
    let l:keyword.abbr =  (len(l:map) > g:NeoComplCache_MaxKeywordWidth)? 
          \ printf(l:abbr_pattern, l:map, l:map[-8:]) : l:map

    call add(l:keyword_list, l:keyword)
  endfor
  return l:keyword_list
endfunction"}}}
function! s:get_envlist()"{{{
  " Get environment variable list.

  let l:keyword_list = []
  let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
  let l:menu_pattern = '[V] environment'
  for line in split(system('set'), '\n')
    let l:word = '$' . toupper(matchstr(line, '^\h\w*'))
    let l:keyword =  {
          \ 'word' : l:word, 'menu' : l:menu_pattern, 'icase' : 1, 'kind' : 'e'
          \}
    let l:keyword.abbr =  (len(l:word) > g:NeoComplCache_MaxKeywordWidth)? 
          \ printf(l:abbr_pattern, l:word, l:word[-8:]) : l:word

    call add(l:keyword_list, l:keyword)
  endfor
  return l:keyword_list
endfunction"}}}
function! s:get_endlist()"{{{
  " Get end command list.

  let l:keyword_dict = {}
  let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
  let l:menu_pattern = '[V] end'
  let l:line_num = line('.') - 1
  let l:end_line = (line('.') < 100) ? line('.') - 100 : 1
  let l:cnt = {
        \ 'endfor' : 0, 'endfunction' : 0, 'endtry' : 0, 
        \ 'endwhile' : 0, 'endif' : 0
        \}
  let l:word = ''

  while l:line_num >= l:end_line
    let l:line = getline(l:line_num)

    if l:line =~ '\<endfo\%[r]\>'
      let l:cnt['endfor'] -= 1
    elseif l:line =~ '\<endf\%[nction]\>'
      let l:cnt['endfunction'] -= 1
    elseif l:line =~ '\<endt\%[ry]\>'
      let l:cnt['endtry'] -= 1
    elseif l:line =~ '\<endw\%[hile]\>'
      let l:cnt['endwhile'] -= 1
    elseif l:line =~ '\<en\%[dif]\>'
      let l:cnt['endif'] -= 1

    elseif l:line =~ '\<for\>'
      let l:cnt['endfor'] += 1
      if l:cnt['endfor'] > 0
        let l:word = 'endfor'
        break
      endif
    elseif l:line =~ '\<fu\%[nction]!\?\s\+'
      let l:cnt['endfunction'] += 1
      if l:cnt['endfunction'] > 0
        let l:word = 'endfunction'
      endif
      break
    elseif l:line =~ '\<try\>'
      let l:cnt['endtry'] += 1
      if l:cnt['endtry'] > 0
        let l:word = 'endtry'
        break
      endif
    elseif l:line =~ '\<wh\%[ile]\>'
      let l:cnt['endwhile'] += 1
      if l:cnt['endwhile'] > 0
        let l:word = 'endwhile'
        break
      endif
    elseif l:line =~ '\<if\>'
      let l:cnt['endif'] += 1
      if l:cnt['endif'] > 0
        let l:word = 'endif'
        break
      endif
    endif

    let l:line_num -= 1
  endwhile

  if l:word == ''
    return []
  else
    let l:keyword =  {
          \ 'word' : l:word, 'menu' : l:menu_pattern, 'icase' : 1, 'kind' : 'c'
          \}
    let l:keyword.abbr =  (len(l:word) > g:NeoComplCache_MaxKeywordWidth)? 
          \ printf(l:abbr_pattern, l:word, l:word[-8:]) : l:word

    return [l:keyword]
  endif
endfunction"}}}
function! s:get_variable_type(expression)"{{{
  " Analyze variable type.
  if a:expression =~ '^\s*\d\+\.\d\+'
    return '.'
  elseif a:expression =~ '^\s*\d\+'
    return '0'
  elseif a:expression =~ '^\s*["'']'
    return '""'
  elseif a:expression =~ '\<function('
    return '()'
  elseif a:expression =~
        \ '^\s*\[\|\<split('
    return '[]'
  elseif a:expression =~ '^\s*{'
    return '{}'
  else
    return ''
  endif
endfunction"}}}
" vim: foldmethod=marker
