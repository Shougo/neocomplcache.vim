"=============================================================================
" FILE: helper.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Apr 2013.
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

function! neocomplcache#sources#vim_complete#helper#on_filetype() "{{{
  " Caching script candidates.
  let bufnumber = 1

  " Check buffer.
  while bufnumber <= bufnr('$')
    if getbufvar(bufnumber, '&filetype') == 'vim' && bufloaded(bufnumber)
          \&& !has_key(s:script_candidates_list, bufnumber)
      let s:script_candidates_list[bufnumber] = s:get_script_candidates(bufnumber)
    endif

    let bufnumber += 1
  endwhile

  if neocomplcache#exists_echodoc()
    call echodoc#register('vim_complete', s:doc_dict)
  endif
endfunction"}}}

function! neocomplcache#sources#vim_complete#helper#recaching(bufname) "{{{
  " Caching script candidates.
  let bufnumber = a:bufname != '' ? bufnr(a:bufname) : bufnr('%')

  if getbufvar(bufnumber, '&filetype') == 'vim' && bufloaded(bufnumber)
    let s:script_candidates_list[bufnumber] = s:get_script_candidates(bufnumber)
  endif
  let s:global_candidates_list = { 'dictionary_variables' : {} }
endfunction"}}}

" For echodoc. "{{{
let s:doc_dict = {
      \ 'name' : 'vim_complete',
      \ 'rank' : 10,
      \ 'filetypes' : { 'vim' : 1 },
      \ }
function! s:doc_dict.search(cur_text) "{{{
  let cur_text = a:cur_text

  " Echo prototype.
  let script_candidates_list = s:get_cached_script_candidates()

  let prototype_name = matchstr(cur_text,
        \'\%(<[sS][iI][dD]>\|[sSgGbBwWtTlL]:\)\=\%(\i\|[#.]\|{.\{-1,}}\)*\s*(\ze\%([^(]\|(.\{-})\)*$')
  let ret = []
  if prototype_name != ''
    if !has_key(s:internal_candidates_list, 'function_prototypes')
      " No cache.
      return []
    endif

    " Search function name.
    call add(ret, { 'text' : prototype_name, 'highlight' : 'Identifier' })
    if has_key(s:internal_candidates_list.function_prototypes, prototype_name)
      call add(ret, { 'text' : s:internal_candidates_list.function_prototypes[prototype_name] })
    elseif has_key(s:global_candidates_list.function_prototypes, prototype_name)
      call add(ret, { 'text' : s:global_candidates_list.function_prototypes[prototype_name] })
    elseif has_key(script_candidates_list.function_prototypes, prototype_name)
      call add(ret, { 'text' : script_candidates_list.function_prototypes[prototype_name] })
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
    let prototype_name = neocomplcache#sources#vim_complete#get_command(cur_text)
    call add(ret, { 'text' : prototype_name, 'highlight' : 'Statement' })
    if has_key(s:internal_candidates_list.command_prototypes, prototype_name)
      call add(ret, { 'text' : s:internal_candidates_list.command_prototypes[prototype_name] })
    elseif has_key(s:global_candidates_list.command_prototypes, prototype_name)
      call add(ret, { 'text' : s:global_candidates_list.command_prototypes[prototype_name] })
    else
      " No prototypes.
      return []
    endif
  endif

  return ret
endfunction"}}}
"}}}

function! neocomplcache#sources#vim_complete#helper#get_command_completion(command_name, cur_text, complete_str) "{{{
  let completion_name =
        \ neocomplcache#sources#vim_complete#helper#get_completion_name(a:command_name)
  if completion_name == ''
    " Not found.
    return []
  endif

  let args = (completion_name ==# 'custom' || completion_name ==# 'customlist')?
        \ [a:command_name, a:cur_text, a:complete_str] : [a:cur_text, a:complete_str]
  return call('neocomplcache#sources#vim_complete#helper#'.completion_name, args)
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#get_completion_name(command_name) "{{{
  if !has_key(s:internal_candidates_list, 'command_completions')
    let s:internal_candidates_list.command_completions =
          \ s:caching_completion_from_dict('command_completions')
  endif
  if !has_key(s:global_candidates_list, 'command_completions')
    let s:global_candidates_list.commands =
          \ neocomplcache#pack_dictionary(s:get_cmdlist())
  endif

  if has_key(s:internal_candidates_list.command_completions, a:command_name)
        \&& exists('*neocomplcache#sources#vim_complete#helper#'
        \ .s:internal_candidates_list.command_completions[a:command_name])
    return s:internal_candidates_list.command_completions[a:command_name]
  elseif has_key(s:global_candidates_list.command_completions, a:command_name)
        \&& exists('*neocomplcache#sources#vim_complete#helper#'
        \ .s:global_candidates_list.command_completions[a:command_name])
    return s:global_candidates_list.command_completions[a:command_name]
  else
    return ''
  endif
endfunction"}}}

function! neocomplcache#sources#vim_complete#helper#autocmd_args(cur_text, complete_str) "{{{
  let args = s:split_args(a:cur_text, a:complete_str)
  if len(args) < 2
    return []
  endif

  " Caching.
  if !has_key(s:global_candidates_list, 'augroups')
    let s:global_candidates_list.augroups = s:get_augrouplist()
  endif
  if !has_key(s:internal_candidates_list, 'autocmds')
    let s:internal_candidates_list.autocmds = s:caching_from_dict('autocmds', '')
  endif

  let list = []
  if len(args) == 2
    let list += s:global_candidates_list.augroups + s:internal_candidates_list.autocmds
  elseif len(args) == 3
    if args[1] ==# 'FileType'
      " Filetype completion.
      let list += neocomplcache#sources#vim_complete#helper#filetype(a:cur_text, a:complete_str)
    endif

    let list += s:internal_candidates_list.autocmds
  elseif len(args) == 4
    if args[2] ==# 'FileType'
      " Filetype completion.
      let list += neocomplcache#sources#vim_complete#helper#filetype(
            \ a:cur_text, a:complete_str)
    endif

    let list += neocomplcache#sources#vim_complete#helper#command(
          \ args[3], a:complete_str)
    let list += s:make_completion_list(['nested'], '')
  else
    let command = args[3] =~ '^*' ?
          \ join(args[4:]) : join(args[3:])
    let list += neocomplcache#sources#vim_complete#helper#command(
          \ command, a:complete_str)
    let list += s:make_completion_list(['nested'], '')
  endif

  return list
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#augroup(cur_text, complete_str) "{{{
  " Caching.
  if !has_key(s:global_candidates_list, 'augroups')
    let s:global_candidates_list.augroups = s:get_augrouplist()
  endif

  return s:global_candidates_list.augroups
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#buffer(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#colorscheme_args(cur_text, complete_str) "{{{
  return s:make_completion_list(filter(map(split(
        \ globpath(&runtimepath, 'colors/*.vim'), '\n'),
        \ 'fnamemodify(v:val, ":t:r")'),
        \ 'stridx(v:val, a:complete_str) == 0'), '')
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#command(cur_text, complete_str) "{{{
  if a:cur_text == '' ||
        \ a:cur_text =~ '^[[:digit:],[:space:][:tab:]$''<>]*\h\w*$'
    " Commands.

    " Caching.
    if !has_key(s:global_candidates_list, 'commands')
      let s:global_candidates_list.commands =
            \ neocomplcache#pack_dictionary(s:get_cmdlist())
    endif
    if !has_key(s:internal_candidates_list, 'commands')
      let s:internal_candidates_list.command_prototypes =
            \ s:caching_prototype_from_dict('command_prototypes')
      let commands = s:caching_from_dict('commands', 'c')
      for command in commands
        if has_key(s:internal_candidates_list.command_prototypes, command.word)
          let command.description = command.word .
                \ s:internal_candidates_list.command_prototypes[command.word]
        endif
      endfor

      let s:internal_candidates_list.commands =
            \ neocomplcache#pack_dictionary(commands)
    endif

    " echomsg string(s:internal_candidates_list.commands)[: 1000]
    " echomsg string(s:global_candidates_list.commands)[: 1000]
    let list = neocomplcache#dictionary_filter(
          \ s:internal_candidates_list.commands, a:complete_str)
          \ + neocomplcache#dictionary_filter(
          \ s:global_candidates_list.commands, a:complete_str)
  else
    " Commands args.
    let command = neocomplcache#sources#vim_complete#get_command(a:cur_text)
    let completion_name =
          \ neocomplcache#sources#vim_complete#helper#get_completion_name(command)

    " Prevent infinite loop.
    let cur_text = completion_name ==# 'command' ?
          \ a:cur_text[len(command):] : a:cur_text

    let list = neocomplcache#sources#vim_complete#helper#get_command_completion(
          \ command, cur_text, a:complete_str)

    if a:cur_text =~
          \'[[(,{]\|`=[^`]*$'
      " Expression.
      let list += neocomplcache#sources#vim_complete#helper#expression(
            \ a:cur_text, a:complete_str)
    endif
  endif

  return list
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#command_args(cur_text, complete_str) "{{{
  " Caching.
  if !has_key(s:internal_candidates_list, 'command_args')
    let s:internal_candidates_list.command_args =
          \ s:caching_from_dict('command_args', '')
    let s:internal_candidates_list.command_replaces =
          \ s:caching_from_dict('command_replaces', '')
  endif

  return s:internal_candidates_list.command_args +
        \ s:internal_candidates_list.command_replaces
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#custom(command_name, cur_text, complete_str) "{{{
  if !has_key(g:neocomplcache_vim_completefuncs, a:command_name)
    return []
  endif

  return s:make_completion_list(split(
        \ call(g:neocomplcache_vim_completefuncs[a:command_name],
        \ [a:complete_str, getline('.'), len(a:cur_text)]), '\n'), '')
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#customlist(command_name, cur_text, complete_str) "{{{
  if !has_key(g:neocomplcache_vim_completefuncs, a:command_name)
    return []
  endif

  return s:make_completion_list(
        \ call(g:neocomplcache_vim_completefuncs[a:command_name],
        \ [a:complete_str, getline('.'), len(a:cur_text)]), '')
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#dir(cur_text, complete_str) "{{{
  return filter(neocomplcache#sources#filename_complete#get_complete_words(
        \ a:complete_str, '.'), 'isdirectory(v:val.word)')
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#environment(cur_text, complete_str) "{{{
  " Caching.
  if !has_key(s:global_candidates_list, 'environments')
    let s:global_candidates_list.environments = s:get_envlist()
  endif

  return s:global_candidates_list.environments
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#event(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#execute(cur_text, complete_str) "{{{
  if a:cur_text =~ '["''][^"'']*$'
    let command = matchstr(a:cur_text, '["'']\zs[^"'']*$')
    return neocomplcache#sources#vim_complete#helper#command(command, a:complete_str)
  else
    return neocomplcache#sources#vim_complete#helper#expression(a:cur_text, a:complete_str)
  endif
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#expression(cur_text, complete_str) "{{{
  return neocomplcache#sources#vim_complete#helper#function(a:cur_text, a:complete_str)
        \+ neocomplcache#sources#vim_complete#helper#var(a:cur_text, a:complete_str)
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#feature(cur_text, complete_str) "{{{
  if !has_key(s:internal_candidates_list, 'features')
    let s:internal_candidates_list.features = s:caching_from_dict('features', '')
  endif
  return s:internal_candidates_list.features
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#file(cur_text, complete_str) "{{{
  return neocomplcache#sources#filename_complete#get_complete_words(
        \ a:complete_str, '.')
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#filetype(cur_text, complete_str) "{{{
  if !has_key(s:internal_candidates_list, 'filetypes')
    let s:internal_candidates_list.filetypes =
          \ neocomplcache#pack_dictionary(s:make_completion_list(map(
          \ split(globpath(&runtimepath, 'syntax/*.vim'), '\n') +
          \ split(globpath(&runtimepath, 'indent/*.vim'), '\n') +
          \ split(globpath(&runtimepath, 'ftplugin/*.vim'), '\n')
          \ , "matchstr(fnamemodify(v:val, ':t:r'), '^[[:alnum:]-]*')"), ''))
  endif

  return neocomplcache#dictionary_filter(
          \ s:internal_candidates_list.filetypes, a:complete_str)
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#function(cur_text, complete_str) "{{{
  " Caching.
  if !has_key(s:global_candidates_list, 'functions')
    let s:global_candidates_list.functions =
          \ neocomplcache#pack_dictionary(s:get_functionlist())
  endif
  if !has_key(s:internal_candidates_list, 'functions')
    let s:internal_candidates_list.function_prototypes =
          \ s:caching_prototype_from_dict('functions')

    let functions = s:caching_from_dict('functions', 'f')
    for function in functions
      if has_key(s:internal_candidates_list.function_prototypes, function.word)
        let function.description = function.word
              \ . s:internal_candidates_list.function_prototypes[function.word]
      endif
    endfor

    let s:internal_candidates_list.functions =
          \ neocomplcache#pack_dictionary(functions)
  endif

  let script_candidates_list = s:get_cached_script_candidates()
  if a:complete_str =~ '^s:'
    let list = values(script_candidates_list.functions)
  elseif a:complete_str =~ '^\a:'
    let functions = deepcopy(values(script_candidates_list.functions))
    for keyword in functions
      let keyword.word = '<SID>' . keyword.word[2:]
      let keyword.abbr = '<SID>' . keyword.abbr[2:]
    endfor
    let list = functions
  else
    let list = neocomplcache#dictionary_filter(
          \ s:internal_candidates_list.functions, a:complete_str)
          \ + neocomplcache#dictionary_filter(
          \ s:global_candidates_list.functions, a:complete_str)
  endif

  return list
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#help(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#highlight(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#let(cur_text, complete_str) "{{{
  if a:cur_text !~ '='
    return neocomplcache#sources#vim_complete#helper#var(a:cur_text, a:complete_str)
  elseif a:cur_text =~# '\<let\s\+&\%([lg]:\)\?filetype\s*=\s*'
    " FileType.
    return neocomplcache#sources#vim_complete#helper#filetype(a:cur_text, a:complete_str)
  else
    return neocomplcache#sources#vim_complete#helper#expression(a:cur_text, a:complete_str)
  endif
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#mapping(cur_text, complete_str) "{{{
  " Caching.
  if !has_key(s:global_candidates_list, 'mappings')
    let s:global_candidates_list.mappings = s:get_mappinglist()
  endif
  if !has_key(s:internal_candidates_list, 'mappings')
    let s:internal_candidates_list.mappings = s:caching_from_dict('mappings', '')
  endif

  let list = s:internal_candidates_list.mappings + s:global_candidates_list.mappings

  if a:cur_text =~ '<expr>'
    let list += neocomplcache#sources#vim_complete#helper#expression(a:cur_text, a:complete_str)
  elseif a:cur_text =~ ':<C-u>\?'
    let command = matchstr(a:cur_text, ':<C-u>\?\zs.*$')
    let list += neocomplcache#sources#vim_complete#helper#command(command, a:complete_str)
  endif

  return list
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#menu(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#option(cur_text, complete_str) "{{{
  " Caching.
  if !has_key(s:internal_candidates_list, 'options')
    let s:internal_candidates_list.options = s:caching_from_dict('options', 'o')

    for keyword in deepcopy(s:internal_candidates_list.options)
      let keyword.word = 'no' . keyword.word
      let keyword.abbr = 'no' . keyword.abbr
      call add(s:internal_candidates_list.options, keyword)
    endfor
  endif

  if a:cur_text =~ '\<set\%[local]\s\+\%(filetype\|ft\)='
    return neocomplcache#sources#vim_complete#helper#filetype(a:cur_text, a:complete_str)
  else
    return s:internal_candidates_list.options
  endif
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#shellcmd(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#tag(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#tag_listfiles(cur_text, complete_str) "{{{
  return []
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#var_dictionary(cur_text, complete_str) "{{{
  let var_name = matchstr(a:cur_text,
        \'\%(\a:\)\?\h\w*\ze\.\%(\h\w*\%(()\?\)\?\)\?$')
  let list = []
  if a:cur_text =~ '[btwg]:\h\w*\.\%(\h\w*\%(()\?\)\?\)\?$'
    let list = has_key(s:global_candidates_list.dictionary_variables, var_name) ?
          \ values(s:global_candidates_list.dictionary_variables[var_name]) : []
  elseif a:cur_text =~ 's:\h\w*\.\%(\h\w*\%(()\?\)\?\)\?$'
    let list = values(get(s:get_cached_script_candidates().dictionary_variables,
          \ var_name, {}))
  endif

  return list
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#var(cur_text, complete_str) "{{{
  " Caching.
  if !has_key(s:global_candidates_list, 'variables')
    let s:global_candidates_list.variables =
          \ neocomplcache#pack_dictionary(
          \  s:get_variablelist(g:, 'g:') + s:get_variablelist(v:, 'v:'))
  endif

  if a:complete_str =~ '^[swtb]:'
    let list = values(s:get_cached_script_candidates().variables)
    if a:complete_str !~ '^s:'
      let prefix = matchstr(a:complete_str, '^[swtb]:')
      let list += s:get_variablelist(eval(prefix), prefix)
    endif
  elseif a:complete_str =~ '^[vg]:'
    let list = neocomplcache#dictionary_filter(
          \ s:global_candidates_list.variables, a:complete_str)
  else
    let list = s:get_local_variables()
  endif

  return list
