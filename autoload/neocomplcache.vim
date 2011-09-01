"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 01 Sep 2011.
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
" Version: 6.2, for Vim 7.0
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Check vimproc.
try
  call vimproc#version()
  let s:exists_vimproc = 1
catch
  let s:exists_vimproc = 0
endtry

if !exists('s:is_enabled')
  let s:is_enabled = 0
endif

function! neocomplcache#enable() "{{{
  augroup neocomplcache "{{{
    autocmd!
    " Auto complete events
    autocmd CursorMovedI * call s:on_moved_i()
    autocmd CursorHoldI * call s:on_hold_i()
    autocmd InsertEnter * call s:on_insert_enter()
    autocmd InsertLeave * call s:on_insert_leave()
  augroup END "}}}

  " Disable beep.
  set vb t_vb=

  " Initialize"{{{
  let s:is_enabled = 1
  let s:complfunc_sources = {}
  let s:plugin_sources = {}
  let s:ftplugin_sources = {}
  let s:loaded_ftplugin_sources = {}
  let s:complete_lock = {}
  let s:plugins_lock = {}
  let s:auto_completion_length = {}
  let s:cur_keyword_str = ''
  let s:complete_words = []
  let s:complete_results = {}
  let s:old_cur_keyword_pos = -1
  let s:update_time_save = &updatetime
  let s:cur_text = ''
  let s:old_cur_text = ''
  let s:moved_cur_text = ''
  let s:changedtick = b:changedtick
  let s:context_filetype = ''
  let s:is_text_mode = 0
  let s:within_comment = 0
  let s:skip_next_complete = 0
  "}}}

  " Initialize sources table."{{{
  " Search autoload.
  for file in split(globpath(&runtimepath, 'autoload/neocomplcache/sources/*.vim'), '\n')
    let l:source_name = fnamemodify(file, ':t:r')
    if !has_key(s:plugin_sources, l:source_name)
          \ && (!has_key(g:neocomplcache_plugin_disable, l:source_name) || 
          \ g:neocomplcache_plugin_disable[l:source_name] == 0)
      let l:source = call('neocomplcache#sources#' . l:source_name . '#define', [])
      if empty(l:source)
        " Ignore.
      elseif l:source.kind ==# 'complfunc'
        let s:complfunc_sources[l:source_name] = l:source
      elseif l:source.kind ==# 'ftplugin'
        let s:ftplugin_sources[l:source_name] = l:source

        " Clear loaded flag.
        let s:ftplugin_sources[l:source_name].loaded = 0
      elseif l:source.kind ==# 'plugin'
            \ && neocomplcache#is_keyword_complete_enabled()
        let s:plugin_sources[l:source_name] = l:source
      endif
    endif
  endfor
  "}}}

  " Initialize keyword patterns."{{{
  if !exists('g:neocomplcache_keyword_patterns')
    let g:neocomplcache_keyword_patterns = {}
  endif
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'default',
        \'\k\+')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'filename',
        \'\%(\\[^[:alnum:].-]\|\f\)\+')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'lisp,scheme,clojure,int-gosh,int-clisp,int-clj',
        \'[[:alpha:]+*/@$_=.!?-][[:alnum:]+*/@$_:=.!?-]*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'ruby,int-irb',
        \'^=\%(b\%[egin]\|e\%[nd]\)\|\%(@@\|[:$@]\)\h\w*\|\h\w*\%(::\w*\)*[!?]\?')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'php',
        \'</\?\%(\h[[:alnum:]_-]*\s*\)\?\%(/\?>\)\?\|\$\h\w*\|\h\w*\%(\%(\\\|::\)\w*\)*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'perl,int-perlsh',
        \'<\h\w*>\?\|[$@%&*]\h\w*\|\h\w*\%(::\w*\)*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'perl6,int-perl6',
        \'<\h\w*>\?\|[$@%&][!.*?]\?\h[[:alnum:]_-]*\|\h[[:alnum:]_-]*\%(::[[:alnum:]_-]*\)*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'pir',
        \'[$@%.=]\?\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'pasm',
        \'[=]\?\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'vim,help',
        \'\c\[:\%(\h\w*:\]\)\?\|&\h[[:alnum:]_:]*\|\$\h\w*\|-\h\w*=\?\|<SID>\%(\h\w*\)\?\|<Plug>([^)]*)\?\|<\h[[:alnum:]_-]*>\?\|\h[[:alnum:]_:#]*!\?')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'tex',
        \'\\\a{\a\{1,2}}\|\\[[:alpha:]@][[:alnum:]@]*\%({\%([[:alnum:]:]\+\*\?}\?\)\?\)\?\|\a[[:alnum:]:_]*\*\?')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'sh,zsh,int-zsh,int-bash,int-sh',
        \'\$\w\+\|[[:alpha:]_.-][[:alnum:]_.-]*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'vimshell',
        \'\$\$\?\w*\|[[:alpha:]_.\\/~-][[:alnum:]_.\\/~-]*\|\d\+\%(\.\d\+\)\+')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'ps1,int-powershell',
        \'\[\h\%([[:alnum:]_.]*\]::\)\?\|[$%@.]\?[[:alpha:]_.:-][[:alnum:]_.:-]*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'c',
        \'^\s*#\s*\h\w*\|\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'cpp',
        \'^\s*#\s*\h\w*\|\h\w*\%(::\w*\)*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'objc',
        \'^\s*#\s*\h\w*\|\h\w*\|@\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'objcpp',
        \'^\s*#\s*\h\w*\|\h\w*\%(::\w*\)*\|@\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'objj',
        \'\h\w*\|@\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'd',
        \'\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'python,int-python,int-ipython',
        \'\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'cs',
        \'\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'java',
        \'[@]\?\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'javascript,actionscript,int-js,int-kjs',
        \'\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'coffee,int-coffee',
        \'@\h\w*\|\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'awk',
        \'\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'haskell,int-ghci',
        \'\%(\u\w*\.\)\+[[:alnum:]_'']*\|[[:alpha:]_''][[:alnum:]_'']*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'ml,ocaml,int-ocaml,int-sml,int-smlsharp',
        \'[''`#.]\?\h[[:alnum:]_'']*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'erlang,int-erl',
        \'^\s*-\h\w*\|\%(\h\w*:\)*\h\w\|\h[[:alnum:]_@]*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'html,xhtml,xml,markdown,eruby',
        \'</\?\%([[:alnum:]_:-]\+\s*\)\?\%(/\?>\)\?\|&\h\%(\w*;\)\?\|\h[[:alnum:]_-]*="\%([^"]*"\?\)\?\|\h[[:alnum:]_:-]*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'css,stylus',
        \'[@#.]\?[[:alpha:]_:-][[:alnum:]_:-]*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'tags',
        \'^[^!][^/[:blank:]]*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'pic',
        \'^\s*#\h\w*\|\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'arm',
        \'\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'asmh8300',
        \'[[:alpha:]_.][[:alnum:]_.]*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'masm',
        \'\.\h\w*\|[[:alpha:]_@?$][[:alnum:]_@?$]*\|\h\w*:\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'nasm',
        \'^\s*\[\h\w*\|[%.]\?\h\w*\|\%(\.\.@\?\|%[%$!]\)\%(\h\w*\)\?\|\h\w*:\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'asm',
        \'[%$.]\?\h\w*\%(\$\h\w*\)\?')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'gas',
        \'[$.]\?\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'gdb,int-gdb',
        \'$\h\w*\|[[:alnum:]:._-]\+')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'make',
        \'[[:alpha:]_.-][[:alnum:]_.-]*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'scala,int-scala',
        \'\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'int-termtter',
        \'\h[[:alnum:]_/-]*\|\$\a\+\|#\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'int-earthquake',
        \'\h[[:alnum:]_/-]*\|\$\a\+\|[:#]\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'dosbatch,int-cmdproxy',
        \'\$\w+\|[[:alpha:]_./-][[:alnum:]_.-]*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'vb',
        \'\a[[:alnum:]]*\|#\a[[:alnum:]]*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'lua',
        \'\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'zimbu',
        \'\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'konoha',
        \'[*$@%]\h\w*\|\h\w*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'cobol',
        \'\a[[:alnum:]-]*')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_keyword_patterns, 'coq',
        \'\h[[:alnum:]_'']*')
  "}}}

  " Initialize next keyword patterns."{{{
  if !exists('g:neocomplcache_next_keyword_patterns')
    let g:neocomplcache_next_keyword_patterns = {}
  endif
  call neocomplcache#set_dictionary_helper(g:neocomplcache_next_keyword_patterns, 'perl',
        \'\h\w*>')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_next_keyword_patterns, 'perl6',
        \'\h\w*>')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_next_keyword_patterns, 'vim,help',
        \'\w*()\?\|\w*:\]\|[[:alnum:]_-]*[)>=]')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_next_keyword_patterns, 'tex',
        \'\h\w*\*\?[*[{}]')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_next_keyword_patterns, 'html,xhtml,xml,mkd',
        \'[[:alnum:]_:-]*>\|[^"]*"')
  "}}}

  " Initialize same file type lists."{{{
  if !exists('g:neocomplcache_same_filetype_lists')
    let g:neocomplcache_same_filetype_lists = {}
  endif
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'c', 'cpp')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'cpp', 'c')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'erb', 'ruby,html,xhtml')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'html,xml', 'xhtml')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'html,xhtml', 'css,stylus')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'stylus', 'css')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'xhtml', 'html,xml')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'help', 'vim')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'tex', 'bib')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'lingr-say', 'lingr-messages,lingr-members')

  " Interactive filetypes.
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-irb', 'ruby')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-ghci,int-hugs', 'haskell')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-python,int-ipython', 'python')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-gosh', 'scheme')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-clisp', 'lisp')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-erl', 'erlang')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-zsh', 'zsh')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-bash', 'bash')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-sh', 'sh')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-cmdproxy', 'dosbatch')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-powershell', 'powershell')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-perlsh', 'perl')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-perl6', 'perl6')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-ocaml', 'ocaml')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-clj', 'clojure')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-sml,int-smlsharp', 'sml')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-js,int-kjs', 'javascript')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-coffee', 'coffee')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-gdb', 'gdb')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_same_filetype_lists, 'int-scala', 'scala')
  "}}}

  " Initialize include filetype lists."{{{
  if !exists('g:neocomplcache_filetype_include_lists')
    let g:neocomplcache_filetype_include_lists = {}
  endif
  call neocomplcache#set_dictionary_helper(g:neocomplcache_filetype_include_lists, 'c,cpp', [
        \ {'filetype' : 'masm', 'start' : '_*asm_*\s\+\h\w*', 'end' : '$'},
        \ {'filetype' : 'masm', 'start' : '_*asm_*\s*\%(\n\s*\)\?{', 'end' : '}'},
        \ {'filetype' : 'gas', 'start' : '_*asm_*\s*\%(_*volatile_*\s*\)\?(', 'end' : ');'},
        \])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_filetype_include_lists, 'd', [
        \ {'filetype' : 'masm', 'start' : 'asm\s*\%(\n\s*\)\?{', 'end' : '}'},
        \])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_filetype_include_lists, 'perl6', [
        \ {'filetype' : 'pir', 'start' : 'Q:PIR\s*{', 'end' : '}'},
        \])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_filetype_include_lists, 'vimshell', [
        \ {'filetype' : 'vim', 'start' : 'vexe \([''"]\)', 'end' : '\\\@<!\1'},
        \ {'filetype' : 'vim', 'start' : ' :\w*', 'end' : '\n'},
        \ {'filetype' : 'vim', 'start' : ' vexe\s\+', 'end' : '\n'},
        \])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_filetype_include_lists, 'eruby', [
        \ {'filetype' : 'ruby', 'start' : '<%[=#]\?', 'end' : '%>'},
        \])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_filetype_include_lists, 'vim', [
        \ {'filetype' : 'python', 'start' : '^\s*python <<\s*\(\h\w*\)', 'end' : '^\1'},
        \ {'filetype' : 'ruby', 'start' : '^\s*ruby <<\s*\(\h\w*\)', 'end' : '^\1'},
        \])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_filetype_include_lists, 'html,xhtml', [
        \ {'filetype' : 'javascript', 'start' : '<script type="text/javascript">', 'end' : '</script>'},
        \ {'filetype' : 'css', 'start' : '<style type="text/css">', 'end' : '</style>'},
        \])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_filetype_include_lists, 'python', [
        \ {'filetype' : 'vim', 'start' : 'vim.command\s*(\([''"]\)', 'end' : '\\\@<!\1\s*)'},
        \ {'filetype' : 'vim', 'start' : 'vim.eval\s*(\([''"]\)', 'end' : '\\\@<!\1\s*)'},
        \])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_filetype_include_lists, 'help', [
        \ {'filetype' : 'vim', 'start' : '^>', 'end' : '^<'},
        \])
  "}}}

  " Initialize member prefix patterns."{{{
  if !exists('g:neocomplcache_member_prefix_patterns')
    let g:neocomplcache_member_prefix_patterns = {}
  endif
  call neocomplcache#set_dictionary_helper(g:neocomplcache_member_prefix_patterns, 'c,cpp,objc,objcpp', '\.\|->')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_member_prefix_patterns, 'perl,php', '->')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_member_prefix_patterns, 'cs,java,javascript,d,vim,ruby,python,perl6,scala,vb', '\.')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_member_prefix_patterns, 'lua', '\.\|:')
  "}}}

  " Initialize delimiter patterns."{{{
  if !exists('g:neocomplcache_delimiter_patterns')
    let g:neocomplcache_delimiter_patterns = {}
  endif
  call neocomplcache#set_dictionary_helper(g:neocomplcache_delimiter_patterns, 'vim,help',
        \['#'])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_delimiter_patterns, 'erlang,lisp,int-clisp',
        \[':'])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_delimiter_patterns, 'lisp,int-clisp',
        \['/', ':'])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_delimiter_patterns, 'clojure,int-clj',
        \['/', '\.'])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_delimiter_patterns, 'perl,cpp',
        \['::'])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_delimiter_patterns, 'php',
        \['\', '::'])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_delimiter_patterns, 'java,d,javascript,actionscript,ruby,eruby,haskell,int-ghci,coffee,zimbu,konoha',
        \['\.'])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_delimiter_patterns, 'lua',
        \['\.', ':'])
  call neocomplcache#set_dictionary_helper(g:neocomplcache_delimiter_patterns, 'perl6',
        \['\.', '::'])
  "}}}

  " Initialize ctags arguments."{{{
  if !exists('g:neocomplcache_ctags_arguments_list')
    let g:neocomplcache_ctags_arguments_list = {}
  endif
  call neocomplcache#set_dictionary_helper(g:neocomplcache_ctags_arguments_list, 'default', '')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_ctags_arguments_list, 'vim',
        \"--extra=fq --fields=afmiKlnsStz --regex-vim='/function!? ([a-z#:_0-9A-Z]+)/\\1/function/'")
  if !neocomplcache#is_win() && (has('macunix') || system('uname') =~? '^darwin')
    call neocomplcache#set_dictionary_helper(g:neocomplcache_ctags_arguments_list, 'c',
          \'--c-kinds=+p --fields=+iaS --extra=+q -I__DARWIN_ALIAS,__DARWIN_ALIAS_C,__DARWIN_ALIAS_I,__DARWIN_INODE64
          \ -I__DARWIN_1050,__DARWIN_1050ALIAS,__DARWIN_1050ALIAS_C,__DARWIN_1050ALIAS_I,__DARWIN_1050INODE64
          \ -I__DARWIN_EXTSN,__DARWIN_EXTSN_C
          \ -I__DARWIN_LDBL_COMPAT,__DARWIN_LDBL_COMPAT2')
  else
    call neocomplcache#set_dictionary_helper(g:neocomplcache_ctags_arguments_list, 'c',
          \'-R --sort=1 --c-kinds=+p --fields=+iaS --extra=+q -I __wur')
  endif
  call neocomplcache#set_dictionary_helper(g:neocomplcache_ctags_arguments_list, 'cpp',
        \'-R --sort=1 --c++-kinds=+p --fields=+iaS --extra=+q -I __wur --language-force=C++')
  "}}}

  " Initialize text mode filetypes."{{{
  if !exists('g:neocomplcache_text_mode_filetypes')
    let g:neocomplcache_text_mode_filetypes = {}
  endif
  call neocomplcache#set_dictionary_helper(g:neocomplcache_text_mode_filetypes, 'text,help,tex,gitcommit,nothing,vcs-commit', 1)
  "}}}

  " Initialize tags filter patterns."{{{
  if !exists('g:neocomplcache_tags_filter_patterns')
    let g:neocomplcache_tags_filter_patterns = {}
  endif
  call neocomplcache#set_dictionary_helper(g:neocomplcache_tags_filter_patterns, 'c,cpp', 
        \'v:val.word !~ ''^[~_]''')
  "}}}

  " Add commands."{{{
  command! -nargs=? Neco call s:display_neco(<q-args>)
  command! -nargs=1 NeoComplCacheAutoCompletionLength call s:set_auto_completion_length(<args>)
  "}}}

  " Must g:neocomplcache_auto_completion_start_length > 1.
  if g:neocomplcache_auto_completion_start_length < 1
    let g:neocomplcache_auto_completion_start_length = 1
  endif
  " Must g:neocomplcache_min_keyword_length > 1.
  if g:neocomplcache_min_keyword_length < 1
    let g:neocomplcache_min_keyword_length = 1
  endif

  " Save options.
  let s:completefunc_save = &completefunc
  let s:completeopt_save = &completeopt

  " Set completefunc.
  let &completefunc = 'neocomplcache#manual_complete'
  let &l:completefunc = 'neocomplcache#manual_complete'

  " Set options.
  set completeopt-=menu
  set completeopt+=menuone

  " For auto complete keymappings.
  inoremap <silent> <Plug>(neocomplcache_start_auto_complete)          <C-x><C-u><C-p>
  inoremap <silent> <Plug>(neocomplcache_start_auto_select_complete)
        \ <C-x><C-u><C-p><C-r>=neocomplcache#popup_post()<CR>
  inoremap <expr><silent> <Plug>(neocomplcache_start_unite_complete)   unite#sources#neocomplcache#start_complete()
  inoremap <expr><silent> <Plug>(neocomplcache_start_unite_snippet)   unite#sources#snippet#start_complete()

  " Disable bell.
  set vb t_vb=

  " Initialize.
  for l:source in values(neocomplcache#available_complfuncs())
    call l:source.initialize()
  endfor
endfunction"}}}

function! neocomplcache#disable()"{{{
  if !neocomplcache#is_enabled()
    call neocomplcache#print_warning('neocomplcache is disabled! This command is ignored.')
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

  for l:source in values(neocomplcache#available_complfuncs())
    call l:source.finalize()
  endfor
  for l:source in values(neocomplcache#available_ftplugins())
    if l:source.loaded
      call l:source.finalize()
    endif
  endfor
endfunction"}}}

function! neocomplcache#manual_complete(findstart, base)"{{{
  if a:findstart
    if !neocomplcache#is_enabled()
      let s:cur_keyword_str = ''
      let s:complete_words = []
      let &l:completefunc = 'neocomplcache#manual_complete'
      return -1
    endif

    " Get cur_keyword_pos.
    let l:complete_results = neocomplcache#get_complete_results_pos(s:get_cur_text())
    let l:cur_keyword_pos = neocomplcache#get_cur_keyword_pos(l:complete_results)

    if l:cur_keyword_pos < 0
      let s:cur_keyword_str = ''
      let s:complete_words = []
      let s:complete_results = {}
      let &l:completefunc = 'neocomplcache#manual_complete'
      return -1
    endif

    let s:complete_results = l:complete_results

    return l:cur_keyword_pos
  endif

  " Set cur_text temporary.
  let l:cur_text = neocomplcache#get_cur_text()
  let l:old_line = getline('.')
  call setline('.', l:cur_text)

  let l:cur_keyword_pos = neocomplcache#get_cur_keyword_pos(s:complete_results)
  let l:complete_words = neocomplcache#get_complete_words(
        \ s:complete_results, 1, l:cur_keyword_pos, a:base)

  call setline('.', l:old_line)

  " Restore function.
  let &l:completefunc = 'neocomplcache#manual_complete'

  let s:complete_words = l:complete_words
  let s:cur_keyword_str = a:base

  return l:complete_words
endfunction"}}}

function! neocomplcache#auto_complete(findstart, base)"{{{
  return neocomplcache#manual_complete(a:findstart, a:base)
endfunction"}}}

function! neocomplcache#do_auto_complete()"{{{
  if (&buftype !~ 'nofile\|nowrite' && b:changedtick == s:changedtick)
        \ || g:neocomplcache_disable_auto_complete
        \ || neocomplcache#is_locked()
        \ || (g:neocomplcache_enable_auto_select
        \         && !neocomplcache#is_eskk_enabled()
        \         && exists('&l:iminsert') && &l:iminsert)
    return
  endif

  " Detect completefunc.
  if &l:completefunc != 'neocomplcache#manual_complete'
        \ && &l:completefunc != 'neocomplcache#auto_complete'
    if g:neocomplcache_force_overwrite_completefunc
          \ || &l:completefunc == ''
      " Set completefunc.
      let &l:completefunc = 'neocomplcache#manual_complete'
    else
      " Warning.
      redir => l:output
      99verbose setl completefunc
      redir END
      call neocomplcache#print_error(l:output)
      call neocomplcache#print_error('Another plugin set completefunc! Disabled neocomplcache.')
      NeoComplCacheLock
      return
    endif
  endif

  " Detect AutoComplPop.
  if exists('g:acp_enableAtStartup') && g:acp_enableAtStartup
    call neocomplcache#print_error('Detected enabled AutoComplPop! Disabled neocomplcache.')
    NeoComplCacheLock
    return
  endif

  " Detect set paste.
  if &paste
    redir => l:output
      99verbose set paste
    redir END
    call neocomplcache#print_error(l:output)
    call neocomplcache#print_error('Detected set paste! Disabled neocomplcache.')
    return
  endif

  " Get cursor word.
  let l:cur_text = s:get_cur_text()
  " Prevent infinity loop.
  if l:cur_text == '' || l:cur_text == s:old_cur_text
        \|| (!neocomplcache#is_eskk_enabled() && exists('b:skk_on') && b:skk_on)
    let s:cur_keyword_str = ''
    let s:complete_words = []
    return
  endif

  let s:old_cur_text = l:cur_text
  if s:skip_next_complete
    let s:skip_next_complete = 0
    return
  endif

  let &l:completefunc = 'neocomplcache#auto_complete'

  " Get cur_keyword_pos.
  let l:cur_keyword_pos = neocomplcache#get_cur_keyword_pos(
        \ neocomplcache#get_complete_results_pos(l:cur_text))
  if l:cur_keyword_pos < 0
    let &l:completefunc = 'neocomplcache#manual_complete'
    " Not found.
    return
  endif

  let s:changedtick = b:changedtick

  " Set options.
  set completeopt-=menu
  set completeopt-=longest
  set completeopt+=menuone

  " Start auto complete.
  if neocomplcache#is_auto_select()
    call feedkeys("\<Plug>(neocomplcache_start_auto_select_complete)")
  else
    call feedkeys("\<Plug>(neocomplcache_start_auto_complete)")
  endif

  let s:changedtick = b:changedtick
endfunction"}}}

" Plugin helper."{{{
function! neocomplcache#available_complfuncs()"{{{
  return s:complfunc_sources
endfunction"}}}
function! neocomplcache#available_ftplugins()"{{{
  return s:ftplugin_sources
endfunction"}}}
function! neocomplcache#available_loaded_ftplugins()"{{{
  return s:loaded_ftplugin_sources
endfunction"}}}
function! neocomplcache#available_plugins()"{{{
  return s:plugin_sources
endfunction"}}}
function! neocomplcache#available_sources()"{{{
  call s:set_context_filetype()
  return extend(extend(copy(s:complfunc_sources), s:plugin_sources), s:loaded_ftplugin_sources)
endfunction"}}}
function! neocomplcache#keyword_escape(cur_keyword_str)"{{{
  " Escape."{{{
  let l:keyword_escape = escape(a:cur_keyword_str, '~" \.^$[]')
  if g:neocomplcache_enable_wildcard
    let l:keyword_escape = substitute(substitute(l:keyword_escape, '.\zs\*', '.*', 'g'), '\%(^\|\*\)\zs\*', '\\*', 'g')
    if '-' !~ '\k'
      let l:keyword_escape = substitute(l:keyword_escape, '.\zs-', '.\\+', 'g')
    endif
  else
    let l:keyword_escape = escape(a:cur_keyword_str, '*')
  endif"}}}

  " Underbar completion."{{{
  if g:neocomplcache_enable_underbar_completion && l:keyword_escape =~ '_'
    let l:keyword_escape_orig = l:keyword_escape
    let l:keyword_escape = substitute(l:keyword_escape, '[^_]\zs_', '[^_]*_', 'g')
  endif
  if g:neocomplcache_enable_underbar_completion && '-' =~ '\k' && l:keyword_escape =~ '-'
    let l:keyword_escape = substitute(l:keyword_escape, '[^-]\zs-', '[^-]*-', 'g')
  endif
  "}}}
  " Camel case completion."{{{
  if g:neocomplcache_enable_camel_case_completion && l:keyword_escape =~ '\u'
    let l:keyword_escape = substitute(l:keyword_escape, '\u\?\zs\U*', '\\%(\0\\l*\\|\U\0\E\\u*_\\?\\)', 'g')
  endif
  "}}}

  " echomsg l:keyword_escape
  return l:keyword_escape
endfunction"}}}
function! neocomplcache#keyword_filter(list, cur_keyword_str)"{{{
  let l:cur_keyword_str = a:cur_keyword_str

  " Delimiter check.
  let l:filetype = neocomplcache#get_context_filetype()
  if has_key(g:neocomplcache_delimiter_patterns, l:filetype)"{{{
    for l:delimiter in g:neocomplcache_delimiter_patterns[l:filetype]
      let l:cur_keyword_str = substitute(l:cur_keyword_str, l:delimiter, '*' . l:delimiter, 'g')
    endfor
  endif"}}}

  if l:cur_keyword_str == ''
    return a:list
  elseif neocomplcache#check_match_filter(l:cur_keyword_str)
    " Match filter.
    return filter(a:list, printf('v:val.word =~ %s',
          \string('^' . neocomplcache#keyword_escape(l:cur_keyword_str))))
  else
    " Use fast filter.
    return neocomplcache#head_filter(a:list, l:cur_keyword_str)
  endif
endfunction"}}}
function! neocomplcache#dup_filter(list)"{{{
  let l:dict = {}
  for l:keyword in a:list
    if !has_key(l:dict, l:keyword.word)
      let l:dict[l:keyword.word] = l:keyword
    endif
  endfor

  return values(l:dict)
endfunction"}}}
function! neocomplcache#check_match_filter(cur_keyword_str)"{{{
  return neocomplcache#keyword_escape(a:cur_keyword_str) =~ '[^\\]\*\|\\+'
endfunction"}}}
function! neocomplcache#check_completion_length_match(cur_keyword_str, completion_length)"{{{
  return neocomplcache#keyword_escape(
        \ a:cur_keyword_str[: a:completion_length-1]) =~
        \'[^\\]\*\|\\+\|\\%(\|\\|'
endfunction"}}}
function! neocomplcache#head_filter(list, cur_keyword_str)"{{{
  if &ignorecase
    let l:expr = printf('!stridx(tolower(v:val.word), %s)', string(tolower(a:cur_keyword_str)))
  else
    let l:expr = printf('!stridx(v:val.word, %s)', string(a:cur_keyword_str))
  endif

  return filter(a:list, l:expr)
endfunction"}}}
function! neocomplcache#fuzzy_filter(list, cur_keyword_str)"{{{
  let l:ret = []

  let l:cur_keyword_str = a:cur_keyword_str[2:]
  let l:max_str2 = len(l:cur_keyword_str)
  let l:len = len(a:cur_keyword_str)
  let m = range(l:max_str2+1)
  for keyword in filter(a:list, 'len(v:val.word) >= '.l:max_str2)
    let l:str1 = keyword.word[2 : l:len-1]

    let i = 0
    while i <= l:max_str2+1
      let m[i] = range(l:max_str2+1)

      let i += 1
    endwhile
    let i = 0
    while i <= l:max_str2+1
      let m[i][0] = i
      let m[0][i] = i

      let i += 1
    endwhile

    let i = 1
    let l:max = l:max_str2 + 1
    while i < l:max
      let j = 1
      while j < l:max
        let m[i][j] = min([m[i-1][j]+1, m[i][j-1]+1, m[i-1][j-1]+(l:str1[i-1] != l:cur_keyword_str[j-1])])

        let j += 1
      endwhile

      let i += 1
    endwhile
    if m[-1][-1] <= 2
      call add(l:ret, keyword)
    endif
  endfor

  return ret
endfunction"}}}
function! neocomplcache#dictionary_filter(dictionary, cur_keyword_str, completion_length)"{{{
  if empty(a:dictionary)
    return []
  endif

  if len(a:cur_keyword_str) < a:completion_length ||
        \ neocomplcache#check_completion_length_match(
        \   a:cur_keyword_str, a:completion_length)
    return neocomplcache#keyword_filter(neocomplcache#unpack_dictionary(a:dictionary), a:cur_keyword_str)
  else
    let l:key = tolower(a:cur_keyword_str[: a:completion_length-1])

    if !has_key(a:dictionary, l:key)
      return []
    endif

    let l:list = a:dictionary[l:key]
    if type(l:list) == type({})
      " Convert dictionary dictionary.
      unlet l:list
      let l:list = values(a:dictionary[l:key])
    endif

    return (len(a:cur_keyword_str) == a:completion_length && &ignorecase)?
          \ l:list : neocomplcache#keyword_filter(copy(l:list), a:cur_keyword_str)
  endif
endfunction"}}}
function! neocomplcache#unpack_dictionary(dict)"{{{
  let l:ret = []
  for l in values(a:dict)
    let l:ret += type(l) == type([]) ? l : values(l)
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
  let l:diff = a:i2.rank - a:i1.rank
  if !l:diff
    let l:diff = (a:i1.word ># a:i2.word) ? 1 : -1
  endif
  return l:diff
endfunction"}}}
" PosOrder."{{{
function! s:compare_pos(i1, i2)
  return a:i1[0] == a:i2[0] ? a:i1[1] - a:i2[1] : a:i1[0] - a:i2[0]
endfunction"}}}

function! neocomplcache#rand(max)"{{{
  if !has('reltime')
    " Same value.
    return 0
  endif

  let l:time = reltime()[1]
  return (l:time < 0 ? -l:time : l:time)% (a:max + 1)
endfunction"}}}
function! neocomplcache#system(str, ...)"{{{
  let l:command = a:str
  let l:input = a:0 >= 1 ? a:1 : ''
  if has('iconv') && &termencoding != '' && &termencoding != &encoding
    let l:command = iconv(l:command, &encoding, &termencoding)
    let l:input = iconv(l:input, &encoding, &termencoding)
  endif

  if !neocomplcache#has_vimproc()
    if a:0 == 0
      let l:output = system(l:command)
    else
      let l:output = system(l:command, l:input)
    endif
  elseif a:0 == 0
    let l:output = vimproc#system(l:command)
  elseif a:0 == 1
    let l:output = vimproc#system(l:command, l:input)
  else
    let l:output = vimproc#system(l:command, l:input, a:2)
  endif

  if has('iconv') && &termencoding != '' && &termencoding != &encoding
    let l:output = iconv(l:output, &termencoding, &encoding)
  endif

  return l:output
endfunction"}}}
function! neocomplcache#has_vimproc()"{{{
  return s:exists_vimproc
endfunction"}}}

function! neocomplcache#get_cur_text(...)"{{{
  " Return cached text.
  return (a:0 == 0 && mode() ==# 'i' && exists('s:cur_text')) ? s:cur_text : s:get_cur_text()
endfunction"}}}
function! neocomplcache#get_next_keyword()"{{{
  " Get next keyword.
  let l:pattern = '^\%(' . neocomplcache#get_next_keyword_pattern() . '\m\)'

  return matchstr('a'.getline('.')[len(neocomplcache#get_cur_text()) :], l:pattern)[1:]
endfunction"}}}
function! neocomplcache#get_completion_length(plugin_name)"{{{
  if neocomplcache#is_auto_complete() && has_key(s:auto_completion_length, bufnr('%'))
    return s:auto_completion_length[bufnr('%')]
  elseif has_key(g:neocomplcache_plugin_completion_length, a:plugin_name)
    return g:neocomplcache_plugin_completion_length[a:plugin_name]
  elseif has_key(s:ftplugin_sources, a:plugin_name) || has_key(s:complfunc_sources, a:plugin_name)
    return 0
  elseif neocomplcache#is_auto_complete()
    return g:neocomplcache_auto_completion_start_length
  else
    return g:neocomplcache_manual_completion_start_length
  endif
endfunction"}}}
function! neocomplcache#set_completion_length(plugin_name, length)"{{{
  if !has_key(g:neocomplcache_plugin_completion_length, a:plugin_name)
    let g:neocomplcache_plugin_completion_length[a:plugin_name] = a:length
  endif
endfunction"}}}
function! neocomplcache#get_auto_completion_length(plugin_name)"{{{
  if has_key(g:neocomplcache_plugin_completion_length, a:plugin_name)
    return g:neocomplcache_plugin_completion_length[a:plugin_name]
  else
    return g:neocomplcache_auto_completion_start_length
  endif
endfunction"}}}
function! neocomplcache#get_keyword_pattern(...)"{{{
  let l:filetype = a:0 != 0? a:000[0] : neocomplcache#get_context_filetype()

  return s:unite_patterns(g:neocomplcache_keyword_patterns, l:filetype)
endfunction"}}}
function! neocomplcache#get_next_keyword_pattern(...)"{{{
  let l:filetype = a:0 != 0? a:000[0] : neocomplcache#get_context_filetype()
  let l:next_pattern = s:unite_patterns(g:neocomplcache_next_keyword_patterns, l:filetype)

  return (l:next_pattern == '' ? '' : l:next_pattern.'\m\|')
        \ . neocomplcache#get_keyword_pattern(l:filetype)
endfunction"}}}
function! neocomplcache#get_keyword_pattern_end(...)"{{{
  let l:filetype = a:0 != 0? a:000[0] : neocomplcache#get_context_filetype()

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
function! neocomplcache#match_word(cur_text, ...)"{{{
  let l:pattern = a:0 >= 1 ? a:1 : neocomplcache#get_keyword_pattern_end()

  " Check wildcard.
  let l:cur_keyword_pos = s:match_wildcard(a:cur_text, l:pattern, match(a:cur_text, l:pattern))

  let l:cur_keyword_str = a:cur_text[l:cur_keyword_pos :]

  return [l:cur_keyword_pos, l:cur_keyword_str]
endfunction"}}}
function! neocomplcache#is_enabled()"{{{
  return s:is_enabled
endfunction"}}}
function! neocomplcache#is_locked(...)"{{{
  let l:bufnr = a:0 > 0 ? a:1 : bufnr('%')
  return !s:is_enabled
        \ || (has_key(s:complete_lock, l:bufnr) && s:complete_lock[l:bufnr])
        \ || (g:neocomplcache_lock_buffer_name_pattern != '' && bufname(l:bufnr) =~ g:neocomplcache_lock_buffer_name_pattern)
endfunction"}}}
function! neocomplcache#is_plugin_locked(plugin_name)"{{{
  if !s:is_enabled
    return 1
  endif

  let l:bufnr = bufnr('%')
  return has_key(s:plugins_lock, l:bufnr)
        \ && has_key(s:plugins_lock[l:bufnr], a:plugin_name)
        \ && s:plugins_lock[l:bufnr][a:plugin_name]
endfunction"}}}
function! neocomplcache#is_auto_select()"{{{
  return g:neocomplcache_enable_auto_select && !neocomplcache#is_eskk_enabled()
        \ && (g:neocomplcache_disable_auto_select_buffer_name_pattern == ''
        \     || bufname('%') !~ g:neocomplcache_disable_auto_select_buffer_name_pattern)
endfunction"}}}
function! neocomplcache#is_auto_complete()"{{{
  return &l:completefunc == 'neocomplcache#auto_complete'
endfunction"}}}
function! neocomplcache#is_eskk_enabled()"{{{
  return exists('*eskk#is_enabled') && eskk#is_enabled()
endfunction"}}}
function! neocomplcache#is_text_mode()"{{{
  return s:is_text_mode || s:within_comment
endfunction"}}}
function! neocomplcache#is_win()"{{{
  return has('win32') || has('win64')
endfunction"}}}
function! neocomplcache#is_buffer_complete_enabled()"{{{
  return    !(has_key(g:neocomplcache_plugin_disable, 'buffer_complete')
        \     && g:neocomplcache_plugin_disable['buffer_complete'])
        \ && neocomplcache#is_keyword_complete_enabled()
endfunction"}}}
function! neocomplcache#is_keyword_complete_enabled()"{{{
  return !(has_key(g:neocomplcache_plugin_disable, 'keyword_complete')
        \     && g:neocomplcache_plugin_disable['keyword_complete'])
endfunction"}}}
function! neocomplcache#exists_echodoc()"{{{
  return exists('g:loaded_echodoc') && g:loaded_echodoc
endfunction"}}}
function! neocomplcache#within_comment()"{{{
  return s:within_comment
endfunction"}}}
function! neocomplcache#print_caching(string)"{{{
  if g:neocomplcache_enable_caching_message
    redraw
    echon a:string
  endif
endfunction"}}}
function! neocomplcache#print_error(string)"{{{
  echohl Error | echomsg a:string | echohl None
endfunction"}}}
function! neocomplcache#print_warning(string)"{{{
  echohl WarningMsg | echomsg a:string | echohl None
endfunction"}}}
function! neocomplcache#trunk_string(string, max)"{{{
  return printf('%.' . a:max-10 . 's..%%s', a:string, a:string[-8:])
endfunction"}}}
function! neocomplcache#head_match(checkstr, headstr)"{{{
  return stridx(a:checkstr, a:headstr) == 0
endfunction"}}}
function! neocomplcache#get_source_filetypes(filetype)"{{{
  let l:filetype = (a:filetype == '') ? 'nothing' : a:filetype

  let l:filetype_dict = {}

  let l:filetypes = [l:filetype]
  if l:filetype =~ '\.'
    " Set compound filetype.
    let l:filetypes += split(l:filetype, '\.')
  endif

  for l:ft in l:filetypes
    let l:filetype_dict[l:ft] = 1

    " Set same filetype.
    if has_key(g:neocomplcache_same_filetype_lists, l:ft)
      for l:same_ft in split(g:neocomplcache_same_filetype_lists[l:ft], ',')
        let l:filetype_dict[l:same_ft] = 1
      endfor
    endif
  endfor

  return keys(l:filetype_dict)
endfunction"}}}
function! neocomplcache#get_sources_list(dictionary, filetype)"{{{
  let l:list = []
  for l:filetype in neocomplcache#get_source_filetypes(a:filetype)
    if has_key(a:dictionary, l:filetype)
      call add(l:list, a:dictionary[l:filetype])
    endif
  endfor

  return l:list
endfunction"}}}
function! neocomplcache#escape_match(str)"{{{
  return escape(a:str, '~"*\.^$[]')
endfunction"}}}
function! neocomplcache#get_context_filetype(...)"{{{
  if a:0 != 0 || s:context_filetype == ''
    call s:set_context_filetype()
  endif

  return s:context_filetype
endfunction"}}}
function! neocomplcache#get_plugin_rank(plugin_name)"{{{
  if has_key(g:neocomplcache_plugin_rank, a:plugin_name)
    return g:neocomplcache_plugin_rank[a:plugin_name]
  elseif has_key(s:complfunc_sources, a:plugin_name)
    return 10
  elseif has_key(s:ftplugin_sources, a:plugin_name)
    return 100
  elseif has_key(s:plugin_sources, a:plugin_name)
    return neocomplcache#get_plugin_rank('keyword_complete')
  else
    " unknown.
    return 1
  endif
endfunction"}}}
function! neocomplcache#get_syn_name(is_trans)"{{{
  return len(getline('.')) < 200 ?
        \ synIDattr(synIDtrans(synID(line('.'), mode() ==# 'i' ?
        \          col('.')-1 : col('.'), a:is_trans)), 'name') : ''
endfunction"}}}

" For unite source.
function! neocomplcache#get_complete_results_pos(cur_text, ...)"{{{
  " Set context filetype.
  call s:set_context_filetype()

  let l:sources = copy(get(a:000, 0, extend(copy(neocomplcache#available_complfuncs()),
        \ neocomplcache#available_loaded_ftplugins())))
  if neocomplcache#is_eskk_enabled() && eskk#get_mode() !=# 'ascii'
    " omni_complete only.
    let l:sources = filter(l:sources, 'v:key ==# "omni_complete"')
  endif
  call filter(l:sources,
        \ '!(has_key(g:neocomplcache_plugin_disable, v:key)
        \     && g:neocomplcache_plugin_disable[v:key])
        \  && !neocomplcache#is_plugin_locked(v:key)')

  " Try source completion."{{{
  let l:complete_results = {}
  for [l:source_name, l:source] in items(l:sources)
    try
      let l:cur_keyword_pos = l:source.get_keyword_pos(a:cur_text)
    catch
      call neocomplcache#print_error(v:throwpoint)
      call neocomplcache#print_error(v:exception)
      call neocomplcache#print_error('Error occured in complfunc''s get_keyword_pos()!')
      call neocomplcache#print_error('Plugin name is ' . l:source_name)
      return
    endtry

    if l:cur_keyword_pos < 0
      continue
    endif

    let l:cur_keyword_str = a:cur_text[l:cur_keyword_pos :]
    if neocomplcache#util#mb_strlen(l:cur_keyword_str)
          \ < neocomplcache#get_completion_length(l:source_name)
      " Skip.
      continue
    endif

    let l:complete_results[l:source_name] = {
          \ 'complete_words' : [],
          \ 'cur_keyword_pos' : l:cur_keyword_pos,
          \ 'cur_keyword_str' : l:cur_keyword_str,
          \ 'source' : l:source,
          \}
  endfor
  "}}}

  return l:complete_results
endfunction"}}}
function! neocomplcache#get_cur_keyword_pos(complete_results)"{{{
  if empty(a:complete_results)
    if neocomplcache#get_cur_text() =~ '\s\+$'
          \ && neocomplcache#is_buffer_complete_enabled()
      " Caching current cache line.
      call neocomplcache#sources#buffer_complete#caching_current_cache_line()
    endif

    return -1
  endif

  let l:cur_keyword_pos = col('.')
  for l:result in values(a:complete_results)
    if l:cur_keyword_pos > l:result.cur_keyword_pos
      let l:cur_keyword_pos = l:result.cur_keyword_pos
    endif
  endfor

  return l:cur_keyword_pos
endfunction"}}}
function! neocomplcache#get_complete_words(complete_results, is_sort,
      \ cur_keyword_pos, cur_keyword_str) "{{{
  call s:set_complete_results_words(a:complete_results)

  let l:frequencies = neocomplcache#is_buffer_complete_enabled() ?
        \ neocomplcache#sources#buffer_complete#get_frequencies() : {}

  " Append prefix.
  let l:complete_words = []
  for [l:source_name, l:result] in items(a:complete_results)
    let l:result.complete_words = deepcopy(l:result.complete_words)
    if l:result.cur_keyword_pos > a:cur_keyword_pos
      let l:prefix = a:cur_keyword_str[: l:result.cur_keyword_pos
            \                            - a:cur_keyword_pos - 1]

      for keyword in l:result.complete_words
        let keyword.word = l:prefix . keyword.word
      endfor
    endif

    let l:base_rank = neocomplcache#get_plugin_rank(l:source_name)

    for l:keyword in l:result.complete_words
      let l:word = l:keyword.word
      if !has_key(l:keyword, 'rank')
        let l:keyword.rank = l:base_rank
      endif
      if has_key(l:frequencies, l:word)
        let l:keyword.rank = l:keyword.rank * l:frequencies[l:word]
      endif
    endfor

    let l:complete_words += s:remove_next_keyword(
          \ l:source_name, l:result.complete_words)
  endfor

  " Sort.
  if !neocomplcache#is_eskk_enabled() && a:is_sort
    call sort(l:complete_words, 'neocomplcache#compare_rank')
  endif

  " Check dup and set icase.
  let l:dup_check = {}
  let l:words = []
  let l:icase = g:neocomplcache_enable_ignore_case &&
        \!(g:neocomplcache_enable_smart_case && a:cur_keyword_str =~ '\u')
  for keyword in l:complete_words
    if has_key(l:keyword, 'kind') && l:keyword.kind == ''
      " Remove kind key.
      call remove(l:keyword, 'kind')
    endif

    if keyword.word != ''
          \&& (!has_key(l:dup_check, keyword.word)
          \    || (has_key(keyword, 'dup') && keyword.dup))
      let l:dup_check[keyword.word] = 1

      let l:keyword.icase = l:icase
      if !has_key(l:keyword, 'abbr')
        let l:keyword.abbr = l:keyword.word
      endif

      call add(l:words, keyword)
    endif
  endfor
  let l:complete_words = l:words

  if g:neocomplcache_max_list >= 0
    let l:complete_words = l:complete_words[: g:neocomplcache_max_list]
  endif

  " Delimiter check.
  let l:filetype = neocomplcache#get_context_filetype()
  if has_key(g:neocomplcache_delimiter_patterns, l:filetype)"{{{
    for l:delimiter in g:neocomplcache_delimiter_patterns[l:filetype]
      " Count match.
      let l:delim_cnt = 0
      let l:matchend = matchend(a:cur_keyword_str, l:delimiter)
      while l:matchend >= 0
        let l:matchend = matchend(a:cur_keyword_str, l:delimiter, l:matchend)
        let l:delim_cnt += 1
      endwhile

      for l:keyword in l:complete_words
        let l:split_list = split(l:keyword.word, l:delimiter)
        if len(l:split_list) > 1
          let l:delimiter_sub = substitute(l:delimiter, '\\\([.^$]\)', '\1', 'g')
          let l:keyword.word = join(l:split_list[ : l:delim_cnt], l:delimiter_sub)
          let l:keyword.abbr = join(
                \ split(l:keyword.abbr, l:delimiter)[ : l:delim_cnt],
                \ l:delimiter_sub)

          if g:neocomplcache_max_keyword_width >= 0
                \ && len(l:keyword.abbr) > g:neocomplcache_max_keyword_width
            let l:keyword.abbr = substitute(l:keyword.abbr,
                  \ '\(\h\)\w*'.l:delimiter, '\1'.l:delimiter_sub, 'g')
          endif
          if l:delim_cnt+1 < len(l:split_list)
            let l:keyword.abbr .= l:delimiter_sub . '~'
            let l:keyword.dup = 0

            if g:neocomplcache_enable_auto_delimiter
              let l:keyword.word .= l:delimiter_sub
            endif
          endif
        endif
      endfor
    endfor
  endif"}}}

  " Convert words.
  if neocomplcache#is_text_mode() "{{{
    if a:cur_keyword_str =~ '^\l\+$'
      for l:keyword in l:complete_words
        let l:keyword.word = tolower(l:keyword.word)
        let l:keyword.abbr = tolower(l:keyword.abbr)
      endfor
    elseif a:cur_keyword_str =~ '^\u\+$'
      for l:keyword in l:complete_words
        let l:keyword.word = toupper(l:keyword.word)
        let l:keyword.abbr = toupper(l:keyword.abbr)
      endfor
    elseif a:cur_keyword_str =~ '^\u\l\+$'
      for l:keyword in l:complete_words
        let l:keyword.word = toupper(l:keyword.word[0]).tolower(l:keyword.word[1:])
        let l:keyword.abbr = toupper(l:keyword.abbr[0]).tolower(l:keyword.abbr[1:])
      endfor
    endif
  endif"}}}

  if g:neocomplcache_max_keyword_width >= 0 "{{{
    " Abbr check.
    let l:abbr_pattern = printf('%%.%ds..%%s',
          \ g:neocomplcache_max_keyword_width-15)
    for l:keyword in l:complete_words
      if len(l:keyword.abbr) > g:neocomplcache_max_keyword_width
        if l:keyword.abbr =~ '[^[:print:]]'
          " Multibyte string.
          let l:len = neocomplcache#util#wcswidth(l:keyword.abbr)

          if l:len > g:neocomplcache_max_keyword_width
            let l:keyword.abbr = neocomplcache#util#truncate(
                  \ l:keyword.abbr, g:neocomplcache_max_keyword_width - 2) . '..'
          endif
        else
          let l:keyword.abbr = printf(l:abbr_pattern,
                \ l:keyword.abbr, l:keyword.abbr[-13:])
        endif
      endif
    endfor
  endif"}}}

  return l:complete_words
endfunction"}}}
function! s:set_complete_results_words(complete_results)"{{{
  " Try source completion.
  for [l:source_name, result] in items(a:complete_results)
    if complete_check()
      return
    endif

    " Save options.
    let l:ignorecase_save = &ignorecase

    if neocomplcache#is_text_mode()
      let &ignorecase = 1
    elseif g:neocomplcache_enable_smart_case && result.cur_keyword_str =~ '\u'
      let &ignorecase = 0
    else
      let &ignorecase = g:neocomplcache_enable_ignore_case
    endif

    try
      let l:words = result.source.get_complete_words(
            \ result.cur_keyword_pos, result.cur_keyword_str)
    catch
      call neocomplcache#print_error(v:throwpoint)
      call neocomplcache#print_error(v:exception)
      call neocomplcache#print_error('Error occured in complfunc''s get_complete_words()!')
      call neocomplcache#print_error('Plugin name is ' . l:source_name)
      return
    endtry

    let &ignorecase = l:ignorecase_save

    let result.complete_words = l:words
  endfor
endfunction"}}}

" Set pattern helper.
function! neocomplcache#set_dictionary_helper(variable, keys, pattern)"{{{
  for key in split(a:keys, ',')
    if !has_key(a:variable, key)
      let a:variable[key] = a:pattern
    endif
  endfor
endfunction"}}}

" Complete filetype helper.
function! neocomplcache#filetype_complete(arglead, cmdline, cursorpos)"{{{
  " Dup check.
  let l:ret = {}
  for l:item in map(split(globpath(&runtimepath, 'syntax/*.vim'), '\n'), 'fnamemodify(v:val, ":t:r")')
    if !has_key(l:ret, l:item) && l:item =~ '^'.a:arglead
      let l:ret[l:item] = 1
    endif
  endfor

  return sort(keys(l:ret))
endfunction"}}}
"}}}

" Command functions."{{{
function! neocomplcache#toggle_lock()"{{{
  if !neocomplcache#is_enabled()
    call neocomplcache#print_warning('neocomplcache is disabled! This command is ignored.')
    return
  endif

  if !has_key(s:complete_lock, bufnr('%')) || !s:complete_lock[bufnr('%')]
    call neocomplcache#lock()
  else
    call neocomplcache#unlock()
  endif
endfunction"}}}
function! neocomplcache#lock(...)"{{{
  if !neocomplcache#is_enabled()
    call neocomplcache#print_warning('neocomplcache is disabled! This command is ignored.')
    return
  endif

  let s:complete_lock[bufnr('%')] = 1
endfunction"}}}
function! neocomplcache#unlock(...)"{{{
  if !neocomplcache#is_enabled()
    call neocomplcache#print_warning('neocomplcache is disabled! This command is ignored.')
    return
  endif

  let s:complete_lock[bufnr('%')] = 0
endfunction"}}}
function! neocomplcache#lock_plugin(plugin_name)"{{{
  if !neocomplcache#is_enabled()
    call neocomplcache#print_warning('neocomplcache is disabled! This command is ignored.')
    return
  endif

  if !has_key(s:plugins_lock, bufnr('%'))
    let s:plugins_lock[bufnr('%')] = {}
  endif

  let s:plugins_lock[bufnr('%')][a:plugin_name] = 1
endfunction"}}}
function! neocomplcache#unlock_plugin(plugin_name)"{{{
  if !neocomplcache#is_enabled()
    call neocomplcache#print_warning('neocomplcache is disabled! This command is ignored.')
    return
  endif

  if !has_key(s:plugins_lock, bufnr('%'))
    let s:plugins_lock[bufnr('%')] = {}
  endif

  let s:plugins_lock[bufnr('%')][a:plugin_name] = 0
endfunction"}}}
function! s:display_neco(number)"{{{
  let l:cmdheight_save = &cmdheight

  let l:animation = [
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

  let l:number = (a:number != '') ? a:number : len(l:animation)
  let l:anim = get(l:animation, l:number, l:animation[neocomplcache#rand(len(l:animation) - 1)])
  let &cmdheight = len(l:anim[0])

  for l:frame in l:anim
    echo repeat("\n", &cmdheight-2)
    redraw
    echon join(l:frame, "\n")
    sleep 300m
  endfor
  redraw

  let &cmdheight = l:cmdheight_save
endfunction"}}}
function! s:set_auto_completion_length(len)"{{{
  let s:auto_completion_length[bufnr('%')] = a:len
endfunction"}}}
"}}}

" Key mapping functions."{{{
function! neocomplcache#smart_close_popup()"{{{
  return g:neocomplcache_enable_auto_select ? neocomplcache#cancel_popup() : neocomplcache#close_popup()
endfunction
"}}}
function! neocomplcache#close_popup()"{{{
  let s:skip_next_complete = 1
  let s:cur_keyword_str = ''
  let s:complete_words = []

  return pumvisible() ? "\<C-y>" : ''
endfunction
"}}}
function! neocomplcache#cancel_popup()"{{{
  let s:skip_next_complete = 1
  let s:cur_keyword_str = ''
  let s:complete_words = []

  return pumvisible() ? "\<C-e>" : ''
endfunction
"}}}

function! neocomplcache#undo_completion()"{{{
  if !exists(':NeoComplCacheDisable')
    return ''
  endif

  " Get cursor word.
  let [l:cur_keyword_pos, l:cur_keyword_str] = neocomplcache#match_word(s:get_cur_text())
  let l:old_keyword_str = s:cur_keyword_str
  let s:cur_keyword_str = l:cur_keyword_str

  return (pumvisible() ? "\<C-e>" : '')
        \ . repeat("\<BS>", len(l:cur_keyword_str)) . l:old_keyword_str
endfunction"}}}

function! neocomplcache#complete_common_string()"{{{
  if !exists(':NeoComplCacheDisable')
    return ''
  endif

  " Save options.
  let l:ignorecase_save = &ignorecase

  " Get cursor word.
  let [l:cur_keyword_pos, l:cur_keyword_str] = neocomplcache#match_word(s:get_cur_text())

  if neocomplcache#is_text_mode()
    let &ignorecase = 1
  elseif g:neocomplcache_enable_smart_case && l:cur_keyword_str =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase = g:neocomplcache_enable_ignore_case
  endif

  let l:complete_words = neocomplcache#keyword_filter(
        \ copy(s:complete_words), l:cur_keyword_str)

  if empty(l:complete_words)
    let &ignorecase = l:ignorecase_save

    return ''
  endif

  let l:common_str = l:complete_words[0].word
  for keyword in l:complete_words[1:]
    while !neocomplcache#head_match(keyword.word, l:common_str)
      let l:common_str = l:common_str[: -2]
    endwhile
  endfor
  if &ignorecase
    let l:common_str = tolower(l:common_str)
  endif

  let &ignorecase = l:ignorecase_save

  return (pumvisible() ? "\<C-e>" : '')
        \ . repeat("\<BS>", len(l:cur_keyword_str)) . l:common_str
endfunction"}}}
"}}}

" Event functions."{{{
function! s:on_hold_i()"{{{
  if g:neocomplcache_enable_cursor_hold_i
    call neocomplcache#do_auto_complete()
  endif
endfunction"}}}
function! s:on_moved_i()"{{{
  if !g:neocomplcache_enable_cursor_hold_i
    call neocomplcache#do_auto_complete()
  endif
endfunction"}}}
function! s:on_insert_enter()"{{{
  if &updatetime > g:neocomplcache_cursor_hold_i_time
    let s:update_time_save = &updatetime
    let &updatetime = g:neocomplcache_cursor_hold_i_time
  endif
endfunction"}}}
function! s:on_insert_leave()"{{{
  let s:cur_keyword_str = ''
  let s:complete_words = []
  let s:context_filetype = ''
  let s:is_text_mode = 0
  let s:skip_next_complete = 0

  if &updatetime < s:update_time_save
    let &updatetime = s:update_time_save
  endif
endfunction"}}}
function! s:remove_next_keyword(plugin_name, list)"{{{
  let l:list = a:list
  " Remove next keyword."{{{
  if a:plugin_name  == 'filename_complete'
    let l:pattern = '^\%(' . neocomplcache#get_next_keyword_pattern('filename') . '\m\)'
  else
    let l:pattern = '^\%(' . neocomplcache#get_next_keyword_pattern() . '\m\)'
  endif

  let l:next_keyword_str = matchstr('a'.getline('.')[len(neocomplcache#get_cur_text()) :], l:pattern)[1:]
  if l:next_keyword_str != ''
    let l:next_keyword_str = substitute(escape(l:next_keyword_str, '~" \.^$*[]'), "'", "''", 'g').'$'

    " No ignorecase.
    let l:ignorecase_save = &ignorecase
    let &ignorecase = 0

    for r in l:list
      if r.word =~ l:next_keyword_str
        let r.word = r.word[: match(r.word, l:next_keyword_str)-1]
      endif
    endfor

    let &ignorecase = l:ignorecase_save
  endif"}}}

  return l:list
endfunction"}}}
function! neocomplcache#popup_post()"{{{
  return pumvisible() ? "\<Down>" : ""
endfunction"}}}
"}}}

" Internal helper functions."{{{
function! s:get_cur_text()"{{{
  "let s:cur_text = col('.') < l:pos ? '' : matchstr(getline('.'), '.*')[: col('.') - l:pos]
  let s:cur_text = matchstr(getline('.'), '^.*\%' . col('.') . 'c' . (mode() ==# 'i' ? '' : '.'))

  " Save cur_text.
  return s:cur_text
endfunction"}}}
function! s:set_context_filetype()"{{{
  let l:old_filetype = &filetype
  if l:old_filetype == ''
    let l:old_filetype = 'nothing'
  endif

  let l:dup_check = {}
  while 1
    let l:new_filetype = s:get_context_filetype(l:old_filetype)

    " Check filetype root.
    if has_key(l:dup_check, l:old_filetype) && l:dup_check[l:old_filetype] ==# l:new_filetype
      let s:context_filetype = l:old_filetype
      break
    endif

    " Save old -> new filetype graph.
    let l:dup_check[l:old_filetype] = l:new_filetype
    let l:old_filetype = l:new_filetype
  endwhile

  " Set text mode or not.
  let l:syn_name = neocomplcache#get_syn_name(1)
  let s:is_text_mode = (has_key(g:neocomplcache_text_mode_filetypes, s:context_filetype) && g:neocomplcache_text_mode_filetypes[s:context_filetype])
        \ || l:syn_name ==# 'Constant'
  let s:within_comment = (l:syn_name ==# 'Comment')

  " Set filetype plugins.
  let s:loaded_ftplugin_sources = {}
  for [l:source_name, l:source] in items(neocomplcache#available_ftplugins())
    if has_key(l:source.filetypes, s:context_filetype)
      let s:loaded_ftplugin_sources[l:source_name] = l:source

      if !l:source.loaded
        " Initialize.
        call l:source.initialize()

        let l:source.loaded = 1
      endif
    endif
  endfor

  return s:context_filetype
endfunction"}}}
function! s:get_context_filetype(filetype)"{{{
  let l:filetype = a:filetype
  if l:filetype == ''
    let l:filetype = 'nothing'
  endif

  " Default.
  let l:context_filetype = l:filetype
  if neocomplcache#is_eskk_enabled()
    let l:context_filetype = 'eskk'
    let l:filetype = 'eskk'
  elseif has_key(g:neocomplcache_filetype_include_lists, l:filetype)
        \ && !empty(g:neocomplcache_filetype_include_lists[l:filetype])

    let l:pos = [line('.'), col('.')]
    for l:include in g:neocomplcache_filetype_include_lists[l:filetype]
      let l:start_backward = searchpos(l:include.start, 'bnW')

      " Check start <= line <= end.
      if l:start_backward[0] == 0 || s:compare_pos(l:start_backward, l:pos) > 0
        continue
      endif

      let l:end_pattern = l:include.end
      if l:end_pattern =~ '\\1'
        let l:match_list = matchlist(getline(l:start_backward[0]), l:include.start)
        let l:end_pattern = substitute(l:end_pattern, '\\1', '\=l:match_list[1]', 'g')
      endif
      let l:end_forward = searchpos(l:end_pattern, 'nW')

      if l:end_forward[0] == 0 || s:compare_pos(l:pos, l:end_forward) < 0
        let l:end_backward = searchpos(l:end_pattern, 'bnW')

        if l:end_backward[0] == 0 || s:compare_pos(l:start_backward, l:end_backward) > 0
          let l:context_filetype = l:include.filetype
          let l:filetype = l:include.filetype
          break
        endif
      endif
    endfor
  endif

  return l:context_filetype
endfunction"}}}
function! s:match_wildcard(cur_text, pattern, cur_keyword_pos)"{{{
  let l:cur_keyword_pos = a:cur_keyword_pos
  if neocomplcache#is_eskk_enabled() || !g:neocomplcache_enable_wildcard
    return l:cur_keyword_pos
  endif

  while l:cur_keyword_pos > 1 && a:cur_text[l:cur_keyword_pos - 1] == '*'
    let l:left_text = a:cur_text[: l:cur_keyword_pos - 2]
    if l:left_text == '' || l:left_text !~ a:pattern
      break
    endif

    let l:cur_keyword_pos = match(l:left_text, a:pattern)
  endwhile

  return l:cur_keyword_pos
endfunction"}}}
function! s:unite_patterns(pattern_var, filetype)"{{{
  let l:keyword_patterns = []
  let l:dup_check = {}

  " Compound filetype.
  for l:ft in split(a:filetype, '\.')
    if has_key(a:pattern_var, l:ft) && !has_key(l:dup_check, l:ft)
      let l:dup_check[l:ft] = 1
      call add(l:keyword_patterns, a:pattern_var[l:ft])
    endif

    " Same filetype.
    if has_key(g:neocomplcache_same_filetype_lists, l:ft)
      for l:ft in split(g:neocomplcache_same_filetype_lists[l:ft], ',')
        if has_key(a:pattern_var, l:ft) && !has_key(l:dup_check, l:ft)
          let l:dup_check[l:ft] = 1
          call add(l:keyword_patterns, a:pattern_var[l:ft])
        endif
      endfor
    endif
  endfor

  if empty(l:keyword_patterns) && has_key(a:pattern_var, 'default')
    call add(l:keyword_patterns, g:neocomplcache_keyword_patterns['default'])
  endif

  return join(l:keyword_patterns, '\m\|')
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
