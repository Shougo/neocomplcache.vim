"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Mar 2013.
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

if !exists('g:loaded_neocomplcache')
  runtime! plugin/neocomplcache.vim
endif

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

function! s:initialize_script_variables() "{{{
  let s:is_enabled = 1
  let s:complfunc_sources = {}
  let s:plugin_sources = {}
  let s:ftplugin_sources = {}
  let s:loaded_ftplugin_sources = {}
  let s:loaded_source_files = {}
  let s:use_sources = {}
  let s:filetype_frequencies = {}
  let s:loaded_all_sources = 0
  let s:runtimepath_save = ''

  if has('reltime')
    let s:start_time = reltime()
  endif
endfunction"}}}

function! s:initialize_autocmds() "{{{
  augroup neocomplcache
    autocmd!
    autocmd InsertEnter * call s:on_insert_enter()
    autocmd InsertLeave * call s:on_insert_leave()
    autocmd CursorMovedI * call s:on_moved_i()
  augroup END

  if g:neocomplcache_enable_insert_char_pre
        \ && (v:version > 703 || v:version == 703 && has('patch418'))
    autocmd neocomplcache InsertCharPre *
          \ call s:do_auto_complete('InsertCharPre')
  elseif g:neocomplcache_enable_cursor_hold_i
    augroup neocomplcache
      autocmd CursorHoldI *
            \ call s:do_auto_complete('CursorHoldI')
      autocmd InsertEnter *
            \ call s:change_update_time()
      autocmd InsertLeave *
            \ call s:restore_update_time()
    augroup END
  else
    autocmd neocomplcache CursorMovedI *
          \ call s:do_auto_complete('CursorMovedI')
  endif

  if (v:version > 703 || v:version == 703 && has('patch598'))
    autocmd neocomplcache CompleteDone *
          \ call s:on_complete_done()
  endif
endfunction"}}}

function! s:initialize_others() "{{{
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
        \'\%(\a\+:/\)\?\%([/[:alnum:]()$+_~.\x80-\xff-]\|[^[:print:]]\|\\[ ;*?[]"={}'']\)\+' :
        \'\%([/\[\][:alnum:]()$+_~.-]\|[^[:print:]]\|\\[ ;*?[]"={}'']\)\+')
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

  " Initialize context filetype lists. "{{{
  call neocomplcache#util#set_default(
        \ 'g:neocomplcache_context_filetype_lists', {})
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_context_filetype_lists',
        \ 'c,cpp', [
        \ {'filetype' : 'masm',
        \  'start' : '_*asm_*\s\+\h\w*', 'end' : '$'},
        \ {'filetype' : 'masm',
        \  'start' : '_*asm_*\s*\%(\n\s*\)\?{', 'end' : '}'},
        \ {'filetype' : 'gas',
        \  'start' : '_*asm_*\s*\%(_*volatile_*\s*\)\?(', 'end' : ');'},
        \])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_context_filetype_lists',
        \ 'd', [
        \ {'filetype' : 'masm',
        \  'start' : 'asm\s*\%(\n\s*\)\?{', 'end' : '}'},
        \])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_context_filetype_lists',
        \ 'perl6', [
        \ {'filetype' : 'pir', 'start' : 'Q:PIR\s*{', 'end' : '}'},
        \])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_context_filetype_lists',
        \ 'vimshell', [
        \ {'filetype' : 'vim',
        \  'start' : 'vexe \([''"]\)', 'end' : '\\\@<!\1'},
        \ {'filetype' : 'vim', 'start' : ' :\w*', 'end' : '\n'},
        \ {'filetype' : 'vim', 'start' : ' vexe\s\+', 'end' : '\n'},
        \])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_context_filetype_lists',
        \ 'eruby', [
        \ {'filetype' : 'ruby', 'start' : '<%[=#]\?', 'end' : '%>'},
        \])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_context_filetype_lists',
        \ 'vim', [
        \ {'filetype' : 'python',
        \  'start' : '^\s*py\%[thon\]3\? <<\s*\(\h\w*\)', 'end' : '^\1'},
        \ {'filetype' : 'ruby',
        \  'start' : '^\s*rub\%[y\] <<\s*\(\h\w*\)', 'end' : '^\1'},
        \ {'filetype' : 'lua',
        \  'start' : '^\s*lua <<\s*\(\h\w*\)', 'end' : '^\1'},
        \])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_context_filetype_lists',
        \ 'html,xhtml', [
        \ {'filetype' : 'javascript', 'start' :
        \'<script\%( [^>]*\)\? type="text/javascript"\%( [^>]*\)\?>',
        \  'end' : '</script>'},
        \ {'filetype' : 'coffee', 'start' :
        \'<script\%( [^>]*\)\? type="text/coffeescript"\%( [^>]*\)\?>',
        \  'end' : '</script>'},
        \ {'filetype' : 'css', 'start' :
        \'<script\%( [^>]*\)\? type="text/css"\%( [^>]*\)\?>',
        \  'end' : '</style>'},
        \])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_context_filetype_lists',
        \ 'python', [
        \ {'filetype' : 'vim',
        \  'start' : 'vim.command\s*(\([''"]\)', 'end' : '\\\@<!\1\s*)'},
        \ {'filetype' : 'vim',
        \  'start' : 'vim.eval\s*(\([''"]\)', 'end' : '\\\@<!\1\s*)'},
        \])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_context_filetype_lists',
        \ 'help', [
        \ {'filetype' : 'vim', 'start' : '^>', 'end' : '^<'},
        \])
  call neocomplcache#util#set_default_dictionary(
        \ 'g:neocomplcache_context_filetype_lists',
        \ 'nyaos,int-nyaos', [
        \ {'filetype' : 'lua',
        \  'start' : '\<lua_e\s\+\(["'']\)', 'end' : '^\1'},
        \])
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

  " Add commands. "{{{
  command! -nargs=? Neco call s:display_neco(<q-args>)
  command! -nargs=1 NeoComplCacheAutoCompletionLength
        \ call s:set_auto_completion_length(<args>)
  "}}}

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

  " Save options.
  let s:completefunc_save = &completefunc
  let s:completeopt_save = &completeopt

  " Set completefunc.
  let &completefunc = 'neocomplcache#manual_complete'
  let &l:completefunc = 'neocomplcache#manual_complete'

  " For auto complete keymappings.
  inoremap <expr><silent> <Plug>(neocomplcache_start_unite_complete)
        \ unite#sources#neocomplcache#start_complete()
  inoremap <expr><silent> <Plug>(neocomplcache_start_unite_quick_match)
        \ unite#sources#neocomplcache#start_quick_match()
  inoremap <silent> <Plug>(neocomplcache_start_auto_complete)
        \ <C-x><C-u><C-r>=neocomplcache#popup_post()<CR>
  inoremap <silent> <Plug>(neocomplcache_start_auto_complete_no_select)
        \ <C-x><C-u><C-p>
  " \ <C-x><C-u><C-p>
  inoremap <silent> <Plug>(neocomplcache_start_omni_complete)
        \ <C-x><C-o><C-p>

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

if !exists('s:is_enabled')
  call s:initialize_script_variables()
  let s:is_enabled = 0
endif

function! neocomplcache#initialize() "{{{
  call neocomplcache#enable()
  call s:initialize_sources(get(g:neocomplcache_sources_list,
        \ neocomplcache#get_context_filetype(), ['_']))
endfunction"}}}

function! neocomplcache#lazy_initialize() "{{{
  if !exists('s:lazy_progress')
    let s:lazy_progress = 0
  endif

  if s:lazy_progress == 0
    call s:initialize_script_variables()
    let s:is_enabled = 0
  elseif s:lazy_progress == 1
    call s:initialize_others()
  else
    call s:initialize_autocmds()
    call s:initialize_sources(get(g:neocomplcache_sources_list,
          \ neocomplcache#get_context_filetype(), ['_']))
    let s:is_enabled = 1
  endif

  let s:lazy_progress += 1
endfunction"}}}

function! neocomplcache#enable() "{{{
  if neocomplcache#is_enabled()
    return
  endif

  call s:initialize_script_variables()
  call s:initialize_autocmds()
  call s:initialize_others()
endfunction"}}}

function! neocomplcache#disable() "{{{
  if !neocomplcache#is_enabled()
    call neocomplcache#print_warning(
          \ 'neocomplcache is disabled! This command is ignored.')
    return
  endif

  let s:is_enabled = 0

  " Restore options.
  let &completefunc = s:completefunc_save
  let &completeopt = s:completeopt_save

  augroup neocomplcache
    autocmd!
  augroup END

  delcommand NeoComplCacheDisable
  delcommand Neco
  delcommand NeoComplCacheAutoCompletionLength

  for source in values(neocomplcache#available_sources())
    if !has_key(source, 'finalize') || !source.loaded
      continue
    endif

    try
      call source.finalize()
    catch
      call neocomplcache#print_error(v:throwpoint)
      call neocomplcache#print_error(v:exception)
      call neocomplcache#print_error(
            \ 'Error occured in source''s finalize()!')
      call neocomplcache#print_error(
            \ 'Source name is ' . source.name)
    endtry
  endfor
endfunction"}}}

function! neocomplcache#manual_complete(findstart, base) "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()

  if a:findstart
    let cur_text = s:get_cur_text()
    if !neocomplcache#is_enabled()
          \ || neocomplcache#is_omni_complete(cur_text)
      call s:clear_result()
      let &l:completefunc = 'neocomplcache#manual_complete'

      return (neocomplcache#is_prefetch()
            \ || g:neocomplcache_enable_insert_char_pre) ?
            \ -1 : -3
    endif

    " Get cur_keyword_pos.
    if neocomplcache#is_prefetch() && !empty(neocomplcache.complete_results)
      " Use prefetch results.
    else
      let neocomplcache.complete_results =
            \ neocomplcache#get_complete_results(cur_text)
    endif
    let cur_keyword_pos =
          \ neocomplcache#get_cur_keyword_pos(neocomplcache.complete_results)

    if cur_keyword_pos < 0
      call s:clear_result()

      let neocomplcache = neocomplcache#get_current_neocomplcache()
      let cur_keyword_pos = (neocomplcache#is_prefetch() ||
            \ g:neocomplcache_enable_insert_char_pre ||
            \ neocomplcache#get_current_neocomplcache().skipped) ?  -1 : -3
      let neocomplcache.skipped = 0
    endif

    return cur_keyword_pos
  else
    let cur_keyword_pos = neocomplcache#get_cur_keyword_pos(
          \ neocomplcache.complete_results)
    let neocomplcache.complete_words = neocomplcache#get_complete_words(
          \ neocomplcache.complete_results, cur_keyword_pos, a:base)
    let neocomplcache.cur_keyword_str = a:base

    if v:version > 703 || v:version == 703 && has('patch418')
      let dict = { 'words' : neocomplcache.complete_words }

      if (g:neocomplcache_enable_cursor_hold_i
            \      || v:version > 703 || v:version == 703 && has('patch561'))
            \ && (len(a:base) < g:neocomplcache_auto_completion_start_length
            \   || !empty(filter(copy(neocomplcache.complete_words),
            \          "get(v:val, 'neocomplcache__refresh', 0)"))
            \   || len(neocomplcache.complete_words) >= g:neocomplcache_max_list)
        " Note: If Vim is less than 7.3.561, it have broken register "." problem.
        let dict.refresh = 'always'
      endif
      return dict
    else
      return neocomplcache.complete_words
    endif
  endif
endfunction"}}}

function! neocomplcache#sources_manual_complete(findstart, base) "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()

  if a:findstart
    if !neocomplcache#is_enabled()
      call s:clear_result()
      return -2
    endif

    " Get cur_keyword_pos.
    let complete_results = neocomplcache#get_complete_results(
          \ s:get_cur_text(), s:use_sources)
    let neocomplcache.cur_keyword_pos =
          \ neocomplcache#get_cur_keyword_pos(complete_results)

    if neocomplcache.cur_keyword_pos < 0
      call s:clear_result()

      return -2
    endif

    let neocomplcache.complete_results = complete_results

    return neocomplcache.cur_keyword_pos
  endif

  let neocomplcache.cur_keyword_pos =
        \ neocomplcache#get_cur_keyword_pos(neocomplcache.complete_results)
  let complete_words = neocomplcache#get_complete_words(
        \ neocomplcache.complete_results,
        \ neocomplcache.cur_keyword_pos, a:base)

  let neocomplcache.complete_words = complete_words
  let neocomplcache.cur_keyword_str = a:base

  return complete_words
endfunction"}}}

function! neocomplcache#unite_complete(findstart, base) "{{{
  " Dummy.
  return a:findstart ? -1 : []
endfunction"}}}

function! neocomplcache#auto_complete(findstart, base) "{{{
  return neocomplcache#manual_complete(a:findstart, a:base)
endfunction"}}}

function! s:do_auto_complete(event) "{{{
  if s:check_in_do_auto_complete()
    return
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.skipped = 0
  let neocomplcache.event = a:event

  let cur_text = s:get_cur_text()

  if g:neocomplcache_enable_debug
    echomsg 'cur_text = ' . cur_text
  endif

  " Prevent infinity loop.
  if s:is_skip_auto_complete(cur_text)
    if g:neocomplcache_enable_debug
      echomsg 'Skipped.'
    endif

    call s:clear_result()
    return
  endif

  let neocomplcache.old_cur_text = cur_text

  if neocomplcache#is_omni_complete(cur_text)
    call feedkeys("\<Plug>(neocomplcache_start_omni_complete)")
    return
  endif

  " Check multibyte input or eskk.
  if neocomplcache#is_eskk_enabled()
        \ || neocomplcache#is_multibyte_input(cur_text)
    if g:neocomplcache_enable_debug
      echomsg 'Skipped.'
    endif

    return
  endif

  " Check complete position.
  let complete_results = s:set_complete_results_pos(cur_text)
  if empty(complete_results)
    if g:neocomplcache_enable_debug
      echomsg 'Skipped.'
    endif

    return
  endif

  let &l:completefunc = 'neocomplcache#auto_complete'

  if neocomplcache#is_prefetch()
    " Do prefetch.
    let neocomplcache.complete_results =
          \ neocomplcache#get_complete_results(cur_text)

    if empty(neocomplcache.complete_results)
      if g:neocomplcache_enable_debug
        echomsg 'Skipped.'
      endif

      " Skip completion.
      let &l:completefunc = 'neocomplcache#manual_complete'
      call s:clear_result()
      return
    endif
  endif

  call s:save_foldinfo()

  " Set options.
  set completeopt-=menu
  set completeopt-=longest
  set completeopt+=menuone

  " Start auto complete.
  call feedkeys(&l:formatoptions !~ 'a' ?
        \ "\<Plug>(neocomplcache_start_auto_complete)":
        \ "\<Plug>(neocomplcache_start_auto_complete_no_select)")
endfunction"}}}
function! s:check_in_do_auto_complete() "{{{
  if neocomplcache#is_locked()
    return 1
  endif

  " Detect completefunc.
  if &l:completefunc != 'neocomplcache#manual_complete'
        \ && &l:completefunc != 'neocomplcache#auto_complete'
    if g:neocomplcache_force_overwrite_completefunc
          \ || &l:completefunc == ''
          \ || &l:completefunc ==# 'neocomplcache#sources_manual_complete'
      " Set completefunc.
      let &l:completefunc = 'neocomplcache#manual_complete'
    else
      " Warning.
      redir => output
      99verbose setl completefunc
      redir END
      call neocomplcache#print_error(output)
      call neocomplcache#print_error(
            \ 'Another plugin set completefunc! Disabled neocomplcache.')
      NeoComplCacheLock
      return 1
    endif
  endif

  " Detect AutoComplPop.
  if exists('g:acp_enableAtStartup') && g:acp_enableAtStartup
    call neocomplcache#print_error(
          \ 'Detected enabled AutoComplPop! Disabled neocomplcache.')
    NeoComplCacheLock
    return 1
  endif
