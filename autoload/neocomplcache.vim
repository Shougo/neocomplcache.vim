"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 26 Oct 2009
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
" Version: 3.07, for Vim 7.0
"=============================================================================

function! neocomplcache#enable() "{{{
    augroup neocomplcache "{{{
        autocmd!
        " Auto complete events
        autocmd CursorHoldI * call s:complete()
        autocmd CursorMovedI * if neocomplcache#get_cur_text() =~ '\d$' | call s:complete()
        autocmd InsertEnter * call s:insert_enter()
        autocmd InsertLeave * call s:insert_leave()
    augroup END "}}}

    " Initialize"{{{
    let s:complete_lock = 0
    let s:old_text = ''
    let s:prev_numbered_list = []
    let s:prepre_numbered_list = []
    let s:skipped = 0
    let s:complfuncs_func_table = []
    let s:skip_next_complete = 0
    let s:cur_keyword_pos = -1
    let s:quickmatched = 0
    let s:prev_quickmatch_type = 'keyword_complete'
    let s:prepre_quickmatch_type = 'keyword_complete'
    let s:complete_words = []
    let s:cur_keyword_pos = -1
    let s:update_time = &updatetime
    "}}}
    
    " Initialize complfuncs table."{{{
    " Search autoload.
    let l:func_list = split(globpath(&runtimepath, 'autoload/neocomplcache/complfunc/*.vim'), '\n')
    for list in l:func_list
        let l:func_name = fnamemodify(list, ':t:r')
        if l:func_name != 'keyword_complete'
            call add(s:complfuncs_func_table, 'neocomplcache#complfunc#' . l:func_name . '#')
        endif
    endfor
    call add(s:complfuncs_func_table, 'neocomplcache#complfunc#keyword_complete#')
    "}}}

    " Initialize keyword pattern match like intellisense."{{{
    if !exists('g:NeoComplCache_KeywordPatterns')
        let g:NeoComplCache_KeywordPatterns = {}
    endif
    call s:set_keyword_pattern('default',
                \'\v\k+')
    call s:set_keyword_pattern('lisp,scheme', 
                \'\v\(?[[:alpha:]*@$%^&_=<>~.][[:alnum:]+*@$%^&_=<>~.-]*[!?]?')
    call s:set_keyword_pattern('ruby',
                \'\v^\=%(b%[egin]|e%[nd])|%(\@\@|[:$@])\h\w*|\h\w*%(::\h\w*)*[!?]?%(\s*%(%(\(\))?\s*%(do|\{)%(\s*\|)?|\(\)?))?')
    call s:set_keyword_pattern('eruby',
                \'\v\</?%([[:alnum:]_-]+\s*)?%(/?\>)?|%(\@\@|[:$@])\h\w*|\h\w*%(::\h\w*)*[!?]?%(\s*%(%(\(\))?\s*%(do|\{)%(\s*\|)?|\(\)?))?')
    call s:set_keyword_pattern('php',
                \'\v\</?%(\h[[:alnum:]_-]*\s*)?%(/?\>)?|\$\h\w*|\h\w*%(::\h\w*)*%(\s*\(\)?)?')
    call s:set_keyword_pattern('perl',
                \'\v\<\h\w*\>?|[$@%&*]\h\w*%(::\h\w*)*|\h\w*%(::\h\w*)*%(\s*\(\)?)?')
    call s:set_keyword_pattern('vim,help',
                \'\v\$\h\w*|\[:%(\h\w*:\])?|\<\h[[:alnum:]_-]*\>?|[&.]?\h[[:alnum:]_:]*%(#\h\w*)*%([!>]|\(\)?)?')
    call s:set_keyword_pattern('tex',
                \'\v\\\a\{\a{1,2}}|\\[[:alpha:]@][[:alnum:]@]*[[{]?|\a[[:alnum:]:]*[*[{]?')
    call s:set_keyword_pattern('sh,zsh',
                \'\v\$\w+|[[:alpha:]_.-][[:alnum:]_.-]*%(\s*\[|\s*\(\)?)?')
    call s:set_keyword_pattern('vimshell',
                \'\v\$\$?\w*|[[:alpha:]_.-][[:alnum:]_.-]*|\d+%(\.\d+)+')
    call s:set_keyword_pattern('ps1',
                \'\v\[\h%([[:alnum:]_.]*\]::)?|[$%@.]?[[:alpha:]_.:-][[:alnum:]_.:-]*%(\s*\(\)?)?')
    call s:set_keyword_pattern('c',
                \'\v^\s*#\s*\h\w*|\h\w*%(\s*\(\)?)?')
    call s:set_keyword_pattern('cpp',
                \'\v^\s*#\s*\h\w*|\h\w*%(::\h\w*)*%(\s*\(\)?|\<\>?)?')
    call s:set_keyword_pattern('objc',
                \'\v^\s*#\s*\h\w*|\h\w*%(\s*\(\)?|\<\>?|:)?|\@\h\w*%(\s*\(\)?)?|\(\h\w*\s*\*?\)?')
    call s:set_keyword_pattern('objcpp',
                \'\v^\s*#\s*\h\w*|\h\w*%(::\h\w*)*%(\s*\(\)?|\<\>?|:)?|\@\h\w*%(\s*\(\)?)?|\(\s*\h\w*\s*\*?\s*\)?')
    call s:set_keyword_pattern('d',
                \'\v\h\w*%(!?\s*\(\)?)?')
    call s:set_keyword_pattern('python',
                \'\v\h\w*%(\s*\(\)?)?')
    call s:set_keyword_pattern('cs',
                \'\v\h\w*%(\s*%(\(\)?|\<))?')
    call s:set_keyword_pattern('java',
                \'\v[@]?\h\w*%(\s*%(\(\)?|\<))?')
    call s:set_keyword_pattern('javascript,actionscript',
                \'\v\h\w*%(\s*\(\)?)?')
    call s:set_keyword_pattern('awk',
                \'\v\h\w*%(\s*\(\)?)?')
    call s:set_keyword_pattern('haskell',
                \'\v\h\w*['']?')
    call s:set_keyword_pattern('ocaml',
                \'\v[~]?[[:alpha:]_''][[:alnum:]_]*['']?')
    call s:set_keyword_pattern('erlang',
                \'\v^\s*-\h\w*[(]?|\h\w*%(:\h\w*)*%(\.|\(\)?)?')
    call s:set_keyword_pattern('html,xhtml,xml',
                \'\v[[:alnum:]_:-]*\>|\</?%([[:alnum:]_:-]+\s*)?%(/?\>)?|\&\h%(\w*;)?|\h[[:alnum:]_:-]*%(\=")?|\<[^>]+\>')
    call s:set_keyword_pattern('css',
                \'\v[[:alpha:]_-][[:alnum:]_-]*[:(]?|[@#:.][[:alpha:]_-][[:alnum:]_-]*')
    call s:set_keyword_pattern('tags',
                \'\v^[^!][^/[:blank:]]*')
    call s:set_keyword_pattern('pic',
                \'\v^\s*#\h\w*|\h\w*')
    call s:set_keyword_pattern('masm',
                \'\v\.\h\w*|[[:alpha:]_@?$][[:alnum:]_@?$]*')
    call s:set_keyword_pattern('nasm',
                \'\v^\s*\[\h\w*|[%.]?\h\w*|%(\.\.\@?|\%[%$!])%(\h\w*)?')
    call s:set_keyword_pattern('asm',
                \'\v[%$.]?\h\w*%(\$\h\w*)?')
    call s:set_keyword_pattern('make',
                \'\v[[:alpha:]_.-][[:alnum:]_.-]*')
    call s:set_keyword_pattern('scala',
                \'\v[.]?\h\w*%(\s*\(\)?|\[)?')
    "}}}

    " Initialize same file type lists."{{{
    if !exists('g:NeoComplCache_SameFileTypeLists')
        let g:NeoComplCache_SameFileTypeLists = {}
    endif
    call s:set_same_filetype('c', 'cpp')
    call s:set_same_filetype('cpp', 'c')
    call s:set_same_filetype('erb', 'ruby,html,xhtml')
    call s:set_same_filetype('html', 'xhtml')
    call s:set_same_filetype('xml', 'xhtml')
    call s:set_same_filetype('xhtml', 'html,xml')
    "}}}

    " Add commands."{{{
    command! -nargs=0 NeoComplCacheDisable call neocomplcache#disable()
    command! -nargs=0 Neco echo "   A A\n~(-'_'-)"
    command! -nargs=0 NeoComplCacheLock call s:lock()
    command! -nargs=0 NeoComplCacheUnlock call s:unlock()
    command! -nargs=0 NeoComplCacheToggle call s:toggle()
    command! -nargs=1 NeoComplCacheAutoCompletionLength let g:NeoComplCache_KeywordCompletionStartLength = <args>
    command! -nargs=1 NeoComplCachePartialCompletionLength let g:NeoComplCache_PartialCompletionStartLength = <args> 
    "}}}
    
    " Must g:NeoComplCache_StartCharLength > 1.
    if g:NeoComplCache_KeywordCompletionStartLength < 1
        g:NeoComplCache_KeywordCompletionStartLength = 1
    endif
    " Must g:NeoComplCache_MinKeywordLength > 1.
    if g:NeoComplCache_MinKeywordLength < 1
        g:NeoComplCache_MinKeywordLength = 1
    endif

    " Save options.
    let s:completefunc_save = &completefunc
    let s:completeopt_save = &completeopt

    " Set completefunc.
    let &completefunc = 'neocomplcache#manual_complete'
    let &l:completefunc = 'neocomplcache#manual_complete'

    " Set options.
    set completeopt-=menu,longest
    set completeopt+=menuone

    " Initialize.
    for l:complfunc in s:complfuncs_func_table
        call call(l:complfunc . 'initialize', [])
    endfor
endfunction"}}}

function! neocomplcache#disable()"{{{
    " Restore options.
    let &completefunc = s:completefunc_save
    let &completeopt = s:completeopt_save
    
    augroup neocomplcache
        autocmd!
    augroup END

    delcommand NeoComplCacheDisable
    delcommand Neco
    delcommand NeoComplCacheLock
    delcommand NeoComplCacheUnlock
    delcommand NeoComplCacheToggle
    delcommand NeoComplCacheAutoCompletionLength
    delcommand NeoComplCachePartialCompletionLength

    for l:complfunc in s:complfuncs_func_table
        call call(l:complfunc . 'finalize', [])
    endfor

    let s:prev_numbered_list = []
    let s:prepre_numbered_list = []
endfunction"}}}

" Complete functions."{{{
function! neocomplcache#manual_complete(findstart, base)"{{{
    if a:findstart
        if !neocomplcache#plugin#buffer_complete#exists_current_source()
            let s:complete_words = []
            return -1
        endif

        " Get cursor word.
        let l:cur_text = neocomplcache#get_cur_text()
        let l:pattern = '\v%(' .  neocomplcache#plugin#buffer_complete#current_keyword_pattern() . ')$'
        let l:cur_keyword_pos = match(l:cur_text, l:pattern)
        let l:cur_keyword_str = matchstr(l:cur_text, l:pattern)

        if g:NeoComplCache_EnableWildCard
            " Check wildcard.
            let [l:cur_keyword_pos, l:cur_keyword_str] = neocomplcache#complfunc#keyword_complete#check_wildcard(l:cur_text, l:pattern, l:cur_keyword_pos, l:cur_keyword_str)
        endif

        if len(l:cur_keyword_str) < g:NeoComplCache_ManualCompletionStartLength
            let s:complete_words = []
            return -1
        endif

        " Save option.
        let l:ignorecase_save = &ignorecase

        " Complete.
        if g:NeoComplCache_SmartCase && l:cur_keyword_str =~ '\u'
            let &ignorecase = 0
        else
            let &ignorecase = g:NeoComplCache_IgnoreCase
        endif

        let s:complete_words = neocomplcache#get_quickmatch_list(neocomplcache#complfunc#keyword_complete#get_complete_words(l:cur_keyword_pos, l:cur_keyword_str),
                \ l:cur_keyword_pos, l:cur_keyword_str, 'keyword_complete')
        let s:complete_words = neocomplcache#remove_next_keyword(s:complete_words)

        " Restore option.
        let &ignorecase = l:ignorecase_save
        
        return l:cur_keyword_pos
    endif

    if g:NeoComplCache_EnableInfo"{{{
        " Check preview window.
        silent! wincmd P
        if &previewwindow
            wincmd p
            setlocal completeopt+=preview
        else
            setlocal completeopt-=preview
        endif
    endif"}}}

    return s:complete_words
endfunction"}}}

function! neocomplcache#auto_complete(findstart, base)"{{{
    if a:findstart
        return s:cur_keyword_pos
    endif

    " Restore option.
    let &l:completefunc = 'neocomplcache#manual_complete'
    " Unlock auto complete.
    let s:complete_lock = 0

    if g:NeoComplCache_EnableInfo"{{{
        " Check preview window.
        silent! wincmd P
        if &previewwindow
            wincmd p
            setlocal completeopt+=preview
        else
            setlocal completeopt-=preview
        endif
    endif"}}}

    return s:complete_words
endfunction"}}}

" Plugin helper."{{{
function! neocomplcache#keyword_filter(list, cur_keyword_str)"{{{
    let l:keyword_escape = neocomplcache#keyword_escape(a:cur_keyword_str)

    if l:keyword_escape !~ '[^\\]*'
        " Use fast filter.
        if g:NeoComplCache_EnablePartialMatch && !s:skipped && len(a:cur_keyword_str) >= g:NeoComplCache_PartialCompletionStartLength
            " Partial match.
            return s:fast_partial_filter(a:list, a:cur_keyword_str)
        else
            " Head match.
            return s:fast_match_filter(a:list, a:cur_keyword_str)
        endif
    else
        " Keyword filter."{{{
        let l:cur_len = len(a:cur_keyword_str)
        if g:NeoComplCache_EnablePartialMatch && !s:skipped && len(a:cur_keyword_str) >= g:NeoComplCache_PartialCompletionStartLength
            " Partial match.
            " Filtering len(a:cur_keyword_str).
            let l:pattern = printf("len(v:val.word) > l:cur_len && v:val.word =~ %s", string(l:keyword_escape))
        else
            " Head match.
            " Filtering len(a:cur_keyword_str).
            let l:pattern = printf("len(v:val.word) > l:cur_len && v:val.word =~ %s", string('^' . l:keyword_escape))
        endif"}}}
        "echomsg l:pattern

        return filter(a:list, l:pattern)
    endif
endfunction"}}}
function! neocomplcache#keyword_escape(cur_keyword_str)"{{{
    " Escape."{{{
    let l:keyword_escape = escape(a:cur_keyword_str, '~" \.^$[]')
    if g:NeoComplCache_EnableWildCard
        let l:keyword_escape = substitute(substitute(l:keyword_escape, '.\zs\*', '.*', 'g'), '\%(^\|\*\)\zs\*', '\\*', 'g')
        if '-' !~ '\k'
            let l:keyword_escape = substitute(l:keyword_escape, '.\zs-', '.\\+', 'g')
        endif
    else
        let l:keyword_escape = escape(a:cur_keyword_str, '*')
    endif"}}}

    " Underbar completion."{{{
    if g:NeoComplCache_EnableUnderbarCompletion && l:keyword_escape =~ '_'
        let l:keyword_escape = substitute(l:keyword_escape, '[^_]\zs_', '[^_]*_', 'g')
    endif
    if g:NeoComplCache_EnableUnderbarCompletion && '-' =~ '\k' && l:keyword_escape =~ '-'
        let l:keyword_escape = substitute(l:keyword_escape, '[^-]\zs-', '[^-]*-', 'g')
    endif
    "}}}
    " Camel case completion."{{{
    if g:NeoComplCache_EnableCamelCaseCompletion && l:keyword_escape =~ '\u'
        let l:keyword_escape = substitute(l:keyword_escape, '\v\u?\zs\U*', '\\%(\0\\l*\\|\U\0\E\\u*_\\?\\)', 'g')
    endif
    "}}}

    "echo l:keyword_escape
    return l:keyword_escape
endfunction"}}}
function! neocomplcache#skipped()"{{{
    return s:skipped
endfunction"}}}

" RankOrder."{{{
function! neocomplcache#compare_rank(i1, i2)
    return a:i1.rank < a:i2.rank ? 1 : a:i1.rank == a:i2.rank ? 0 : -1
endfunction"}}}
" PreviousRankOrder."{{{
function! neocomplcache#compare_prev_rank(i1, i2)
    return a:i1.rank+a:i1.prev_rank < a:i2.rank+a:i2.prev_rank ? 1 :
                \a:i1.rank+a:i1.prev_rank == a:i2.rank+a:i2.prev_rank ? 0 : -1
endfunction"}}}
" AlphabeticalOrder."{{{
function! neocomplcache#compare_words(i1, i2)
    return a:i1.word > a:i2.word ? 1 : a:i1.word == a:i2.word ? 0 : -1
endfunction"}}}

function! neocomplcache#assume_buffer_pattern(bufname)"{{{
    let l:ft = getbufvar(a:bufname, '&filetype')
    if l:ft == ''
        let l:ft = 'nothing'
    endif

    if l:ft =~ '\.'
        " Composite filetypes.
        let l:keyword_array = []
        let l:keyword_default = 0
        for l:f in split(l:ft, '\.')
            if has_key(g:NeoComplCache_KeywordPatterns, l:f)
                call add(l:keyword_array, g:NeoComplCache_KeywordPatterns[l:f])
            elseif !l:keyword_default
                call add(l:keyword_array, g:NeoComplCache_KeywordPatterns['default'])
                let l:keyword_default = 1
            endif
        endfor
        let l:keyword_pattern = join(l:keyword_array, '|')
    else
        " Normal filetypes.
        if !has_key(g:NeoComplCache_KeywordPatterns, l:ft)
            let l:keyword_pattern = g:NeoComplCache_KeywordPatterns['default']
        else
            let l:keyword_pattern = g:NeoComplCache_KeywordPatterns[l:ft]
        endif
    endif
    return l:keyword_pattern
endfunction"}}}
function! neocomplcache#assume_pattern(bufname)"{{{
    " Extract extention.
    let l:ext = fnamemodify(a:bufname, ':e')
    if l:ext == ''
        let l:ext = fnamemodify(a:bufname, ':t')
    endif

    if has_key(g:NeoComplCache_NonBufferFileTypeDetect, l:ext)
        return g:NeoComplCache_NonBufferFileTypeDetect[l:ext]
    elseif has_key(g:NeoComplCache_KeywordPatterns, l:ext)
        return g:NeoComplCache_KeywordPatterns[l:ext]
    else
        " Not found.
        return ''
    endif
endfunction "}}}

function! neocomplcache#check_skip_time(start_time)"{{{
    if !g:NeoComplCache_EnableSkipCompletion || &l:completefunc != 'neocomplcache#auto_complete'
        return 0
    endif

    if substitute(reltimestr(reltime(a:start_time)), '^\s*', '', '') > g:NeoComplCache_SkipCompletionTime
        return 1
    else
        return 0
    endif
endfunction"}}}

let s:quickmatch_table = {
            \'0' : 0, '1' : 1, '2' : 2, '3' : 3, '4' : 4, '5' : 5, '6' : 6, '7' : 7, '8' : 8, '9' : 9
            \}
function! neocomplcache#get_quickmatch_list(list, cur_keyword_pos, cur_keyword_str, type)"{{{
    if !g:NeoComplCache_EnableQuickMatch
        let l:list = []
        for keyword in deepcopy(a:list[:g:NeoComplCache_MaxList])
            let keyword.abbr = substitute(keyword.abbr, '^\s*\d*: \|^    ', '', '')
            call add(l:list, keyword)
        endfor
        return l:list
    endif

    let l:list = deepcopy(a:list[: g:NeoComplCache_MaxList])

    if a:cur_keyword_str =~ '\d$'
        " Get numbered list."{{{
        let l:quick_key = a:cur_keyword_str[-1:]
        let l:num = s:quickmatch_table[l:quick_key]
        let l:numbered = get(s:prev_numbered_list, l:num)
        if type(l:numbered) == type({})
            " Set prefix.
            let l:prefix = ''
            if a:type != 'keyword_complete' && a:type != s:prev_quickmatch_type
                let l:cur_text = neocomplcache#get_cur_text()
                let l:quick_keyword_pos = call(a:type . 'get_keyword_pos', [l:cur_text])

                if l:quick_keyword_pos > a:cur_keyword_pos
                    let l:prefix = getline('.')[a:cur_keyword_pos : l:quick_keyword_pos-1]
                endif
            endif

            let l:numbered.word = l:prefix . l:numbered.word
            let l:numbered.abbr = l:prefix . substitute(l:numbered.abbr, '^\s*\d*: \|^    ', '', '')
            call insert(l:list, l:numbered)

            if g:NeoComplCache_EnableAutoSelect &&
                        \ a:cur_keyword_str !~# '^\d\+$' && len(a:cur_keyword_str) <= g:NeoComplCache_KeywordCompletionStartLength + 2
                        \&& len(s:prev_numbered_list) < l:num*10
                let s:quickmatched = 1
            endif
        endif"}}}
    endif

    " Get next numbered list."{{{
    if a:cur_keyword_str =~ '\d\d$'
        let l:num = str2nr(matchstr(a:cur_keyword_str, '\d\d$'))-len(s:quickmatch_table)
        if l:num >= 0
            unlet l:numbered
            let l:numbered = get(s:prepre_numbered_list, l:num)

            if type(l:numbered) == type({})
                " Set prefix.
                let l:prefix = ''
                if a:type != 'keyword_complete' && a:type != s:prev_quickmatch_type
                    let l:cur_text = neocomplcache#get_cur_text()
                    let l:quick_keyword_pos = call(a:type . 'get_keyword_pos', [l:cur_text])

                    if l:quick_keyword_pos > a:cur_keyword_pos
                        let l:prefix = getline('.')[a:cur_keyword_pos : l:quick_keyword_pos-1]
                    endif
                endif

                let l:numbered.word = l:prefix . l:numbered.word
                let l:numbered.abbr = l:prefix . substitute(l:numbered.abbr, '^\s*\d*: \|^    ', '', '')
                call insert(l:list, l:numbered)

                if g:NeoComplCache_EnableAutoSelect && len(a:cur_keyword_str) <= g:NeoComplCache_KeywordCompletionStartLength + 3
                    let s:quickmatched = 1
                endif
            endif
        endif
    endif"}}}

    " Create quickmatch abbr."{{{
    let l:qlist = []
    " Check dup."{{{
    let l:dup_check = {}
    let l:num = 0
    let l:numbered_ret = []
    for keyword in l:list[:100]
        if keyword.word != '' && !has_key(l:dup_check, keyword.word)
            let l:dup_check[keyword.word] = 1

            call add(l:numbered_ret, keyword)
        endif
        let l:num += 1
    endfor"}}}

    " Add number."{{{
    let l:num = 0
    for keyword in l:numbered_ret
        let keyword.abbr = printf('%2d: %s', l:num, substitute(keyword.abbr, '^\s*\d*: \|^    ', '', ''))
        let l:num += 1
    endfor
    for keyword in l:list[100 :]
        let keyword.abbr = '    ' . substitute(keyword.abbr, '^\s*\d*: \|^    ', '', '')
        call add(l:qlist, keyword)
    endfor"}}}

    " Append list.
    let l:qlist = l:numbered_ret + l:qlist

    " Save numbered lists.
    let s:prepre_numbered_list = s:prev_numbered_list[len(s:quickmatch_table) :]
    let s:prev_numbered_list = l:numbered_ret
    let s:prepre_quickmatch_type = s:prev_quickmatch_type
    let s:prev_quickmatch_type = a:type
    "}}}

    return l:qlist
endfunction"}}}

function! neocomplcache#start_manual_complete(complete_words, cur_keyword_pos, cur_keyword_str)"{{{
    let s:complete_words = a:complete_words
    let s:cur_keyword_pos = a:cur_keyword_pos
    let s:cur_keyword_str = a:cur_keyword_str
    let s:skipped = 0

    " Set function.
    let &l:completefunc = 'neocomplcache#auto_complete'

    return "\<C-x>\<C-u>\<C-p>"
endfunction"}}}

function! neocomplcache#remove_next_keyword(list)"{{{
    let l:list = a:list
    " Remove next keyword."{{{
    let l:next_keyword_str = matchstr('a'.getline('.')[col('.') - 1 :],
                \'\v^%(' . neocomplcache#plugin#buffer_complete#current_keyword_pattern() . ')')[1:]
    if l:next_keyword_str != ''
        let l:next_keyword_str = substitute(escape(l:next_keyword_str, '~" \.^$*[]'), "'", "''", 'g').'$'

        " No ignorecase.
        let l:save_ignorecase = &ignorecase
        let &ignorecase = 0
        let l:found = 0
        for r in l:list
            if r.word =~ l:next_keyword_str
                break
            endif

            let l:found += 1
        endfor

        if l:found < len(a:list)
            let l:list = deepcopy(a:list)
            for r in l:list[l:found :]
                if r.word =~ l:next_keyword_str
                    let r.word = r.word[: match(r.word, l:next_keyword_str)-1]
                    let r.dup = 1
                endif
            endfor
        endif
        let &ignorecase = l:save_ignorecase
    endif"}}}

    return l:list
endfunction"}}}

function! neocomplcache#caching_percent()"{{{
    return neocomplcache#plugin#buffer_complete#caching_percent("")
endfunction"}}}

function! neocomplcache#get_cur_text()"{{{
    let l:pos = mode() ==# 'i' ? 2 : 1

    return col('.') < l:pos ? '' : getline('.')[: col('.') - l:pos]
endfunction"}}}
"}}}

" Complete internal functions."{{{
function! s:complete()"{{{
    if !neocomplcache#plugin#buffer_complete#exists_current_source()
        let s:prev_numbered_list = []
        let s:prepre_numbered_list = []
        return
    endif

    if s:skip_next_complete
        let s:skip_next_complete = 0

        let s:prev_numbered_list = []
        let s:prepre_numbered_list = []
        return
    endif

    if pumvisible() || &paste || s:complete_lock || g:NeoComplCache_DisableAutoComplete
                \||(&l:completefunc != 'neocomplcache#manual_complete'
                    \&& &l:completefunc != 'neocomplcache#auto_complete')
        let s:prev_numbered_list = []
        let s:prepre_numbered_list = []
        return
    endif
    
    " Get cursor word.
    let l:cur_text = neocomplcache#get_cur_text()
    " Prevent infinity loop.
    " Not complete multi byte character for ATOK X3.
    if l:cur_text == s:old_text || l:cur_text == '' || char2nr(l:cur_text[-1]) >= 0x80
        let s:prev_numbered_list = []
        let s:prepre_numbered_list = []
        return
    endif
    
    let s:old_text = l:cur_text

    " Set function.
    let &l:completefunc = 'neocomplcache#auto_complete'
    " Try complfuncs completion."{{{
    let l:pattern = '\v%(' .  neocomplcache#plugin#buffer_complete#current_keyword_pattern() . ')$'
    let l:cur_keyword_pos = match(l:cur_text, l:pattern)
    let l:cur_keyword_str = matchstr(l:cur_text, l:pattern)
    let l:complete_words = []
    let s:skipped = 0
    for l:complfunc in s:complfuncs_func_table
        let l:keyword_pos = call(l:complfunc . 'get_keyword_pos', [l:cur_text])

        if l:keyword_pos >= 0 &&
                    \(l:cur_keyword_pos == -1 || l:cur_keyword_pos == l:keyword_pos)
            let l:keyword_str = l:cur_text[l:keyword_pos :]

            " Save options.
            let l:ignorecase_save = &ignorecase

            if g:NeoComplCache_SmartCase && l:keyword_str =~ '\u'
                let &ignorecase = 0
            else
                let &ignorecase = g:NeoComplCache_IgnoreCase
            endif

            let l:words = call(l:complfunc . 'get_complete_words', [l:keyword_pos, l:keyword_str])

            let &ignorecase = l:ignorecase_save

            if !empty(l:words)
                let l:complete_words += neocomplcache#remove_next_keyword(l:words)
                let l:cur_keyword_pos = l:keyword_pos
                let l:cur_keyword_str = l:keyword_str

                let s:prepre_quickmatch_type = s:prev_quickmatch_type
                let s:prev_quickmatch_type = l:complfunc
            endif

            if s:skipped
                let s:prev_numbered_list = []
                let s:prepre_numbered_list = []
                return
            endif
        endif
    endfor
    "}}}
    
    let l:complete_words = neocomplcache#get_quickmatch_list(l:complete_words, l:cur_keyword_pos, l:cur_keyword_str, l:complfunc)
    if empty(l:complete_words)
        return
    endif

    " Start auto complete.
    let s:cur_keyword_pos = l:cur_keyword_pos
    let s:cur_keyword_str = l:cur_keyword_str
    let s:complete_words = l:complete_words

    " Reset quick match flag.
    let s:quickmatched = 0

    if s:quickmatched && len(s:complete_words) == 1
        call feedkeys("\<C-x>\<C-u>", 'n')
    else
        call feedkeys("\<C-x>\<C-u>\<C-p>", 'n')
    endif
endfunction"}}}

" Fast filters.
function! s:fast_partial_filter(list, cur_keyword_str)"{{{
    let l:cur_keyword = a:cur_keyword_str

    let l:cur_len = len(l:cur_keyword)
    let l:ret = []
    if &ignorecase
        let l:cur_keyword = tolower(l:cur_keyword)
        for keyword in a:list
            if len(keyword.word) > l:cur_len && stridx(tolower(keyword.word), l:cur_keyword) != -1
                call add(l:ret, keyword)
            endif
        endfor
    else
        for keyword in a:list
            if len(keyword.word) > l:cur_len && stridx(keyword.word, l:cur_keyword) != -1
                call add(l:ret, keyword)
            endif
        endfor
    endif

    return ret
endfunction"}}}
function! s:fast_match_filter(list, cur_keyword_str)"{{{
    let l:cur_keyword = substitute(a:cur_keyword_str, '\\\zs.', '\0', 'g')

    let l:cur_len = len(l:cur_keyword)
    let l:cur_max = l:cur_len - 1
    let l:ret = []
    if &ignorecase
        let l:cur_keyword = tolower(l:cur_keyword)
        for keyword in a:list
            if len(keyword.word) > l:cur_len && l:cur_keyword == tolower(keyword.word[: l:cur_max])
                call add(l:ret, keyword)
            endif
        endfor
    else
        for keyword in a:list
            if len(keyword.word) > l:cur_len && l:cur_keyword == keyword.word[: l:cur_max] 
                call add(l:ret, keyword)
            endif
        endfor
    endif

    return ret
endfunction"}}}
"}}}

" Set pattern helper."{{{
function! s:set_keyword_pattern(filetype, pattern)"{{{
    for ft in split(a:filetype, ',')
        if !has_key(g:NeoComplCache_KeywordPatterns, ft) 
            let g:NeoComplCache_KeywordPatterns[ft] = a:pattern
        endif
    endfor
endfunction"}}}
function! s:set_same_filetype(filetype, pattern)"{{{
    if !has_key(g:NeoComplCache_SameFileTypeLists, a:filetype) 
        let g:NeoComplCache_SameFileTypeLists[a:filetype] = a:pattern
    endif
endfunction"}}}
"}}}

" Command functions."{{{
function! s:toggle()"{{{
    if &l:completefunc == 'neocomplcache#manual_complete'
        call s:lock()
    else
        call s:unlock()
    endif
endfunction"}}}

function! s:lock()"{{{
    let s:complete_lock = 1
endfunction"}}}

function! s:unlock()"{{{
    let s:complete_lock = 0
endfunction"}}}
"}}}

" Key mapping functions."{{{
function! neocomplcache#close_popup()"{{{
    if !exists(':NeoComplCacheDisable')
        return ''
    endif

    let s:old_text = getline('.')[: col('.')-2]

    if neocomplcache#plugin#buffer_complete#exists_current_source()
        let l:pattern = '\v%(' .  neocomplcache#plugin#buffer_complete#current_keyword_pattern() . ')$'
        call neocomplcache#plugin#buffer_complete#caching_keyword(matchstr(s:old_text, l:pattern))
    endif

    let s:prev_numbered_list = []
    let s:prepre_numbered_list = []

    return "\<C-y>"
endfunction
"}}}

function! neocomplcache#cancel_popup()"{{{
    if !exists(':NeoComplCacheDisable')
        return ''
    endif

    let s:skip_next_complete = 1
    let s:prev_numbered_list = []
    let s:prepre_numbered_list = []

    return "\<C-e>"
endfunction"}}}

function! neocomplcache#manual_filename_complete()"{{{
    return neocomplcache#complfunc#filename_complete#manual_complete()
endfunction"}}}

function! neocomplcache#manual_omni_complete()"{{{
    return neocomplcache#complfunc#omni_complete#manual_complete()
endfunction"}}}

function! neocomplcache#undo_completion()"{{{
    if !exists(':NeoComplCacheDisable')
        return ''
    endif

    " Get cursor word.
    let l:cur_text = neocomplcache#get_cur_text()

    if !neocomplcache#plugin#buffer_complete#exists_current_source()
        return ''
    endif

    let l:pattern = '\v%(' .  neocomplcache#plugin#buffer_complete#current_keyword_pattern() . ')$'
    let l:cur_keyword_str = matchstr(l:cur_text, l:pattern)
    let l:old_keyword_str = s:cur_keyword_str
    let s:cur_keyword_str = l:cur_keyword_str

    let s:skip_next_complete = 1

    return (pumvisible() ? "\<C-e>" : '')
                \ . repeat("\<BS>", len(l:cur_keyword_str)) . l:old_keyword_str
endfunction"}}}
"}}}

" Event functions."{{{
function! s:insert_enter()"{{{
    let s:update_time = &updatetime
    set updatetime=200
endfunction"}}}
function! s:insert_leave()"{{{
    let s:old_text = ''
    let s:prev_numbered_list = []
    let s:prepre_numbered_list = []
    let s:skipped = 0
    let s:skip_next_complete = 0
    let &updatetime = s:update_time
endfunction"}}}
"}}}

" vim: foldmethod=marker
