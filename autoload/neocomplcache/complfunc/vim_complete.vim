"=============================================================================
" FILE: vim_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 11 Jun 2010
" Usage: Just source this file.
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
" Version: 1.08, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.08:
"    - Fixed functions_prototype bug.
"
"   1.07:
"    - Improved analyzing extra args.
"    - Fixed analyzing bug.
"
"   1.06:
"    - Implemented no options.
"    - Fixed nobuflisted buffer error.
"
"   1.05:
"    - Changed for neocomplcache 4.0.
"    - Improved complete option.
"    - Improved print prototype.
"
"   1.04:
"    - Implemented environment variable completion.
"    - Supported wildcard.
"
"   1.03:
"    - Become complfunc.
"    - Don't complete within comment.
"    - Improved global caching.
"
"   1.02:
"    - Implemented intellisense like prototype echo.
"    - Display kind.
"
"   1.01:
"    - Poweruped.
"    - Supported backslash.
"
"   1.00:
"    - Initial version.
" }}}
"-----------------------------------------------------------------------------
" TODO: "{{{
"     - Nothing.
""}}}
" Bugs"{{{
"     - Nothing.
""}}}
"=============================================================================

function! neocomplcache#complfunc#vim_complete#initialize()"{{{
    " Initialize.
    let s:internal_candidates_list = {}
    let s:global_candidates_list = {}
    let s:script_candidates_list = {}
    let s:local_candidates_list = {}
    let s:completion_length = neocomplcache#get_completion_length('vim_complete')

    " Set caching event.
    autocmd neocomplcache FileType vim call s:script_caching_check()

    " Add command.
    command! -nargs=? -complete=buffer NeoComplCacheCachingVim call s:recaching(<q-args>)
endfunction"}}}

function! neocomplcache#complfunc#vim_complete#finalize()"{{{
    delcommand NeoComplCacheCachingVim
endfunction"}}}

