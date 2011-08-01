"=============================================================================
" FILE: helper.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 01 Aug 2011.
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

if !exists('s:internal_candidates_list')
  let s:internal_candidates_list = {}
  let s:global_candidates_list = { 'dictionary_variables' : {} }
  let s:script_candidates_list = {}
  let s:local_candidates_list = {}
endif

function! neocomplcache#sources#vim_complete#helper#on_filetype()"{{{
  " Caching script candidates.
  let l:bufnumber = 1

  " Check buffer.
  while l:bufnumber <= bufnr('$')
    if getbufvar(l:bufnumber, '&filetype') == 'vim' && bufloaded(l:bufnumber)
          \&& !has_key(s:script_candidates_list, l:bufnumber)
      let s:script_candidates_list[l:bufnumber] = s:get_script_candidates(l:bufnumber)
    endif

    let l:bufnumber += 1
  endwhile

  if neocomplcache#exists_echodoc()
    call echodoc#register('vim_complete', s:doc_dict)
  endif
endfunction"}}}

function! neocomplcache#sources#vim_complete#helper#recaching(bufname)"{{{
  " Caching script candidates.
  let l:bufnumber = a:bufname != '' ? bufnr(a:bufname) : bufnr('%')

  if getbufvar(l:bufnumber, '&filetype') == 'vim' && bufloaded(l:bufnumber)
    let s:script_candidates_list[l:bufnumber] = s:get_script_candidates(l:bufnumber)
  endif
  let s:global_candidates_list = { 'dictionary_variables' : {} }
endfunction"}}}

