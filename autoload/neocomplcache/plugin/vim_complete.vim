"=============================================================================
" FILE: vim_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 20 Nov 2009
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
" Version: 1.00, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
"   1.01:
"    - Poweruped.
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

function! neocomplcache#plugin#vim_complete#initialize()"{{{
    " Initialize.
    let s:internal_candidates_list = {}
    let s:user_candidates_list = {}
    let s:completion_length = neocomplcache#get_completion_length('vim_complete')
    
    " Set caching event.
    autocmd neocomplcache FileType vim call s:caching(0)

    " Add command.
    command! NeoComplCacheCachingVim call s:caching(1)
endfunction"}}}

function! neocomplcache#plugin#vim_complete#finalize()"{{{
    delcommand NeoComplCacheCachingVim
endfunction"}}}

function! neocomplcache#plugin#vim_complete#get_keyword_list(cur_keyword_str)"{{{
    if &filetype != 'vim'
        return []
    endif

    let l:list = []
    let l:cur_text = neocomplcache#get_cur_text()

    if l:cur_text =~ '\<\%(setl\%[ocal]\|setg\%[lobal]\|set\)\>'
        let l:list += s:internal_candidates_list['options']
    elseif a:cur_keyword_str =~ '^&\%([gl]:\)\?'
        let l:prefix = matchstr(a:cur_keyword_str, '&\%([gl]:\)\?')
        let l:options = deepcopy(s:internal_candidates_list['options'])
        for l:option in l:options
            let l:option.word = l:prefix . l:option.word
            let l:option.abbr = l:prefix . l:option.abbr
        endfor
        let l:list += l:options
    endif
    
    if l:cur_text =~ '\<has(''\h\w*$'
        let l:list += s:internal_candidates_list['features']
    endif
    if l:cur_text =~ '\<map\|cm[ap]\|cno[remap]\|im[ap]\|ino[remap]\|lm[ap]\|ln[oremap]\|nm[ap]\|nn[oremap]\|no[remap]\|om[ap]\|ono[remap]\|smap\|snor[emap]\|vm[ap]\|vn[oremap]\|xm[ap]\|xn[oremap]\>'
        let l:list += s:internal_candidates_list['mappings']
    endif
    if l:cur_text =~ '\<autocmd!\?\>'
        let l:list += s:internal_candidates_list['autocmds']
    endif
    if l:cur_text =~ '\<autocmd!\?\s*\h\w*$'
        let l:list += s:user_candidates_list['augroups']
    endif
    if l:cur_text =~ '\<command!\?\>'
        let l:list += s:internal_candidates_list['commands_args']
        let l:list += s:internal_candidates_list['commands_replaces']
    endif
    if l:cur_text =~ '\%(^\||silent!\?\)\s*\h\w*$'
        let l:list += s:internal_candidates_list['commands']
        let l:list += s:user_candidates_list['commands']
    else
        let l:list += s:internal_candidates_list['functions']
        let l:list += s:user_candidates_list['functions']
        if a:cur_keyword_str =~ '^\a:'
            let l:list += s:user_candidates_list['variables']
        endif
    endif

    return neocomplcache#keyword_filter(l:list, a:cur_keyword_str)
endfunction"}}}

" Dummy function.
function! neocomplcache#plugin#vim_complete#calc_rank(cache_keyword_buffer_list)"{{{
    return
endfunction"}}}
function! neocomplcache#plugin#vim_complete#calc_prev_rank(cache_keyword_buffer_list, prev_word, prepre_word)"{{{
endfunction"}}}

