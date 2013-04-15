"=============================================================================
" FILE: init.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 15 Apr 2013.
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

function! neocomplcache#init#_autocmds() "{{{
  augroup neocomplcache
    autocmd!
    autocmd InsertEnter *
          \ call neocomplcache#handler#_on_insert_enter()
    autocmd InsertLeave *
          \ call neocomplcache#handler#_on_insert_leave()
    autocmd CursorMovedI *
          \ call neocomplcache#handler#_on_moved_i()
    autocmd BufWritePost *
          \ call neocomplcache#handler#_on_write_post()
  augroup END

  if g:neocomplcache_enable_insert_char_pre
        \ && (v:version > 703 || v:version == 703 && has('patch418'))
    autocmd neocomplcache InsertCharPre *
          \ call neocomplcache#handler#_do_auto_complete('InsertCharPre')
  elseif g:neocomplcache_enable_cursor_hold_i
    augroup neocomplcache
      autocmd CursorHoldI *
            \ call neocomplcache#handler#_do_auto_complete('CursorHoldI')
      autocmd InsertEnter *
            \ call neocomplcache#handler#_change_update_time()
      autocmd InsertLeave *
            \ call neocomplcache#handler#_restore_update_time()
    augroup END
  else
    autocmd neocomplcache CursorMovedI *
          \ call neocomplcache#handler#_do_auto_complete('CursorMovedI')
  endif

  if (v:version > 703 || v:version == 703 && has('patch598'))
    autocmd neocomplcache CompleteDone *
          \ call neocomplcache#handler#_on_complete_done()
  endif
endfunction"}}}

function! neocomplcache#init#_others() "{{{
  call neocomplcache#init#_variables()

  call neocomplcache#context_filetype#initialize()

  call neocomplcache#commands#_initialize()

  " Save options.
  let s:completefunc_save = &completefunc
  let s:completeopt_save = &completeopt

  " Set completefunc.
  let &completefunc = 'neocomplcache#complete#manual_complete'
  let &l:completefunc = 'neocomplcache#complete#manual_complete'

  " For auto complete keymappings.
  call neocomplcache#mappings#define_default_mappings()

  " Detect set paste.
  if &paste
    redir => output
    99verbose set paste
    redir END
    call neocomplcache#print_error(output)
    call neocomplcache#print_error(
          \ 'Detected set paste! Disabled neocomplcache.')
  endif
endfunction"}}}