function! neocomplcache#complfunc#vim_complete#get_keyword_pos(cur_text)"{{{
    if &filetype != 'vim' || empty(s:global_candidates_list)
        return -1
    endif

    let l:cur_text = a:cur_text
    let l:line = line('%')
    while l:cur_text =~ '^\s*\\' && l:line > 1
        let l:cur_text = getline(l:line - 1) . substitute(l:cur_text, '^\s*\\', '', '')
        let l:line -= 1
    endwhile

    if l:cur_text =~ '^\s*"'
        " Comment.
        return -1
    endif
    
    if g:NeoComplCache_EnableDispalyParameter"{{{
        " Echo prototype.
        let l:script_candidates_list = has_key(s:script_candidates_list, bufnr('%')) ?
                    \ s:script_candidates_list[bufnr('%')] : { 'functions' : [], 'variables' : [], 'functions_prototype' : {} }
        
        let l:prototype_name = matchstr(l:cur_text, 
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
            let l:prototype_name = matchstr(l:cur_text, '\<\h\w*')
            if has_key(s:internal_candidates_list.commands_prototype, l:prototype_name)
                echo s:internal_candidates_list.commands_prototype[l:prototype_name]
            elseif has_key(s:global_candidates_list.commands_prototype, l:prototype_name)
                echo s:global_candidates_list.commands_prototype[l:prototype_name]
            endif
        endif
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
    if &l:completefunc != 'neocomplcache#manual_complete'
                \&& a:cur_keyword_str != '.' && len(a:cur_keyword_str) < s:completion_length
        return []
    endif
    
    let l:script_candidates_list = has_key(s:script_candidates_list, bufnr('%')) ?
                \ s:script_candidates_list[bufnr('%')] : { 'functions' : [], 'variables' : [], 'functions_prototype' : {} }

    let l:list = []
    
    let l:cur_text = neocomplcache#get_cur_text()
    let l:line = line('%')
    while l:cur_text =~ '^\s*\\' && l:line > 1
        let l:cur_text = getline(l:line - 1) . substitute(l:cur_text, '^\s*\\', '', '')
        let l:line -= 1
    endwhile

    let l:script_candidates_list = has_key(s:script_candidates_list, bufnr('%')) ?
                \ s:script_candidates_list[bufnr('%')] : { 'functions' : [], 'variables' : [] }

    if a:cur_keyword_str == '.'
        " Dictionary.
        return []
    endif

    let l:prev_word = neocomplcache#get_prev_word(a:cur_keyword_str)
    if l:prev_word =~ '^\%(setl\%[ocal]\|setg\%[lobal]\|set\)$'
        let l:list += s:internal_candidates_list.options
    elseif a:cur_keyword_str =~ '^&\%([gl]:\)\?'
        let l:prefix = matchstr(a:cur_keyword_str, '&\%([gl]:\)\?')
        let l:options = deepcopy(s:internal_candidates_list.options)
        for l:keyword in l:options
            let l:keyword.word = l:prefix . l:keyword.word
            let l:keyword.abbr = l:prefix . l:keyword.abbr
        endfor
        let l:list += l:options
    elseif l:cur_text =~ '\<has(''\h\w*$'
        let l:list += s:internal_candidates_list.features
    elseif l:cur_text =~ '\<\%(map\|cm\%[ap]\|cno\%[remap]\|im\%[ap]\|ino\%[remap]\|lm\%[ap]\|ln\%[oremap]\|nm\%[ap]\|nn\%[oremap]\|no\%[remap]\|om\%[ap]\|ono\%[remap]\|smap\|snor\%[emap]\|vm\%[ap]\|vn\%[oremap]\|xm\%[ap]\|xn\%[oremap]\)\>'
        let l:list += s:internal_candidates_list.mappings
        let l:list += s:global_candidates_list.mappings
    elseif l:cur_text =~ '\<au\%[tocmd]!\?'
        let l:list += s:internal_candidates_list.autocmds
        let l:list += s:global_candidates_list.augroups
    elseif l:cur_text =~ '\<aug\%[roup]'
        let l:list += s:global_candidates_list.augroups
    elseif l:cur_text =~ '\<com\%[mand]!\?'
        let l:list += s:internal_candidates_list.command_args
        let l:list += s:internal_candidates_list.command_replaces
    elseif l:cur_text =~ '^\$'
        let l:list += s:global_candidates_list.environments
    endif
    
    if l:cur_text =~ '\%(^\||sil\%[ent]!\?\)\s*\h\w*$'
        let l:list += s:internal_candidates_list.commands
        let l:list += s:global_candidates_list.commands
        
        if a:cur_keyword_str =~ '^en\%[d]'
            let l:list += s:get_endlist()
        endif
    else
        if l:cur_text !~ '\<let\s\+\a[[:alnum:]_:]*$'
            " Functions.
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
        endif
        
        if l:cur_text !~ '\<call\s\+\%(<[sS][iI][dD]>\|[sSgGbBwWtTlL]:\)\=\%(\i\|[#.]\|{.\{-1,}}\)*\s*(\?$'
            " Variables.
            if a:cur_keyword_str =~ '^s:'
                let l:list += l:script_candidates_list.variables
            elseif a:cur_keyword_str =~ '^\a:'
                let l:list += s:global_candidates_list.variables
            endif

            let s:local_candidates_list = s:get_local_candidates()
            let l:list += s:local_candidates_list.variables
        endif
    endif

    return neocomplcache#keyword_filter(l:list, a:cur_keyword_str)
endfunction"}}}

function! neocomplcache#complfunc#vim_complete#get_rank()"{{{
    return 20
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
function! s:script_caching_check()"{{{
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
function! s:recaching(bufname)"{{{
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

function! s:get_local_candidates()"{{{
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
            let l:word = matchstr(l:line, '\<\%(let\|for\)\s\+\zs\a[[:alnum:]_:]*')
            if !has_key(l:keyword_dict, l:word) 
                let l:expression = matchstr(l:line, 
                            \'\<let\s\+\a[[:alnum:]_:]*\s*=\zs.*$')
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

    return { 'variables' : values(l:keyword_dict) }
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
        let l:word = matchstr(line, l:keyword_pattern)
        if len(l:word) > s:completion_length
            let l:keyword =  {
                        \ 'word' : l:word, 'menu' : l:menu_pattern, 'icase' : 1, 'kind' : a:kind
                        \}
            let l:keyword.abbr =  (len(line) > g:NeoComplCache_MaxKeywordWidth)? 
                        \ printf(l:abbr_pattern, line, line[-8:]) : line

            call add(l:keyword_list, l:keyword)
        endif
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