" For echodoc."{{{
let s:doc_dict = {
      \ 'name' : 'vim_complete',
      \ 'rank' : 10,
      \ 'filetypes' : { 'vim' : 1 },
      \ }
function! s:doc_dict.search(cur_text)"{{{
  let l:cur_text = a:cur_text

  " Echo prototype.
  let l:script_candidates_list = s:get_cached_script_candidates()

  let l:prototype_name = matchstr(l:cur_text,
        \'\%(<[sS][iI][dD]>\|[sSgGbBwWtTlL]:\)\=\%(\i\|[#.]\|{.\{-1,}}\)*\s*(\ze\%([^(]\|(.\{-})\)*$')
  let l:ret = []
  if l:prototype_name != ''
    if !has_key(s:internal_candidates_list, 'function_prototypes')
      " No cache.
      return []
    endif

    " Search function name.
    call add(l:ret, { 'text' : l:prototype_name, 'highlight' : 'Identifier' })
    if has_key(s:internal_candidates_list.function_prototypes, l:prototype_name)
      call add(l:ret, { 'text' : s:internal_candidates_list.function_prototypes[l:prototype_name] })
    elseif has_key(s:global_candidates_list.function_prototypes, l:prototype_name)
      call add(l:ret, { 'text' : s:global_candidates_list.function_prototypes[l:prototype_name] })
    elseif has_key(l:script_candidates_list.function_prototypes, l:prototype_name)
      call add(l:ret, { 'text' : l:script_candidates_list.function_prototypes[l:prototype_name] })
    else
      " No prototypes.
      return []
    endif
  else
    if !has_key(s:internal_candidates_list, 'command_prototypes')
      " No cache.
      return []
    endif

    " Search command name.
    " Skip head digits.
    let l:prototype_name = neocomplcache#sources#vim_complete#get_command(l:cur_text)
    call add(l:ret, { 'text' : l:prototype_name, 'highlight' : 'Statement' })
    if has_key(s:internal_candidates_list.command_prototypes, l:prototype_name)
      call add(l:ret, { 'text' : s:internal_candidates_list.command_prototypes[l:prototype_name] })
    elseif has_key(s:global_candidates_list.command_prototypes, l:prototype_name)
      call add(l:ret, { 'text' : s:global_candidates_list.command_prototypes[l:prototype_name] })
    else
      " No prototypes.
      return []
    endif
  endif

  return l:ret
endfunction"}}}
"}}}

function! neocomplcache#sources#vim_complete#helper#get_command_completion(command_name, cur_text, cur_keyword_str)"{{{
  let l:completion_name = neocomplcache#sources#vim_complete#helper#get_completion_name(a:command_name)
  if l:completion_name == ''
    " Not found.
    return []
  endif

  let l:args = (l:completion_name ==# 'custom' || l:completion_name ==# 'customlist')?
        \ [a:command_name, a:cur_text, a:cur_keyword_str] : [a:cur_text, a:cur_keyword_str]
  return call('neocomplcache#sources#vim_complete#helper#'.l:completion_name, l:args)
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#get_completion_name(command_name)"{{{
  if !has_key(s:internal_candidates_list, 'command_completions')
    let s:internal_candidates_list.command_completions = s:caching_completion_from_dict('command_completions')
  endif
  if !has_key(s:global_candidates_list, 'command_completions')
    let s:global_candidates_list.commands = s:get_cmdlist()
  endif

  if has_key(s:internal_candidates_list.command_completions, a:command_name)
        \&& exists('*neocomplcache#sources#vim_complete#helper#'.s:internal_candidates_list.command_completions[a:command_name])
    return s:internal_candidates_list.command_completions[a:command_name]
  elseif has_key(s:global_candidates_list.command_completions, a:command_name)
        \&& exists('*neocomplcache#sources#vim_complete#helper#'.s:global_candidates_list.command_completions[a:command_name])
    return s:global_candidates_list.command_completions[a:command_name]
  else
    return ''
  endif
endfunction"}}}

function! neocomplcache#sources#vim_complete#helper#autocmd_args(cur_text, cur_keyword_str)"{{{
  let l:args = s:split_args(a:cur_text, a:cur_keyword_str)

  " Caching.
  if !has_key(s:global_candidates_list, 'augroups')
    let s:global_candidates_list.augroups = s:get_augrouplist()
  endif
  if !has_key(s:internal_candidates_list, 'autocmds')
    let s:internal_candidates_list.autocmds = s:caching_from_dict('autocmds', '')
  endif

  let l:list = []
  if len(l:args) == 2
    let l:list += s:global_candidates_list.augroups + s:internal_candidates_list.autocmds
  elseif len(l:args) == 3
    if l:args[1] ==# 'FileType'
      " Filetype completion.
      let l:list += neocomplcache#sources#vim_complete#helper#filetype(a:cur_text, a:cur_keyword_str)
    endif

    let l:list += s:internal_candidates_list.autocmds
  elseif len(l:args) == 4
    if l:args[2] ==# 'FileType'
      " Filetype completion.
      let l:list += neocomplcache#sources#vim_complete#helper#filetype(a:cur_text, a:cur_keyword_str)
    endif

    let l:list += neocomplcache#sources#vim_complete#helper#command(l:args[3], a:cur_keyword_str)
    let l:list += s:make_completion_list(['nested'], '[V] autocmd', '')
  else
    let l:command = l:args[3] =~ '^*' ?
          \ join(l:args[4:]) : join(l:args[3:])
    let l:list += neocomplcache#sources#vim_complete#helper#command(l:command, a:cur_keyword_str)
    let l:list += s:make_completion_list(['nested'], '[V] autocmd', '')
  endif

  return l:list
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#augroup(cur_text, cur_keyword_str)"{{{
  " Caching.
  if !has_key(s:global_candidates_list, 'augroups')
    let s:global_candidates_list.augroups = s:get_augrouplist()
  endif

  return s:global_candidates_list.augroups
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#buffer(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#colorscheme_args(cur_text, cur_keyword_str)"{{{
  return s:make_completion_list(filter(map(split(globpath(&runtimepath, 'colors/*.vim'), '\n'),
        \'fnamemodify(v:val, ":t:r")'), 'stridx(v:val, a:cur_keyword_str) == 0'), '[vim] colorscheme', '')
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#command(cur_text, cur_keyword_str)"{{{
  if a:cur_text == '' ||
        \ a:cur_text =~ '^[[:digit:],[:space:][:tab:]$''<>]*\h\w*$'
    " Commands.

    " Caching.
    if !has_key(s:global_candidates_list, 'commands')
      let s:global_candidates_list.commands = s:get_cmdlist()
    endif
    if !has_key(s:internal_candidates_list, 'commands')
      let s:internal_candidates_list.commands = s:caching_from_dict('commands', 'c')

      let s:internal_candidates_list.command_prototypes = s:caching_prototype_from_dict('command_prototypes')
      for l:command in s:internal_candidates_list.commands
        if has_key(s:internal_candidates_list.command_prototypes, l:command.word)
          let l:command.description = l:command.word . s:internal_candidates_list.command_prototypes[l:command.word]
        endif
      endfor
    endif

    let l:list = s:internal_candidates_list.commands + s:global_candidates_list.commands
    let l:list = neocomplcache#keyword_filter(l:list, a:cur_keyword_str)

    if a:cur_keyword_str =~# '^en\%[d]'
      let l:list += s:get_endlist()
    endif
  else
    " Commands args.
    let l:command = neocomplcache#sources#vim_complete#get_command(a:cur_text)
    let l:completion_name = neocomplcache#sources#vim_complete#helper#get_completion_name(l:command)

    " Prevent infinite loop.
    let l:cur_text = l:completion_name ==# 'command' ?
          \ a:cur_text[len(l:command):] : a:cur_text

    let l:list = neocomplcache#sources#vim_complete#helper#get_command_completion(l:command, l:cur_text, a:cur_keyword_str)

    if a:cur_text =~
          \'[[(,{]\|`=[^`]*$'
      " Expression.
      let l:list += neocomplcache#sources#vim_complete#helper#expression(a:cur_text, a:cur_keyword_str)
    endif
  endif

  return l:list
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#command_args(cur_text, cur_keyword_str)"{{{
  " Caching.
  if !has_key(s:internal_candidates_list, 'command_args')
    let s:internal_candidates_list.command_args = s:caching_from_dict('command_args', '')
    let s:internal_candidates_list.command_replaces = s:caching_from_dict('command_replaces', '')
  endif

  return s:internal_candidates_list.command_args + s:internal_candidates_list.command_replaces
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#custom(command_name, cur_text, cur_keyword_str)"{{{
  if !has_key(g:neocomplcache_vim_completefuncs, a:command_name)
    return []
  endif

  return s:make_completion_list(split(call(g:neocomplcache_vim_completefuncs[a:command_name],
        \ [a:cur_keyword_str, getline('.'), len(a:cur_text)]), '\n'), '[vim] custom', '')
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#customlist(command_name, cur_text, cur_keyword_str)"{{{
  if !has_key(g:neocomplcache_vim_completefuncs, a:command_name)
    return []
  endif

  return s:make_completion_list(call(g:neocomplcache_vim_completefuncs[a:command_name],
        \ [a:cur_keyword_str, getline('.'), len(a:cur_text)]), '[vim] customlist', '')
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#dir(cur_text, cur_keyword_str)"{{{
  " Check dup.
  let l:check = {}
  for keyword in filter(split(substitute(globpath(&cdpath, a:cur_keyword_str . '*'), '\\', '/', 'g'), '\n'), 'isdirectory(v:val)')
    if !has_key(l:check, keyword) && keyword =~ '/'
      let l:check[keyword] = keyword
    endif
  endfor

  let l:ret = []
  let l:paths = map(split(&cdpath, ','), 'substitute(v:val, "\\\\", "/", "g")')
  for keyword in keys(l:check)
    let l:dict = { 'word' : escape(keyword, ' *?[]"={}'), 'abbr' : keyword.'/', 'menu' : '[vim] directory', }
    " Path search.
    for path in l:paths
      if path != '' && neocomplcache#head_match(l:dict.word, path . '/')
        let l:dict.word = l:dict.word[len(path)+1 : ]
        break
      endif
    endfor

    call add(l:ret, l:dict)
  endfor

  return l:ret
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#environment(cur_text, cur_keyword_str)"{{{
  " Caching.
  if !has_key(s:global_candidates_list, 'environments')
    let s:global_candidates_list.environments = s:get_envlist()
  endif

  return s:global_candidates_list.environments
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#event(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#execute(cur_text, cur_keyword_str)"{{{
  if a:cur_text =~ '["''][^"'']*$'
    let l:command = matchstr(a:cur_text, '["'']\zs[^"'']*$')
    return neocomplcache#sources#vim_complete#helper#command(l:command, a:cur_keyword_str)
  else
    return neocomplcache#sources#vim_complete#helper#expression(a:cur_text, a:cur_keyword_str)
  endif
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#expression(cur_text, cur_keyword_str)"{{{
  return neocomplcache#sources#vim_complete#helper#function(a:cur_text, a:cur_keyword_str)
        \+ neocomplcache#sources#vim_complete#helper#var(a:cur_text, a:cur_keyword_str)
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#feature(cur_text, cur_keyword_str)"{{{
  if !has_key(s:internal_candidates_list, 'features')
    let s:internal_candidates_list.features = s:caching_from_dict('features', '')
  endif
  return s:internal_candidates_list.features
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#file(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#filetype(cur_text, cur_keyword_str)"{{{
  return s:make_completion_list(filter(map(
        \ split(globpath(&runtimepath, 'syntax/*.vim'), '\n') + split(globpath(&runtimepath, 'ftplugin/*.vim'), '\n'),
        \'matchstr(fnamemodify(v:val, ":t:r"), "^[[:alnum:]-]*")'), 'stridx(v:val, a:cur_keyword_str) == 0'), '[vim] filetype', '')
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#function(cur_text, cur_keyword_str)"{{{
  " Caching.
  if !has_key(s:global_candidates_list, 'functions')
    let s:global_candidates_list.functions = s:get_functionlist()
  endif
  if !has_key(s:internal_candidates_list, 'functions')
    let l:dict = {}
    for l:function in s:caching_from_dict('functions', 'f')
      let l:dict[l:function.word] = l:function
    endfor
    let s:internal_candidates_list.functions = l:dict

    let l:function_prototypes = {}
    for function in values(s:internal_candidates_list.functions)
      let l:function_prototypes[function.word] = function.abbr
    endfor
    let s:internal_candidates_list.function_prototypes = s:caching_prototype_from_dict('functions')

    for l:function in values(s:internal_candidates_list.functions)
      if has_key(s:internal_candidates_list.function_prototypes, l:function.word)
        let l:function.description = l:function.word . s:internal_candidates_list.function_prototypes[l:function.word]
      endif
    endfor
  endif

  let l:script_candidates_list = s:get_cached_script_candidates()
  if a:cur_keyword_str =~ '^s:'
    let l:list = values(l:script_candidates_list.functions)
  elseif a:cur_keyword_str =~ '^\a:'
    let l:functions = deepcopy(values(l:script_candidates_list.functions))
    for l:keyword in l:functions
      let l:keyword.word = '<SID>' . l:keyword.word[2:]
      let l:keyword.abbr = '<SID>' . l:keyword.abbr[2:]
    endfor
    let l:list = l:functions
  else
    let l:list = values(s:internal_candidates_list.functions) + values(s:global_candidates_list.functions)
  endif

  return l:list
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#help(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#highlight(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#let(cur_text, cur_keyword_str)"{{{
  if a:cur_text !~ '='
    return neocomplcache#sources#vim_complete#helper#var(a:cur_text, a:cur_keyword_str)
  elseif a:cur_text =~# '\<let\s\+&\%([lg]:\)\?filetype\s*=\s*'
    " FileType.
    return neocomplcache#sources#vim_complete#helper#filetype(a:cur_text, a:cur_keyword_str)
  else
    return neocomplcache#sources#vim_complete#helper#expression(a:cur_text, a:cur_keyword_str)
  endif
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#mapping(cur_text, cur_keyword_str)"{{{
  " Caching.
  if !has_key(s:global_candidates_list, 'mappings')
    let s:global_candidates_list.mappings = s:get_mappinglist()
  endif
  if !has_key(s:internal_candidates_list, 'mappings')
    let s:internal_candidates_list.mappings = s:caching_from_dict('mappings', '')
  endif

  let l:list = s:internal_candidates_list.mappings + s:global_candidates_list.mappings

  if a:cur_text =~ '<expr>'
    let l:list += neocomplcache#sources#vim_complete#helper#expression(a:cur_text, a:cur_keyword_str)
  elseif a:cur_text =~ ':<C-u>\?'
    let l:command = matchstr(a:cur_text, ':<C-u>\?\zs.*$')
    let l:list += neocomplcache#sources#vim_complete#helper#command(l:command, a:cur_keyword_str)
  endif

  return l:list
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#menu(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#option(cur_text, cur_keyword_str)"{{{
  " Caching.
  if !has_key(s:internal_candidates_list, 'options')
    let s:internal_candidates_list.options = s:caching_from_dict('options', 'o')

    for l:keyword in deepcopy(s:internal_candidates_list.options)
      let l:keyword.word = 'no' . l:keyword.word
      let l:keyword.abbr = 'no' . l:keyword.abbr
      call add(s:internal_candidates_list.options, l:keyword)
    endfor
  endif

  if a:cur_text =~ '\<set\%[local]\s\+\%(filetype\|ft\)='
    return neocomplcache#sources#vim_complete#helper#filetype(a:cur_text, a:cur_keyword_str)
  else
    return s:internal_candidates_list.options
  endif
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#shellcmd(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#tag(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#tag_listfiles(cur_text, cur_keyword_str)"{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#var_dictionary(cur_text, cur_keyword_str)"{{{
  let l:var_name = matchstr(a:cur_text, '\%(\a:\)\?\h\w*\ze\.\%(\h\w*\%(()\?\)\?\)\?$')
  if a:cur_text =~ '[btwg]:\h\w*\.\%(\h\w*\%(()\?\)\?\)\?$'
    let l:list = has_key(s:global_candidates_list.dictionary_variables, l:var_name) ?
          \ values(s:global_candidates_list.dictionary_variables[l:var_name]) : []
  elseif a:cur_text =~ 's:\h\w*\.\%(\h\w*\%(()\?\)\?\)\?$'
    let l:list = values(get(s:get_cached_script_candidates().dictionary_variables, l:var_name, {}))
  else
    let l:list = s:get_local_dictionary_variables(l:var_name)
  endif

  return l:list
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#var(cur_text, cur_keyword_str)"{{{
  " Caching.
  if !has_key(s:global_candidates_list, 'variables')
    let l:dict = {}
    for l:var in extend(s:caching_from_dict('variables', ''), s:get_variablelist())
      let l:dict[l:var.word] = l:var
    endfor
    let s:global_candidates_list.variables = l:dict
  endif

  if a:cur_keyword_str =~ '^[swtb]:'
    let l:list = values(s:get_cached_script_candidates().variables)
  elseif a:cur_keyword_str =~ '^[vg]:'
    let l:list = values(s:global_candidates_list.variables)
  else
    let l:list = s:get_local_variables()
  endif

  return l:list
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#expand(cur_text, cur_keyword_str)"{{{
  return s:make_completion_list(
        \ ['<cfile>', '<afile>', '<abuf>', '<amatch>', '<sfile>', '<cword>', '<cWORD>', '<client>'],
        \ '[vim] expand', '')
endfunction"}}}

function! s:get_local_variables()"{{{
  " Get local variable list.

  let l:keyword_dict = {}
  " Search function.
  let l:line_num = line('.') - 1
  let l:end_line = (line('.') > 100) ? line('.') - 100 : 1
  while l:line_num >= l:end_line
    let l:line = getline(l:line_num)
    if l:line =~ '\<endf\%[unction]\>'
      break
    elseif l:line =~ '\<fu\%[nction]!\?\s\+'
      let l:candidates_list = l:line =~ '\<fu\%[nction]!\?\s\+s:' && has_key(s:script_candidates_list, bufnr('%')) ?
            \ s:script_candidates_list[bufnr('%')] : s:global_candidates_list
      if has_key(l:candidates_list, 'functions') && has_key(l:candidates_list, 'function_prototypes')
        call s:analyze_function_line(l:line, l:candidates_list.functions, l:candidates_list.function_prototypes) 
      endif

      " Get function arguments.
      call s:analyze_variable_line(l:line, l:keyword_dict)
      break
    endif

    let l:line_num -= 1
  endwhile
  let l:line_num += 1

  let l:end_line = line('.') - 1
  while l:line_num <= l:end_line
    let l:line = getline(l:line_num)

    if l:line =~ '\<\%(let\|for\)\s\+'
      if l:line =~ '\<\%(let\|for\)\s\+s:' && has_key(s:script_candidates_list, bufnr('%'))
            \ && has_key(s:script_candidates_list[bufnr('%')], 'variables')
        let l:candidates_list = s:script_candidates_list[bufnr('%')].variables
      elseif l:line =~ '\<\%(let\|for\)\s\+[btwg]:'
            \ && has_key(s:global_candidates_list, 'variables')
        let l:candidates_list = s:global_candidates_list.variables
      else
        let l:candidates_list = l:keyword_dict
      endif
      call s:analyze_variable_line(l:line, l:candidates_list)
    endif

    let l:line_num += 1
  endwhile

  return values(l:keyword_dict)
endfunction"}}}
function! s:get_local_dictionary_variables(var_name)"{{{
  " Get local dictionary variable list.

  " Search function.
  let l:line_num = line('.') - 1
  let l:end_line = (line('.') > 100) ? line('.') - 100 : 1
  while l:line_num >= l:end_line
    let l:line = getline(l:line_num)
    if l:line =~ '\<fu\%[nction]\>'
      break
    endif

    let l:line_num -= 1
  endwhile
  let l:line_num += 1

  let l:end_line = line('.') - 1
  let l:keyword_dict = {}
  let l:var_pattern = a:var_name.'\.\h\w*\%(()\?\)\?'
  while l:line_num <= l:end_line
    let l:line = getline(l:line_num)

    if l:line =~ l:var_pattern
      while l:line =~ l:var_pattern
        let l:var_name = matchstr(l:line, '\a:[[:alnum:]_:]*\ze\.\h\w*')
        if l:var_name =~ '^[btwg]:'
          let l:candidates = s:global_candidates_list.dictionary_variables
          if !has_key(l:candidates, l:var_name)
            let l:candidates[l:var_name] = {}
          endif
          let l:candidates_dict = l:candidates[l:var_name]
        elseif l:var_name =~ '^s:' && has_key(s:script_candidates_list, bufnr('%'))
          let l:candidates = s:script_candidates_list[bufnr('%')].dictionary_variables
          if !has_key(l:candidates, l:var_name)
            let l:candidates[l:var_name] = {}
          endif
          let l:candidates_dict = l:candidates[l:var_name]
        else
          let l:candidates_dict = l:keyword_dict
        endif

        call s:analyze_dictionary_variable_line(l:line, l:candidates_dict, l:var_name)

        let l:line = l:line[matchend(l:line, l:var_pattern) :]
      endwhile
    endif

    let l:line_num += 1
  endwhile

  return values(l:keyword_dict)
endfunction"}}}

function! s:get_cached_script_candidates()"{{{
  return has_key(s:script_candidates_list, bufnr('%')) && v:version > 700 ?
        \ s:script_candidates_list[bufnr('%')] : {
        \   'functions' : {}, 'variables' : {}, 'function_prototypes' : {}, 'dictionary_variables' : {} }
endfunction"}}}
function! s:get_script_candidates(bufnumber)"{{{
  " Get script candidate list.

  let l:function_dict = {}
  let l:variable_dict = {}
  let l:dictionary_variable_dict = {}
  let l:function_prototypes = {}
  let l:var_pattern = '\a:[[:alnum:]_:]*\.\h\w*\%(()\?\)\?'

  for l:line in getbufline(a:bufnumber, 1, '$')
    if l:line =~ '\<fu\%[nction]!\?\s\+s:'
      call s:analyze_function_line(l:line, l:function_dict, l:function_prototypes)
    elseif l:line =~ '\<let\s\+'
      " Get script variable.
      call s:analyze_variable_line(l:line, l:variable_dict)
    elseif l:line =~ l:var_pattern
      while l:line =~ l:var_pattern
        let l:var_name = matchstr(l:line, '\a:[[:alnum:]_:]*\ze\.\h\w*')
        if l:var_name =~ '^[btwg]:'
          let l:candidates_dict = s:global_candidates_list.dictionary_variables
        else
          let l:candidates_dict = l:dictionary_variable_dict
        endif
        if !has_key(l:candidates_dict, l:var_name)
          let l:candidates_dict[l:var_name] = {}
        endif

        call s:analyze_dictionary_variable_line(l:line, l:candidates_dict[l:var_name], l:var_name)

        let l:line = l:line[matchend(l:line, l:var_pattern) :]
      endwhile
    endif
  endfor

  return { 'functions' : l:function_dict, 'variables' : l:variable_dict, 
        \'function_prototypes' : l:function_prototypes, 'dictionary_variables' : l:dictionary_variable_dict }
endfunction"}}}

function! s:caching_from_dict(dict_name, kind)"{{{
  let l:dict_files = split(globpath(&runtimepath, 'autoload/neocomplcache/sources/vim_complete/'.a:dict_name.'.dict'), '\n')
  if empty(l:dict_files)
    return []
  endif

  let l:menu_pattern = '[vim] '.a:dict_name[: -2]
  let l:keyword_pattern =
        \'^\%(-\h\w*\%(=\%(\h\w*\|[01*?+%]\)\?\)\?\|<\h[[:alnum:]_-]*>\?\|\h[[:alnum:]_:#\[]*\%([!\]]\+\|()\?\)\?\)'
  let l:keyword_list = []
  for line in readfile(l:dict_files[0])
    call add(l:keyword_list, {
          \ 'word' : substitute(matchstr(line, l:keyword_pattern), '[\[\]]', '', 'g'), 
          \ 'menu' : l:menu_pattern, 'kind' : a:kind, 'abbr' : l:line
          \})
  endfor

  return l:keyword_list
endfunction"}}}
function! s:caching_completion_from_dict(dict_name)"{{{
  let l:dict_files = split(globpath(&runtimepath, 'autoload/neocomplcache/sources/vim_complete/'.a:dict_name.'.dict'), '\n')
  if empty(l:dict_files)
    return {}
  endif

  let l:keyword_dict = {}
  for l:line in readfile(l:dict_files[0])
    let l:word = matchstr(l:line, '^[[:alnum:]_\[\]]\+')
    let l:completion = matchstr(l:line[len(l:word):], '\h\w*')
    if l:completion != ''
      if l:word =~ '\['
        let [l:word_head, l:word_tail] = split(l:word, '\[')
        let l:word_tail = ' ' . substitute(l:word_tail, '\]', '', '')
      else
        let l:word_head = l:word
        let l:word_tail = ' '
      endif

      for i in range(len(l:word_tail))
        let l:keyword_dict[l:word_head . l:word_tail[1:i]] = l:completion
      endfor
    endif
  endfor

  return l:keyword_dict
endfunction"}}}
function! s:caching_prototype_from_dict(dict_name)"{{{
  let l:dict_files = split(globpath(&runtimepath, 'autoload/neocomplcache/sources/vim_complete/'.a:dict_name.'.dict'), '\n')
  if empty(l:dict_files)
    return {}
  endif
  if a:dict_name == 'functions'
    let l:pattern = '^[[:alnum:]_]\+('
  else
    let l:pattern = '^[[:alnum:]_\[\](]\+'
  endif

  let l:keyword_dict = {}
  for l:line in readfile(l:dict_files[0])
    let l:word = matchstr(l:line, l:pattern)
    let l:rest = l:line[len(l:word):]
    if l:word =~ '\['
      let [l:word_head, l:word_tail] = split(l:word, '\[')
      let l:word_tail = ' ' . substitute(l:word_tail, '\]', '', '')
    else
      let l:word_head = l:word
      let l:word_tail = ' '
    endif

    for i in range(len(l:word_tail))
      let l:keyword_dict[l:word_head . l:word_tail[1:i]] = l:rest
    endfor
  endfor

  return l:keyword_dict
endfunction"}}}

function! s:get_cmdlist()"{{{
  " Get command list.
  redir => l:redir
  silent! command
  redir END

  let l:keyword_list = []
  let l:completions = [ 'augroup', 'buffer', 'command', 'dir', 'environment', 
        \ 'event', 'expression', 'file', 'shellcmd', 'function', 
        \ 'help', 'highlight', 'mapping', 'menu', 'option', 'tag', 'tag_listfiles', 
        \ 'var', 'custom', 'customlist' ]
  let l:command_prototypes = {}
  let l:command_completions = {}
  let l:menu_pattern = '[vim] command'
  for line in split(l:redir, '\n')[1:]
    let l:word = matchstr(line, '\a\w*')

    " Analyze prototype.
    let l:end = matchend(line, '\a\w*')
    let l:args = matchstr(line, '[[:digit:]?+*]', l:end)
    if l:args != '0'
      let l:prototype = matchstr(line, '\a\w*', l:end)
      let l:found = 0
      for l:comp in l:completions
        if l:comp == l:prototype
          let l:command_completions[l:word] = l:prototype
          let l:found = 1

          break
        endif
      endfor

      if !l:found
        let l:prototype = 'arg'
      endif

      if l:args == '*'
        let l:prototype = '[' . l:prototype . '] ...'
      elseif l:args == '?'
        let l:prototype = '[' . l:prototype . ']'
      elseif l:args == '+'
        let l:prototype = l:prototype . ' ...'
      endif

      let l:command_prototypes[l:word] = ' ' . repeat(' ', 16 - len(l:word)) . l:prototype
    else
      let l:command_prototypes[l:word] = ''
    endif
    let l:prototype = l:command_prototypes[l:word]

    call add(l:keyword_list, {
          \ 'word' : l:word, 'abbr' : l:word . l:prototype,
          \ 'description' : l:word . l:prototype, 'menu' : l:menu_pattern, 'kind' : 'c'
          \})
  endfor
  let s:global_candidates_list.command_prototypes = l:command_prototypes
  let s:global_candidates_list.command_completions = l:command_completions

  return l:keyword_list
endfunction"}}}
function! s:get_variablelist()"{{{
  " Get variable list.
  redir => l:redir
  silent! let
  redir END

  let l:keyword_list = []
  let l:menu_pattern = '[vim] variable'
  let l:kind_dict = ['0', '""', '()', '[]', '{}', '.']
  for line in split(l:redir, '\n')
    let l:word = matchstr(line, '^\a[[:alnum:]_:]*')
    if l:word !~ '^\a:'
      let l:word = 'g:' . l:word
    elseif l:word =~ '[^gv]:'
      continue
    endif
    call add(l:keyword_list, {
          \ 'word' : l:word, 'menu' : l:menu_pattern,
          \ 'kind' : exists(l:word)? l:kind_dict[type(eval(l:word))] : ''
          \})
  endfor
  return l:keyword_list
endfunction"}}}
function! s:get_functionlist()"{{{
  " Get function list.
  redir => l:redir
  silent! function
  redir END

  let l:keyword_dict = {}
  let l:function_prototypes = {}
  let l:menu_pattern = '[vim] function'
  for l:line in split(l:redir, '\n')
    let l:line = l:line[9:]
    if l:line =~ '^<SNR>'
      continue
    endif
    let l:orig_line = l:line

    let l:word = matchstr(l:line, '\h[[:alnum:]_:#.]*()\?')
    if l:word != ''
      let l:keyword_dict[l:word] = {
            \ 'word' : l:word, 'abbr' : l:line,
            \ 'description' : l:line, 'menu' : l:menu_pattern,
            \}

      let l:function_prototypes[l:word] = l:orig_line[len(l:word):]
    endif
  endfor

  let s:global_candidates_list.function_prototypes = l:function_prototypes

  return l:keyword_dict
endfunction"}}}
function! s:get_augrouplist()"{{{
  " Get augroup list.
  redir => l:redir
  silent! augroup
  redir END

  let l:keyword_list = []
  let l:menu_pattern = '[vim] augroup'
  for l:group in split(l:redir . ' END', '\s\|\n')
    call add(l:keyword_list, { 'word' : l:group, 'menu' : l:menu_pattern})
  endfor
  return l:keyword_list
endfunction"}}}
function! s:get_mappinglist()"{{{
  " Get mapping list.
  redir => l:redir
  silent! map
  redir END

  let l:keyword_list = []
  let l:menu_pattern = '[vim] mapping'
  for line in split(l:redir, '\n')
    let l:map = matchstr(line, '^\a*\s*\zs\S\+')
    if l:map !~ '^<' || l:map =~ '^<SNR>'
      continue
    endif
    call add(l:keyword_list, { 'word' : l:map, 'menu' : l:menu_pattern })
  endfor
  return l:keyword_list
endfunction"}}}
function! s:get_envlist()"{{{
  " Get environment variable list.

  let l:keyword_list = []
  let l:menu_pattern = '[vim] environment'
  for line in split(system('set'), '\n')
    let l:word = '$' . toupper(matchstr(line, '^\h\w*'))
    call add(l:keyword_list, { 'word' : l:word, 'menu' : l:menu_pattern, 'kind' : 'e' })
  endfor
  return l:keyword_list
endfunction"}}}
function! s:get_endlist()"{{{
  " Get end command list.

  let l:keyword_dict = {}
  let l:menu_pattern = '[vim] end'
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

  return (l:word == '')? [] : [{'word' : l:word, 'menu' : l:menu_pattern, 'kind' : 'c'}]
endfunction"}}}
function! s:make_completion_list(list, menu_pattern, kind)"{{{
  let l:list = []
  for l:item in a:list
    call add(l:list, { 'word' : l:item, 'menu' : a:menu_pattern, 'kind' : a:kind })
  endfor 

  return l:list
endfunction"}}}
function! s:analyze_function_line(line, keyword_dict, prototype)"{{{
  let l:menu_pattern = '[vim] function'

  " Get script function.
  let l:line = substitute(matchstr(a:line, '\<fu\%[nction]!\?\s\+\zs.*)'), '".*$', '', '')
  let l:orig_line = l:line
  let l:word = matchstr(l:line, '^\h[[:alnum:]_:#.]*()\?')
  if l:word != '' && !has_key(a:keyword_dict, l:word) 
    let a:keyword_dict[l:word] = {
          \ 'word' : l:word, 'abbr' : l:line, 'menu' : l:menu_pattern, 'kind' : 'f'
          \}
    let a:prototype[l:word] = l:orig_line[len(l:word):]
  endif
endfunction"}}}
function! s:analyze_variable_line(line, keyword_dict)"{{{
  let l:menu_pattern = '[vim] variable'

  if a:line =~ '\<\%(let\|for\)\s\+\a[[:alnum:]_:]*'
    " let var = pattern.
    let l:word = matchstr(a:line, '\<\%(let\|for\)\s\+\zs\a[[:alnum:]_:]*')
    let l:expression = matchstr(a:line, '\<let\s\+\a[[:alnum:]_:]*\s*=\s*\zs.*$')
    if !has_key(a:keyword_dict, l:word) 
      let a:keyword_dict[l:word] = {
            \ 'word' : l:word, 'menu' : l:menu_pattern,
            \ 'kind' : s:get_variable_type(l:expression)
            \}
    elseif l:expression != '' && a:keyword_dict[l:word].kind == ''
      " Update kind.
      let a:keyword_dict[l:word].kind = s:get_variable_type(l:expression)
    endif
  elseif a:line =~ '\<\%(let\|for\)\s\+\[.\{-}\]'
    " let [var1, var2] = pattern.
    let l:words = split(matchstr(a:line, '\<\%(let\|for\)\s\+\[\zs.\{-}\ze\]'), '[,[:space:]]\+')
      let l:expressions = split(matchstr(a:line, '\<let\s\+\[.\{-}\]\s*=\s*\[\zs.\{-}\ze\]$'), '[,[:space:];]\+')

      let i = 0
      while i < len(l:words)
        let l:expression = get(l:expressions, i, '')
        let l:word = l:words[i]

        if !has_key(a:keyword_dict, l:word) 
          let a:keyword_dict[l:word] = {
                \ 'word' : l:word, 'menu' : l:menu_pattern,
                \ 'kind' : s:get_variable_type(l:expression)
                \}
        elseif l:expression != '' && a:keyword_dict[l:word].kind == ''
          " Update kind.
          let a:keyword_dict[l:word].kind = s:get_variable_type(l:expression)
        endif

        let i += 1
      endwhile
    elseif a:line =~ '\<fu\%[nction]!\?\s\+'
      " Get function arguments.
      for l:arg in split(matchstr(a:line, '^[^(]*(\zs[^)]*'), '\s*,\s*')
        let l:word = 'a:' . (l:arg == '...' ?  '000' : l:arg)
        let a:keyword_dict[l:word] = {
              \ 'word' : l:word, 'menu' : l:menu_pattern,
              \ 'kind' : (l:arg == '...' ?  '[]' : '')
              \}

      endfor
      if a:line =~ '\.\.\.)'
        " Extra arguments.
        for l:arg in range(5)
          let l:word = 'a:' . l:arg
          let a:keyword_dict[l:word] = {
                \ 'word' : l:word, 'menu' : l:menu_pattern,
                \ 'kind' : (l:arg == 0 ?  '0' : '')
                \}
        endfor
      endif
    endif
endfunction"}}}
function! s:analyze_dictionary_variable_line(line, keyword_dict, var_name)"{{{
  let l:menu_pattern = '[vim] dictionary'
  let l:var_pattern = a:var_name.'\.\h\w*\%(()\?\)\?'
  let l:let_pattern = '\<let\s\+'.a:var_name.'\.\h\w*'
  let l:call_pattern = '\<call\s\+'.a:var_name.'\.\h\w*()\?'

  if a:line =~ l:let_pattern
    let l:word = matchstr(a:line, a:var_name.'\zs\.\h\w*')
    let l:expression = matchstr(a:line, l:let_pattern.'\s*=\zs.*$')
    let l:kind = ''
  elseif a:line =~ l:call_pattern
    let l:word = matchstr(a:line, a:var_name.'\zs\.\h\w*()\?')
    let l:kind = '()'
  else
    let l:word = matchstr(a:line, a:var_name.'\zs.\h\w*\%(()\?\)\?')
    let l:kind = s:get_variable_type(matchstr(a:line, a:var_name.'\.\h\w*\zs.*$'))
  endif

  if !has_key(a:keyword_dict, l:word) 
    let a:keyword_dict[l:word] = { 'word' : l:word, 'menu' : l:menu_pattern,  'kind' : l:kind }
  elseif l:kind != '' && a:keyword_dict[l:word].kind == ''
    " Update kind.
    let a:keyword_dict[l:word].kind = l:kind
  endif
endfunction"}}}
function! s:split_args(cur_text, cur_keyword_str)"{{{
  let l:args = split(a:cur_text)
  if a:cur_keyword_str == ''
    call add(l:args, '')
  endif

  return l:args
endfunction"}}}

" Initialize return types."{{{
function! s:set_dictionary_helper(variable, keys, value)"{{{
  for key in split(a:keys, ',')
    let a:variable[key] = a:value
  endfor
endfunction"}}}
let s:function_return_types = {}
call neocomplcache#set_dictionary_helper(s:function_return_types,
      \ 'len,match,matchend',
      \ '0')
call neocomplcache#set_dictionary_helper(s:function_return_types,
      \ 'input,matchstr',
      \ '""')
call neocomplcache#set_dictionary_helper(s:function_return_types,
      \ 'expand,filter,sort,split',
      \ '[]')
"}}}
function! s:get_variable_type(expression)"{{{
  " Analyze variable type.
  if a:expression =~ '^\%(\s*+\)\?\s*\d\+\.\d\+'
    return '.'
  elseif a:expression =~ '^\%(\s*+\)\?\s*\d\+'
    return '0'
  elseif a:expression =~ '^\%(\s*\.\)\?\s*["'']'
    return '""'
  elseif a:expression =~ '\<function('
    return '()'
  elseif a:expression =~ '^\%(\s*+\)\?\s*\['
    return '[]'
  elseif a:expression =~ '^\s*{\|^\.\h[[:alnum:]_:]*'
    return '{}'
  elseif a:expression =~ '\<\h\w*('
    " Function.
    let l:func_name = matchstr(a:expression, '\<\zs\h\w*\ze(')
    return has_key(s:function_return_types, l:func_name) ? s:function_return_types[l:func_name] : ''
  else
    return ''
  endif
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