endfunction"}}}
function! neocomplcache#sources#vim_complete#helper#expand(cur_text, complete_str) "{{{
  return s:make_completion_list(
        \ ['<cfile>', '<afile>', '<abuf>', '<amatch>',
        \  '<sfile>', '<cword>', '<cWORD>', '<client>'], '')
endfunction"}}}

function! s:get_local_variables() "{{{
  " Get local variable list.

  let keyword_dict = {}
  " Search function.
  let line_num = line('.') - 1
  let end_line = (line('.') > 100) ? line('.') - 100 : 1
  while line_num >= end_line
    let line = getline(line_num)
    if line =~ '\<endf\%[unction]\>'
      break
    elseif line =~ '\<fu\%[nction]!\?\s\+'
      " Get function arguments.
      call s:analyze_variable_line(line, keyword_dict)
      break
    endif

    let line_num -= 1
  endwhile
  let line_num += 1

  let end_line = line('.') - 1
  while line_num <= end_line
    let line = getline(line_num)

    if line =~ '\<\%(let\|for\)\s\+'
      if line =~ '\<\%(let\|for\)\s\+s:' &&
            \ has_key(s:script_candidates_list, bufnr('%'))
            \ && has_key(s:script_candidates_list[bufnr('%')], 'variables')
        let candidates_list = s:script_candidates_list[bufnr('%')].variables
      else
        let candidates_list = keyword_dict
      endif

      call s:analyze_variable_line(line, candidates_list)
    endif

    let line_num += 1
  endwhile

  return values(keyword_dict)
