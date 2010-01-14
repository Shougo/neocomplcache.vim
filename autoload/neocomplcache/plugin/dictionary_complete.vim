"=============================================================================
" FILE: dictionary.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 11 Jun 2010
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
"   1.00:
"    - Initial version.
" }}}
"=============================================================================

function! neocomplcache#plugin#dictionary_complete#initialize()"{{{
    " Initialize.
    let s:dictionary_list = {}
    let s:completion_length = neocomplcache#get_completion_length('dictionary_complete')
    
    " Initialize dictionary."{{{
    if !exists('g:NeoComplCache_DictionaryFileTypeLists')
        let g:NeoComplCache_DictionaryFileTypeLists = {}
    endif
    if !has_key(g:NeoComplCache_DictionaryFileTypeLists, 'default')
        let g:NeoComplCache_DictionaryFileTypeLists['default'] = ''
    endif
    "}}}

    " Set caching event.
    autocmd neocomplcache FileType * call s:caching()

    " Add command.
    command! -nargs=? -complete=customlist,neocomplcache#filetype_complete NeoComplCacheCachingDictionary call s:recaching(<q-args>)

    " Create cache directory.
    if !isdirectory(g:NeoComplCache_TemporaryDir . '/dictionary_cache')
        call mkdir(g:NeoComplCache_TemporaryDir . '/dictionary_cache')
    endif
endfunction"}}}

function! neocomplcache#plugin#dictionary_complete#finalize()"{{{
    delcommand NeoComplCacheCachingDictionary
endfunction"}}}

function! neocomplcache#plugin#dictionary_complete#get_keyword_list(cur_keyword_str)"{{{
    let l:list = []
    
    for l:source in neocomplcache#get_sources_list(s:dictionary_list, &filetype)
        if len(a:cur_keyword_str) < s:completion_length ||
                    \neocomplcache#check_match_filter(a:cur_keyword_str, s:completion_length)
            let l:list += neocomplcache#keyword_filter(neocomplcache#unpack_dictionary(l:source), a:cur_keyword_str)
        else
            let l:key = tolower(a:cur_keyword_str[: s:completion_length-1])

            if has_key(l:source, l:key)
                if len(a:cur_keyword_str) == s:completion_length
                    let l:list += l:source[l:key]
                else
                    let l:list += neocomplcache#keyword_filter(copy(l:source[l:key]), a:cur_keyword_str)
                endif
            endif
        endif
    endfor

    return l:list
endfunction"}}}

function! s:caching()"{{{
    if !buflisted(bufnr('%'))
        return
    endif

    for l:filetype in keys(neocomplcache#get_source_filetypes(&filetype))
        if !has_key(s:dictionary_list, l:filetype)
            if g:NeoComplCache_CachingPercentInStatusline
                let l:statusline_save = &l:statusline
            endif

            call neocomplcache#print_caching('Caching dictionary "' . l:filetype . '"... please wait.')

            let s:dictionary_list[l:filetype] = s:initialize_dictionary(l:filetype)

            call neocomplcache#print_caching('Caching done.')

            if g:NeoComplCache_CachingPercentInStatusline
                let &l:statusline = l:statusline_save
            endif
        endif
    endfor
endfunction"}}}

function! s:recaching(filetype)"{{{
    if a:filetype == ''
        if &filetype != ''
            let l:filetype = &filetype
        else
            let l:filetype = 'nothing'
        endif
    else
        let l:filetype = a:filetype
    endif

    " Caching.
    if g:NeoComplCache_CachingPercentInStatusline
        let l:statusline_save = &l:statusline
    endif

    call neocomplcache#print_caching('Caching dictionary "' . l:filetype . '"... please wait.')
    let s:dictionary_list[l:filetype] = s:caching_from_dict(l:filetype)
    
    call neocomplcache#print_caching('Caching done.')

    if g:NeoComplCache_CachingPercentInStatusline
        let &l:statusline = l:statusline_save
    endif
endfunction"}}}

function! s:initialize_dictionary(filetype)"{{{
    let l:keyword_lists = neocomplcache#cache#index_load_from_cache('dictionary_cache', a:filetype, s:completion_length)
    if !empty(l:keyword_lists)
        " Caching from cache.
        return l:keyword_lists
    endif

    return s:caching_from_dict(a:filetype)
endfunction"}}}

function! s:caching_from_dict(filetype)"{{{
    if !has_key(g:NeoComplCache_DictionaryFileTypeLists, a:filetype)
        return {}
    endif
    
    let l:keyword_list = []
    
    for l:dictionary in split(g:NeoComplCache_DictionaryFileTypeLists[a:filetype], ',')
        if filereadable(l:dictionary)
            let l:keyword_list += neocomplcache#cache#load_from_file(l:dictionary, 
                        \neocomplcache#get_keyword_pattern(a:filetype), 'D')
        endif
    endfor
    
    let l:keyword_dict = {}

    for l:keyword in l:keyword_list
        let l:key = tolower(l:keyword.word[: s:completion_length-1])
        if !has_key(l:keyword_dict, l:key)
            let l:keyword_dict[l:key] = []
        endif
        call add(l:keyword_dict[l:key], l:keyword)
    endfor 

    " Save dictionary cache.
    call neocomplcache#cache#save_cache('dictionary_cache', &filetype, neocomplcache#unpack_dictionary(l:keyword_dict))
    
    return l:keyword_dict
endfunction"}}}
" vim: foldmethod=marker
