"=============================================================================
" FILE: init.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Jun 2013.
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

if !exists('s:is_enabled')
  let s:is_enabled = 0
endif

function! neocomplcache#init#lazy() "{{{
  if !exists('s:lazy_progress')
    let s:lazy_progress = 0
  endif

  if s:lazy_progress == 0
    call neocomplcache#init#_others()
    let s:is_enabled = 0
  elseif s:lazy_progress == 1
    call neocomplcache#init#_sources(get(g:neocomplcache_sources_list,
          \ neocomplcache#get_context_filetype(), ['_']))
  else
    call neocomplcache#init#_autocmds()
    let s:is_enabled = 1
  endif

  let s:lazy_progress += 1
endfunction"}}}

function! neocomplcache#init#enable() "{{{
  if neocomplcache#is_enabled()
    return
  endif

  call neocomplcache#init#_autocmds()
  call neocomplcache#init#_others()

  call neocomplcache#init#_sources(get(g:neocomplcache_sources_list,
        \ neocomplcache#get_context_filetype(), ['_']))
  let s:is_enabled = 1
endfunction"}}}

function! neocomplcache#init#disable() "{{{
  if !neocomplcache#is_enabled()
    call neocomplcache#print_warning(
          \ 'neocomplcache is disabled! This command is ignored.')
    return
  endif

  let s:is_enabled = 0

  augroup neocomplcache
    autocmd!
  augroup END

  delcommand NeoComplCacheDisable

  call neocomplcache#helper#call_hook(filter(values(
        \ neocomplcache#variables#get_sources()), 'v:val.loaded'),
        \ 'on_final', {})
endfunction"}}}

function! neocomplcache#init#is_enabled() "{{{
  return s:is_enabled
endfunction"}}}

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

  command! -nargs=0 -bar NeoComplCacheDisable
        \ call neocomplcache#init#disable()
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
        \'[^"]*"\|[[:alnum:]_:-]*>')
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
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'J6uil_say', 'J6uil')
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_same_filetype_lists',
        \ 'vimconsole', 'vim')

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
        \ 'text,help,tex,gitcommit,vcs-commit,markdown', 1)
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

  " Set custom.
  call s:set_default_custom()
endfunction"}}}

function! neocomplcache#init#_current_neocomplcache() "{{{
  let b:neocomplcache = {
        \ 'context' : {
        \      'input' : '',
        \      'complete_pos' : -1,
        \      'complete_str' : '',
        \      'candidates' : [],
        \ },
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
        \ 'complete_str' : '',
        \ 'complete_pos' : -1,
        \ 'candidates' : [],
        \ 'complete_results' : [],
        \ 'complete_sources' : [],
        \ 'manual_sources' : [],
        \ 'start_time' : reltime(),
        \}
endfunction"}}}

function! neocomplcache#init#_sources(names) "{{{
  if !exists('s:loaded_source_files')
    " Initialize.
    let s:loaded_source_files = {}
    let s:loaded_all_sources = 0
    let s:runtimepath_save = ''
  endif

  " Initialize sources table.
  if s:loaded_all_sources && &runtimepath ==# s:runtimepath_save
    return
  endif

  let runtimepath_save = neocomplcache#util#split_rtp(s:runtimepath_save)
  let runtimepath = neocomplcache#util#join_rtp(
        \ filter(neocomplcache#util#split_rtp(),
        \ 'index(runtimepath_save, v:val) < 0'))
  let sources = neocomplcache#variables#get_sources()

  for name in filter(copy(a:names), '!has_key(sources, v:val)')
    " Search autoload.
    for source_name in map(split(globpath(runtimepath,
          \ 'autoload/neocomplcache/sources/*.vim'), '\n'),
          \ "fnamemodify(v:val, ':t:r')")
      if has_key(s:loaded_source_files, source_name)
        continue
      endif

      let s:loaded_source_files[source_name] = 1

      let source = neocomplcache#sources#{source_name}#define()
      if empty(source)
        " Ignore.
        continue
      endif

      call neocomplcache#define_source(source)
    endfor

    if name == '_'
      let s:loaded_all_sources = 1
      let s:runtimepath_save = &runtimepath
    endif
  endfor
endfunction"}}}