endfunction"}}}

function! s:get_cached_script_candidates() "{{{
  return has_key(s:script_candidates_list, bufnr('%')) && v:version > 700 ?
        \ s:script_candidates_list[bufnr('%')] : {
        \   'functions' : {}, 'variables' : {}, 'function_prototypes' : {}, 'dictionary_variables' : {} }
endfunction"}}}
function! s:get_script_candidates(bufnumber) "{{{
  " Get script candidate list.

  let function_dict = {}
  let variable_dict = {}
  let dictionary_variable_dict = {}
  let function_prototypes = {}
  let var_pattern = '\a:[[:alnum:]_:]*\.\h\w*\%(()\?\)\?'

  for line in getbufline(a:bufnumber, 1, '$')
    if line =~ '\<fu\%[nction]!\?\s\+s:'
      call s:analyze_function_line(line, function_dict, function_prototypes)
    elseif line =~ '\<let\s\+'
      " Get script variable.
      call s:analyze_variable_line(line, variable_dict)
    elseif line =~ var_pattern
      while line =~ var_pattern
        let var_name = matchstr(line, '\a:[[:alnum:]_:]*\ze\.\h\w*')
        let candidates_dict = dictionary_variable_dict
        if !has_key(candidates_dict, var_name)
          let candidates_dict[var_name] = {}
        endif

        call s:analyze_dictionary_variable_line(line, candidates_dict[var_name], var_name)

        let line = line[matchend(line, var_pattern) :]
      endwhile
    endif
  endfor

  return { 'functions' : function_dict, 'variables' : variable_dict,
        \ 'function_prototypes' : function_prototypes,
        \ 'dictionary_variables' : dictionary_variable_dict }
