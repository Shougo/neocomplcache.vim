**neocomplcache**
=================

Description
-----------

Neocomplcache performs keyword completion by making a cache of keywords in
a buffer. I implemented it because unlike the Vim builtin keyword completion.
Neocomplcache can be customized flexibly. Unfortunately neocomplcache may use
more memory than other plugins.

Installation
============

* Extract the file and Put files in your Vim directory
   (usually ~/.vim/ or Program Files/Vim/vimfiles on Windows).
* Execute `|:NeoComplCacheEnable|` command or
`let g:neocomplcache_enable_at_startup = 1`
in your .vimrc.

Caution
-------

Because all variable names are changed in neocomplcache Ver.5, it is not
backwards compatible. If you want to upgrade, you should use the following
script from Mr.thinca.

http://gist.github.com/422503

Screen shots
============

Quick match
-----------
![Quick match.](http://3.bp.blogspot.com/_ci2yBnqzJgM/TD1PeahCmOI/AAAAAAAAADc/Rz_Pbpr92z4/s1600/quick_match.png)

Snippet completion like snipMate.
---------------------------------
http://3.bp.blogspot.com/_ci2yBnqzJgM/SfkgaHXLS0I/AAAAAAAAAA4/TmaylpFl_Uw/s1600-h/screenshot2.png
![Snippet completion like snipMate.](http://3.bp.blogspot.com/_ci2yBnqzJgM/SfkgaHXLS0I/AAAAAAAAAA4/TmaylpFl_Uw/s1600-h/screenshot2.png)

Original filename completion.
-----------
![Original filename completion.](http://1.bp.blogspot.com/_ci2yBnqzJgM/TD1O5_bOQ2I/AAAAAAAAADE/vHf9Xg_mrTI/s1600/filename_complete.png)

Register completion.
-----------
![Register completion.](http://1.bp.blogspot.com/_ci2yBnqzJgM/TD1Pel4fomI/AAAAAAAAADk/YsAxF8i6r3w/s1600/register_complete.png)

Omni completion.
----------------
![Omni completion.](http://2.bp.blogspot.com/_ci2yBnqzJgM/TD1PTolkTBI/AAAAAAAAADU/knJ3eniuHWI/s1600/omni_complete.png)

Completion with vimshell(http://github.com/Shougo/vimshell).
------------------------------------------------------------
![Completion with vimshell(http://github.com/Shougo/vimshell).](http://1.bp.blogspot.com/_ci2yBnqzJgM/TD1PLfdQrwI/AAAAAAAAADM/2pSFRTHwYOY/s1600/neocomplcache_with_vimshell.png)

Vim completion
------------------------------------------------------------
![Vim completion.](http://1.bp.blogspot.com/_ci2yBnqzJgM/TD1PfKTlwnI/AAAAAAAAADs/nOGWTRLuae8/s1600/vim_complete.png)

Setting examples

```vim
" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplcache.
let g:neocomplcache_enable_at_startup = 1
" Use smartcase.
let g:neocomplcache_enable_smart_case = 1
" Use camel case completion.
let g:neocomplcache_enable_camel_case_completion = 1
" Use underbar completion.
let g:neocomplcache_enable_underbar_completion = 1
" Set minimum syntax keyword length.
let g:neocomplcache_min_syntax_length = 3
let g:neocomplcache_lock_buffer_name_pattern = '\*ku\*'

" Define dictionary.
let g:neocomplcache_dictionary_filetype_lists = {
    \ 'default' : '',
    \ 'vimshell' : $HOME.'/.vimshell_hist',
    \ 'scheme' : $HOME.'/.gosh_completions'
    \ }

" Define keyword.
if !exists('g:neocomplcache_keyword_patterns')
  let g:neocomplcache_keyword_patterns = {}
endif
let g:neocomplcache_keyword_patterns['default'] = '\h\w*'

" Plugin key-mappings.
imap <C-k>     <Plug>(neocomplcache_snippets_expand)
smap <C-k>     <Plug>(neocomplcache_snippets_expand)
inoremap <expr><C-g>     neocomplcache#undo_completion()
inoremap <expr><C-l>     neocomplcache#complete_common_string()

" SuperTab like snippets behavior.
"imap <expr><TAB> neocomplcache#sources#snippets_complete#expandable() ? "\<Plug>(neocomplcache_snippets_expand)" : pumvisible() ? "\<C-n>" : "\<TAB>"

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <expr><CR>  neocomplcache#smart_close_popup() . "\<CR>"
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplcache#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplcache#close_popup()
inoremap <expr><C-e>  neocomplcache#cancel_popup()

" AutoComplPop like behavior.
"let g:neocomplcache_enable_auto_select = 1

" Shell like behavior(not recommended).
"set completeopt+=longest
"let g:neocomplcache_enable_auto_select = 1
"let g:neocomplcache_disable_auto_complete = 1
"inoremap <expr><TAB>  pumvisible() ? "\<Down>" : "\<TAB>"
"inoremap <expr><CR>  neocomplcache#smart_close_popup() . "\<CR>"

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

" Enable heavy omni completion.
if !exists('g:neocomplcache_omni_patterns')
  let g:neocomplcache_omni_patterns = {}
endif
let g:neocomplcache_omni_patterns.ruby = '[^. *\t]\.\w*\|\h\w*::'
"autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
let g:neocomplcache_omni_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
let g:neocomplcache_omni_patterns.c = '\%(\.\|->\)\h\w*'
let g:neocomplcache_omni_patterns.cpp = '\h\w*\%(\.\|->\)\h\w*\|\h\w*::'
```