function! neocomplcache#init#_variables() "{{{
  " Initialize keyword patterns. "{{{
  call neocomplcache#util#set_default(
        \ 'g:neocomplcache_keyword_patterns', {})
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'_',
        \'\k\+')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_keyword_patterns',
        \'filename',
        \ neocomplcache#util#is_windows() ?
        \'\%(\a\+:/\)\?\%([/[:alnum:]()$+_~.\x80-\xff-]\|[^[:print:]]\|\\.\)\+' :
        \'\%([/\[\][:alnum:]()$+_~.-]\|[^[:print:]]\|\\.\)\+')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'lisp,scheme,clojure,int-gosh,int-clisp,int-clj',
        \'[[:alpha:]+*/@$_=.!?-][[:alnum:]+*/@$_:=.!?-]*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'ruby,int-irb',
        \'^=\%(b\%[egin]\|e\%[nd]\)\|\%(@@\|[:$@]\)\h\w*\|\h\w*\%(::\w*\)*[!?]\?')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'php,int-php',
        \'</\?\%(\h[[:alnum:]_-]*\s*\)\?\%(/\?>\)\?'.
        \'\|\$\h\w*\|\h\w*\%(\%(\\\|::\)\w*\)*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'perl,int-perlsh',
        \'<\h\w*>\?\|[$@%&*]\h\w*\|\h\w*\%(::\w*\)*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'perl6,int-perl6',
        \'<\h\w*>\?\|[$@%&][!.*?]\?\h[[:alnum:]_-]*'.
        \'\|\h[[:alnum:]_-]*\%(::[[:alnum:]_-]*\)*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'pir',
        \'[$@%.=]\?\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'pasm',
        \'[=]\?\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'vim,help',
        \'-\h[[:alnum:]-]*=\?\|\c\[:\%(\h\w*:\]\)\?\|&\h[[:alnum:]_:]*\|'.
        \'<SID>\%(\h\w*\)\?\|<Plug>([^)]*)\?'.
        \'\|<\h[[:alnum:]_-]*>\?\|\h[[:alnum:]_:#]*!\?\|$\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'tex',
        \'\\\a{\a\{1,2}}\|\\[[:alpha:]@][[:alnum:]@]*'.
        \'\%({\%([[:alnum:]:_]\+\*\?}\?\)\?\)\?\|\a[[:alnum:]:_]*\*\?')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'sh,zsh,int-zsh,int-bash,int-sh',
        \'[[:alpha:]_.-][[:alnum:]_.-]*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'vimshell',
        \'\$\$\?\w*\|[[:alpha:]_.\\/~-][[:alnum:]_.\\/~-]*\|\d\+\%(\.\d\+\)\+')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'ps1,int-powershell',
        \'\[\h\%([[:alnum:]_.]*\]::\)\?\|[$%@.]\?[[:alpha:]_.:-][[:alnum:]_.:-]*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'c',
        \'^\s*#\s*\h\w*\|\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'cpp',
        \'^\s*#\s*\h\w*\|\h\w*\%(::\w*\)*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'objc',
        \'^\s*#\s*\h\w*\|\h\w*\|@\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'objcpp',
        \'^\s*#\s*\h\w*\|\h\w*\%(::\w*\)*\|@\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'objj',
        \'\h\w*\|@\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'d',
        \'\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'python,int-python,int-ipython',
        \'[@]\?\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'cs',
        \'\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'java',
        \'[@]\?\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'javascript,actionscript,int-js,int-kjs,int-rhino',
        \'\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'coffee,int-coffee',
        \'[@]\?\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'awk',
        \'\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'haskell,int-ghci',
        \'\%(\u\w*\.\)\+[[:alnum:]_'']*\|[[:alpha:]_''][[:alnum:]_'']*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'ml,ocaml,int-ocaml,int-sml,int-smlsharp',
        \'[''`#.]\?\h[[:alnum:]_'']*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'erlang,int-erl',
        \'^\s*-\h\w*\|\%(\h\w*:\)*\h\w\|\h[[:alnum:]_@]*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'html,xhtml,xml,markdown,eruby',
        \'</\?\%([[:alnum:]_:-]\+\s*\)\?\%(/\?>\)\?\|&\h\%(\w*;\)\?'.
        \'\|\h[[:alnum:]_-]*="\%([^"]*"\?\)\?\|\h[[:alnum:]_:-]*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'css,stylus,scss,less',
        \'[@#.]\?[[:alpha:]_:-][[:alnum:]_:-]*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'tags',
        \'^[^!][^/[:blank:]]*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'pic',
        \'^\s*#\h\w*\|\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'arm',
        \'\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'asmh8300',
        \'[[:alpha:]_.][[:alnum:]_.]*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'masm',
        \'\.\h\w*\|[[:alpha:]_@?$][[:alnum:]_@?$]*\|\h\w*:\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'nasm',
        \'^\s*\[\h\w*\|[%.]\?\h\w*\|\%(\.\.@\?\|%[%$!]\)\%(\h\w*\)\?\|\h\w*:\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'asm',
        \'[%$.]\?\h\w*\%(\$\h\w*\)\?')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'gas',
        \'[$.]\?\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'gdb,int-gdb',
        \'$\h\w*\|[[:alnum:]:._-]\+')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'make',
        \'[[:alpha:]_.-][[:alnum:]_.-]*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'scala,int-scala',
        \'\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'int-termtter',
        \'\h[[:alnum:]_/-]*\|\$\a\+\|#\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'int-earthquake',
        \'[:#$]\h\w*\|\h[[:alnum:]_/-]*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'dosbatch,int-cmdproxy',
        \'\$\w+\|[[:alpha:]_./-][[:alnum:]_.-]*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'vb',
        \'\h\w*\|#\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'lua',
        \'\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \ 'zimbu',
        \'\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'konoha',
        \'[*$@%]\h\w*\|\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'cobol',
        \'\a[[:alnum:]-]*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'coq',
        \'\h[[:alnum:]_'']*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'tcl',
        \'[.-]\h\w*\|\h\w*')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_keyword_patterns',
        \'nyaos,int-nyaos',
        \'\h\w*')
  "}}}

  " Initialize next keyword patterns. "{{{
  call neocomplcache#util#set_default(
        \ 'g:neocomplcache_next_keyword_patterns', {})
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_next_keyword_patterns', 'perl',
        \'\h\w*>')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_next_keyword_patterns', 'perl6',
        \'\h\w*>')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_next_keyword_patterns', 'vim,help',
        \'\w*()\?\|\w*:\]\|[[:alnum:]_-]*[)>=]')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_next_keyword_patterns', 'python',
        \'\w*()\?')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_next_keyword_patterns', 'tex',
        \'[[:alnum:]:_]\+[*[{}]')
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_next_keyword_patterns', 'html,xhtml,xml,mkd',
        \'[[:alnum:]_:-]*>\|[^"]*"')
  "}}}

  " Initialize same file type lists. "{{{
  call neocomplcache#util#set_default(
        \ 'g:neocomplcache_same_filetype_lists', {})
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'c', 'cpp')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'cpp', 'c')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'erb', 'ruby,html,xhtml')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'html,xml', 'xhtml')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'html,xhtml', 'css,stylus,less')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'css', 'scss')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'scss', 'css')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'stylus', 'css')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'less', 'css')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'xhtml', 'html,xml')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'help', 'vim')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'tex', 'bib,plaintex')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'plaintex', 'bib,tex')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'lingr-say', 'lingr-messages,lingr-members')

  " Interactive filetypes.
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-irb', 'ruby')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-ghci,int-hugs', 'haskell')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-python,int-ipython', 'python')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-gosh', 'scheme')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-clisp', 'lisp')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-erl', 'erlang')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-zsh', 'zsh')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-bash', 'bash')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-sh', 'sh')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-cmdproxy', 'dosbatch')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-powershell', 'powershell')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-perlsh', 'perl')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-perl6', 'perl6')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-ocaml', 'ocaml')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-clj', 'clojure')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-sml,int-smlsharp', 'sml')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-js,int-kjs,int-rhino', 'javascript')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-coffee', 'coffee')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-gdb', 'gdb')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-scala', 'scala')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-nyaos', 'nyaos')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'int-php', 'php')
  "}}}

  " Initialize delimiter patterns. "{{{
  call neocomplcache#util#set_default(
        \ 'g:neocomplcache_delimiter_patterns', {})
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_delimiter_patterns',
        \ 'vim,help', ['#'])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_delimiter_patterns',
        \ 'erlang,lisp,int-clisp', [':'])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_delimiter_patterns',
        \ 'lisp,int-clisp', ['/', ':'])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_delimiter_patterns',
        \ 'clojure,int-clj', ['/', '\.'])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_delimiter_patterns',
        \ 'perl,cpp', ['::'])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_delimiter_patterns',
        \ 'php', ['\', '::'])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_delimiter_patterns',
        \ 'java,d,javascript,actionscript,'.
        \ 'ruby,eruby,haskell,int-ghci,coffee,zimbu,konoha',
        \ ['\.'])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_delimiter_patterns',
        \ 'lua', ['\.', ':'])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_delimiter_patterns',
        \ 'perl6', ['\.', '::'])
  "}}}

  " Initialize ctags arguments. "{{{
  call neocomplcache#util#set_default(
        \ 'g:neocomplcache_ctags_arguments_list', {})
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_ctags_arguments_list',
        \ '_', '')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_ctags_arguments_list', 'vim',
        \ '--extra=fq --fields=afmiKlnsStz ' .
        \ "--regex-vim='/function!? ([a-z#:_0-9A-Z]+)/\\1/function/'")
  if neocomplcache#util#is_mac()
    call neocomplcache#util#set_default_dictionary(
          \ 'g:neocomplcache_ctags_arguments_list', 'c',
          \ '--c-kinds=+p --fields=+iaS --extra=+q
          \ -I__DARWIN_ALIAS,__DARWIN_ALIAS_C,__DARWIN_ALIAS_I,__DARWIN_INODE64
          \ -I__DARWIN_1050,__DARWIN_1050ALIAS,__DARWIN_1050ALIAS_C,__DARWIN_1050ALIAS_I,__DARWIN_1050INODE64
          \ -I__DARWIN_EXTSN,__DARWIN_EXTSN_C
          \ -I__DARWIN_LDBL_COMPAT,__DARWIN_LDBL_COMPAT2')
  else
    call neocomplcache#util#set_default_dictionary(
          \ 'g:neocomplcache_ctags_arguments_list', 'c',
          \ '-R --sort=1 --c-kinds=+p --fields=+iaS --extra=+q ' .
          \ '-I __wur,__THROW,__attribute_malloc__,__nonnull+,'.
          \   '__attribute_pure__,__attribute_warn_unused_result__,__attribute__+')
  endif
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_ctags_arguments_list', 'cpp',
        \ '--language-force=C++ -R --sort=1 --c++-kinds=+p --fields=+iaS --extra=+q '.
        \ '-I __wur,__THROW,__attribute_malloc__,__nonnull+,'.
        \   '__attribute_pure__,__attribute_warn_unused_result__,__attribute__+')
  "}}}

  " Initialize text mode filetypes. "{{{
  call neocomplcache#util#set_default(
        \ 'g:neocomplcache_text_mode_filetypes', {})
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_text_mode_filetypes',
        \ 'text,help,tex,gitcommit,vcs-commit', 1)
  "}}}

  " Initialize tags filter patterns. "{{{
  call neocomplcache#util#set_default(
        \ 'g:neocomplcache_tags_filter_patterns', {})
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_tags_filter_patterns', 'c,cpp',
        \'v:val.word !~ ''^[~_]''')
  "}}}

  " Initialize force omni completion pattern. "{{{
  call neocomplcache#util#set_default(
        \ 'g:neocomplcache_force_omni_patterns', {})
  call neocomplcache#util#set_default_dictionary(
        \'g:neocomplcache_force_omni_patterns', 'objc',
        \'\h\w\+\|[^.[:digit:] *\t]\%(\.\|->\)')
  "}}}

  " Initialize ignore composite filetypes
  call neocomplcache#util#set_default(
        \ 'g:neocomplcache_ignore_composite_filetype_lists', {})

  " Must g:neocomplcache_auto_completion_start_length > 1.
  if g:neocomplcache_auto_completion_start_length < 1
    let g:neocomplcache_auto_completion_start_length = 1
  endif
  " Must g:neocomplcache_min_keyword_length > 1.
  if g:neocomplcache_min_keyword_length < 1
    let g:neocomplcache_min_keyword_length = 1
  endif

  " Initialize omni function list. "{{{
  if !exists('g:neocomplcache_omni_functions')
    let g:neocomplcache_omni_functions = {}
  endif
  "}}}
endfunction"}}}

function! neocomplcache#init#_current_neocomplcache() "{{{
  let b:neocomplcache = {
        \ 'lock' : 0,
        \ 'skip_next_complete' : 0,
        \ 'filetype' : '',
        \ 'context_filetype' : '',
        \ 'context_filetype_range' :
        \    [[1, 1], [line('$'), len(getline('$'))+1]],
        \ 'completion_length' : -1,
        \ 'update_time_save' : &updatetime,
        \ 'foldinfo' : [],
        \ 'lock_sources' : {},
        \ 'skipped' : 0,
        \ 'event' : '',
        \ 'cur_text' : '',
        \ 'old_cur_text' : '',
        \ 'cur_keyword_str' : '',
        \ 'cur_keyword_pos' : -1,
        \ 'complete_words' : [],
        \ 'complete_results' : {},
        \ 'start_time' : reltime(),
        \}
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