endfunction"}}}

function! s:caching_from_dict(dict_name, kind) "{{{
  let dict_files = split(globpath(&runtimepath,
        \ 'autoload/neocomplcache/sources/vim_complete/'.a:dict_name.'.dict'), '\n')
  if empty(dict_files)
    return []
  endif

  let keyword_pattern =
        \'^\%(-\h\w*\%(=\%(\h\w*\|[01*?+%]\)\?\)\?'.
        \'\|<\h[[:alnum:]_-]*>\?\|\h[[:alnum:]_:#\[]*\%([!\]]\+\|()\?\)\?\)'
  let keyword_list = []
  for line in readfile(dict_files[0])
    call add(keyword_list, {
          \ 'word' : substitute(matchstr(
          \       line, keyword_pattern), '[\[\]]', '', 'g'),
          \ 'kind' : a:kind, 'abbr' : line
          \})
  endfor

  return keyword_list
endfunction"}}}
function! s:caching_completion_from_dict(dict_name) "{{{
  let dict_files = split(globpath(&runtimepath,
        \ 'autoload/neocomplcache/sources/vim_complete/'.a:dict_name.'.dict'), '\n')
  if empty(dict_files)
    return {}
  endif

  let keyword_dict = {}
  for line in readfile(dict_files[0])
    let word = matchstr(line, '^[[:alnum:]_\[\]]\+')
    let completion = matchstr(line[len(word):], '\h\w*')
    if completion != ''
      if word =~ '\['
        let [word_head, word_tail] = split(word, '\[')
        let word_tail = ' ' . substitute(word_tail, '\]', '', '')
      else
        let word_head = word
        let word_tail = ' '
      endif

      for i in range(len(word_tail))
        let keyword_dict[word_head . word_tail[1:i]] = completion
      endfor
    endif
  endfor

  return keyword_dict
