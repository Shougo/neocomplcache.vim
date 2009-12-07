"=============================================================================
" FILE: cache.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 04 Dec 2009
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
"=============================================================================

function! neocomplcache#cache#save()"{{{
endfunction"}}}

function! neocomplcache#cache#getfilename(cache_dir, filename)"{{{
    let l:cache_name = printf('%s/%s/%s=', g:NeoComplCache_TemporaryDir, a:cache_dir, 
                \substitute(substitute(a:filename, ':', '=-', 'g'), '[/\\]', '=+', 'g'))
    return l:cache_name
endfunction"}}}
function! neocomplcache#cache#filereadable(cache_dir, filename)"{{{
    let l:cache_name = printf('%s/%s/%s=', g:NeoComplCache_TemporaryDir, a:cache_dir, 
                \substitute(substitute(a:filename, ':', '=-', 'g'), '[/\\]', '=+', 'g'))
    return filereadable(l:cache_name)
endfunction"}}}
function! neocomplcache#cache#readfile(cache_dir, filename)"{{{
    let l:cache_name = printf('%s/%s/%s=', g:NeoComplCache_TemporaryDir, a:cache_dir, 
                \substitute(substitute(a:filename, ':', '=-', 'g'), '[/\\]', '=+', 'g'))
    return filereadable(l:cache_name) ? readfile(l:cache_name) : []
endfunction"}}}
function! neocomplcache#cache#writefile(cache_dir, filename, list)"{{{
    " Create cache directory.
    let l:cache_dir = g:NeoComplCache_TemporaryDir . '/' . a:cache_dir
    if !isdirectory(l:cache_dir)
        call mkdir(l:cache_dir, 'p')
    endif
    
    let l:cache_name = printf('%s/%s=', l:cache_dir, substitute(substitute(a:filename, ':', '=-', 'g'), '[/\\]', '=+', 'g'))

    call writefile(a:list, l:cache_name)
endfunction"}}}

" vim: foldmethod=marker
