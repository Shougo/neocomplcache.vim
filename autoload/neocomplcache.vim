"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 10 May 2009
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
" Version: 2.42, for Vim 7.0
"=============================================================================

function! neocomplcache#enable() "{{{
    augroup neocomplcache "{{{
        autocmd!
        " Auto complete events
        autocmd CursorMovedI * call s:complete()
    augroup END "}}}

    " Initialize"{{{
    let s:complete_lock = 0
    let s:old_text = ''
    let s:prev_numbered_list = []
    let s:prepre_numbered_list = []
    let s:skipped = 0
    let s:plugins_func_table = {}

    if g:NeoComplCache_EnableSkipCompletion
        let s:prev_input_time = reltime()
    endif
    "}}}
    
    " Initialize plugins table.
    " Search autoload.
    let l:plugin_list = split(globpath(&runtimepath, 'autoload/neocomplcache/*.vim'), '\n')
    for list in l:plugin_list
        let l:func_name = fnamemodify(list, ':t:r')
        let s:plugins_func_table[l:func_name] = 'neocomplcache#' . l:func_name . '#'
    endfor

    " Initialize keyword pattern match like intellisense."{{{
    if !exists('g:NeoComplCache_KeywordPatterns')
        let g:NeoComplCache_KeywordPatterns = {}
    endif
    call s:set_keyword_pattern('default',
                \'\v\k+')
    call s:set_keyword_pattern('lisp,scheme', 
                \'\v\(?[[:alpha:]*@$%^&_=<>~.][[:alnum:]+*@$%^&_=<>~.-]*[!?]?')
    call s:set_keyword_pattern('ruby',
                \'\v\h\w*::|^\=%(b%[egin]|e%[nd])|%(\@\@|[:$@])\h\w*|\h\w*[!?]?%(\s*%(%(\(\))?\s*%(do|\{)%(\s*\|)?|\(\)?))?')
    call s:set_keyword_pattern('eruby',
                \'\v\</?%(\h[[:alnum:]_-]*\s*)?%(/?\>)?|\h\w*::|%(\@\@|[:$@])\h\w*|\h\w*[!?]?%(\s*%(%(\(\))?\s*%(do|\{)%(\s*\|)?|\(\)?))?')
    call s:set_keyword_pattern('php',
                \'\v\</?%(\h[[:alnum:]_-]*\s*)?%(/?\>)?|\h\w*::|\$\h\w*|\h\w*%(\s*\(\)?)?')
    call s:set_keyword_pattern('perl',
                \'\v\<\h\w*\>?|\h\w*::|[$@%&*]\h\w*|\h\w*%(\s*\(\)?)?')
    call s:set_keyword_pattern('vim,help',
                \'\v\$\h\w*|\[:%(\h\w*:\])?|\<\h[[:alnum:]_-]*\>?|[&]?\h[[:alnum:]_:]*%([!>#]|\(\)?)?')
    call s:set_keyword_pattern('tex',
                \'\v\\\a\{\a{1,2}\}?|\\[[:alpha:]_@][[:alnum:]_@]*[[{]?|\h\w*[*[{]?')
    call s:set_keyword_pattern('sh,zsh,vimshell',
                \'\v\$\w+|[[:alpha:]_.-][[:alnum:]_.-]*%(\s*[[(])?')
    call s:set_keyword_pattern('ps1',
                \'\v\$\w+|[[:alpha:]_.-][[:alnum:]_.-]*%(\s*\(\)?)?')
    call s:set_keyword_pattern('c',
                \'\v^\s*#\s*\h\w*|\h\w*%(\s*\(\)?)?')
    call s:set_keyword_pattern('cpp',
                \'\v\h\w*::|^\s*#\s*\h\w*|\h\w*%(\s*\(\)?|\<\>?)?')
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
                \'\v^\s*-\h\w*[(]?|\h\w*%([:.]|\(\)?)?')
    call s:set_keyword_pattern('html,xhtml,xml',
                \'\v\</?%(\h[[:alnum:]_-]*\s*)?%(/?\>)?|\&\h%(\w*;)?|\h[[:alnum:]_-]*%(\=")?')
    call s:set_keyword_pattern('tags',
                \'\v^[^!/[:blank:]][^[:blank:]]*')
    call s:set_keyword_pattern('pic',
                \'\v^\s*#\h\w*|\h\w*')
    call s:set_keyword_pattern('masm',
                \'\v\.\h\w*|[[:alpha:]_@?$][[:alnum:]_@?$]*')
    call s:set_keyword_pattern('nasm',
                \'\v^\s*\[\h\w*|[%.]?\h\w*|%(\.\.\@?|\%[%$!])%(\h\w*)?')
    call s:set_keyword_pattern('asm',
                \'\v[%$.]?\h\w*%(\$\h\w*)?')
    "}}}

    " Initialize assume file type lists."{{{
    if !exists('g:NeoComplCache_NonBufferFileTypeDetect')
        let g:NeoComplCache_NonBufferFileTypeDetect = {}
    endif
    " For test.
    "let g:NeoComplCache_NonBufferFileTypeDetect['rb'] = 'ruby'"}}}

    " Initialize same file type lists."{{{
    if !exists('g:NeoComplCache_SameFileTypeLists')
        let g:NeoComplCache_SameFileTypeLists = {}
    endif
    call s:set_same_filetype('c', 'cpp')
    call s:set_same_filetype('cpp', 'c')
    "}}}
    
    " Initialize omni completion pattern."{{{
    if !exists('g:NeoComplCache_OmniPatterns')
        let g:NeoComplCache_OmniPatterns = {}
    endif
    if has('ruby')
        call s:set_omni_pattern('ruby', '\v[^. \t]%(\.|::)')
    endif
    if has('python')
        call s:set_omni_pattern('python', '\v[^. \t]\.')
    endif
    call s:set_omni_pattern('html,xhtml,xml', '\v\<|\</|\<[^>]+\s')
    call s:set_omni_pattern('css', '\v%(^\s|[;{])\s*|[:@!]\s*')
    call s:set_omni_pattern('javascript', '\v[^. \t]\.')
    call s:set_omni_pattern('c', '\v[^. \t]%(\.|-\>)')
    call s:set_omni_pattern('cpp', '\v[^. \t]%(\.|-\>|::)')
    call s:set_omni_pattern('php', '\v[^. \t]%(-\>|::)')
    call s:set_omni_pattern('java', '\v[^. \t]\.')
    call s:set_omni_pattern('vim', '\v%(^\s*:).*')
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

    " Set completefunc.
    let &completefunc = 'neocomplcache#manual_complete'

    for l:plugin in values(s:plugins_func_table)
        call call(l:plugin . 'initialize', [])
    endfor
endfunction"}}}

function! neocomplcache#disable()"{{{
    " Restore options.
    let &completefunc = s:completefunc_save
    
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

    for l:plugin in values(s:plugins_func_table)
        call call(l:plugin . 'finalize', [])
    endfor
endfunction"}}}

" Complete functions."{{{
function! neocomplcache#manual_complete(findstart, base)"{{{
    if a:findstart
        " Get cursor word.
        let l:cur = col('.') - 1
        let l:cur_text = strpart(getline('.'), 0, l:cur)

        if !neocomplcache#keyword_complete#exists_current_source()
            return -1
        endif

        let l:pattern = '\v%(' .  neocomplcache#keyword_complete#current_keyword_pattern() . ')$'
        let l:cur_keyword_pos = match(l:cur_text, l:pattern)
        let l:cur_keyword_str = matchstr(l:cur_text, l:pattern)

        if g:NeoComplCache_EnableWildCard
            " Check wildcard.
            let [l:cur_keyword_pos, l:cur_keyword_str] = s:check_wildcard(l:cur_text, l:pattern, l:cur_keyword_pos, l:cur_keyword_str)

            if l:cur_keyword_str == ''
                " Add wildcard.
                let l:cur_keyword_str  = l:cur_text[l:cur - 1] . '*'
                let l:cur_keyword_pos = l:cur - 1
            endif
        endif

        " Save options.
        let l:ignorecase_save = &ignorecase

        " Complete.
        if g:NeoComplCache_SmartCase && l:cur_keyword_str =~ '\u'
            let &ignorecase = 0
        else
            let &ignorecase = g:NeoComplCache_IgnoreCase
        endif

        let s:complete_words = s:get_complete_words(l:cur_keyword_str)

        if empty(s:complete_words)
            " Try empty completion.
            let s:complete_words = s:get_complete_words('')
            let l:cur_keyword_pos = l:cur
        endif

        " Restore options.
        let &ignorecase = l:ignorecase_save
        
        return l:cur_keyword_pos
    endif

    return s:complete_words
endfunction"}}}

function! neocomplcache#auto_complete(findstart, base)"{{{
    if a:findstart
        return s:cur_keyword_pos
    endif

    " Restore options.
    let &l:completefunc = 'neocomplcache#manual_complete'
    let &ignorecase = s:ignorecase_save
    " Unlock auto complete.
    let s:complete_lock = 0

    return s:complete_words
endfunction"}}}
"}}}

" Plugin helper."{{{
function! neocomplcache#keyword_filter(list, cur_keyword_str)"{{{
    let l:keyword_escape = neocomplcache#keyword_escape(a:cur_keyword_str)

    " Keyword filter."{{{
    let l:cur_len = len(a:cur_keyword_str)
    if g:NeoComplCache_PartialMatch && !s:skipped && len(a:cur_keyword_str) >= g:NeoComplCache_PartialCompletionStartLength
        " Partial match.
        " Filtering len(a:cur_keyword_str).
        let l:pattern = printf("len(v:val.word) > l:cur_len && v:val.word =~ '%s'", l:keyword_escape)
    else
        " Head match.
        " Filtering len(a:cur_keyword_str).
        let l:pattern = printf("len(v:val.word) > l:cur_len && v:val.word =~ '^%s'", l:keyword_escape)
    endif"}}}

    return filter(a:list, l:pattern)
endfunction"}}}
function! neocomplcache#keyword_escape(cur_keyword_str)"{{{
    " Escape."{{{
    let l:keyword_escape = substitute(escape(a:cur_keyword_str, '" \.^$[]'), "'", "''", 'g')
    if g:NeoComplCache_EnableWildCard
        let l:keyword_escape = substitute(substitute(l:keyword_escape, '.\zs\*', '.*', 'g'), '^\*', '\\*', '')
        if &filetype != 'lisp' && &filetype != 'scheme'
            let l:keyword_escape = substitute(l:keyword_escape, '.\zs-', '.\\+', 'g')
        endif
    else
        let l:keyword_escape = escape(a:cur_keyword_str, '*')
    endif"}}}

    " Underbar completion."{{{
    if g:NeoComplCache_EnableUnderbarCompletion
        let l:keyword_escape = substitute(l:keyword_escape, '[^_]\zs_', '[^_]*_', 'g')
        if &filetype == 'lisp' || &filetype == 'scheme'
            let l:keyword_escape = substitute(l:keyword_escape, '[^-]\zs-', '[^-]*-', 'g')
        endif
    endif
    "}}}
    " Camel case completion."{{{
    if g:NeoComplCache_EnableCamelCaseCompletion
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

function! neocomplcache#check_skip_time()"{{{
    if !g:NeoComplCache_EnableSkipCompletion || &l:completefunc != 'neocomplcache#auto_complete'
        return 0
    endif

    "let l:end_time = split(reltimestr(reltime(l:start_time)))[0]
    if split(reltimestr(reltime(s:start_time)))[0] > g:NeoComplCache_SkipCompletionTime
        "echo l:end_time
        return 1
    else
        return 0
    endif
endfunction"}}}
"}}}

" Complete internal function."{{{
function! s:complete()"{{{
    if pumvisible() || &paste || s:complete_lock || g:NeoComplCache_DisableAutoComplete
        return
    endif

    " Get cursor word.
    let l:cur_text = strpart(getline('.'), 0, col('.') - 1) 
    " Prevent infinity loop.
    if l:cur_text == s:old_text || l:cur_text == ''
        return
    endif
    let s:old_text = l:cur_text

    if g:NeoComplCache_EnableSkipCompletion
        if split(reltimestr(reltime(s:prev_input_time)))[0] < g:NeoComplCache_SkipInputTime
            echo 'Skipped auto completion'
            let s:skipped = 1

            return 1
        endif
        let s:prev_input_time = reltime()
    endif

    " Not complete multi byte character for ATOK X3.
    if char2nr(l:cur_text[-1]) >= 0x80
        return
    endif

    if exists('&l:omnifunc') && &l:omnifunc != '' 
                \&& has_key(g:NeoComplCache_OmniPatterns, &filetype)
                \&& g:NeoComplCache_OmniPatterns[&filetype] != ''
        if l:cur_text =~ '\v%(' . g:NeoComplCache_OmniPatterns[&filetype] . ')$'
            if &filetype == 'vim'
                call feedkeys("\<C-x>\<C-v>\<C-p>", 'n')
            else
                call feedkeys("\<C-x>\<C-o>\<C-p>", 'n')
            endif

            return
        endif
    endif

    if !neocomplcache#keyword_complete#exists_current_source()
        return
    endif

    let l:pattern = '\v%(' .  neocomplcache#keyword_complete#current_keyword_pattern() . ')$'
    let l:cur_keyword_pos = match(l:cur_text, l:pattern)
    let l:cur_keyword_str = matchstr(l:cur_text, l:pattern)

    if g:NeoComplCache_EnableWildCard
        " Check wildcard.
        let [l:cur_keyword_pos, l:cur_keyword_str] = s:check_wildcard(l:cur_text, l:pattern, l:cur_keyword_pos, l:cur_keyword_str)
    endif

    if l:cur_keyword_pos < 0 || len(l:cur_keyword_str) < g:NeoComplCache_KeywordCompletionStartLength
        " Try filename completion.
        if g:NeoComplCache_TryFilenameCompletion && &filetype != 'tex' && s:check_filename_completion(l:cur_text)
            call feedkeys("\<C-x>\<C-f>\<C-p>", 'n')
        endif

        return
    endif

    if &l:completefunc != 'neocomplcache#manual_complete'
                \&& &l:completefunc != 'neocomplcache#auto_complete'
        " Call completefunc.
        call feedkeys("\<C-x>\<C-u>\<C-p>", 'n')
        return
    endif

    " Save options.
    let s:ignorecase_save = &ignorecase

    " Set function.
    let &l:completefunc = 'neocomplcache#auto_complete'

    " Extract complete words.
    if g:NeoComplCache_SmartCase && l:cur_keyword_str =~ '\u'
        let &ignorecase = 0
    else
        let &ignorecase = g:NeoComplCache_IgnoreCase
    endif

    let s:complete_words = s:get_complete_words(l:cur_keyword_str)

    if empty(s:complete_words) && !s:skipped && g:NeoComplCache_TryKeywordCompletion
                \&& len(l:cur_keyword_str) <= g:NeoComplCache_MaxTryKeywordLength
                \&& l:cur_keyword_str =~ '\a\+$' && l:cur_keyword_str !~ '\a\+[*-]\a\+$'
        if g:NeoComplCache_TryDefaultCompletion
            let l:default_pattern = '\v(' . g:NeoComplCache_KeywordPatterns['default'] . ')$'
            if l:default_pattern != l:pattern
                " Try default completion.
                let l:cur_keyword_pos = match(l:cur_text, l:default_pattern)
                let l:cur_keyword_str = matchstr(l:cur_text, l:default_pattern)
                let s:complete_words = s:get_complete_words(l:cur_keyword_str)
            endif
        endif

        if empty(s:complete_words)
            " Try keyword completion.
            call feedkeys("\<C-n>\<C-p>", 'n')
        endif
    endif

    if empty(s:complete_words)
        " Restore options
        let &l:completefunc = 'neocomplcache#manual_complete'
        let &ignorecase = s:ignorecase_save
        return
    endif

    " Start original complete.
    let s:cur_keyword_pos = l:cur_keyword_pos
    let s:cur_keyword_str = l:cur_keyword_str
    let s:skipped = 0
    call feedkeys("\<C-x>\<C-u>\<C-p>", 'n')
endfunction"}}}

function! s:check_filename_completion(cur_text)"{{{
    let l:PATH_SEPARATOR = (has('win32') || has('win64')) ? '/\\' : '/'
    " Filename pattern.
    let l:pattern = printf('[/~]\=\f\+[%s]\f*$', l:PATH_SEPARATOR)
    " Not Filename pattern.
    let l:exclude_pattern = '[*/\\][/\\]\f*$\|[^[:print:]]\f*$\|/c\%[ygdrive/]$'

    " Check filename completion.
    return match(a:cur_text, l:pattern) >= 0 && match(a:cur_text, l:exclude_pattern) < 0
                \ && len(matchstr(a:cur_text, l:pattern)) >= g:NeoComplCache_KeywordCompletionStartLength
endfunction"}}}

function! s:check_wildcard(cur_text, pattern, cur_keyword_pos, cur_keyword_str)"{{{
    let l:cur_keyword_pos = a:cur_keyword_pos
    let l:cur_keyword_str = a:cur_keyword_str

    while l:cur_keyword_pos > 1 && a:cur_text[l:cur_keyword_pos - 1] =~ '[*-]'
        let l:left_text = strpart(a:cur_text, 0, l:cur_keyword_pos - 1) 
        let l:left_keyword_str = matchstr(l:left_text, a:pattern)

        let l:cur_keyword_str = l:left_keyword_str . a:cur_text[l:cur_keyword_pos - 1] . l:cur_keyword_str
        let l:cur_keyword_pos = match(l:left_text, a:pattern)
    endwhile

    if l:cur_keyword_str == ''
        " Get cursor word.
        let l:cur_text = strpart(getline('.'), 0, col('.') - 1) 
        let l:pattern = '\(^\|[^[:alpha:]_]\)[^\t ][*-]$'
        let [l:cur_keyword_pos, l:cur_keyword_str] = [match(l:cur_text, l:pattern), matchstr(l:cur_text, l:pattern)]
    endif

    return [l:cur_keyword_pos, l:cur_keyword_str]
endfunction"}}}

function! s:get_complete_words(cur_keyword_str)"{{{
    if g:NeoComplCache_EnableSkipCompletion && &l:completefunc == 'neocomplcache#auto_complete'
        let s:start_time = reltime()
    endif

    " Load plugin.
    let l:loaded_plugins = copy(s:plugins_func_table)

    " Get keyword list.
    let l:cache_keyword_lists = {}
    let l:len = 0
    for l:plugin in keys(l:loaded_plugins)
        let l:cache_keyword_lists[l:plugin] = call(l:loaded_plugins[l:plugin] . 'get_keyword_list', [a:cur_keyword_str])
        let l:len += len(l:cache_keyword_lists[l:plugin])
    endfor
    if l:len == 0 && (!g:NeoComplCache_EnableQuickMatch || match(a:cur_keyword_str, '\d$') < 0)
        return []
    endif

    if g:NeoComplCache_AlphabeticalOrder
        " Not calc rank.
        let l:order_func = 'neocomplcache#compare_words'
    else
        " Calc rank."{{{
        for l:plugin in keys(l:loaded_plugins)
            call call(l:loaded_plugins[l:plugin] . 'calc_rank', [l:cache_keyword_lists[l:plugin]])

            " Skip completion if takes too much time."{{{
            if neocomplcache#check_skip_time()
                call s:skip_function(a:cur_keyword_str)
                return []
            endif"}}}

            if g:NeoComplCache_DeleteRank0
                " Delete element if rank is 0.
                call filter(l:cache_keyword_lists[l:plugin], 'v:val.rank > 0')
            endif
        endfor

        let l:order_func = 'neocomplcache#compare_rank'"}}}
    endif

    let l:cache_keyword_filtered = []

    " Previous keyword completion.
    if g:NeoComplCache_PreviousKeywordCompletion && !g:NeoComplCache_AlphabeticalOrder "{{{
        let [l:prev_word, l:prepre_word] = s:get_prev_word(a:cur_keyword_str)
        for l:plugin in keys(l:loaded_plugins)
            let l:cache_keyword_list = l:cache_keyword_lists[l:plugin]
            call call(l:loaded_plugins[l:plugin] . 'calc_prev_rank', [l:cache_keyword_list, l:prev_word, l:prepre_word])

            " Sort.
            call extend(l:cache_keyword_filtered, sort(
                        \filter(copy(l:cache_keyword_list), 'v:val.prev_rank > 0'), 'neocomplcache#compare_prev_rank'))
            call filter(l:cache_keyword_lists[l:plugin], 'v:val.prev_rank == 0 && v:val.prepre_rank == 0')
        endfor
    endif"}}}

    " Extend list.
    let l:cache_keyword_list = []
    for l:plugin in keys(l:loaded_plugins)
        call extend(l:cache_keyword_list, l:cache_keyword_lists[l:plugin])
    endfor

    " Filtering for optimize."{{{
    if !g:NeoComplCache_AlphabeticalOrder
        if len(l:cache_keyword_list) > g:NeoComplCache_MaxList * 5
            call filter(l:cache_keyword_list, 'v:val.rank > 2')
        elseif len(l:cache_keyword_list) > g:NeoComplCache_MaxList * 3
            call filter(l:cache_keyword_list, 'v:val.rank > 1')
        endif
    endif"}}}

    " Sort.
    call extend(l:cache_keyword_filtered, sort(l:cache_keyword_list, l:order_func))

    " Trunk too many item.
    let l:cache_keyword_filtered = deepcopy(l:cache_keyword_filtered[:g:NeoComplCache_MaxList-1])

    " Quick match.
    if g:NeoComplCache_EnableQuickMatch"{{{
        " Append numbered list.
        if match(a:cur_keyword_str, '\d$') >= 0
            " Get numbered list.
            let l:numbered = get(s:prev_numbered_list, str2nr(matchstr(a:cur_keyword_str, '\d$')))
            if type(l:numbered) == type({})
                call insert(l:cache_keyword_filtered, l:numbered)
            endif

            " Get next numbered list.
            if match(a:cur_keyword_str, '\d\d$') >= 0
                let l:num = str2nr(matchstr(a:cur_keyword_str, '\d\d$'))-10
                if l:num >= 0
                    unlet l:numbered
                    let l:numbered = get(s:prepre_numbered_list, l:num)
                    if type(l:numbered) == type({})
                        call insert(l:cache_keyword_filtered, l:numbered)
                    endif
                endif
            endif
        endif

        " Check dup.
        let l:dup_check = {}
        let l:num = 0
        let l:numbered_ret = []
        for keyword in l:cache_keyword_filtered[:g:NeoComplCache_QuickMatchMaxLists]
            if !has_key(l:dup_check, keyword.word)
                let l:dup_check[keyword.word] = 1

                call add(l:numbered_ret, keyword)
            endif
            let l:num += 1
        endfor

        " Add number.
        let l:num = 0
        for keyword in l:numbered_ret
            let keyword.abbr = printf('%2d: %s', l:num, keyword.abbr)
            let l:num += 1
        endfor
        let l:cache_keyword_filtered = l:cache_keyword_filtered[g:NeoComplCache_QuickMatchMaxLists :]
        for keyword in l:cache_keyword_filtered
            let keyword.abbr = '    ' . keyword.abbr_save
        endfor

        " Append list.
        let l:cache_keyword_filtered = extend(l:numbered_ret, l:cache_keyword_filtered)

        " Save numbered lists.
        let s:prepre_numbered_list = s:prev_numbered_list[10:g:NeoComplCache_QuickMatchMaxLists-1]
        let s:prev_numbered_list = l:numbered_ret[:g:NeoComplCache_QuickMatchMaxLists-1]
    endif"}}}

    " Remove next keyword."{{{
    let l:next_keyword_str = matchstr('a'.strpart(getline('.'), col('.')-1),
                \'\v^%(' . neocomplcache#keyword_complete#current_keyword_pattern() . ')')[1:]
    if l:next_keyword_str != ''
        let l:next_keyword_str .= '$'
        for r in l:cache_keyword_filtered
            if r.word =~ l:next_keyword_str
                let r.word = strpart(r.word, 0, match(r.word, l:next_keyword_str))
                let r.dup = 1
            endif
        endfor
    endif"}}}

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

    return l:cache_keyword_filtered
endfunction"}}}

function! s:get_prev_word(cur_keyword_str)"{{{
    let l:keyword_pattern = neocomplcache#keyword_complete#current_keyword_pattern()
    let l:line_part = strpart(getline('.'), 0, col('.')-1 - len(a:cur_keyword_str))
    let l:prev_word_end = matchend(l:line_part, l:keyword_pattern)
    if l:prev_word_end > 0
        let l:word_end = matchend(l:line_part, l:keyword_pattern, l:prev_word_end)
        if l:word_end >= 0
            while l:word_end >= 0
                let l:prepre_word_end = l:prev_word_end
                let l:prev_word_end = l:word_end
                let l:word_end = matchend(l:line_part, l:keyword_pattern, l:prev_word_end)
            endwhile
            let l:prepre_word = matchstr(l:line_part[: l:prepre_word_end-1], l:keyword_pattern . '$')
        else
            let l:prepre_word = '^'
        endif

        let l:prev_word = matchstr(l:line_part[: l:prev_word_end-1], l:keyword_pattern . '$')
    else
        let l:prepre_word = ''
        let l:prev_word = '^'
    endif
    return [l:prev_word, l:prepre_word]
    "echo printf('prepre = %s, pre = %s', l:prepre_word, l:prev_word)
endfunction"}}}

function! s:skip_function(cur_keyword_str)
    echo 'Skipped auto completion'
    let s:skipped = 1
endfunction
"}}}

" Set pattern helper."{{{
function! s:set_keyword_pattern(filetype, pattern)"{{{
    for ft in split(a:filetype, ',')
        if !has_key(g:NeoComplCache_KeywordPatterns, ft) 
            let g:NeoComplCache_KeywordPatterns[ft] = a:pattern
        endif
    endfor
endfunction"}}}

function! s:set_omni_pattern(filetype, pattern)"{{{
    for ft in split(a:filetype, ',')
        if !has_key(g:NeoComplCache_OmniPatterns, ft) 
            let g:NeoComplCache_OmniPatterns[ft] = a:pattern
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
    if &completefunc == 'neocomplcache#manual_complete'
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

" vim: foldmethod=marker