function! s:caching(force)"{{{
    " Caching.
    if !empty(s:internal_candidates_list) && !a:force
        return
    endif

    let s:user_candidates_list['commands'] = s:get_cmdlist()
    let s:user_candidates_list['variables'] = s:get_variablelist()
    let s:user_candidates_list['functions'] = s:get_functionlist()
    let s:user_candidates_list['augroups'] = s:get_augrouplist()
    
    if g:NeoComplCache_CachingPercentInStatusline
        let l:statusline_save = &l:statusline
        let &l:statusline = 'Caching vim from dictionary ... please wait.'
        redrawstatus
    else
        redraw
        echo 'Caching vim from dictionary ... please wait.'
    endif

    let s:internal_candidates_list['functions'] = s:caching_from_dict('functions', 'f')
    let s:internal_candidates_list['options'] = s:caching_from_dict('options', 'o')
    let s:internal_candidates_list['features'] = s:caching_from_dict('features', '')
    let s:internal_candidates_list['mappings'] = s:caching_from_dict('mappings', '')
    let s:internal_candidates_list['commands'] = s:caching_from_dict('commands', 'c')
    let s:internal_candidates_list['command_args'] = s:caching_from_dict('commands_args', '')
    let s:internal_candidates_list['autocmds'] = s:caching_from_dict('autocmds', '')
    let s:internal_candidates_list['commands_replaces'] = s:caching_from_dict('commands_replaces', '')
    
    if g:NeoComplCache_CachingPercentInStatusline
        let &l:statusline = l:statusline_save
        redrawstatus
    else
        redraw
        echo ''
        redraw
    endif
endfunction"}}}

function! s:caching_from_dict(dict_name, kind)"{{{
    let l:dict_files = split(globpath(&runtimepath, 'autoload/neocomplcache/plugin/vim_complete/'.a:dict_name.'.dict'), '\n')
    if empty(l:dict_files)
        return []
    endif

    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:menu_pattern = '[V] '.a:dict_name[: -2]
    let l:keyword_pattern = '^\v%('.neocomplcache#get_keyword_pattern().')'
    let l:keyword_list = []
    for line in readfile(l:dict_files[-1])
        let l:word = matchstr(line, l:keyword_pattern)
        if len(l:word) > s:completion_length
            let l:keyword =  {
                        \ 'word' : l:word, 'menu' : l:menu_pattern, 'icase' : 1,
                        \ 'kind' : a:kind, 
                        \ 'rank' : 10, 'prev_rank' : 10, 'prepre_rank' : 10
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
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:menu_pattern = '[V] command'
    for line in split(l:redir, '\n')[1:]
        let l:word = matchstr(line, '\a\w*')
        let l:keyword =  {
                    \ 'word' : l:word, 'menu' : l:menu_pattern, 'icase' : 1, 'kind' : 'c', 
                    \ 'rank' : 10, 'prev_rank' : 10, 'prepre_rank' : 10
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
    for line in split(l:redir, '\n')
        let l:word = matchstr(line, '^\a[[:alnum:]_:]*')
        if l:word !~ '^\a:'
            let l:word = 'g:' . l:word
        endif
        let l:keyword =  {
                    \ 'word' : l:word, 'menu' : l:menu_pattern, 'icase' : 1,
                    \ 'rank' : 10, 'prev_rank' : 10, 'prepre_rank' : 10
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
    let l:abbr_pattern = printf('%%.%ds..%%s', g:NeoComplCache_MaxKeywordWidth-10)
    let l:menu_pattern = '[V] function'
    let l:keyword_pattern = '^\v%('.neocomplcache#get_keyword_pattern().')'
    for l:line in split(l:redir, '\n')
        let l:line = l:line[9:]
        let l:word = matchstr(l:line, neocomplcache#get_keyword_pattern())
        if l:word =~ '^<SNR>\d\+_'
            continue
        endif
        let l:keyword =  {
                    \ 'word' : l:word, 'menu' : l:menu_pattern, 'icase' : 1,
                    \ 'rank' : 10, 'prev_rank' : 10, 'prepre_rank' : 10
                    \}
            let l:keyword.abbr =  (len(l:line) > g:NeoComplCache_MaxKeywordWidth)? 
                        \ printf(l:abbr_pattern, l:line, l:line[-8:]) : l:line

        call add(l:keyword_list, l:keyword)
    endfor
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
                    \ 'word' : l:group, 'menu' : l:menu_pattern, 'icase' : 1,
                    \ 'rank' : 10, 'prev_rank' : 10, 'prepre_rank' : 10
                    \}
            let l:keyword.abbr =  (len(l:group) > g:NeoComplCache_MaxKeywordWidth)? 
                        \ printf(l:abbr_pattern, l:group, l:group[-8:]) : l:group

        call add(l:keyword_list, l:keyword)
    endfor
    return l:keyword_list
endfunction"}}}
" vim: foldmethod=marker