endfunction"}}}
function! s:caching_prototype_from_dict(dict_name) "{{{
  let dict_files = split(globpath(&runtimepath,
        \ 'autoload/neocomplcache/sources/vim_complete/'.a:dict_name.'.dict'), '\n')
  if empty(dict_files)
    return {}
  endif
  if a:dict_name == 'functions'
    let pattern = '^[[:alnum:]_]\+('
  else
    let pattern = '^[[:alnum:]_\[\](]\+'
  endif

  let keyword_dict = {}
  for line in readfile(dict_files[0])
    let word = matchstr(line, pattern)
    let rest = line[len(word):]
    if word =~ '\['
      let [word_head, word_tail] = split(word, '\[')
      let word_tail = ' ' . substitute(word_tail, '\]', '', '')
    else
      let word_head = word
      let word_tail = ' '
    endif

    for i in range(len(word_tail))
      let keyword_dict[word_head . word_tail[1:i]] = rest
    endfor
  endfor

  return keyword_dict
endfunction"}}}

function! s:get_cmdlist() "{{{
  " Get command list.
  redir => redir
  silent! command
  redir END

  let keyword_list = []
  let completions = [ 'augroup', 'buffer', 'behave',
        \ 'color', 'command', 'compiler', 'cscope',
        \ 'dir', 'environment', 'event', 'expression',
        \ 'file', 'file_in_path', 'filetype', 'function',
        \ 'help', 'highlight', 'history', 'locale',
        \ 'mapping', 'menu', 'option', 'shellcmd', 'sign',
        \ 'syntax', 'tag', 'tag_listfiles',
        \ 'var', 'custom', 'customlist' ]
  let command_prototypes = {}
  let command_completions = {}
  for line in split(redir, '\n')[1:]
    let word = matchstr(line, '\a\w*')

    " Analyze prototype.
    let end = matchend(line, '\a\w*')
    let args = matchstr(line, '[[:digit:]?+*]', end)
    if args != '0'
      let prototype = matchstr(line, '\a\w*', end)
      let found = 0
      for comp in completions
        if comp == prototype
          let command_completions[word] = prototype
          let found = 1

          break
        endif
      endfor

      if !found
        let prototype = 'arg'
      endif

      if args == '*'
        let prototype = '[' . prototype . '] ...'
      elseif args == '?'
        let prototype = '[' . prototype . ']'
      elseif args == '+'
        let prototype = prototype . ' ...'
      endif

      let command_prototypes[word] = ' ' . repeat(' ', 16 - len(word)) . prototype
    else
      let command_prototypes[word] = ''
    endif
    let prototype = command_prototypes[word]

    call add(keyword_list, {
          \ 'word' : word, 'abbr' : word . prototype,
          \ 'description' : word . prototype, 'kind' : 'c'
          \})
  endfor
  let s:global_candidates_list.command_prototypes = command_prototypes
  let s:global_candidates_list.command_completions = command_completions

  return keyword_list