endfunction"}}}

" Source helper. "{{{
function! neocomplcache#available_complfuncs() "{{{
  return s:complfunc_sources
endfunction"}}}
function! neocomplcache#available_ftplugins() "{{{
  return s:ftplugin_sources
endfunction"}}}
function! neocomplcache#available_loaded_ftplugins() "{{{
  return s:loaded_ftplugin_sources
endfunction"}}}
function! neocomplcache#available_plugins() "{{{
  return s:plugin_sources
endfunction"}}}
function! neocomplcache#available_sources() "{{{
  call s:set_context_filetype()
  return extend(extend(copy(s:complfunc_sources),
        \ s:ftplugin_sources), s:plugin_sources)
endfunction"}}}
function! neocomplcache#is_enabled_source(source_name) "{{{
  if neocomplcache#is_disabled_source(a:source_name)
    return 0
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()
  if !has_key(neocomplcache, 'sources')
    call s:get_sources_list()
  endif

  return index(keys(neocomplcache.sources), a:source_name) >= 0
endfunction"}}}
function! neocomplcache#is_disabled_source(source_name) "{{{
  let filetype = neocomplcache#get_context_filetype()

  let disabled_sources = get(
        \ g:neocomplcache_disabled_sources_list, filetype,
        \   get(g:neocomplcache_disabled_sources_list, '_', []))
  return index(disabled_sources, a:source_name) >= 0
endfunction"}}}
function! s:keyword_escape(cur_keyword_str)
  let keyword_escape = escape(a:cur_keyword_str, '~" \.^$[]')
  if g:neocomplcache_enable_wildcard
    let keyword_escape = substitute(
          \ substitute(keyword_escape, '.\zs\*', '.*', 'g'),
          \ '\%(^\|\*\)\zs\*', '\\*', 'g')
  else
    let keyword_escape = escape(keyword_escape, '*')
  endif

  return keyword_escape
endfunction
function! neocomplcache#keyword_escape(cur_keyword_str) "{{{
  " Fuzzy completion.
  let keyword_len = len(a:cur_keyword_str)
  let keyword_escape = s:keyword_escape(a:cur_keyword_str)
  if g:neocomplcache_enable_fuzzy_completion
        \ && (g:neocomplcache_fuzzy_completion_start_length
        \          <= keyword_len && keyword_len < 20)
    let pattern = keyword_len >= 8 ?
          \ '\0\\w*' : '\\%(\0\\w*\\|\U\0\E\\l*\\)'

    let start = g:neocomplcache_fuzzy_completion_start_length
    if start <= 1
      let keyword_escape =
            \ substitute(keyword_escape, '\w', pattern, 'g')
    elseif keyword_len < 8
      let keyword_escape = keyword_escape[: start - 2]
            \ . substitute(keyword_escape[start-1 :], '\w', pattern, 'g')
    else
      let keyword_escape = keyword_escape[: 3] .
            \ substitute(keyword_escape[4:12], '\w',
            \   pattern, 'g') . keyword_escape[13:]
    endif
  else
    " Underbar completion. "{{{
    if g:neocomplcache_enable_underbar_completion
          \ && keyword_escape =~ '[^_]_\|^_'
      let keyword_escape = substitute(keyword_escape,
            \ '\%(^\|[^_]\)\zs_', '[^_]*_', 'g')
    endif
    if g:neocomplcache_enable_underbar_completion
          \ && '-' =~ '\k' && keyword_escape =~ '[^-]-'
      let keyword_escape = substitute(keyword_escape,
            \ '[^-]\zs-', '[^-]*-', 'g')
    endif
    "}}}
    " Camel case completion. "{{{
    if g:neocomplcache_enable_camel_case_completion
          \ && keyword_escape =~ '\u\?\U*'
      let keyword_escape =
            \ substitute(keyword_escape,
            \ '\u\?\zs\U*',
            \ '\\%(\0\\l*\\|\U\0\E\\u*_\\?\\)', 'g')
    endif
    "}}}
  endif

  call neocomplcache#print_debug(keyword_escape)
  return keyword_escape
endfunction"}}}
function! neocomplcache#keyword_filter(list, cur_keyword_str) "{{{
  let cur_keyword_str = a:cur_keyword_str

  if g:neocomplcache_enable_debug
    echomsg len(a:list)
  endif

  " Delimiter check.
  let filetype = neocomplcache#get_context_filetype()
  for delimiter in get(g:neocomplcache_delimiter_patterns, filetype, [])
    let cur_keyword_str = substitute(cur_keyword_str,
          \ delimiter, '*' . delimiter, 'g')
  endfor

  if cur_keyword_str == '' ||
        \ &l:completefunc ==# 'neocomplcache#unite_complete' ||
        \ empty(a:list)
    return a:list
  elseif neocomplcache#check_match_filter(cur_keyword_str)
    " Match filter.
    let word = type(a:list[0]) == type('') ? 'v:val' : 'v:val.word'

    let expr = printf('%s =~ %s',
          \ word, string('^' .
          \ neocomplcache#keyword_escape(cur_keyword_str)))
    if neocomplcache#is_auto_complete()
      " Don't complete cursor word.
      let expr .= printf(' && %s !=? a:cur_keyword_str', word)
    endif

    " Check head character.
    if cur_keyword_str[0] != '\' && cur_keyword_str[0] != '.'
      let expr = word.'[0] == ' .
            \ string(cur_keyword_str[0]) .' && ' . expr
    endif

    call neocomplcache#print_debug(expr)

    return filter(a:list, expr)
  else
    " Use fast filter.
    return neocomplcache#head_filter(a:list, cur_keyword_str)
  endif
endfunction"}}}
function! neocomplcache#dup_filter(list) "{{{
  let dict = {}
  for keyword in a:list
    if !has_key(dict, keyword.word)
      let dict[keyword.word] = keyword
    endif
  endfor

  return values(dict)
endfunction"}}}
function! neocomplcache#check_match_filter(cur_keyword_str) "{{{
  return neocomplcache#keyword_escape(a:cur_keyword_str) =~ '[^\\]\*\|\\+'
endfunction"}}}
function! neocomplcache#check_completion_length_match(cur_keyword_str, completion_length) "{{{
  return neocomplcache#keyword_escape(
        \ a:cur_keyword_str[: a:completion_length-1]) =~
        \'[^\\]\*\|\\+\|\\%(\|\\|'
endfunction"}}}
function! neocomplcache#head_filter(list, cur_keyword_str) "{{{
  let word = type(a:list[0]) == type('') ? 'v:val' : 'v:val.word'

  if &ignorecase
   let expr = printf('!stridx(tolower(%s), %s)',
          \ word, string(tolower(a:cur_keyword_str)))
  else
    let expr = printf('!stridx(%s, %s)',
          \ word, string(a:cur_keyword_str))
  endif

  if neocomplcache#is_auto_complete()
    " Don't complete cursor word.
    let expr .= printf(' && %s !=? a:cur_keyword_str', word)
  endif

  return filter(a:list, expr)
endfunction"}}}
function! neocomplcache#fuzzy_filter(list, cur_keyword_str) "{{{
  let ret = []

  let cur_keyword_str = a:cur_keyword_str[2:]
  let max_str2 = len(cur_keyword_str)
  let len = len(a:cur_keyword_str)
  let m = range(max_str2+1)
  for keyword in filter(a:list, 'len(v:val.word) >= '.max_str2)
    let str1 = keyword.word[2 : len-1]

    let i = 0
    while i <= max_str2+1
      let m[i] = range(max_str2+1)

      let i += 1
    endwhile
    let i = 0
    while i <= max_str2+1
      let m[i][0] = i
      let m[0][i] = i

      let i += 1
    endwhile

    let i = 1
    let max = max_str2 + 1
    while i < max
      let j = 1
      while j < max
        let m[i][j] = min([m[i-1][j]+1, m[i][j-1]+1,
              \ m[i-1][j-1]+(str1[i-1] != cur_keyword_str[j-1])])

        let j += 1
      endwhile

      let i += 1
    endwhile
    if m[-1][-1] <= 2
      call add(ret, keyword)
    endif
  endfor

  return ret
endfunction"}}}
function! neocomplcache#dictionary_filter(dictionary, cur_keyword_str) "{{{
  if empty(a:dictionary)
    return []
  endif

  let completion_length = 2
  if len(a:cur_keyword_str) < completion_length ||
        \ neocomplcache#check_completion_length_match(
        \         a:cur_keyword_str, completion_length) ||
        \ &l:completefunc ==# 'neocomplcache#unite_complete'
    return neocomplcache#keyword_filter(
          \ neocomplcache#unpack_dictionary(a:dictionary), a:cur_keyword_str)
  endif

  let key = tolower(a:cur_keyword_str[: completion_length-1])

  if !has_key(a:dictionary, key)
    return []
  endif

  let list = a:dictionary[key]
  if type(list) == type({})
    " Convert dictionary dictionary.
    unlet list
    let list = values(a:dictionary[key])
  else
    let list = copy(list)
  endif

  return (len(a:cur_keyword_str) == completion_length && &ignorecase
        \ && !neocomplcache#check_completion_length_match(
        \   a:cur_keyword_str, completion_length)) ?
        \ list : neocomplcache#keyword_filter(list, a:cur_keyword_str)
endfunction"}}}
function! neocomplcache#unpack_dictionary(dict) "{{{
  let ret = []
  let values = values(a:dict)
  for l in (type(values) == type([]) ?
        \ values : values(values))
    let ret += (type(l) == type([])) ? copy(l) : values(l)
  endfor

  return ret
endfunction"}}}
function! neocomplcache#pack_dictionary(list) "{{{
  let completion_length = 2
  let ret = {}
  for candidate in a:list
    let key = tolower(candidate.word[: completion_length-1])
    if !has_key(ret, key)
      let ret[key] = {}
    endif

    let ret[key][candidate.word] = candidate
  endfor

  return ret
endfunction"}}}
function! neocomplcache#add_dictionaries(dictionaries) "{{{
  if empty(a:dictionaries)
    return {}
  endif

  let ret = a:dictionaries[0]
  for dict in a:dictionaries[1:]
    for [key, value] in items(dict)
      if has_key(ret, key)
        let ret[key] += value
      else
        let ret[key] = value
      endif
    endfor
  endfor

  return ret
endfunction"}}}

" Rank order. "{{{
function! neocomplcache#compare_rank(i1, i2)
  let diff = (get(a:i2, 'rank', 0) - get(a:i1, 'rank', 0))
  return (diff != 0) ? diff : (a:i1.word ># a:i2.word) ? 1 : -1
endfunction"}}}
" Word order. "{{{
function! neocomplcache#compare_word(i1, i2)
  return (a:i1.word ># a:i2.word) ? 1 : -1
endfunction"}}}
" Nothing order. "{{{
function! neocomplcache#compare_nothing(i1, i2)
  return 0
endfunction"}}}
" Human order. "{{{
function! neocomplcache#compare_human(i1, i2)
  let words_1 = map(split(a:i1.word, '\D\zs\ze\d'),
        \ "v:val =~ '^\\d' ? str2nr(v:val) : v:val")
  let words_2 = map(split(a:i2.word, '\D\zs\ze\d'),
        \ "v:val =~ '^\\d' ? str2nr(v:val) : v:val")
  let words_1_len = len(words_1)
  let words_2_len = len(words_2)

  for i in range(0, min([words_1_len, words_2_len])-1)
    if words_1[i] ># words_2[i]
      return 1
    elseif words_1[i] <# words_2[i]
      return -1
    endif
  endfor

  return words_1_len - words_2_len
endfunction"}}}

" Source rank order. "{{{
function! s:compare_source_rank(i1, i2)
  return neocomplcache#get_source_rank(a:i2[0]) -
        \ neocomplcache#get_source_rank(a:i1[0])
endfunction"}}}
" Pos order. "{{{
function! s:compare_pos(i1, i2)
  return a:i1[0] == a:i2[0] ? a:i1[1] - a:i2[1] : a:i1[0] - a:i2[0]
endfunction"}}}

function! neocomplcache#rand(max) "{{{
  if !has('reltime')
    " Same value.
    return 0
  endif

  let time = reltime()[1]
  return (time < 0 ? -time : time)% (a:max + 1)
endfunction"}}}
function! neocomplcache#system(...) "{{{
  let V = vital#of('neocomplcache')
  return call(V.system, a:000)
endfunction"}}}
function! neocomplcache#has_vimproc(...) "{{{
  " Initialize.
  if !exists('g:neocomplcache_use_vimproc')
    " Check vimproc.
    try
      call vimproc#version()
      let exists_vimproc = 1
    catch
      let exists_vimproc = 0
    endtry

    let g:neocomplcache_use_vimproc = exists_vimproc
  endif

  return g:neocomplcache_use_vimproc
endfunction"}}}

function! neocomplcache#get_cur_text(...) "{{{
  " Return cached text.
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  return (a:0 == 0 && mode() ==# 'i' &&
        \  neocomplcache.cur_text != '') ?
        \ neocomplcache.cur_text : s:get_cur_text()
endfunction"}}}
function! neocomplcache#get_next_keyword() "{{{
  " Get next keyword.
  let pattern = '^\%(' . neocomplcache#get_next_keyword_pattern() . '\m\)'

  return matchstr('a'.getline('.')[len(neocomplcache#get_cur_text()) :], pattern)[1:]
endfunction"}}}
function! neocomplcache#get_completion_length(plugin_name) "{{{
  if neocomplcache#is_auto_complete()
        \ && neocomplcache#get_current_neocomplcache().completion_length >= 0
    return neocomplcache#get_current_neocomplcache().completion_length
  elseif has_key(g:neocomplcache_source_completion_length,
        \ a:plugin_name)
    return g:neocomplcache_source_completion_length[a:plugin_name]
  elseif has_key(s:ftplugin_sources, a:plugin_name)
        \ || has_key(s:complfunc_sources, a:plugin_name)
    return 0
  elseif neocomplcache#is_auto_complete()
    return g:neocomplcache_auto_completion_start_length
  else
    return g:neocomplcache_manual_completion_start_length
  endif
endfunction"}}}
function! neocomplcache#set_completion_length(plugin_name, length) "{{{
  if !has_key(g:neocomplcache_source_completion_length, a:plugin_name)
    let g:neocomplcache_source_completion_length[a:plugin_name] = a:length
  endif
endfunction"}}}
function! neocomplcache#get_auto_completion_length(plugin_name) "{{{
  if has_key(g:neocomplcache_source_completion_length, a:plugin_name)
    return g:neocomplcache_source_completion_length[a:plugin_name]
  elseif g:neocomplcache_enable_fuzzy_completion
    return 1
  else
    return g:neocomplcache_auto_completion_start_length
  endif
endfunction"}}}
function! neocomplcache#get_keyword_pattern(...) "{{{
  let filetype = a:0 != 0? a:000[0] : neocomplcache#get_context_filetype()

  return s:unite_patterns(g:neocomplcache_keyword_patterns, filetype)
endfunction"}}}
function! neocomplcache#get_next_keyword_pattern(...) "{{{
  let filetype = a:0 != 0? a:000[0] : neocomplcache#get_context_filetype()
  let next_pattern = s:unite_patterns(g:neocomplcache_next_keyword_patterns, filetype)

  return (next_pattern == '' ? '' : next_pattern.'\m\|')
        \ . neocomplcache#get_keyword_pattern(filetype)
endfunction"}}}
function! neocomplcache#get_keyword_pattern_end(...) "{{{
  let filetype = a:0 != 0? a:000[0] : neocomplcache#get_context_filetype()

  return '\%('.neocomplcache#get_keyword_pattern(filetype).'\m\)$'
endfunction"}}}
function! neocomplcache#match_word(cur_text, ...) "{{{
  let pattern = a:0 >= 1 ? a:1 : neocomplcache#get_keyword_pattern_end()

  " Check wildcard.
  let cur_keyword_pos = s:match_wildcard(
        \ a:cur_text, pattern, match(a:cur_text, pattern))

  let cur_keyword_str = (cur_keyword_pos >=0) ?
        \ a:cur_text[cur_keyword_pos :] : ''

  return [cur_keyword_pos, cur_keyword_str]
endfunction"}}}
function! neocomplcache#match_wild_card(cur_keyword_str) "{{{
  let index = stridx(a:cur_keyword_str, '*')
  return !g:neocomplcache_enable_wildcard && index > 0 ?
        \ a:cur_keyword_str : a:cur_keyword_str[: index]
endfunction"}}}
function! neocomplcache#is_enabled() "{{{
  return s:is_enabled
endfunction"}}}
function! neocomplcache#is_locked(...) "{{{
  let bufnr = a:0 > 0 ? a:1 : bufnr('%')
  return !s:is_enabled || &paste
        \ || g:neocomplcache_disable_auto_complete
        \ || neocomplcache#get_current_neocomplcache().lock
        \ || (g:neocomplcache_lock_buffer_name_pattern != '' &&
        \   bufname(bufnr) =~ g:neocomplcache_lock_buffer_name_pattern)
        \ || &l:omnifunc ==# 'fuf#onComplete'
endfunction"}}}
function! neocomplcache#is_plugin_locked(source_name) "{{{
  if !neocomplcache#is_enabled()
    return 1
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  return get(neocomplcache.lock_sources, a:source_name, 0)
endfunction"}}}
function! neocomplcache#is_auto_select() "{{{
  return g:neocomplcache_enable_auto_select && !neocomplcache#is_eskk_enabled()
endfunction"}}}
function! neocomplcache#is_auto_complete() "{{{
  return &l:completefunc == 'neocomplcache#auto_complete'
endfunction"}}}
function! neocomplcache#is_sources_complete() "{{{
  return &l:completefunc == 'neocomplcache#sources_manual_complete'
endfunction"}}}
function! neocomplcache#is_eskk_enabled() "{{{
  return exists('*eskk#is_enabled') && eskk#is_enabled()
endfunction"}}}
function! neocomplcache#is_eskk_convertion(cur_text) "{{{
  return neocomplcache#is_eskk_enabled()
        \   && eskk#get_preedit().get_henkan_phase() !=#
        \             g:eskk#preedit#PHASE_NORMAL
endfunction"}}}
function! neocomplcache#is_multibyte_input(cur_text) "{{{
  return (exists('b:skk_on') && b:skk_on)
        \     || char2nr(split(a:cur_text, '\zs')[-1]) > 0x80
endfunction"}}}
function! neocomplcache#is_text_mode() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  return get(g:neocomplcache_text_mode_filetypes,
        \ neocomplcache.context_filetype, 0)
endfunction"}}}
function! neocomplcache#is_windows() "{{{
  return neocomplcache#util#is_windows()
endfunction"}}}
function! neocomplcache#is_win() "{{{
  return neocomplcache#is_windows()
endfunction"}}}
function! neocomplcache#is_prefetch() "{{{
  return !neocomplcache#is_locked() &&
        \ (g:neocomplcache_enable_prefetch || &l:formatoptions =~# 'a')
endfunction"}}}
function! neocomplcache#is_omni_complete(cur_text) "{{{
  " Check eskk complete length.
  if neocomplcache#is_eskk_enabled()
        \ && exists('g:eskk#start_completion_length')
    if !neocomplcache#is_eskk_convertion(a:cur_text)
          \ || !neocomplcache#is_multibyte_input(a:cur_text)
      return 0
    endif

    let cur_keyword_pos = call(&l:omnifunc, [1, ''])
    let cur_keyword_str = a:cur_text[cur_keyword_pos :]
    return neocomplcache#util#mb_strlen(cur_keyword_str) >=
          \ g:eskk#start_completion_length
  endif

  let filetype = neocomplcache#get_context_filetype()
  let omnifunc = get(g:neocomplcache_omni_functions,
        \ filetype, &l:omnifunc)

  if neocomplcache#check_invalid_omnifunc(omnifunc)
    return 0
  endif

  let syn_name = neocomplcache#get_syn_name(1)
  if syn_name ==# 'Comment' || syn_name ==# 'String'
    " Skip omni_complete in string literal.
    return 0
  endif

  if has_key(g:neocomplcache_force_omni_patterns, omnifunc)
    let pattern = g:neocomplcache_force_omni_patterns[omnifunc]
  elseif filetype != '' &&
        \ get(g:neocomplcache_force_omni_patterns, filetype, '') != ''
    let pattern = g:neocomplcache_force_omni_patterns[filetype]
  else
    return 0
  endif

  if a:cur_text !~# '\%(' . pattern . '\m\)$'
    return 0
  endif

  " Set omnifunc.
  let &omnifunc = omnifunc

  return 1
endfunction"}}}
function! neocomplcache#exists_echodoc() "{{{
  return exists('g:loaded_echodoc') && g:loaded_echodoc
endfunction"}}}
function! neocomplcache#within_comment() "{{{
  return neocomplcache#get_syn_name(1) ==# 'Comment'
endfunction"}}}
function! neocomplcache#print_caching(string) "{{{
  if g:neocomplcache_enable_caching_message
    redraw
    echon a:string
  endif
endfunction"}}}
function! neocomplcache#print_error(string) "{{{
  echohl Error | echomsg a:string | echohl None
endfunction"}}}
function! neocomplcache#print_warning(string) "{{{
  echohl WarningMsg | echomsg a:string | echohl None
endfunction"}}}
function! neocomplcache#trunk_string(string, max) "{{{
  return printf('%.' . a:max-10 . 's..%%s', a:string, a:string[-8:])
endfunction"}}}
function! neocomplcache#head_match(checkstr, headstr) "{{{
  let checkstr = &ignorecase ?
        \ tolower(a:checkstr) : a:checkstr
  let headstr = &ignorecase ?
        \ tolower(a:headstr) : a:headstr
  return stridx(checkstr, headstr) == 0
endfunction"}}}
function! neocomplcache#get_source_filetypes(filetype) "{{{
  let filetype = (a:filetype == '') ? 'nothing' : a:filetype

  let filetype_dict = {}

  let filetypes = [filetype, '_']
  if filetype =~ '\.'
    if exists('g:neocomplcache_ignore_composite_filetype_lists')
          \ && has_key(g:neocomplcache_ignore_composite_filetype_lists, filetype)
      let filetypes = [g:neocomplcache_ignore_composite_filetype_lists[filetype]]
    else
      " Set composite filetype.
      let filetypes += split(filetype, '\.')
    endif
  endif

  if exists('g:neocomplcache_same_filetype_lists')
    for ft in filetypes
      for same_ft in split(get(g:neocomplcache_same_filetype_lists, ft,
            \ get(g:neocomplcache_same_filetype_lists, '_', '')), ',')
        if same_ft != '' && index(filetypes, same_ft) < 0
          " Add same filetype.
          call add(filetypes, same_ft)
        endif
      endfor
    endfor
  endif

  return neocomplcache#util#uniq(filetypes)
endfunction"}}}
function! neocomplcache#get_sources_list(dictionary, filetype) "{{{
  let list = []
  for filetype in neocomplcache#get_source_filetypes(a:filetype)
    if has_key(a:dictionary, filetype)
      call add(list, a:dictionary[filetype])
    endif
  endfor

  return list
endfunction"}}}
function! neocomplcache#escape_match(str) "{{{
  return escape(a:str, '~"*\.^$[]')
endfunction"}}}
function! neocomplcache#get_context_filetype(...) "{{{
  if !neocomplcache#is_enabled()
    return &filetype
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  if a:0 != 0 || mode() !=# 'i' ||
        \ neocomplcache.context_filetype == ''
    call s:set_context_filetype()
  endif

  return neocomplcache.context_filetype
endfunction"}}}
function! neocomplcache#get_context_filetype_range(...) "{{{
  if !neocomplcache#is_enabled()
    return [[1, 1], [line('$'), len(getline('$'))+1]]
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  if a:0 != 0 || mode() !=# 'i' ||
        \ neocomplcache.context_filetype == ''
    call s:set_context_filetype()
  endif

  if neocomplcache.context_filetype ==# &filetype
    return [[1, 1], [line('$'), len(getline('$'))+1]]
  endif

  return neocomplcache.context_filetype_range
endfunction"}}}
function! neocomplcache#get_source_rank(plugin_name) "{{{
  if has_key(g:neocomplcache_source_rank, a:plugin_name)
    return g:neocomplcache_source_rank[a:plugin_name]
  elseif has_key(s:complfunc_sources, a:plugin_name)
    return 10
  elseif has_key(s:ftplugin_sources, a:plugin_name)
    return 100
  elseif has_key(s:plugin_sources, a:plugin_name)
    return 5
  else
    " unknown.
    return 1
  endif
endfunction"}}}
function! neocomplcache#get_syn_name(is_trans) "{{{
  return len(getline('.')) < 200 ?
        \ synIDattr(synIDtrans(synID(line('.'), mode() ==# 'i' ?
        \          col('.')-1 : col('.'), a:is_trans)), 'name') : ''
endfunction"}}}
function! neocomplcache#print_debug(expr) "{{{
  if g:neocomplcache_enable_debug
    echomsg string(a:expr)
  endif
endfunction"}}}
function! neocomplcache#get_temporary_directory() "{{{
  let directory = neocomplcache#util#substitute_path_separator(
        \ neocomplcache#util#expand(g:neocomplcache_temporary_dir))
  if !isdirectory(directory)
    call mkdir(directory, 'p')
  endif

  return directory
endfunction"}}}
function! neocomplcache#complete_check() "{{{
  if g:neocomplcache_enable_debug
    echomsg split(reltimestr(reltime(s:start_time)))[0]
  endif
  let ret = (!neocomplcache#is_prefetch() && complete_check())
        \ || (neocomplcache#is_auto_complete()
        \     && has('reltime') && g:neocomplcache_skip_auto_completion_time != ''
        \     && split(reltimestr(reltime(s:start_time)))[0] >
        \          g:neocomplcache_skip_auto_completion_time)
  if ret
    let neocomplcache = neocomplcache#get_current_neocomplcache()
    let neocomplcache.skipped = 1

    redraw
    echo 'Skipped.'
  endif

  return ret
endfunction"}}}
function! neocomplcache#check_invalid_omnifunc(omnifunc) "{{{
  return a:omnifunc == '' || (a:omnifunc !~ '#' && !exists('*' . a:omnifunc))
endfunction"}}}
function! neocomplcache#skip_next_complete()
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.skip_next_complete = 1
endfunction

" For unite source.
function! neocomplcache#get_complete_results(cur_text, ...) "{{{
  if has('reltime')
    if g:neocomplcache_enable_debug
      echomsg 'start get_complete_results'
    endif

    let s:start_time = reltime()
  endif

  let complete_results = call(
        \ 's:set_complete_results_pos', [a:cur_text] + a:000)
  call s:set_complete_results_words(complete_results)

  return filter(complete_results,
        \ '!empty(v:val.complete_words)')
endfunction"}}}
function! neocomplcache#get_cur_keyword_pos(complete_results) "{{{
  if empty(a:complete_results)
    return -1
  endif

  let cur_keyword_pos = col('.')
  for result in values(a:complete_results)
    if cur_keyword_pos > result.cur_keyword_pos
      let cur_keyword_pos = result.cur_keyword_pos
    endif
  endfor

  return cur_keyword_pos
endfunction"}}}
function! neocomplcache#get_complete_words(complete_results, cur_keyword_pos, cur_keyword_str) "{{{
  let frequencies = s:get_frequencies()
  if exists('*neocomplcache#sources#buffer_complete#get_frequencies')
    let frequencies = extend(copy(
          \ neocomplcache#sources#buffer_complete#get_frequencies()),
          \ frequencies)
  endif

  let sources = neocomplcache#available_sources()

  " Append prefix.
  let complete_words = []
  let len_words = 0
  for [source_name, result] in sort(items(a:complete_results),
        \ 's:compare_source_rank')
    let source = sources[source_name]

    if empty(result.complete_words)
      " Skip.
      continue
    endif

    let result.complete_words =
          \ type(result.complete_words[0]) == type('') ?
          \ map(copy(result.complete_words), "{'word': v:val}") :
          \ deepcopy(result.complete_words)

    if result.cur_keyword_pos > a:cur_keyword_pos
      let prefix = a:cur_keyword_str[: result.cur_keyword_pos
            \                            - a:cur_keyword_pos - 1]

      for keyword in result.complete_words
        let keyword.word = prefix . keyword.word
      endfor
    endif

    for keyword in result.complete_words
      if !has_key(keyword, 'menu') && has_key(source, 'mark')
        " Set default menu.
        let keyword.menu = source.mark
      endif
    endfor

    for keyword in filter(copy(result.complete_words),
          \ 'has_key(frequencies, v:val.word)')
      let keyword.rank = frequencies[keyword.word]
    endfor

    let compare_func = get(sources[source_name], 'compare_func',
          \ g:neocomplcache_compare_function)
    if compare_func !=# 'neocomplcache#compare_nothing'
      call sort(result.complete_words, compare_func)
    endif

    let complete_words += s:remove_next_keyword(
          \ source_name, result.complete_words)
    let len_words += len(result.complete_words)

    if g:neocomplcache_max_list > 0
          \ && len_words > g:neocomplcache_max_list
      break
    endif

    if neocomplcache#complete_check()
      return []
    endif
  endfor

  if g:neocomplcache_max_list > 0
    let complete_words = complete_words[: g:neocomplcache_max_list]
  endif

  " Check dup and set icase.
  let dup_check = {}
  let words = []
  let icase = g:neocomplcache_enable_ignore_case &&
        \!(g:neocomplcache_enable_smart_case && a:cur_keyword_str =~ '\u')
        \ && !neocomplcache#is_text_mode()
  for keyword in complete_words
    if has_key(keyword, 'kind') && keyword.kind == ''
      " Remove kind key.
      call remove(keyword, 'kind')
    endif

    if keyword.word != ''
          \&& (!has_key(dup_check, keyword.word)
          \    || (has_key(keyword, 'dup') && keyword.dup))
      let dup_check[keyword.word] = 1

      let keyword.icase = icase
      if !has_key(keyword, 'abbr')
        let keyword.abbr = keyword.word
      endif

      call add(words, keyword)
    endif
  endfor
  let complete_words = words

  " Delimiter check. "{{{
  let filetype = neocomplcache#get_context_filetype()
  for delimiter in ['/'] +
        \ get(g:neocomplcache_delimiter_patterns, filetype, [])
    " Count match.
    let delim_cnt = 0
    let matchend = matchend(a:cur_keyword_str, delimiter)
    while matchend >= 0
      let matchend = matchend(a:cur_keyword_str, delimiter, matchend)
      let delim_cnt += 1
    endwhile

    for keyword in complete_words
      let split_list = split(keyword.word, delimiter.'\ze.', 1)
      if len(split_list) > 1
        let delimiter_sub = substitute(delimiter, '\\\([.^$]\)', '\1', 'g')
        let keyword.word = join(split_list[ : delim_cnt], delimiter_sub)
        let keyword.abbr = join(
              \ split(keyword.abbr, delimiter.'\ze.', 1)[ : delim_cnt],
              \ delimiter_sub)

        if g:neocomplcache_max_keyword_width >= 0
              \ && len(keyword.abbr) > g:neocomplcache_max_keyword_width
          let keyword.abbr = substitute(keyword.abbr,
                \ '\(\h\)\w*'.delimiter, '\1'.delimiter_sub, 'g')
        endif
        if delim_cnt+1 < len(split_list)
          let keyword.abbr .= delimiter_sub . '~'
          let keyword.dup = 0

          if g:neocomplcache_enable_auto_delimiter
            let keyword.word .= delimiter_sub
          endif
        endif
      endif
    endfor
  endfor"}}}

  if neocomplcache#complete_check()
    return []
  endif

  " Convert words.
  if neocomplcache#is_text_mode() "{{{
    let convert_candidates = filter(copy(complete_words),
          \ "get(v:val, 'neocomplcache__convertable', 1)
          \  && v:val.word =~ '^\\u\\+$\\|^\\u\\?\\l\\+$'")

    if a:cur_keyword_str =~ '^\l\+$'
      for keyword in convert_candidates
        let keyword.word = tolower(keyword.word)
        let keyword.abbr = tolower(keyword.abbr)
      endfor
    elseif a:cur_keyword_str =~ '^\u\+$'
      for keyword in convert_candidates
        let keyword.word = toupper(keyword.word)
        let keyword.abbr = toupper(keyword.abbr)
      endfor
    elseif a:cur_keyword_str =~ '^\u\l\+$'
      for keyword in convert_candidates
        let keyword.word = toupper(keyword.word[0]).
              \ tolower(keyword.word[1:])
        let keyword.abbr = toupper(keyword.abbr[0]).
              \ tolower(keyword.abbr[1:])
      endfor
    endif
  endif"}}}

  if g:neocomplcache_max_keyword_width >= 0 "{{{
    " Abbr check.
    let abbr_pattern = printf('%%.%ds..%%s',
          \ g:neocomplcache_max_keyword_width-15)
    for keyword in complete_words
      if len(keyword.abbr) > g:neocomplcache_max_keyword_width
        if keyword.abbr =~ '[^[:print:]]'
          " Multibyte string.
          let len = neocomplcache#util#wcswidth(keyword.abbr)

          if len > g:neocomplcache_max_keyword_width
            let keyword.abbr = neocomplcache#util#truncate(
                  \ keyword.abbr, g:neocomplcache_max_keyword_width - 2) . '..'
          endif
        else
          let keyword.abbr = printf(abbr_pattern,
                \ keyword.abbr, keyword.abbr[-13:])
        endif
      endif
    endfor
  endif"}}}

  return complete_words
endfunction"}}}
function! s:set_complete_results_pos(cur_text, ...) "{{{
  " Set context filetype.
  call s:set_context_filetype()

  let sources = copy(get(a:000, 0, s:get_sources_list()))
  if a:0 < 1
    call filter(sources, '!neocomplcache#is_plugin_locked(v:key)')
  endif

  " Try source completion. "{{{
  let complete_results = {}
  for [source_name, source] in items(sources)
    if source.kind ==# 'plugin'
      " Plugin default keyword position.
      let [cur_keyword_pos, cur_keyword_str] = neocomplcache#match_word(a:cur_text)
    else
      let pos = getpos('.')

      try
        let cur_keyword_pos = source.get_keyword_pos(a:cur_text)
      catch
        call neocomplcache#print_error(v:throwpoint)
        call neocomplcache#print_error(v:exception)
        call neocomplcache#print_error(
              \ 'Error occured in source''s get_keyword_pos()!')
        call neocomplcache#print_error(
              \ 'Source name is ' . source_name)
        return complete_results
      finally
        if getpos('.') != pos
          call setpos('.', pos)
        endif
      endtry
    endif

    if cur_keyword_pos < 0
      continue
    endif

    let cur_keyword_str = a:cur_text[cur_keyword_pos :]
    if neocomplcache#is_auto_complete() &&
          \ neocomplcache#util#mb_strlen(cur_keyword_str)
          \     < neocomplcache#get_completion_length(source_name)
      " Skip.
      continue
    endif

    let complete_results[source_name] = {
          \ 'complete_words' : [],
          \ 'cur_keyword_pos' : cur_keyword_pos,
          \ 'cur_keyword_str' : cur_keyword_str,
          \ 'source' : source,
          \}
  endfor
  "}}}

  return complete_results
endfunction"}}}
function! s:set_complete_results_words(complete_results) "{{{
  " Try source completion.
  for [source_name, result] in items(a:complete_results)
    if neocomplcache#complete_check()
      return
    endif

    " Save options.
    let ignorecase_save = &ignorecase

    if neocomplcache#is_text_mode()
      let &ignorecase = 1
    elseif g:neocomplcache_enable_smart_case
          \ && result.cur_keyword_str =~ '\u'
      let &ignorecase = 0
    else
      let &ignorecase = g:neocomplcache_enable_ignore_case
    endif

    let pos = getpos('.')

    try
      let words = result.source.kind ==# 'plugin' ?
            \ result.source.get_keyword_list(result.cur_keyword_str) :
            \ result.source.get_complete_words(
            \   result.cur_keyword_pos, result.cur_keyword_str)
    catch
      call neocomplcache#print_error(v:throwpoint)
      call neocomplcache#print_error(v:exception)
      call neocomplcache#print_error(
            \ 'Source name is ' . source_name)
      if result.source.kind ==# 'plugin'
        call neocomplcache#print_error(
              \ 'Error occured in source''s get_keyword_list()!')
      else
        call neocomplcache#print_error(
              \ 'Error occured in source''s get_complete_words()!')
      endif
      return
    finally
      if getpos('.') != pos
        call setpos('.', pos)
      endif
    endtry

    if g:neocomplcache_enable_debug
      echomsg source_name
    endif

    let &ignorecase = ignorecase_save

    let result.complete_words = words
  endfor
endfunction"}}}

" Set default pattern helper.
function! neocomplcache#set_dictionary_helper(variable, keys, value) "{{{
  return neocomplcache#util#set_dictionary_helper(
        \ a:variable, a:keys, a:value)
endfunction"}}}

function! neocomplcache#disable_default_dictionary(variable) "{{{
  return neocomplcache#util#disable_default_dictionary(a:variable)
endfunction"}}}

" Complete filetype helper.
function! neocomplcache#filetype_complete(arglead, cmdline, cursorpos) "{{{
  " Dup check.
  let ret = {}
  for item in map(
        \ split(globpath(&runtimepath, 'syntax/*.vim'), '\n') +
        \ split(globpath(&runtimepath, 'indent/*.vim'), '\n') +
        \ split(globpath(&runtimepath, 'ftplugin/*.vim'), '\n')
        \ , 'fnamemodify(v:val, ":t:r")')
    if !has_key(ret, item) && item =~ '^'.a:arglead
      let ret[item] = 1
    endif
  endfor

  return sort(keys(ret))
endfunction"}}}
"}}}

" Command functions. "{{{
function! neocomplcache#clean() "{{{
  " Delete cache files.
  for directory in filter(neocomplcache#util#glob(
        \ g:neocomplcache_temporary_dir.'/*'), 'isdirectory(v:val)')
    for filename in filter(neocomplcache#util#glob(directory.'/*'),
          \ '!isdirectory(v:val)')
      call delete(filename)
    endfor
  endfor

  echo 'Cleaned cache files in: ' . g:neocomplcache_temporary_dir
endfunction"}}}
function! neocomplcache#toggle_lock() "{{{
  if neocomplcache#get_current_neocomplcache().lock
    echo 'neocomplcache is unlocked!'
    call neocomplcache#unlock()
  else
    echo 'neocomplcache is locked!'
    call neocomplcache#lock()
  endif
endfunction"}}}
function! neocomplcache#lock() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.lock = 1
endfunction"}}}
function! neocomplcache#unlock() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.lock = 0
endfunction"}}}
function! neocomplcache#lock_source(source_name) "{{{
  if !neocomplcache#is_enabled()
    call neocomplcache#print_warning(
          \ 'neocomplcache is disabled! This command is ignored.')
    return
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  let neocomplcache.lock_sources[a:source_name] = 1
endfunction"}}}
function! neocomplcache#unlock_source(source_name) "{{{
  if !neocomplcache#is_enabled()
    call neocomplcache#print_warning(
          \ 'neocomplcache is disabled! This command is ignored.')
    return
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  let neocomplcache.lock_sources[a:source_name] = 1
endfunction"}}}
function! s:display_neco(number) "{{{
  let cmdheight_save = &cmdheight

  let animation = [
    \[
        \[
        \ "   A A",
        \ "~(-'_'-)"
        \],
        \[
        \ "      A A",
        \ "   ~(-'_'-)",
        \],
        \[
        \ "        A A",
        \ "     ~(-'_'-)",
        \],
        \[
        \ "          A A  ",
        \ "       ~(-'_'-)",
        \],
        \[
        \ "             A A",
        \ "          ~(-^_^-)",
        \],
    \],
    \[
        \[
        \ "   A A",
        \ "~(-'_'-)",
        \],
        \[
        \ "      A A",
        \ "   ~(-'_'-)",
        \],
        \[
        \ "        A A",
        \ "     ~(-'_'-)",
        \],
        \[
        \ "          A A  ",
        \ "       ~(-'_'-)",
        \],
        \[
        \ "             A A",
        \ "          ~(-'_'-)",
        \],
        \[
        \ "          A A  ",
        \ "       ~(-'_'-)"
        \],
        \[
        \ "        A A",
        \ "     ~(-'_'-)"
        \],
        \[
        \ "      A A",
        \ "   ~(-'_'-)"
        \],
        \[
        \ "   A A",
        \ "~(-'_'-)"
        \],
    \],
    \[
        \[
        \ "   A A",
        \ "~(-'_'-)",
        \],
        \[
        \ "        A A",
        \ "     ~(-'_'-)",
        \],
        \[
        \ "             A A",
        \ "          ~(-'_'-)",
        \],
        \[
        \ "                  A A",
        \ "               ~(-'_'-)",
        \],
        \[
        \ "                       A A",
        \ "                    ~(-'_'-)",
        \],
        \["                           A A",
        \ "                        ~(-'_'-)",
        \],
    \],
    \[
        \[
        \ "",
        \ "   A A",
        \ "~(-'_'-)",
        \],
        \["      A A",
        \ "   ~(-'_'-)",
        \ "",
        \],
        \[
        \ "",
        \ "        A A",
        \ "     ~(-'_'-)",
        \],
        \[
        \ "          A A  ",
        \ "       ~(-'_'-)",
        \ "",
        \],
        \[
        \ "",
        \ "             A A",
        \ "          ~(-^_^-)",
        \],
    \],
    \[
        \[
        \ "   A A        A A",
        \ "~(-'_'-)  -8(*'_'*)"
        \],
        \[
        \ "     A A        A A",
        \ "  ~(-'_'-)  -8(*'_'*)"
        \],
        \[
        \ "       A A        A A",
        \ "    ~(-'_'-)  -8(*'_'*)"
        \],
        \[
        \ "     A A        A A",
        \ "  ~(-'_'-)  -8(*'_'*)"
        \],
        \[
        \ "   A A        A A",
        \ "~(-'_'-)  -8(*'_'*)"
        \],
    \],
    \[
        \[
        \ "  A\\_A\\",
        \ "(=' .' ) ~w",
        \ "(,(\")(\")",
        \],
    \],
  \]

  let number = (a:number != '') ? a:number : len(animation)
  let anim = get(animation, number, animation[neocomplcache#rand(len(animation) - 1)])
  let &cmdheight = len(anim[0])

  for frame in anim
    echo repeat("\n", &cmdheight-2)
    redraw
    echon join(frame, "\n")
    sleep 300m
  endfor
  redraw

  let &cmdheight = cmdheight_save
endfunction"}}}
function! neocomplcache#set_file_type(filetype) "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.filetype = a:filetype
endfunction"}}}
function! s:set_auto_completion_length(len) "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.completion_length = a:len
endfunction"}}}
"}}}

" Key mapping functions. "{{{
function! neocomplcache#smart_close_popup() "{{{
  return g:neocomplcache_enable_auto_select ?
        \ neocomplcache#cancel_popup() : neocomplcache#close_popup()
endfunction
"}}}
function! neocomplcache#close_popup() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.cur_keyword_str = ''
  let neocomplcache.skip_next_complete = 2
  let neocomplcache.complete_words = []

  return pumvisible() ? "\<C-y>" : ''
endfunction
"}}}
function! neocomplcache#cancel_popup() "{{{
  call neocomplcache#skip_next_complete()
  call s:clear_result()

  return pumvisible() ? "\<C-e>" : ''
endfunction
"}}}

function! neocomplcache#undo_completion() "{{{
  if !exists(':NeoComplCacheDisable')
    return ''
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  " Get cursor word.
  let [cur_keyword_pos, cur_keyword_str] =
        \ neocomplcache#match_word(s:get_cur_text())
  let old_keyword_str = neocomplcache.cur_keyword_str
  let neocomplcache.cur_keyword_str = cur_keyword_str

  return (!pumvisible() ? '' :
        \ cur_keyword_str ==# old_keyword_str ? "\<C-e>" : "\<C-y>")
        \. repeat("\<BS>", len(cur_keyword_str)) . old_keyword_str
endfunction"}}}

function! neocomplcache#complete_common_string() "{{{
  if !exists(':NeoComplCacheDisable')
    return ''
  endif

  " Save options.
  let ignorecase_save = &ignorecase

  " Get cursor word.
  let [cur_keyword_pos, cur_keyword_str] =
        \ neocomplcache#match_word(s:get_cur_text())

  if neocomplcache#is_text_mode()
    let &ignorecase = 1
  elseif g:neocomplcache_enable_smart_case && cur_keyword_str =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase = g:neocomplcache_enable_ignore_case
  endif

  let is_fuzzy = g:neocomplcache_enable_fuzzy_completion

  try
    let g:neocomplcache_enable_fuzzy_completion = 0
    let neocomplcache = neocomplcache#get_current_neocomplcache()
    let complete_words = neocomplcache#keyword_filter(
          \ copy(neocomplcache.complete_words), cur_keyword_str)
  finally
    let g:neocomplcache_enable_fuzzy_completion = is_fuzzy
  endtry

  if empty(complete_words)
    let &ignorecase = ignorecase_save

    return ''
  endif

  let common_str = complete_words[0].word
  for keyword in complete_words[1:]
    while !neocomplcache#head_match(keyword.word, common_str)
      let common_str = common_str[: -2]
    endwhile
  endfor
  if &ignorecase
    let common_str = tolower(common_str)
  endif

  let &ignorecase = ignorecase_save

  if common_str == ''
    return ''
  endif

  return (pumvisible() ? "\<C-e>" : '')
        \ . repeat("\<BS>", len(cur_keyword_str)) . common_str
endfunction"}}}

" Wrapper functions.
function! neocomplcache#manual_filename_complete() "{{{
  return neocomplcache#start_manual_complete('filename_complete')
endfunction"}}}
function! neocomplcache#manual_omni_complete() "{{{
  return neocomplcache#start_manual_complete('omni_complete')
endfunction"}}}

" Manual complete wrapper.
function! neocomplcache#start_manual_complete(...) "{{{
  if !neocomplcache#is_enabled()
    return ''
  endif

  " Set context filetype.
  call s:set_context_filetype()

  " Set function.
  let &l:completefunc = 'neocomplcache#sources_manual_complete'

  let all_sources = neocomplcache#available_sources()
  let sources = get(a:000, 0, keys(all_sources))
  let s:use_sources = s:get_sources_list(type(sources) == type([]) ?
        \ sources : [sources])

  " Start complete.
  return "\<C-x>\<C-u>\<C-p>"
endfunction"}}}
function! neocomplcache#start_manual_complete_list(cur_keyword_pos, cur_keyword_str, complete_words) "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let [neocomplcache.cur_keyword_pos,
        \ neocomplcache.cur_keyword_str, neocomplcache.complete_words] =
        \ [a:cur_keyword_pos, a:cur_keyword_str, a:complete_words]

  " Set function.
  let &l:completefunc = 'neocomplcache#auto_complete'

  " Start complete.
  return "\<C-x>\<C-u>\<C-p>"
endfunction"}}}
"}}}

" Event functions. "{{{
function! s:on_moved_i() "{{{
  " Get cursor word.
  let cur_text = s:get_cur_text()

  " Make cache.
  if cur_text =~ '^\s*$\|\s\+$'
    if neocomplcache#is_enabled_source('buffer_complete')
      " Caching current cache line.
      call neocomplcache#sources#buffer_complete#caching_current_line()
    endif
    if neocomplcache#is_enabled_source('member_complete')
      " Caching current cache line.
      call neocomplcache#sources#member_complete#caching_current_line()
    endif
  endif

  if g:neocomplcache_enable_auto_close_preview &&
        \ bufname('%') !=# '[Command Line]'
    " Close preview window.
    pclose!
  endif
endfunction"}}}
function! s:on_insert_leave() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()

  let neocomplcache.cur_text = ''
  let neocomplcache.old_cur_text = ''

  " Restore foldinfo.
  " Note: settabwinvar() in insert mode has bug before 7.3.768.
  for tabnr in (v:version > 703 || (v:version == 703 && has('patch768')) ?
        \ range(1, tabpagenr('$')) : [tabpagenr()])
    for winnr in filter(range(1, tabpagewinnr(tabnr, '$')),
          \ "!empty(gettabwinvar(tabnr, v:val, 'neocomplcache_foldinfo'))")
      let neocomplcache_foldinfo =
            \ gettabwinvar(tabnr, winnr, 'neocomplcache_foldinfo')
      call settabwinvar(tabnr, winnr, '&foldmethod',
            \ neocomplcache_foldinfo.foldmethod)
      call settabwinvar(tabnr, winnr, '&foldexpr',
            \ neocomplcache_foldinfo.foldexpr)
      call settabwinvar(tabnr, winnr,
            \ 'neocomplcache_foldinfo', {})
    endfor
  endfor

  if g:neocomplcache_enable_auto_close_preview &&
        \ bufname('%') !=# '[Command Line]'
    " Close preview window.
    pclose!
  endif
endfunction"}}}
function! s:save_foldinfo() "{{{
  " Save foldinfo.
  " Note: settabwinvar() in insert mode has bug before 7.3.768.
  for tabnr in filter((v:version > 703 || (v:version == 703 && has('patch768')) ?
        \ range(1, tabpagenr('$')) : [tabpagenr()]),
        \ "index(tabpagebuflist(v:val), bufnr('%')) >= 0")
    let winnrs = range(1, tabpagewinnr(tabnr, '$'))
    if tabnr == tabpagenr()
      call filter(winnrs, "winbufnr(v:val) == bufnr('%')")
    endif

    " Note: for foldmethod=expr or syntax.
    call filter(winnrs, "
          \  (gettabwinvar(tabnr, v:val, '&foldmethod') ==# 'expr' ||
          \   gettabwinvar(tabnr, v:val, '&foldmethod') ==# 'syntax') &&
          \  gettabwinvar(tabnr, v:val, '&modifiable')")
    for winnr in winnrs
      call settabwinvar(tabnr, winnr, 'neocomplcache_foldinfo', {
            \ 'foldmethod' : gettabwinvar(tabnr, winnr, '&foldmethod'),
            \ 'foldexpr'   : gettabwinvar(tabnr, winnr, '&foldexpr')
            \ })
      call settabwinvar(tabnr, winnr, '&foldmethod', 'manual')
      call settabwinvar(tabnr, winnr, '&foldexpr', 0)
    endfor
  endfor
endfunction"}}}
function! s:on_insert_enter() "{{{
  if &l:foldmethod ==# 'expr' && foldlevel('.') != 0
    foldopen
  endif
endfunction"}}}
function! s:on_complete_done() "{{{
  " Get cursor word.
  let [_, candidate] =
        \ neocomplcache#match_word(s:get_cur_text())
  if candidate == ''
    return
  endif

  let frequencies = s:get_frequencies()
  if !has_key(frequencies, candidate)
    let frequencies[candidate] = 20
  else
    let frequencies[candidate] += 20
  endif
endfunction"}}}
function! s:change_update_time() "{{{
  if &updatetime > g:neocomplcache_cursor_hold_i_time
    " Change updatetime.
    let neocomplcache = neocomplcache#get_current_neocomplcache()
    let neocomplcache.update_time_save = &updatetime
    let &updatetime = g:neocomplcache_cursor_hold_i_time
  endif
endfunction"}}}
function! s:restore_update_time() "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()
  if &updatetime < neocomplcache.update_time_save
    " Restore updatetime.
    let &updatetime = neocomplcache.update_time_save
  endif
endfunction"}}}
function! s:remove_next_keyword(source_name, list) "{{{
  " Remove next keyword.
  let pattern = '^\%(' .
        \ (a:source_name  == 'filename_complete' ?
        \   neocomplcache#get_next_keyword_pattern('filename') :
        \   neocomplcache#get_next_keyword_pattern()) . '\m\)'

  let next_keyword_str = matchstr('a'.
        \ getline('.')[len(neocomplcache#get_cur_text(1)) :], pattern)[1:]
  if next_keyword_str == ''
    return a:list
  endif

  let next_keyword_str = substitute(
        \ substitute(escape(next_keyword_str,
        \ '~" \.^$*[]'), "'", "''", 'g'), ')$', '', '').'$'

  " No ignorecase.
  let ignorecase_save = &ignorecase
  let &ignorecase = 0

  for r in a:list
    if r.word =~ next_keyword_str
      if !has_key(r, 'abbr')
        let r.abbr = r.word
      endif

      let r.word = r.word[:match(r.word, next_keyword_str)-1]
    endif
  endfor

  let &ignorecase = ignorecase_save

  return a:list
endfunction"}}}
function! neocomplcache#popup_post() "{{{
  return  !pumvisible() ? "" :
        \ g:neocomplcache_enable_auto_select ? "\<C-p>\<Down>" :
        \ "\<C-p>"
endfunction"}}}
function! s:clear_result()
  let neocomplcache = neocomplcache#get_current_neocomplcache()

  let neocomplcache.cur_keyword_str = ''
  let neocomplcache.complete_words = []
  let neocomplcache.complete_results = {}
  let neocomplcache.cur_keyword_pos = -1
endfunction
"}}}

" Internal helper functions. "{{{
function! s:get_cur_text() "{{{
  let cur_text =
        \ (mode() ==# 'i' ? (col('.')-1) : col('.')) >= len(getline('.')) ?
        \      getline('.') :
        \      matchstr(getline('.'),
        \         '^.*\%' . col('.') . 'c' . (mode() ==# 'i' ? '' : '.'))

  if cur_text =~ '^.\{-}\ze\S\+$'
    let cur_keyword_str = matchstr(cur_text, '\S\+$')
    let cur_text = matchstr(cur_text, '^.\{-}\ze\S\+$')
  else
    let cur_keyword_str = ''
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()
  if neocomplcache.event ==# 'InsertCharPre'
    let cur_keyword_str .= v:char
  endif

  let filetype = neocomplcache#get_context_filetype()
  let wildcard = get(g:neocomplcache_wildcard_characters, filetype,
        \ get(g:neocomplcache_wildcard_characters, '_', '*'))
  if g:neocomplcache_enable_wildcard &&
        \ wildcard !=# '*' && len(wildcard) == 1
    " Substitute wildcard character.
    while 1
      let index = stridx(cur_keyword_str, wildcard)
      if index <= 0
        break
      endif

      let cur_keyword_str = cur_keyword_str[: index-1]
            \ . '*' . cur_keyword_str[index+1: ]
    endwhile
  endif

  let neocomplcache.cur_text = cur_text . cur_keyword_str

  " Save cur_text.
  return neocomplcache.cur_text
endfunction"}}}
function! s:set_context_filetype() "{{{
  let old_filetype = neocomplcache#get_current_neocomplcache().filetype
  if old_filetype == ''
    let old_filetype = &filetype
  endif
  if old_filetype == ''
    let old_filetype = 'nothing'
  endif

  let neocomplcache = neocomplcache#get_current_neocomplcache()

  let dup_check = {}
  while 1
    let new_filetype = s:get_context_filetype(old_filetype)

    " Check filetype root.
    if get(dup_check, old_filetype, '') ==# new_filetype
      let neocomplcache.context_filetype = old_filetype
      break
    endif

    " Save old -> new filetype graph.
    let dup_check[old_filetype] = new_filetype
    let old_filetype = new_filetype
  endwhile

  " Set filetype plugins.
  let s:loaded_ftplugin_sources = {}
  for [source_name, source] in
        \ items(filter(copy(neocomplcache#available_ftplugins()),
        \ 'has_key(v:val.filetypes, neocomplcache.context_filetype)'))
    let s:loaded_ftplugin_sources[source_name] = source

    if !source.loaded
      " Initialize.
      if has_key(source, 'initialize')
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
      endif

      let source.loaded = 1
    endif
  endfor

  return neocomplcache.context_filetype
endfunction"}}}
function! s:get_context_filetype(filetype) "{{{
  " Default.
  let filetype = a:filetype
  if filetype == ''
    let filetype = 'nothing'
  endif

  " Default range.
  let neocomplcache = neocomplcache#get_current_neocomplcache()

  let pos = [line('.'), col('.')]
  for include in get(g:neocomplcache_context_filetype_lists, filetype, [])
    let start_backward = searchpos(include.start, 'bneW')

    " Check pos > start.
    if start_backward[0] == 0 || s:compare_pos(start_backward, pos) > 0
      continue
    endif

    let end_pattern = include.end
    if end_pattern =~ '\\1'
      let match_list = matchlist(getline(start_backward[0]), include.start)
      let end_pattern = substitute(end_pattern, '\\1', '\=match_list[1]', 'g')
    endif
    let end_forward = searchpos(end_pattern, 'nW')
    if end_forward[0] == 0
      let end_forward = [line('$'), len(getline('$'))+1]
    endif

    " Check end > pos.
    if s:compare_pos(pos, end_forward) > 0
      continue
    endif

    let end_backward = searchpos(end_pattern, 'bnW')

    " Check start <= end.
    if s:compare_pos(start_backward, end_backward) < 0
      continue
    endif

    if start_backward[1] == len(getline(start_backward[0]))
      " Next line.
      let start_backward[0] += 1
      let start_backward[1] = 1
    endif
    if end_forward[1] == 1
      " Previous line.
      let end_forward[0] -= 1
      let end_forward[1] = len(getline(end_forward[0]))
    endif

    let neocomplcache.context_filetype_range =
          \ [ start_backward, end_forward ]
    return include.filetype
  endfor

  return filetype
endfunction"}}}
function! s:match_wildcard(cur_text, pattern, cur_keyword_pos) "{{{
  let cur_keyword_pos = a:cur_keyword_pos
  while cur_keyword_pos > 1 && a:cur_text[cur_keyword_pos - 1] == '*'
    let left_text = a:cur_text[: cur_keyword_pos - 2]
    if left_text == '' || left_text !~ a:pattern
      break
    endif

    let cur_keyword_pos = match(left_text, a:pattern)
  endwhile

  return cur_keyword_pos
endfunction"}}}
function! s:unite_patterns(pattern_var, filetype) "{{{
  let keyword_patterns = []
  let dup_check = {}

  " Composite filetype.
  for ft in split(a:filetype, '\.')
    if has_key(a:pattern_var, ft) && !has_key(dup_check, ft)
      let dup_check[ft] = 1
      call add(keyword_patterns, a:pattern_var[ft])
    endif

    " Same filetype.
    if has_key(g:neocomplcache_same_filetype_lists, ft)
      for ft in split(g:neocomplcache_same_filetype_lists[ft], ',')
        if has_key(a:pattern_var, ft) && !has_key(dup_check, ft)
          let dup_check[ft] = 1
          call add(keyword_patterns, a:pattern_var[ft])
        endif
      endfor
    endif
  endfor

  if empty(keyword_patterns)
    let default = get(a:pattern_var, '_', get(a:pattern_var, 'default', ''))
    if default != ''
      call add(keyword_patterns, default)
    endif
  endif

  return join(keyword_patterns, '\m\|')
endfunction"}}}
function! s:get_frequencies() "{{{
  let filetype = neocomplcache#get_context_filetype()
  if !has_key(s:filetype_frequencies, filetype)
    let s:filetype_frequencies[filetype] = {}
  endif

  let frequencies = s:filetype_frequencies[filetype]

  return frequencies
endfunction"}}}
function! neocomplcache#get_current_neocomplcache() "{{{
  if !exists('b:neocomplcache')
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
          \}
  endif

  return b:neocomplcache
endfunction"}}}
function! s:initialize_sources(source_names) "{{{
  " Initialize sources table.
  if s:loaded_all_sources && &runtimepath ==# s:runtimepath_save
    return
  endif

  let runtimepath_save = neocomplcache#util#split_rtp(s:runtimepath_save)
  let runtimepath = neocomplcache#util#join_rtp(
        \ filter(neocomplcache#util#split_rtp(),
        \ 'index(runtimepath_save, v:val) < 0'))

  for name in a:source_names
    if has_key(s:complfunc_sources, name)
            \ || has_key(s:ftplugin_sources, name)
            \ || has_key(s:plugin_sources, name)
      continue
    endif

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

      if source.kind ==# 'complfunc'
        let s:complfunc_sources[source_name] = source
        let source.loaded = 1
      elseif source.kind ==# 'ftplugin'
        let s:ftplugin_sources[source_name] = source

        " Clear loaded flag.
        let s:ftplugin_sources[source_name].loaded = 0
      elseif source.kind ==# 'plugin'
        let s:plugin_sources[source_name] = source
        let source.loaded = 1
      endif

      if (source.kind ==# 'complfunc' || source.kind ==# 'plugin')
            \ && has_key(source, 'initialize')
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
      endif
    endfor

    if name == '_'
      let s:loaded_all_sources = 1
      let s:runtimepath_save = &runtimepath
    endif
  endfor
endfunction"}}}
function! s:get_sources_list(...) "{{{
  let filetype = neocomplcache#get_context_filetype()

  let source_names = exists('b:neocomplcache_sources_list') ?
        \ b:neocomplcache_sources_list :
        \ get(a:000, 0,
        \   get(g:neocomplcache_sources_list, filetype,
        \     get(g:neocomplcache_sources_list, '_', ['_'])))
  let disabled_sources = get(
        \ g:neocomplcache_disabled_sources_list, filetype,
        \   get(g:neocomplcache_disabled_sources_list, '_', []))
  call s:initialize_sources(source_names)

  let all_sources = neocomplcache#available_sources()
  let sources = {}
  for source_name in source_names
    if source_name ==# '_'
      " All sources.
      let sources = all_sources
      break
    endif

    if !has_key(all_sources, source_name)
      call neocomplcache#print_warning(printf(
            \ 'Invalid source name "%s" is given.', source_name))
      continue
    endif

    let sources[source_name] = all_sources[source_name]
  endfor

  let neocomplcache = neocomplcache#get_current_neocomplcache()
  let neocomplcache.sources = filter(sources, "
        \ index(disabled_sources, v:val.name) < 0 &&
        \   (v:val.kind !=# 'ftplugin' ||
        \    get(v:val.filetypes, neocomplcache.context_filetype, 0))")

  return neocomplcache.sources
endfunction"}}}
function! s:is_skip_auto_complete(cur_text) "{{{
  let neocomplcache = neocomplcache#get_current_neocomplcache()

  if a:cur_text =~ '^\s*$\|\s\+$'
        \ || a:cur_text == neocomplcache.old_cur_text
        \ || (g:neocomplcache_lock_iminsert && &l:iminsert)
        \ || (&l:formatoptions =~# '[tc]' && &l:textwidth > 0
        \     && neocomplcache#util#wcswidth(a:cur_text) >= &l:textwidth)
    return 1
  endif

  if !neocomplcache.skip_next_complete
    return 0
  endif

  " Check delimiter pattern.
  let is_delimiter = 0
  let filetype = neocomplcache#get_context_filetype()

  for delimiter in ['/', '\.'] +
        \ get(g:neocomplcache_delimiter_patterns, filetype, [])
    if a:cur_text =~ delimiter . '$'
      let is_delimiter = 1
      break
    endif
  endfor

  if is_delimiter && neocomplcache.skip_next_complete == 2
    let neocomplcache.skip_next_complete = 0
    return 0
  endif

  let neocomplcache.skip_next_complete = 0
  let neocomplcache.cur_text = ''
  let neocomplcache.old_cur_text = ''

  return 1
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