function! neocomplcache#init#_source(source) "{{{
  let default = {
        \ 'max_candidates' : 0,
        \ 'filetypes' : {},
        \ 'hooks' : {},
        \ 'matchers' : ['matcher_old'],
        \ 'sorters' : ['sorter_rank'],
        \ 'converters' : [
        \      'converter_remove_next_keyword',
        \      'converter_delimiter',
        \      'converter_case',
        \      'converter_abbr',
        \ ],
        \ 'neocomplcache__context' : copy(neocomplcache#get_context()),
        \ }

  let source = extend(copy(default), a:source)

  " Overwritten by user custom.
  let custom = neocomplcache#variables#get_custom().sources
  let source = extend(source, get(custom, source.name,
        \ get(custom, '_', {})))

  let source.loaded = 0
  " Source kind convertion.
  if source.kind ==# 'plugin' ||
        \ (!has_key(source, 'gather_candidates') &&
        \  !has_key(source, 'get_complete_words'))
    let source.kind = 'keyword'
  elseif source.kind ==# 'ftplugin' || source.kind ==# 'complfunc'
    " For compatibility.
    let source.kind = 'manual'
  else
    let source.kind = 'manual'
  endif

  if !has_key(source, 'rank')
    " Set default rank.
    let source.rank = (source.kind ==# 'keyword') ? 5 :
          \ empty(source.filetypes) ? 10 : 100
  endif

  if !has_key(source, 'min_pattern_length')
    " Set min_pattern_length.
    let source.min_pattern_length = (source.kind ==# 'keyword') ?
          \ g:neocomplcache_auto_completion_start_length : 0
  endif

  let source.neocomplcache__context.source_name = source.name

  " Note: This routine is for compatibility of old sources implementation.
  " Initialize sources.
  if empty(source.filetypes) && has_key(source, 'initialize')
    try
      call source.initialize()
    catch
      call neocomplcache#print_error(v:throwpoint)
      call neocomplcache#print_error(v:exception)
      call neocomplcache#print_error(
            \ 'Error occured in source''s initialize()!')
      call neocomplcache#print_error(
            \ 'Source name is ' . source.name)
    endtry

    let source.loaded = 1
  endif

  return source
endfunction"}}}

function! neocomplcache#init#_filters(names) "{{{
  let _ = []
  let filters = neocomplcache#variables#get_filters()

  for name in a:names
    if !has_key(filters, name)
      " Search autoload.
      for filter_name in map(split(globpath(&runtimepath,
            \ 'autoload/neocomplcache/filters/'.
            \   substitute(name,
            \'^\%(matcher\|sorter\|converter\)_[^/_-]\+\zs[/_-].*$', '', '')
            \  .'*.vim'), '\n'), "fnamemodify(v:val, ':t:r')")
        let filter = neocomplcache#filters#{filter_name}#define()
        if empty(filter)
          " Ignore.
          continue
        endif

        call neocomplcache#define_filter(filter)
      endfor

      if !has_key(filters, name)
        " Not found.
        call neocomplcache#print_error(
              \ printf('filter name : %s is not found.', string(name)))
        continue
      endif
    endif

    if has_key(filters, name)
      call add(_, filters[name])
    endif
  endfor

  return _
endfunction"}}}

function! neocomplcache#init#_filter(filter) "{{{
  let default = {
        \ }

  let filter = extend(default, a:filter)
  if !has_key(filter, 'kind')
    let filter.kind =
          \ (filter.name =~# '^matcher_') ? 'matcher' :
          \ (filter.name =~# '^sorter_') ? 'sorter' : 'converter'
  endif

  return filter
endfunction"}}}

function! s:set_default_custom() "{{{
  let custom = neocomplcache#variables#get_custom().sources

  " Initialize completion length.
  for [source_name, length] in items(
        \ g:neocomplcache_source_completion_length)
    if !has_key(custom, source_name)
      let custom[source_name] = {}
    endif
    let custom[source_name].min_pattern_length = length
  endfor

  " Initialize rank.
  for [source_name, rank] in items(
        \ g:neocomplcache_source_rank)
    if !has_key(custom, source_name)
      let custom[source_name] = {}
    endif
    let custom[source_name].rank = rank
  endfor
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