endfunction"}}}
function! s:get_variablelist(dict, prefix) "{{{
  let kind_dict = ['0', '""', '()', '[]', '{}', '.', 'bool', 'null']
  return values(map(copy(a:dict), "{
        \ 'word' : a:prefix.v:key,
        \ 'kind' : get(kind_dict, type(v:val), '?'),
        \}"))
endfunction"}}}
function! s:get_functionlist() "{{{
  " Get function list.
  redir => redir
  silent! function
  redir END

  let keyword_dict = {}
  let function_prototypes = {}
  for line in split(redir, '\n')
    let line = line[9:]
    if line =~ '^<SNR>'
      continue
    endif
    let orig_line = line

    let word = matchstr(line, '\h[[:alnum:]_:#.]*()\?')
    if word != ''
      let keyword_dict[word] = {
            \ 'word' : word, 'abbr' : line,
            \ 'description' : line,
            \}

      let function_prototypes[word] = orig_line[len(word):]
    endif
  endfor

  let s:global_candidates_list.function_prototypes = function_prototypes

  return values(keyword_dict)
endfunction"}}}
function! s:get_augrouplist() "{{{
  " Get augroup list.
  redir => redir
  silent! augroup
  redir END

  let keyword_list = []
  for group in split(redir . ' END', '\s\|\n')
    call add(keyword_list, { 'word' : group })
  endfor
  return keyword_list
endfunction"}}}
function! s:get_mappinglist() "{{{
  " Get mapping list.
  redir => redir
  silent! map
  redir END

  let keyword_list = []
  for line in split(redir, '\n')
    let map = matchstr(line, '^\a*\s*\zs\S\+')
    if map !~ '^<' || map =~ '^<SNR>'
      continue
    endif
    call add(keyword_list, { 'word' : map })
  endfor
  return keyword_list
endfunction"}}}
function! s:get_envlist() "{{{
  " Get environment variable list.

  let keyword_list = []
  for line in split(system('set'), '\n')
    let word = '$' . toupper(matchstr(line, '^\h\w*'))
    call add(keyword_list, { 'word' : word, 'kind' : 'e' })
  endfor
  return keyword_list
endfunction"}}}
function! s:make_completion_list(list, kind) "{{{
  let list = []
  for item in a:list
    call add(list, { 'word' : item, 'kind' : a:kind })
  endfor

  return list
endfunction"}}}
function! s:analyze_function_line(line, keyword_dict, prototype) "{{{
  " Get script function.
  let line = substitute(matchstr(a:line, '\<fu\%[nction]!\?\s\+\zs.*)'), '".*$', '', '')
  let orig_line = line
  let word = matchstr(line, '^\h[[:alnum:]_:#.]*()\?')
  if word != '' && !has_key(a:keyword_dict, word) 
    let a:keyword_dict[word] = {
          \ 'word' : word, 'abbr' : line, 'kind' : 'f'
          \}
    let a:prototype[word] = orig_line[len(word):]
  endif
endfunction"}}}
function! s:analyze_variable_line(line, keyword_dict) "{{{
  if a:line =~ '\<\%(let\|for\)\s\+\a[[:alnum:]_:]*'
    " let var = pattern.
    let word = matchstr(a:line, '\<\%(let\|for\)\s\+\zs\a[[:alnum:]_:]*')
    let expression = matchstr(a:line, '\<let\s\+\a[[:alnum:]_:]*\s*=\s*\zs.*$')
    if !has_key(a:keyword_dict, word) 
      let a:keyword_dict[word] = {
            \ 'word' : word,
            \ 'kind' : s:get_variable_type(expression)
            \}
    elseif expression != '' && a:keyword_dict[word].kind == ''
      " Update kind.
      let a:keyword_dict[word].kind = s:get_variable_type(expression)
    endif
  elseif a:line =~ '\<\%(let\|for\)\s\+\[.\{-}\]'
    " let [var1, var2] = pattern.
    let words = split(matchstr(a:line,
          \'\<\%(let\|for\)\s\+\[\zs.\{-}\ze\]'), '[,[:space:]]\+')
      let expressions = split(matchstr(a:line,
            \'\<let\s\+\[.\{-}\]\s*=\s*\[\zs.\{-}\ze\]$'), '[,[:space:];]\+')

      let i = 0
      while i < len(words)
        let expression = get(expressions, i, '')
        let word = words[i]

        if !has_key(a:keyword_dict, word) 
          let a:keyword_dict[word] = {
                \ 'word' : word,
                \ 'kind' : s:get_variable_type(expression)
                \}
        elseif expression != '' && a:keyword_dict[word].kind == ''
          " Update kind.
          let a:keyword_dict[word].kind = s:get_variable_type(expression)
        endif

        let i += 1
      endwhile
    elseif a:line =~ '\<fu\%[nction]!\?\s\+'
      " Get function arguments.
      for arg in split(matchstr(a:line, '^[^(]*(\zs[^)]*'), '\s*,\s*')
        let word = 'a:' . (arg == '...' ?  '000' : arg)
        let a:keyword_dict[word] = {
              \ 'word' : word,
              \ 'kind' : (arg == '...' ?  '[]' : '')
              \}

      endfor
      if a:line =~ '\.\.\.)'
        " Extra arguments.
        for arg in range(5)
          let word = 'a:' . arg
          let a:keyword_dict[word] = {
                \ 'word' : word,
                \ 'kind' : (arg == 0 ?  '0' : '')
                \}
        endfor
      endif
    endif
endfunction"}}}
function! s:analyze_dictionary_variable_line(line, keyword_dict, var_name) "{{{
  let var_pattern = a:var_name.'\.\h\w*\%(()\?\)\?'
  let let_pattern = '\<let\s\+'.a:var_name.'\.\h\w*'
  let call_pattern = '\<call\s\+'.a:var_name.'\.\h\w*()\?'

  if a:line =~ let_pattern
    let word = matchstr(a:line, a:var_name.'\zs\.\h\w*')
    let expression = matchstr(a:line, let_pattern.'\s*=\zs.*$')
    let kind = ''
  elseif a:line =~ call_pattern
    let word = matchstr(a:line, a:var_name.'\zs\.\h\w*()\?')
    let kind = '()'
  else
    let word = matchstr(a:line, a:var_name.'\zs.\h\w*\%(()\?\)\?')
    let kind = s:get_variable_type(matchstr(a:line, a:var_name.'\.\h\w*\zs.*$'))
  endif

  if !has_key(a:keyword_dict, word)
    let a:keyword_dict[word] = { 'word' : word, 'kind' : kind }
  elseif kind != '' && a:keyword_dict[word].kind == ''
    " Update kind.
    let a:keyword_dict[word].kind = kind
  endif
endfunction"}}}
function! s:split_args(cur_text, complete_str) "{{{
  let args = split(a:cur_text)
  if a:complete_str == ''
    call add(args, '')
  endif

  return args
endfunction"}}}

" Initialize return types. "{{{
function! s:set_dictionary_helper(variable, keys, value) "{{{
  for key in split(a:keys, ',')
    let a:variable[key] = a:value
  endfor
endfunction"}}}
let s:function_return_types = {}
call neocomplcache#util#set_dictionary_helper(
      \ s:function_return_types,
      \ 'len,match,matchend',
      \ '0')
call neocomplcache#util#set_dictionary_helper(
      \ s:function_return_types,
      \ 'input,matchstr',
      \ '""')
call neocomplcache#util#set_dictionary_helper(
      \ s:function_return_types,
      \ 'expand,filter,sort,split',
      \ '[]')
"}}}
function! s:get_variable_type(expression) "{{{
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
    let func_name = matchstr(a:expression, '\<\zs\h\w*\ze(')
    return has_key(s:function_return_types, func_name) ? s:function_return_types[func_name] : ''
  else
    return ''
  endif
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
