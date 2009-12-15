"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 14 Dec 2009
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
" Version: 4.02, for Vim 7.0
"=============================================================================

function! neocomplcache#enable() "{{{
    augroup neocomplcache "{{{
        autocmd!
        " Auto complete events
        autocmd CursorMovedI * call s:complete()
        autocmd InsertLeave * call s:insert_leave()
    augroup END "}}}

    " Initialize"{{{
    let s:complete_lock = {}
    let s:old_text = ''
    let s:skipped = 0
    let s:complfuncs_func_table = []
    let s:global_complfuncs = {}
    let s:skip_next_complete = 0
    let s:cur_keyword_pos = -1
    let s:cur_keyword_str = ''
    let s:complete_words = []
    let s:update_time = &updatetime
    let s:prev_numbered_list = []
    let s:cur_text = ''
    let s:start_time = reltime()
    "}}}
    
    " Initialize complfuncs table."{{{
    " Search autoload.
    let l:func_list = split(globpath(&runtimepath, 'autoload/neocomplcache/complfunc/*.vim'), '\n')
    for list in l:func_list
        let l:func_name = fnamemodify(list, ':t:r')
        if !has_key(g:NeoComplCache_DisablePluginList, l:func_name) || 
                    \ g:NeoComplCache_DisablePluginList[l:func_name] == 0
            let s:global_complfuncs[l:func_name] = 'neocomplcache#complfunc#' . l:func_name . '#'
        endif
    endfor
    "}}}

    " Initialize keyword patterns."{{{
    if !exists('g:NeoComplCache_KeywordPatterns')
        let g:NeoComplCache_KeywordPatterns = {}
    endif
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'default',
                \'\k\+')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'filename',
                \'[~]\?\%(\\[^[:alnum:].-]\|\f\|\*\)\+')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'lisp,scheme', 
                \'(\?[[:alpha:]*@$%^&_=<>~.][[:alnum:]+*@$%^&_=<>~.-]*[!?]\?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'ruby',
                \'^=\%(b\%[egin]\|e\%[nd]\)\|\%(@@\|[:$@]\)\h\w*\|\%(\.\|\%(\h\w*::\)\+\)\?\h\w*[!?]\?\%(\s*\%(\%(()\)\?\s*\%(do\|{\)\%(\s*|\)\?\|()\?\)\)\?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'eruby',
                \'\v\</?%([[:alnum:]_-]+\s*)?%(/?\>)?|%(\@\@|[:$@])\h\w*|%(\.|%(\h\w*::)+)?\h\w*[!?]?%(\s*%(%(\(\))?\s*%(do|\{)%(\s*\|)?|\(\)?))?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'php',
                \'</\?\%(\h[[:alnum:]_-]*\s*\)\?\%(/\?>\)\?\|\$\h\w*\|->\(\h\w*\%(\s*()\?\)\?\)\?\|\%(\h\w*::\)*\h\w*\%(\s*()\?\)\?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'perl',
                \'<\h\w*>\?\|[$@%&*]\h\w*\|\h\w*\%(::\h\w*\)*\%(\s*()\?\)\?\|->\h\w*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'perl6',
                \'<\h\w*>\?\|[$@%&][!.*?]\?\h\w*\|\h\w*\%(::\h\w*\)*\%(\s*()\?\)\?\|\.\h\w*\%(()\?\)\?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'vim,help',
                \'\[:\%(\h\w*:\]\)\?\|&\h[[:alnum:]_:]*\|\$\h\w*\|-\h\w*=\?\|<\h[[:alnum:]_-]*>\?\|\.\h\w*\%(()\?\)\?\|\h[[:alnum:]_:]*\%(#\h\w*\)*\%(!\|()\?\)\?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'tex',
                \'\\\a{\a\{1,2}}\|\\[[:alpha:]@][[:alnum:]@]*\%({\%(\h\w*\*\?}\?\)\?\)\?\|\a[[:alnum:]:]*\*\?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'sh,zsh',
                \'\v\$\w+|[[:alpha:]_.-][[:alnum:]_.-]*%(\s*\[|\s*\(\)?)?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'vimshell',
                \'\v\$\$?\w*|[[:alpha:]_.-][[:alnum:]_.-]*|\d+%(\.\d+)+')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'ps1',
                \'\v\[\h%([[:alnum:]_.]*\]::)?|[$%@.]?[[:alpha:]_.:-][[:alnum:]_.:-]*%(\s*\(\)?)?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'c',
                \'\v^\s*#\s*\h\w*|%(\.|-\>)?\h\w*%(\s*\(\)?)?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'cpp',
                \'\v^\s*#\s*\h\w*|%(\.|-\>|%(\h\w*::)+)?\h\w*%(\s*\(\)?|\<\>?)?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'objc',
                \'\v^\s*#\s*\h\w*|%(\.|-\>)?\h\w*%(\s*\(\)?|\<\>?|:)?|\@\h\w*%(\s*\(\)?)?|\(\h\w*\s*\*?\)?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'objcpp',
                \'\v^\s*#\s*\h\w*|%(\.|-\>|%(\h\w*::)+)?\h\w*%(\s*\(\)?|\<\>?|:)?|\@\h\w*%(\s*\(\)?)?|\(\s*\h\w*\s*\*?\s*\)?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'd',
                \'\v[.]?\h\w*%(!?\s*\(\)?)?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'python',
                \'\v[.]?\h\w*%(\s*\(\)?)?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'cs',
                \'\v[.]?\h\w*%(\s*%(\(\)?|\<))?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'java',
                \'\v[@.]?\h\w*%(\s*%(\(\)?|\<))?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'javascript,actionscript',
                \'\v[.]?\h\w*%(\s*\(\)?)?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'awk',
                \'\v\h\w*%(\s*\(\)?)?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'haskell',
                \'[[:alpha:]_''][[:alnum:]_'']*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'ocaml',
                \'[~]\?[[:alpha:]_''][[:alnum:]_'']*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'erlang',
                \'\v^\s*-\h\w*[(]?|\h\w*%(:\h\w*)*%(\.|\(\)?)?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'html,xhtml,xml,markdown',
                \'</\?\%([[:alnum:]_:-]\+\s*\)\?\%(/\?>\)\?\|&\h\%(\w*;\)\?\|\h[[:alnum:]_-]*="\%([^"]*"\?\)\?\|\h[[:alnum:]_:-]*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'css',
                \'\v[[:alpha:]_-][[:alnum:]_-]*[:(]?|[@#:.][[:alpha:]_-][[:alnum:]_-]*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'tags',
                \'\v^[^!][^/[:blank:]]*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'pic',
                \'\v^\s*#\h\w*|\h\w*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'masm',
                \'\v\.\h\w*|[[:alpha:]_@?$][[:alnum:]_@?$]*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'nasm',
                \'\v^\s*\[\h\w*|[%.]?\h\w*|%(\.\.\@?|\%[%$!])%(\h\w*)?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'asm',
                \'\v[%$.]?\h\w*%(\$\h\w*)?')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'make',
                \'\v[[:alpha:]_.-][[:alnum:]_.-]*')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_KeywordPatterns', 'scala',
                \'\v[.]?\h\w*%(\s*\(\)?|\[)?')
    "}}}

    " Initialize next keyword patterns."{{{
    if !exists('g:NeoComplCache_NextKeywordPatterns')
        let g:NeoComplCache_NextKeywordPatterns = {}
    endif
    call neocomplcache#set_variable_pattern('g:NeoComplCache_NextKeywordPatterns', 'perl',
                \'\h\w*>')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_NextKeywordPatterns', 'perl6',
                \'\h\w*>')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_NextKeywordPatterns', 'vim,help',
                \'\h\w*:\]\|\h\w*=\|[[:alnum:]_-]*>')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_NextKeywordPatterns', 'tex',
                \'\h\w*\*\?[*[{}]')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_NextKeywordPatterns', 'html,xhtml,xml,mkd',
                \'[[:alnum:]_:-]*>\|[[:alnum:]_-]*="[^"]*"')
    "}}}
    
    " Initialize same file type lists."{{{
    if !exists('g:NeoComplCache_SameFileTypeLists')
        let g:NeoComplCache_SameFileTypeLists = {}
    endif
    call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'c', 'cpp')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'cpp', 'c')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'erb', 'ruby,html,xhtml')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'html,xml', 'xhtml')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'xhtml', 'html,xml')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_SameFileTypeLists', 'help', 'vim')
    "}}}
    
    " Initialize member prefix patterns."{{{
    if !exists('g:NeoComplCache_MemberPrefixPatterns')
        let g:NeoComplCache_MemberPrefixPatterns = {}
    endif
    call neocomplcache#set_variable_pattern('g:NeoComplCache_MemberPrefixPatterns', 'c,cpp,objc,objcpp', '^\.\|^->')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_MemberPrefixPatterns', 'perl,php', '^->')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_MemberPrefixPatterns', 'java,javascript,d,vim,ruby', '^\.')
    "}}}

    " Initialize ctags arguments."{{{
    if !exists('g:NeoComplCache_CtagsArgumentsList')
        let g:NeoComplCache_CtagsArgumentsList = {}
    endif
    call neocomplcache#set_variable_pattern('g:NeoComplCache_CtagsArgumentsList', 'default', '')
    call neocomplcache#set_variable_pattern('g:NeoComplCache_CtagsArgumentsList', 'vim',
                \"--extra=fq --fields=afmiKlnsStz --regex-vim='/function!? ([a-z#:_0-9A-Z]+)/\\1/function/'")
    call neocomplcache#set_variable_pattern('g:NeoComplCache_CtagsArgumentsList', 'cpp',
                \'--c++-kinds=+p --fields=+iaS --extra=+q')
    "}}}
    
    " Initialize quick match patterns."{{{
    if !exists('g:NeoComplCache_QuickMatchPatterns')
        let g:NeoComplCache_QuickMatchPatterns = {}
    endif
    call neocomplcache#set_variable_pattern('g:NeoComplCache_QuickMatchPatterns', 'default', '-')
    "}}}
    
    " Initialize tags filter patterns."{{{
    if !exists('g:NeoComplCache_TagsFilterPatterns')
        let g:NeoComplCache_TagsFilterPatterns = {}
    endif
    call neocomplcache#set_variable_pattern('g:NeoComplCache_TagsFilterPatterns', 'c,cpp', 
                \'v:val.word !~ ''^[~_]''')
    "}}}
    
    " Initialize plugin completion length."{{{
    if !exists('g:NeoComplCache_PluginCompletionLength')
        let g:NeoComplCache_PluginCompletionLength = {}
    endif
    call neocomplcache#set_variable_pattern('g:NeoComplCache_PluginCompletionLength', 'omni_complete', 0)
    "}}}
    
    " Add commands."{{{
    command! -nargs=0 NeoComplCacheDisable call neocomplcache#disable()
    command! -nargs=0 Neco call s:display_neco()
    command! -nargs=0 NeoComplCacheLock call s:lock()
    command! -nargs=0 NeoComplCacheUnlock call s:unlock()
    command! -nargs=0 NeoComplCacheToggle call s:toggle()
    command! -nargs=1 NeoComplCacheAutoCompletionLength let g:NeoComplCache_KeywordCompletionStartLength = <args>
    "}}}
    
    " Must g:NeoComplCache_StartCharLength > 1.
    if g:NeoComplCache_KeywordCompletionStartLength < 1
        let g:NeoComplCache_KeywordCompletionStartLength = 1
    endif
    " Must g:NeoComplCache_MinKeywordLength > 1.
    if g:NeoComplCache_MinKeywordLength < 1
        let g:NeoComplCache_MinKeywordLength = 1
    endif

    " Save options.
    let s:completefunc_save = &completefunc
    let s:completeopt_save = &completeopt

    " Set completefunc.
    let &completefunc = 'neocomplcache#manual_complete'
    let &l:completefunc = 'neocomplcache#manual_complete'

    " Set options.
    set completeopt-=menu
    set completeopt-=longest
    set completeopt+=menuone

    " Initialize.
    for l:complfunc_name in keys(s:global_complfuncs)
        call call(s:global_complfuncs[l:complfunc_name] . 'initialize', [])
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

    for l:complfunc_name in keys(s:global_complfuncs)
        call call(s:global_complfuncs[l:complfunc_name] . 'finalize', [])
    endfor
endfunction"}}}

function! neocomplcache#manual_complete(findstart, base)"{{{
    if a:findstart
        " Get cursor word.
        let l:cur_text = s:get_cur_text()

        " Try complfuncs completion."{{{
        let l:complete_result = {}
        for [l:complfunc_name, l:complfunc] in items(s:global_complfuncs)
            
            let l:cur_keyword_pos = call(l:complfunc . 'get_keyword_pos', [l:cur_text])
            if l:cur_keyword_pos < 0
                " Try append 'a'.
                let l:cur_keyword_pos = call(l:complfunc . 'get_keyword_pos', [l:cur_text.'a'])
            endif

            if l:cur_keyword_pos >= 0
                let l:cur_keyword_str = l:cur_text[l:cur_keyword_pos :]

                " Save options.
                let l:ignorecase_save = &ignorecase

                if g:NeoComplCache_SmartCase && l:cur_keyword_str =~ '\u'
                    let &ignorecase = 0
                else
                    let &ignorecase = g:NeoComplCache_IgnoreCase
                endif

                let l:words = call(l:complfunc . 'get_complete_words', [l:cur_keyword_pos, l:cur_keyword_str])

                let &ignorecase = l:ignorecase_save

                if !empty(l:words)
                    let l:complete_result[l:complfunc_name] = {
                                \'complete_words' : l:words, 
                                \'cur_keyword_pos' : l:cur_keyword_pos, 
                                \'cur_keyword_str' : l:cur_keyword_str, 
                                \'rank' : call(l:complfunc . 'get_rank', [])
                                \}
                endif
            endif
        endfor
        "}}}
        let [l:cur_keyword_pos, l:cur_keyword_str, l:complete_words] = s:integrate_completion(l:complete_result)
        if empty(l:complete_words)
            return -1
        endif
        let [s:cur_keyword_pos, s:cur_keyword_str, s:complete_words] = [l:cur_keyword_pos, l:cur_keyword_str, l:complete_words]

        return s:cur_keyword_pos
    else
        return s:complete_words
    endif
endfunction"}}}

function! neocomplcache#auto_complete(findstart, base)"{{{
    if a:findstart
        return s:cur_keyword_pos
    else
        " Restore option.
        let &l:completefunc = 'neocomplcache#manual_complete'

        return s:complete_words
    endif
endfunction"}}}

" Plugin helper."{{{
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
        let l:keyword_escape = substitute(l:keyword_escape, '\u\?\zs\U*', '\\%(\0\\l*\\|\U\0\E\\u*_\\?\\)', 'g')
    endif
    "}}}

    "echo l:keyword_escape
    return l:keyword_escape
endfunction"}}}
function! neocomplcache#keyword_filter(list, cur_keyword_str)"{{{
    if neocomplcache#check_match_filter(a:cur_keyword_str)
        " Match filter.
        return filter(a:list, printf("v:val.word =~ %s", 
                    \string('^' . neocomplcache#keyword_escape(a:cur_keyword_str))))
    else
        " Use fast filter.
        return neocomplcache#head_filter(a:list, a:cur_keyword_str)
    endif
endfunction"}}}
function! neocomplcache#check_match_filter(cur_keyword_str)"{{{
    return neocomplcache#keyword_escape(a:cur_keyword_str) =~ '[^\\]\*\|\\+'
endfunction"}}}
function! neocomplcache#head_filter(list, cur_keyword_str)"{{{
    let l:cur_keyword = substitute(a:cur_keyword_str, '\\\zs.', '\0', 'g')

    let l:cur_max = len(l:cur_keyword) - 1
    let l:ret = []
    if &ignorecase
        let l:cur_keyword = tolower(l:cur_keyword)
        for keyword in a:list
            if l:cur_keyword == tolower(keyword.word[: l:cur_max])
                call add(l:ret, keyword)
            endif
        endfor
    else
        for keyword in a:list
            if l:cur_keyword == keyword.word[: l:cur_max] 
                call add(l:ret, keyword)
            endif
        endfor
    endif

    return ret
endfunction"}}}
function! neocomplcache#member_filter(list, cur_keyword_str)"{{{
    let l:ft = &filetype
    if l:ft == ''
        let l:ft = 'nothing'
    endif
    
    if has_key(g:NeoComplCache_MemberPrefixPatterns, l:ft) && a:cur_keyword_str =~ g:NeoComplCache_MemberPrefixPatterns[l:ft]
        let l:prefix = matchstr(a:cur_keyword_str, g:NeoComplCache_MemberPrefixPatterns[l:ft])
        let l:cur_keyword_str = a:cur_keyword_str[len(l:prefix) :]

        let l:ret = deepcopy(neocomplcache#keyword_filter(filter(a:list, 
                    \'(has_key(v:val, "kind") && v:val.kind ==# "m") || (has_key(v:val, "class") && v:val.class != "")'), l:cur_keyword_str))
        for l:keyword in l:ret
            let l:keyword.word = l:prefix . l:keyword.word
        endfor

        return ret
    else
        return neocomplcache#keyword_filter(a:list, a:cur_keyword_str)
    endif
endfunction"}}}
function! neocomplcache#unpack_dictionary(dict)"{{{
    let l:ret = []
    for l in values(a:dict)
        let l:ret += l
    endfor

    return l:ret
endfunction"}}}
function! neocomplcache#unpack_dictionary_dictionary(dict)"{{{
    let l:ret = []
    for l in values(a:dict)
        let l:ret += values(l)
    endfor

    return l:ret
endfunction"}}}
function! neocomplcache#add_dictionaries(dictionaries)"{{{
    if empty(a:dictionaries)
        return {}
    endif
    
    let l:ret = a:dictionaries[0]
    for l:dict in a:dictionaries[1:]
        for [l:key, l:value] in items(l:dict)
            if has_key(l:ret, l:key)
                let l:ret[l:key] += l:value
            else
                let l:ret[l:key] = l:value
            endif
        endfor
    endfor

    return l:ret
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

function! neocomplcache#check_skip_time()"{{{
    if !g:NeoComplCache_EnableSkipCompletion || !neocomplcache#is_auto_complete()
        return 0
    endif

    if s:skipped || getchar(1) || substitute(reltimestr(reltime(s:start_time)), '^\s*', '', '') > g:NeoComplCache_SkipCompletionTime
        let s:skipped = 1
        return 1
    else
        return 0
    endif
endfunction"}}}
function! neocomplcache#rand(max)"{{{
    return abs(reltime()[1]) % (a:max + 1)
endfunction"}}}

function! neocomplcache#caching_percent()"{{{
    return neocomplcache#plugin#buffer_complete#caching_percent('')
endfunction"}}}

function! neocomplcache#get_cur_text()"{{{
    " Return cached text.

    return s:cur_text
endfunction"}}}
function! neocomplcache#get_completion_length(plugin_name)"{{{
    if has_key(g:NeoComplCache_PluginCompletionLength, a:plugin_name)
        return g:NeoComplCache_PluginCompletionLength[a:plugin_name]
    else
        return g:NeoComplCache_KeywordCompletionStartLength
    endif
endfunction"}}}
function! neocomplcache#get_keyword_pattern(...)"{{{
    if empty(a:000)
        let l:filetype = (&filetype == '')?  'nothing' : &filetype
    else
        let l:filetype = a:000[0]
    endif

    return has_key(g:NeoComplCache_KeywordPatterns, l:filetype) ?
                \ g:NeoComplCache_KeywordPatterns[l:filetype] : g:NeoComplCache_KeywordPatterns['default']
endfunction"}}}
function! neocomplcache#get_next_keyword_pattern(...)"{{{
    if empty(a:000)
        let l:filetype = (&filetype == '')?  'nothing' : &filetype
    else
        let l:filetype = a:000[0]
    endif

    if has_key(g:NeoComplCache_NextKeywordPatterns, l:filetype)
        return g:NeoComplCache_NextKeywordPatterns[l:filetype] . '\m\|' . neocomplcache#get_keyword_pattern(l:filetype)
    else
        return neocomplcache#get_keyword_pattern(l:filetype)
    endif
endfunction"}}}
function! neocomplcache#get_keyword_pattern_end(...)"{{{
    if empty(a:000)
        let l:filetype = (&filetype == '')?  'nothing' : &filetype
    else
        let l:filetype = a:000[0]
    endif
    
    return '\%('.neocomplcache#get_keyword_pattern(l:filetype).'\m\)$'
endfunction"}}}
function! neocomplcache#get_prev_word(cur_keyword_str)"{{{
    let l:keyword_pattern = neocomplcache#get_keyword_pattern()
    let l:line_part = neocomplcache#get_cur_text()[: -1-len(a:cur_keyword_str)]
    let l:prev_word_end = matchend(l:line_part, l:keyword_pattern)
    if l:prev_word_end > 0
        let l:word_end = matchend(l:line_part, l:keyword_pattern, l:prev_word_end)
        if l:word_end >= 0
            while l:word_end >= 0
                let l:prev_word_end = l:word_end
                let l:word_end = matchend(l:line_part, l:keyword_pattern, l:prev_word_end)
            endwhile
        endif

        let l:prev_word = matchstr(l:line_part[: l:prev_word_end-1], l:keyword_pattern . '$')
    else
        let l:prev_word = '^'
    endif
    
    return l:prev_word
endfunction"}}}
function! neocomplcache#match_word(cur_text)"{{{
    return matchstr(a:cur_text, neocomplcache#get_keyword_pattern_end())
endfunction"}}}
function! neocomplcache#match_wildcard(cur_text, pattern, cur_keyword_pos)"{{{
    let l:cur_keyword_pos = a:cur_keyword_pos

    while l:cur_keyword_pos > 1 && a:cur_text[l:cur_keyword_pos - 1] == '*'
        let l:left_text = a:cur_text[: l:cur_keyword_pos - 2]
        if l:left_text !~ a:pattern
            break
        endif

        let l:cur_keyword_pos = match(l:left_text, a:pattern)
    endwhile

    return l:cur_keyword_pos
endfunction"}}}
function! neocomplcache#is_auto_complete()"{{{
    return &l:completefunc == 'neocomplcache#auto_complete'
endfunction"}}}
function! neocomplcache#print_caching(string)"{{{
    if g:NeoComplCache_CachingPercentInStatusline
        let &l:statusline = a:string
        redrawstatus
    else
        redraw
        echo a:string
    endif
endfunction"}}}
function! neocomplcache#print_error(string)"{{{
    echohl Error | echo a:string | echohl None
endfunction"}}}

" Set pattern helper.
function! neocomplcache#set_variable_pattern(variable, filetype, pattern)"{{{
    for ft in split(a:filetype, ',')
        if !has_key({a:variable}, ft) 
            let {a:variable}[ft] = a:pattern
        endif
    endfor
endfunction"}}}
"}}}

" Command functions."{{{
function! s:toggle()"{{{
    if !has_key(s:complete_lock, bufnr('%')) || !s:complete_lock[bufnr('%')]
        call s:lock()
    else
        call s:unlock()
    endif
endfunction"}}}
function! s:lock()"{{{
    let s:complete_lock[bufnr('%')] = 1
endfunction"}}}
function! s:unlock()"{{{
    let s:complete_lock[bufnr('%')] = 0
endfunction"}}}
function! s:display_neco()"{{{
    let l:animation = [
                \["   A A", 
                \ "~(-'_'-)"], 
                \["      A A", 
                \ "   ~(-'_'-)"], 
                \["        A A", 
                \ "     ~(-'_'-)"], 
                \["          A A  ", 
                \ "       ~(-'_'-)"], 
                \["             A A", 
                \ "          ~(-^_^-)"],
                \]
    
    for l:anim in l:animation
        echo ''
        redraw
        echo l:anim[0] . "\n" . l:anim[1]
        sleep 150m
    endfor
endfunction"}}}
"}}}

" Key mapping functions."{{{
function! neocomplcache#close_popup()"{{{
    if !exists(':NeoComplCacheDisable')
        return ''
    endif

    let s:old_text = neocomplcache#get_cur_text()
    let s:prev_numbered_list = []

    return "\<C-y>"
endfunction
"}}}

function! neocomplcache#cancel_popup()"{{{
    if !exists(':NeoComplCacheDisable')
        return ''
    endif

    let s:skip_next_complete = 1
    let s:prev_numbered_list = []

    return "\<C-e>"
endfunction"}}}

function! neocomplcache#manual_filename_complete()"{{{
    return neocomplcache#start_manual_complete('filename_complete')
endfunction"}}}

function! neocomplcache#manual_omni_complete()"{{{
    return neocomplcache#start_manual_complete('omni_complete')
endfunction"}}}

function! neocomplcache#manual_keyword_complete()"{{{
    return neocomplcache#start_manual_complete('keyword_complete')
endfunction"}}}

function! neocomplcache#start_manual_complete(complfunc_name)"{{{
    let l:cur_text = s:get_cur_text()

    " Set function.
    let &l:completefunc = 'neocomplcache#manual_complete'
    
    if !has_key(s:global_complfuncs, a:complfunc_name)
        let l:cur_keyword_pos = neocomplcache#complfunc#keyword_complete#get_keyword_pos(l:cur_text)
        let l:cur_keyword_str = l:cur_text[l:cur_keyword_pos :]
        let l:complete_words = neocomplcache#complfunc#keyword_complete#get_manual_complete_list(a:complfunc_name)
        
        if empty(l:complete_words)
            return ''
        endif
    else
        let l:complfunc = s:global_complfuncs[a:complfunc_name]

        let l:cur_keyword_pos = call(l:complfunc . 'get_keyword_pos', [l:cur_text])
        if l:cur_keyword_pos < 0
            " Try append 'a'.
            let l:cur_keyword_pos = call(l:complfunc . 'get_keyword_pos', [l:cur_text.'a'])
        endif
        
        let l:cur_keyword_str = l:cur_text[l:cur_keyword_pos :]
        if l:cur_keyword_pos < 0 || len(l:cur_keyword_str) < g:NeoComplCache_ManualCompletionStartLength
            return ''
        endif

        " Save options.
        let l:ignorecase_save = &ignorecase

        if g:NeoComplCache_SmartCase && l:cur_keyword_str =~ '\u'
            let &ignorecase = 0
        else
            let &ignorecase = g:NeoComplCache_IgnoreCase
        endif

        let l:complete_words = s:remove_next_keyword(a:complfunc_name, deepcopy(
                    \call(l:complfunc . 'get_complete_words', [l:cur_keyword_pos, l:cur_keyword_str])[: g:NeoComplCache_MaxList]))

        let &ignorecase = l:ignorecase_save
    endif
    
    let s:skipped = 0
    let [s:cur_keyword_pos, s:cur_keyword_str, s:complete_words] = [l:cur_keyword_pos, l:cur_keyword_str, l:complete_words]

    " Set function.
    let &l:completefunc = 'neocomplcache#auto_complete'

    " Start complete.
    return "\<C-x>\<C-u>\<C-p>"
endfunction"}}}

function! neocomplcache#undo_completion()"{{{
    if !exists(':NeoComplCacheDisable')
        return ''
    endif

    " Get cursor word.
    let l:cur_keyword_str = neocomplcache#match_word(s:get_cur_text())
    let l:old_keyword_str = s:cur_keyword_str
    let s:cur_keyword_str = l:cur_keyword_str

    let s:skip_next_complete = 1

    return (pumvisible() ? "\<C-e>" : '')
                \ . repeat("\<BS>", len(l:cur_keyword_str)) . l:old_keyword_str
endfunction"}}}
"}}}

" Event functions."{{{
function! s:complete()"{{{
    if s:skip_next_complete
        let s:skip_next_complete = 0
        return
    endif

    if (&buftype !~ 'nofile\|nowrite' && !&modified) || &paste
                \|| (has_key(s:complete_lock, bufnr('%')) && s:complete_lock[bufnr('%')])
                \|| g:NeoComplCache_DisableAutoComplete
                \|| (&l:completefunc != 'neocomplcache#manual_complete' && &l:completefunc != 'neocomplcache#auto_complete')
        return
    endif

    " Get cursor word.
    let l:cur_text = s:get_cur_text()
    " Prevent infinity loop.
    " Not complete multi byte character for ATOK X3.
    if l:cur_text == s:old_text || l:cur_text == '' || char2nr(l:cur_text[-1:]) >= 0x80
        return
    endif

    let s:old_text = l:cur_text
    
    let l:quickmatch_pattern = s:get_quickmatch_pattern()
    if g:NeoComplCache_EnableQuickMatch && l:cur_text =~ l:quickmatch_pattern.'[a-z0-9]$'
        " Select quickmatch list.
        let l:complete_words = s:select_quickmatch_list(l:cur_text[-1:])
        
        if !empty(l:complete_words)
            let s:complete_words = l:complete_words
            let s:prev_numbered_list = []

            " Set function.
            let &l:completefunc = 'neocomplcache#auto_complete'
            call feedkeys("\<C-x>\<C-u>", 'n')
            return 
        endif
        
        let s:prev_numbered_list = []
        let l:is_quickmatch_list = 0
    elseif g:NeoComplCache_EnableQuickMatch && l:cur_text =~ l:quickmatch_pattern.'$'
        " Quickmatch list.
        let l:is_quickmatch_list = 1
        let l:cur_text = l:cur_text[: -len(matchstr(l:cur_text, l:quickmatch_pattern.'$'))-1]
        let s:cur_text = l:cur_text
    else
        let s:prev_numbered_list = []
        let l:is_quickmatch_list = 0
    endif
    
    echo ''
    redraw

    " Set function.
    let &l:completefunc = 'neocomplcache#auto_complete'
    " Try complfuncs completion."{{{
    let l:complete_result = {}
    let s:skipped = 0
    let s:start_time = reltime()
    for [l:complfunc_name, l:complfunc] in items(s:global_complfuncs)
        let l:cur_keyword_pos = call(l:complfunc . 'get_keyword_pos', [l:cur_text])

        if l:cur_keyword_pos >= 0
            let l:cur_keyword_str = l:cur_text[l:cur_keyword_pos :]
            if len(l:cur_keyword_str) < neocomplcache#get_completion_length(l:complfunc_name)
                continue
            endif

            " Save options.
            let l:ignorecase_save = &ignorecase

            if g:NeoComplCache_SmartCase && l:cur_keyword_str =~ '\u'
                let &ignorecase = 0
            else
                let &ignorecase = g:NeoComplCache_IgnoreCase
            endif

            let l:words = call(l:complfunc . 'get_complete_words', [l:cur_keyword_pos, l:cur_keyword_str])

            let &ignorecase = l:ignorecase_save

            if !empty(l:words)
                let l:complete_result[l:complfunc_name] = {
                            \'complete_words' : l:words, 
                            \'cur_keyword_pos' : l:cur_keyword_pos, 
                            \'cur_keyword_str' : l:cur_keyword_str, 
                            \'rank' : call(l:complfunc . 'get_rank', [])
                            \}
            endif

            if neocomplcache#check_skip_time()
                echo 'Skipped auto completion'
                let &l:completefunc = 'neocomplcache#manual_complete'
                return
            endif
        endif
    endfor
    "}}}

    " Start auto complete.
    let [l:cur_keyword_pos, l:cur_keyword_str, l:complete_words] = s:integrate_completion(l:complete_result)

    if empty(l:complete_words)
        let &l:completefunc = 'neocomplcache#manual_complete'
        return
    endif

    if l:is_quickmatch_list
       let l:complete_words = s:make_quickmatch_list(l:complete_words) 
    endif
    
    if neocomplcache#check_skip_time()
        echo 'Skipped auto completion'
        let &l:completefunc = 'neocomplcache#manual_complete'
        return
    endif

    let [s:cur_keyword_pos, s:cur_keyword_str, s:complete_words] = [l:cur_keyword_pos, l:cur_keyword_str, l:complete_words]

    call feedkeys("\<C-x>\<C-u>\<C-p>", 'n')
endfunction"}}}
function! s:integrate_completion(complete_result)"{{{
    if empty(a:complete_result)
        return [-1, '', []]
    endif
    
    let l:cur_keyword_pos = col('.')
    for l:result in values(a:complete_result)
        if l:cur_keyword_pos > l:result.cur_keyword_pos
            let l:cur_keyword_pos = l:result.cur_keyword_pos
        endif
    endfor
    let l:cur_text = neocomplcache#get_cur_text()
    let l:cur_keyword_str = l:cur_text[l:cur_keyword_pos :]

    let l:frequencies = neocomplcache#plugin#buffer_complete#get_frequencies()
    let l:prev_frequencies = neocomplcache#plugin#buffer_complete#get_prev_frequencies()
    
    " Append prefix.
    let l:complete_words = []
    for [l:complfunc_name, l:result] in items(a:complete_result)
        let l:result.complete_words = deepcopy(l:result.complete_words)
        if l:result.cur_keyword_pos > l:cur_keyword_pos
            let l:prefix = l:cur_keyword_str[: l:result.cur_keyword_pos - l:cur_keyword_pos - 1]
            
            for keyword in l:result.complete_words
                let keyword.word = l:prefix . keyword.word
            endfor
        endif

        let l:rank = l:result.rank
        for l:keyword in l:result.complete_words
            let l:word = l:keyword.word
            let l:keyword.rank = has_key(l:frequencies, l:word)? l:rank * l:frequencies[l:word] : l:rank
            let l:keyword.prev_rank = has_key(l:prev_frequencies, l:word)? l:prev_frequencies[l:word] : 0
        endfor
        let l:complete_words += s:remove_next_keyword(l:complfunc_name, l:result.complete_words)
    endfor
    
    " Sort.
    if (has_key(g:NeoComplCache_DisablePluginList, 'buffer_complete') && g:NeoComplCache_DisablePluginList['buffer_complete'])
                \|| g:NeoComplCache_AlphabeticalOrder
        let l:func = 'neocomplcache#compare_words'
    else
        let l:func = 'neocomplcache#compare_prev_rank'
    endif
    
    return [l:cur_keyword_pos, l:cur_keyword_str, sort(l:complete_words, l:func)[: g:NeoComplCache_MaxList]]
endfunction"}}}
function! s:insert_leave()"{{{
    let s:old_text = ''
    let s:skip_next_complete = 0
    let s:cur_keyword_pos = -1
    let s:cur_keyword_str = ''
    let s:complete_words = []
endfunction"}}}
function! s:remove_next_keyword(plugin_name, list)"{{{
    let l:list = a:list
    " Remove next keyword."{{{
    if a:plugin_name  == 'filename_complete'
        let l:pattern = '^\%(' . neocomplcache#get_next_keyword_pattern('filename') . '\m\)'
    else
        let l:pattern = '^\%(' . neocomplcache#get_next_keyword_pattern() . '\m\)'
    endif
    
    let l:next_keyword_str = matchstr('a'.getline('.')[col('.') - 1 :], l:pattern)[1:]
    if l:next_keyword_str != ''
        let l:next_keyword_str = substitute(escape(l:next_keyword_str, '~" \.^$*[]'), "'", "''", 'g').'$'

        " No ignorecase.
        let l:save_ignorecase = &ignorecase
        let &ignorecase = 0

        for r in l:list
            if r.word =~ l:next_keyword_str
                let r.word = r.word[: match(r.word, l:next_keyword_str)-1]
            endif
        endfor

        let &ignorecase = l:save_ignorecase
    endif"}}}

    return l:list
endfunction"}}}

let s:quickmatch_table = {
            \'a' : 0, 's' : 1, 'd' : 2, 'f' : 3, 'g' : 4, 'h' : 5, 'j' : 6, 'k' : 7, 'l' : 8, 
            \'q' : 9, 'w' : 10, 'e' : 11, 'r' : 12, 't' : 13, 'y' : 14, 'u' : 15, 'i' : 16, 'o' : 17, 'p' : 18, 
            \'z' : 19, 'x' : 20, 'c' : 21, 'v' : 22, 'b' : 23, 'n' : 24, 'm' : 25,
            \'1' : 26, '2' : 27, '3' : 28, '4' : 29, '5' : 30, '6' : 31, '7' : 32, '8' : 33, '9' : 34, '0' : 35,
            \}
function! s:make_quickmatch_list(list)"{{{
    " Check dup.
    let l:dup_check = {}
    let l:num = 0
    let l:qlist = []
    let l:key = 'asdfghjklqwertyuiopzxcvbnm1234567890'
    for keyword in deepcopy(a:list[: len(s:quickmatch_table)])
        if keyword.word != '' && (
                    \!has_key(l:dup_check, keyword.word) ||
                    \(has_key(keyword, 'dup') && keyword.dup))
            let l:dup_check[keyword.word] = 1
            let keyword.abbr = printf('%s: %s', l:key[l:num], keyword.abbr)

            call add(l:qlist, keyword)
            let l:num += 1
        endif
    endfor

    " Save numbered lists.
    let s:prev_numbered_list = l:qlist

    return l:qlist
endfunction"}}}
function! s:select_quickmatch_list(key)"{{{
    if !has_key(s:quickmatch_table, a:key)
        return []
    endif
    let l:numbered = get(s:prev_numbered_list, s:quickmatch_table[a:key])
    if type(l:numbered) == type({})
        return [l:numbered]
    endif

    return []
endfunction"}}}
function! s:get_quickmatch_pattern()"{{{
    let l:filetype = (&filetype == '')?   'nothing' : &filetype

    let l:pattern = has_key(g:NeoComplCache_QuickMatchPatterns, l:filetype)?  
                \ g:NeoComplCache_QuickMatchPatterns[l:filetype] : g:NeoComplCache_QuickMatchPatterns['default']
        
    return l:pattern
endfunction"}}}
function! s:get_cur_text()"{{{
    let l:pos = mode() ==# 'i' ? 2 : 1

    let s:cur_text = col('.') < l:pos ? '' : getline('.')[: col('.') - l:pos]
    return s:cur_text
endfunction"}}}

" vim: foldmethod=marker
