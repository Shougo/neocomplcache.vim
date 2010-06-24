"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Jun 2010
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
" Version: 5.0, for Vim 7.0
"=============================================================================

" Check vimproc.
let s:exists_vimproc = exists('*vimproc#system')

function! neocomplcache#enable() "{{{
  augroup neocomplcache "{{{
    autocmd!
    " Auto complete events
    autocmd CursorMovedI * call s:on_moved_i()
    autocmd CursorHoldI * call s:on_hold_i()
    autocmd InsertEnter * call s:on_insert_enter()
    autocmd InsertLeave * call s:on_insert_leave()
    autocmd GUIEnter * set vb t_vb=
  augroup END "}}}

  " Initialize"{{{
  let s:complete_lock = {}
  let s:complfuncs_func_table = []
  let s:global_complfuncs = {}
  let s:cur_keyword_pos = -1
  let s:cur_keyword_str = ''
  let s:complete_words = []
  let s:old_cur_keyword_pos = -1
  let s:quickmatch_keywordpos = -1
  let s:old_complete_words = []
  let s:update_time_save = &updatetime
  let s:prev_numbered_list = []
  let s:cur_text = ''
  let s:old_cur_text = ''
  let s:moved_cur_text = ''
  let s:changedtick = b:changedtick
  let s:used_match_filter = 0
  let s:context_filetype = ''
  let s:skip_next_complete = 0
  "}}}

  " Initialize complfuncs table."{{{
  " Search autoload.
  let l:func_list = split(globpath(&runtimepath, 'autoload/neocomplcache/complfunc/*.vim'), '\n')
  for list in l:func_list
    let l:func_name = fnamemodify(list, ':t:r')
    if !has_key(g:neocomplcache_plugin_disable, l:func_name) || 
          \ g:neocomplcache_plugin_disable[l:func_name] == 0
      let s:global_complfuncs[l:func_name] = 'neocomplcache#complfunc#' . l:func_name . '#'
    endif
  endfor
  "}}}

  " Initialize keyword patterns."{{{
  if !exists('g:neocomplcache_keyword_patterns')
    let g:neocomplcache_keyword_patterns = {}
  endif
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'default',
        \'\k\+')
  if has('win32') || has('win64')
    call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'filename',
          \'\%(\\[^[:alnum:].-]\|[[:alnum:]:@/._+#$%~-]\)\+')
  else
    call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'filename',
          \'\%(\\[^[:alnum:].-]\|[[:alnum:]@/._+#$%~-]\)\+')
  endif
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'lisp,scheme,clojure,int-gosh,int-clisp,int-clj', 
        \'[[:alnum:]+*@$%^&_=<>~.-]\+[!?]\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'ruby,int-irb',
        \'\<\%(\u\w*::\)*\u\w*\%(\.\w*\%(()\?\)\?\)*\|^=\%(b\%[egin]\|e\%[nd]\)\|\%(@@\|[:$@]\)\h\w*\|\%(\h\w*::\)*\h\w*[!?]\?\%(\s\?()\?\|\s\?\%(do\|{\)\s\?\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'php',
        \'</\?\%(\h[[:alnum:]_-]*\s*\)\?\%(/\?>\)\?\|\$\h\w*\|\%(\h\w*::\)*\h\w*\%(\s\?()\?\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'perl,int-perlsh',
        \'<\h\w*>\?\|[$@%&*]\h\w*\|\h\w*\%(::\h\w*\)*\%(\s\?()\?\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'perl6,int-perl6',
        \'<\h\w*>\?\|[$@%&][!.*?]\?\h\w*\|\h\w*\%(::\h\w*\)*\%(\s\?()\?\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'pir',
        \'[$@%.=]\?\h\w*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'pasm',
        \'[=]\?\h\w*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'vim,help',
        \'\[:\%(\h\w*:\]\)\?\|&\h[[:alnum:]_:]*\|\$\h\w*\|-\h\w*=\?\|<\h[[:alnum:]_-]*>\?\|\.\h\w*\%(()\?\)\?\|\h[[:alnum:]_:#]*\%(!\|()\?\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'tex',
        \'\\\a{\a\{1,2}}\|\\[[:alpha:]@][[:alnum:]@]*\%({\%([[:alnum:]:]\+\*\?}\?\)\?\)\?\|\a[[:alnum:]:]*\*\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'sh,zsh,int-zsh,int-bash,int-sh',
        \'\$\w\+\|[[:alpha:]_.-][[:alnum:]_.-]*\%(\s\?\[|\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'vimshell',
        \'\$\$\?\w*\|[[:alpha:]_.-][[:alnum:]_.-]*\|\d\+\%(\.\d\+\)\+')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'ps1,int-powershell',
        \'\[\h\%([[:alnum:]_.]*\]::\)\?\|[$%@.]\?[[:alpha:]_.:-][[:alnum:]_.:-]*\%(\s\?()\?\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'c',
        \'^\s*#\s*\h\w*\|\h\w*\%(\s\?()\?\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'cpp',
        \'^\s*#\s*\h\w*\|\%(\h\w*::\)*\h\w*\%(\s\?()\?\|<>\?\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'objc',
        \'^\s*#\s*\h\w*\|\h\w*\%(\s\?()\?\|<>\?\|:\)\?\|@\h\w*\%(\s\?()\?\)\?\|(\h\w*\s*\*\?)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'objcpp',
        \'^\s*#\s*\h\w*\|\%(\h\w*::\)*\h\w*\%(\s\?()\?\|<>\?\|:\)\?\|@\h\w*\%(\s\?()\?\)\?\|(\s*\h\w*\s*\*\?\s*)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'd',
        \'\<\u\w*\%(\.\w*\%(()\?\)\?\)*\|\h\w*\%(!\?\s\?()\?\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'python,int-python,int-ipython',
        \'\h\w*\%(\s\?()\?\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'cs',
        \'\h\w*\%(\s\?()\?\|<\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'java',
        \'\<\u\w*\%(\.\w*\%(()\?\)\?\)*\|[@]\?\h\w*\%(\s\?()\?\|<\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'javascript,actionscript',
        \'\<\u\w*\%(\.\w*\%(()\?\)\?\)*\|\h\w*\%(\s\?()\?\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'awk',
        \'\h\w*\%(\s\?()\?\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'haskell,int-ghci',
        \'[[:alpha:]_''][[:alnum:]_'']*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'ml,ocaml,int-ocaml,int-sml,int-smlsharp',
        \'[''`#.]\?\h[[:alnum:]_'']*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'erlang,int-erl',
        \'^\s*-\h\w*()?\|\%(\h\w*:\)*\h\w()\?\|\h[[:alnum:]_@]*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'html,xhtml,xml,markdown,eruby',
        \'</\?\%([[:alnum:]_:-]\+\s*\)\?\%(/\?>\)\?\|&\h\%(\w*;\)\?\|\h[[:alnum:]_-]*="\%([^"]*"\?\)\?\|\h[[:alnum:]_:-]*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'css',
        \'[[:alpha:]_-][[:alnum:]_-]*[:(]\?\|[@#:.][[:alpha:]_-][[:alnum:]_-]*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'tags',
        \'^[^!][^/[:blank:]]*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'pic',
        \'^\s*#\h\w*\|\h\w*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'arm',
        \'\h\w*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'asmh8300',
        \'[[:alpha:]_.][[:alnum:]_.]*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'masm',
        \'\.\h\w*\|[[:alpha:]_@?$][[:alnum:]_@?$]*\|\h\w*:\h\w*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'nasm',
        \'^\s*\[\h\w*\|[%.]\?\h\w*\|\%(\.\.\@\?\|%[%$!]\)\%(\h\w*\)\?\|\h\w*:\h\w*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'asm',
        \'[%$.]\?\h\w*\%(\$\h\w*\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'make',
        \'[[:alpha:]_.-][[:alnum:]_.-]*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'scala',
        \'\h\w*\%(\s\?()\?\|\[\)\?')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'int-termtter',
        \'\h[[:alnum:]_-]*\|@[[:alnum:]_+-]\+\|\$\a\+\|#\h\w*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'dosbatch,int-cmdproxy',
        \'\$\w+\|[[:alpha:]_./-][[:alnum:]_.-]*')
  call neocomplcache#set_variable_pattern('g:neocomplcache_keyword_patterns', 'vb',
        \'\a[[:alnum:]]*\%(()\?\)\?\|#\a[[:alnum:]]*')
  "}}}

  " Initialize next keyword patterns."{{{
  if !exists('g:neocomplcache_next_keyword_patterns')
    let g:neocomplcache_next_keyword_patterns = {}
  endif
  call neocomplcache#set_variable_pattern('g:neocomplcache_next_keyword_patterns', 'perl',
        \'\h\w*>')
  call neocomplcache#set_variable_pattern('g:neocomplcache_next_keyword_patterns', 'perl6',
        \'\h\w*>')
  call neocomplcache#set_variable_pattern('g:neocomplcache_next_keyword_patterns', 'vim,help',
        \'\h\w*:\]\|\h\w*=\|[[:alnum:]_-]*>')
  call neocomplcache#set_variable_pattern('g:neocomplcache_next_keyword_patterns', 'tex',
        \'\h\w*\*\?[*[{}]')
  call neocomplcache#set_variable_pattern('g:neocomplcache_next_keyword_patterns', 'html,xhtml,xml,mkd',
        \'[[:alnum:]_:-]*>\|[^"]*"')
  "}}}

  " Initialize same file type lists."{{{
  if !exists('g:neocomplcache_same_filetype_lists')
    let g:neocomplcache_same_filetype_lists = {}
  endif
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'c', 'cpp')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'cpp', 'c')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'erb', 'ruby,html,xhtml')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'html,xml', 'xhtml')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'html,xhtml', 'css')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'xhtml', 'html,xml')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'help', 'vim')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'lingr-say', 'lingr-messages,lingr-members')

  " Interactive filetypes.
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-irb', 'ruby')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-ghci,int-hugs', 'haskell')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-python,int-ipython', 'python')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-gosh', 'scheme')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-clisp', 'lisp')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-erl', 'erlang')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-zsh', 'zsh')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-bash', 'bash')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-sh', 'sh')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-cmdproxy', 'dosbatch')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-powershell', 'powershell')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-perlsh', 'perl')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-perl6', 'perl6')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-ocaml', 'ocaml')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-clj', 'clojure')
  call neocomplcache#set_variable_pattern('g:neocomplcache_same_filetype_lists', 'int-sml,int-smlsharp', 'sml')
  "}}}

  " Initialize include filetype lists."{{{
  if !exists('g:neocomplcache_filetype_include_lists')
    let g:neocomplcache_filetype_include_lists = {}
  endif
  call neocomplcache#set_variable_pattern('g:neocomplcache_filetype_include_lists', 'perl6', [
        \ {'filetype' : 'pir', 'start' : 'Q:PIR\s*{', 'end' : '}'},
        \])
  call neocomplcache#set_variable_pattern('g:neocomplcache_filetype_include_lists', 'vimshell', [
        \ {'filetype' : 'vim', 'start' : 'vexe \([''"]\)', 'end' : '\\\@<!\1'},
        \])
  call neocomplcache#set_variable_pattern('g:neocomplcache_filetype_include_lists', 'eruby', [
        \ {'filetype' : 'ruby', 'start' : '<%[=#]\?', 'end' : '%>'},
        \])
  call neocomplcache#set_variable_pattern('g:neocomplcache_filetype_include_lists', 'vim', [
        \ {'filetype' : 'python', 'start' : '^\s*python <<\s*\(\h\w*\)', 'end' : '^\1'},
        \ {'filetype' : 'ruby', 'start' : '^\s*ruby <<\s*\(\h\w*\)', 'end' : '^\1'},
        \])
  "}}}
  
  " Initialize member prefix patterns."{{{
  if !exists('g:neocomplcache_member_prefix_patterns')
    let g:neocomplcache_member_prefix_patterns = {}
  endif
  call neocomplcache#set_variable_pattern('g:neocomplcache_member_prefix_patterns', 'c,cpp,objc,objcpp', '^\.\|^->')
  call neocomplcache#set_variable_pattern('g:neocomplcache_member_prefix_patterns', 'perl,php', '^->')
  call neocomplcache#set_variable_pattern('g:neocomplcache_member_prefix_patterns', 'java,javascript,d,vim,ruby', '^\.')
  "}}}

  " Initialize delimiter patterns."{{{
  if !exists('g:neocomplcache_delimiter_patterns')
    let g:neocomplcache_delimiter_patterns = {}
  endif
  call neocomplcache#set_variable_pattern('g:neocomplcache_delimiter_patterns', 'vim,help',
        \['#'])
  call neocomplcache#set_variable_pattern('g:neocomplcache_delimiter_patterns', 'erlang,lisp,int-clisp',
        \[':'])
  call neocomplcache#set_variable_pattern('g:neocomplcache_delimiter_patterns', 'perl,cpp',
        \['::'])
  call neocomplcache#set_variable_pattern('g:neocomplcache_delimiter_patterns', 'java,d,javascript,actionscript,ruby,eruby',
        \['\.'])
  "}}}
  
  " Initialize ctags arguments."{{{
  if !exists('g:neocomplcache_ctags_arguments_list')
    let g:neocomplcache_ctags_arguments_list = {}
  endif
  call neocomplcache#set_variable_pattern('g:neocomplcache_ctags_arguments_list', 'default', '')
  call neocomplcache#set_variable_pattern('g:neocomplcache_ctags_arguments_list', 'vim',
        \"--extra=fq --fields=afmiKlnsStz --regex-vim='/function!? ([a-z#:_0-9A-Z]+)/\\1/function/'")
  call neocomplcache#set_variable_pattern('g:neocomplcache_ctags_arguments_list', 'cpp',
        \'--c++-kinds=+p --fields=+iaS --extra=+q')
  "}}}

  " Initialize quick match patterns."{{{
  if !exists('g:neocomplcache_quick_match_patterns')
    let g:neocomplcache_quick_match_patterns = {}
  endif
  call neocomplcache#set_variable_pattern('g:neocomplcache_quick_match_patterns', 'default', '-')
  "}}}

  " Initialize tags filter patterns."{{{
  if !exists('g:neocomplcache_tags_filter_patterns')
    let g:neocomplcache_tags_filter_patterns = {}
  endif
  call neocomplcache#set_variable_pattern('g:neocomplcache_tags_filter_patterns', 'c,cpp', 
        \'v:val.word !~ ''^[~_]''')
  "}}}

  " Add commands."{{{
  command! -nargs=0 NeoComplCacheDisable call neocomplcache#disable()
  command! -nargs=0 Neco call s:display_neco()
  command! -nargs=0 NeoComplCacheLock call s:lock()
  command! -nargs=0 NeoComplCacheUnlock call s:unlock()
  command! -nargs=0 NeoComplCacheToggle call s:toggle()
  command! -nargs=1 NeoComplCacheAutoCompletionLength let g:neocomplcache_auto_completion_start_length = <args>
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
  set completeopt-=longest
  set completeopt+=menuone

  " Disable bell.
  set vb t_vb=
  
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
    " Clear flag.
    let s:used_match_filter = 0
    
    let [l:cur_keyword_pos, l:cur_keyword_str, l:complete_words] = s:integrate_completion(s:get_complete_result(s:get_cur_text()))
    if empty(l:complete_words)
      return -1
    endif
    let s:complete_words = l:complete_words

    return l:cur_keyword_pos
  else
    return s:complete_words
  endif
endfunction"}}}

function! neocomplcache#auto_complete(findstart, base)"{{{
  if a:findstart
    " Check text was changed.
    let l:cached_text = s:cur_text
    if s:get_cur_text() != l:cached_text
      " Text was changed.
      
      " Restore options.
      let s:cur_keyword_pos = -1
      let &l:completefunc = 'neocomplcache#manual_complete'
      let s:old_complete_words = s:complete_words
      let s:complete_words = []
      
      return -1
    endif
    
    let s:old_cur_keyword_pos = s:cur_keyword_pos
    let s:cur_keyword_pos = -1
    return s:old_cur_keyword_pos
  else
    " Restore option.
    let &l:completefunc = 'neocomplcache#manual_complete'
    let s:old_complete_words = s:complete_words
    let s:complete_words = []

    return s:old_complete_words
  endif
endfunction"}}}

" Plugin helper."{{{
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

  "echo l:keyword_escape
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
    let s:used_match_filter = 1
    " Match filter.
    return filter(a:list, printf("v:val.word =~ %s", 
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
function! neocomplcache#check_match_filter(cur_keyword_str, ...)"{{{
  return neocomplcache#keyword_escape(
        \empty(a:000)? a:cur_keyword_str : a:cur_keyword_str[ : a:1-1]) =~ '[^\\]\*\|\\+'
endfunction"}}}
function! neocomplcache#head_filter(list, cur_keyword_str)"{{{
  let l:cur_keyword = substitute(a:cur_keyword_str, '\\\zs.', '\0', 'g')

  return filter(a:list, printf("v:val.word[: %d] == %s", len(l:cur_keyword) - 1, string(l:cur_keyword)))
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
function! neocomplcache#member_filter(list, cur_keyword_str)"{{{
  let l:ft = neocomplcache#get_context_filetype()

  if has_key(g:neocomplcache_member_prefix_patterns, l:ft) && a:cur_keyword_str =~ g:neocomplcache_member_prefix_patterns[l:ft]
    let l:list = filter(a:list, '(has_key(v:val, "kind") && v:val.kind ==# "m") || (has_key(v:val, "class") && v:val.class != "")')
  else
    let l:list = a:list
  endif
  
  return neocomplcache#keyword_filter(a:list, a:cur_keyword_str)
endfunction"}}}
function! neocomplcache#dictionary_filter(dictionary, cur_keyword_str, completion_length)"{{{
  if len(a:cur_keyword_str) < a:completion_length ||
        \neocomplcache#check_match_filter(a:cur_keyword_str, a:completion_length)
    return neocomplcache#keyword_filter(neocomplcache#unpack_dictionary(a:dictionary), a:cur_keyword_str)
  else
    let l:key = tolower(a:cur_keyword_str[: a:completion_length-1])

    if !has_key(a:dictionary, l:key)
      return []
    endif

    return (len(a:cur_keyword_str) == a:completion_length && &ignorecase)?
          \ a:dictionary[l:key] : neocomplcache#keyword_filter(copy(a:dictionary[l:key]), a:cur_keyword_str)
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
function! neocomplcache#used_match_filter()"{{{
  let s:used_match_filter = 1
endfunction"}}}

" RankOrder."{{{
function! neocomplcache#compare_rank(i1, i2)
  return a:i2.rank - a:i1.rank
endfunction"}}}
" PosOrder."{{{
function! s:compare_pos(i1, i2)
  return a:i1[0] == a:i2[0] ? a:i1[1] - a:i2[1] : a:i1[0] - a:i2[0]
endfunction"}}}

function! neocomplcache#rand(max)"{{{
  let l:time = reltime()[1]
  return (l:time < 0 ? -l:time : l:time)% (a:max + 1)
endfunction"}}}
function! neocomplcache#system(str, ...)"{{{
  let l:command = a:str
  let l:input = join(a:000)
  if &termencoding != '' && &termencoding != &encoding
    let l:command = iconv(l:command, &encoding, &termencoding)
    let l:input = iconv(l:input, &encoding, &termencoding)
  endif
  let l:output = s:exists_vimproc ? (a:0 == 0 ? vimproc#system(l:command) : vimproc#system(l:command, l:input))
        \: (a:0 == 0 ? system(l:command) : system(l:command, l:input))
  if &termencoding != '' && &termencoding != &encoding
    let l:output = iconv(l:output, &termencoding, &encoding)
  endif
  return l:output
endfunction"}}}

function! neocomplcache#get_cur_text()"{{{
  " Return cached text.
  return neocomplcache#is_auto_complete()? s:cur_text : s:get_cur_text()
endfunction"}}}
function! neocomplcache#get_completion_length(plugin_name)"{{{
  if has_key(g:neocomplcache_plugin_completion_length, a:plugin_name)
    return g:neocomplcache_plugin_completion_length[a:plugin_name]
  elseif a:plugin_name == 'omni_complete' || a:plugin_name == 'vim_complete' || a:plugin_name == 'completefunc_complete'
    return 0
  elseif neocomplcache#is_auto_complete()
    return g:neocomplcache_auto_completion_start_length
  else
    return g:neocomplcache_manual_completion_start_length
  endif
endfunction"}}}
function! neocomplcache#get_auto_completion_length(plugin_name)"{{{
  if has_key(g:neocomplcache_plugin_completion_length, a:plugin_name)
    return g:neocomplcache_plugin_completion_length[a:plugin_name]
  elseif a:plugin_name == 'omni_complete' || a:plugin_name == 'vim_complete' || a:plugin_name == 'completefunc_complete'
    return 0
  else
    return g:neocomplcache_auto_completion_start_length
  endif
endfunction"}}}
function! neocomplcache#get_keyword_pattern(...)"{{{
  let l:filetype = a:0 != 0? a:000[0] : neocomplcache#get_context_filetype()

  let l:keyword_patterns = []
  for l:ft in split(l:filetype, '\.')
    call add(l:keyword_patterns, has_key(g:neocomplcache_keyword_patterns, l:ft) ?
          \ g:neocomplcache_keyword_patterns[l:ft] : g:neocomplcache_keyword_patterns['default'])
  endfor

  return join(l:keyword_patterns, '\m\|')
endfunction"}}}
function! neocomplcache#get_next_keyword_pattern(...)"{{{
  let l:filetype = a:0 != 0? a:000[0] : neocomplcache#get_context_filetype()

  if has_key(g:neocomplcache_next_keyword_patterns, l:filetype)
    return g:neocomplcache_next_keyword_patterns[l:filetype] . '\m\|' . neocomplcache#get_keyword_pattern(l:filetype)
  else
    return neocomplcache#get_keyword_pattern(l:filetype)
  endif
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
function! neocomplcache#match_word(cur_text)"{{{
  return matchstr(a:cur_text, neocomplcache#get_keyword_pattern_end())
endfunction"}}}
function! neocomplcache#match_wildcard(cur_text, pattern, cur_keyword_pos)"{{{
  let l:cur_keyword_pos = a:cur_keyword_pos
  if neocomplcache#is_eskk_enabled()
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
function! neocomplcache#is_auto_complete()"{{{
  return &l:completefunc == 'neocomplcache#auto_complete'
endfunction"}}}
function! neocomplcache#is_eskk_enabled()"{{{
  return exists('*eskk#is_enabled') && eskk#is_enabled()
endfunction"}}}
function! neocomplcache#print_caching(string)"{{{
  redraw
  echo a:string
endfunction"}}}
function! neocomplcache#print_error(string)"{{{
  echohl Error | echo a:string | echohl None
endfunction"}}}
function! neocomplcache#trunk_string(string, max)"{{{
  return printf('%.' . a:max-10 . 's..%%s', a:string, a:string[-8:])
endfunction"}}}
function! neocomplcache#head_match(checkstr, headstr)"{{{
  return a:headstr == '' || a:checkstr ==# a:headstr
        \|| a:checkstr[: len(a:headstr)-1] ==# a:headstr
endfunction"}}}
function! neocomplcache#get_source_filetypes(filetype)"{{{
  let l:filetype = a:filetype == ''? 'nothing' : a:filetype

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

  return l:filetype_dict
endfunction"}}}
function! neocomplcache#get_sources_list(dictionary, filetype)"{{{
  let l:list = []
  for l:filetype in keys(neocomplcache#get_source_filetypes(a:filetype))
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

" Set pattern helper.
function! neocomplcache#set_variable_pattern(variable, filetype, pattern)"{{{
  for ft in split(a:filetype, ',')
    if !has_key({a:variable}, ft) 
      let {a:variable}[ft] = a:pattern
    endif
  endfor
endfunction"}}}

" Complete filetype helper.
function! neocomplcache#filetype_complete(arglead, cmdline, cursorpos)"{{{
  let l:list = split(globpath(&runtimepath, 'snippets/*.snip*'), '\n') +
        \split(globpath(&runtimepath, 'autoload/neocomplcache/plugin/snippets_complete/*.snip*'), '\n')
  if exists('g:neocomplcache_snippets_dir')
    for l:dir in split(g:neocomplcache_snippets_dir, ',')
      let l:dir = expand(l:dir)
      if isdirectory(l:dir)
        let l:list += split(globpath(l:dir, '*.snip*'), '\n')
      endif
    endfor
  endif
  let l:items = map(l:list, 'fnamemodify(v:val, ":t:r")')

  " Dup check.
  let l:ret = {}
  for l:item in l:items
    if !has_key(l:ret, l:item) && l:item =~ '^'.a:arglead
      let l:ret[l:item] = 1
    endif
  endfor

  return sort(keys(l:ret))
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
  if !pumvisible()
    return ''
  endif

  let s:skip_next_complete = 1
  
  return "\<C-y>"
endfunction
"}}}
function! neocomplcache#cancel_popup()"{{{
  if !pumvisible()
    return ''
  endif

  let s:skip_next_complete = 1
  
  return "\<C-e>"
endfunction
"}}}

" Wrapper functions.
function! neocomplcache#manual_filename_complete()"{{{
  return neocomplcache#start_manual_complete('filename_complete')
endfunction"}}}
function! neocomplcache#manual_omni_complete()"{{{
  return neocomplcache#start_manual_complete('omni_complete')
endfunction"}}}
function! neocomplcache#manual_keyword_complete()"{{{
  return neocomplcache#start_manual_complete('keyword_complete')
endfunction"}}}

" Manual complete wrapper.
function! neocomplcache#start_manual_complete(complfunc_name)"{{{
  if !has_key(s:global_complfuncs, a:complfunc_name)
    echoerr printf("Invalid completefunc name %s is given.", a:complfunc_name)
    return ''
  endif
  
  " Clear flag.
  let s:used_match_filter = 0

  " Set function.
  let &l:completefunc = 'neocomplcache#manual_complete'

  let l:dict = {}
  let l:dict[a:complfunc_name] = s:global_complfuncs[a:complfunc_name]
  " Get complete result.
  let [l:cur_keyword_pos, l:cur_keyword_str, l:complete_words] = 
        \ s:integrate_completion(s:get_complete_result(s:get_cur_text(), l:dict))
  
  " Restore function.
  let &l:completefunc = 'neocomplcache#auto_complete'

  let [s:cur_keyword_pos, s:cur_keyword_str, s:complete_words] = [l:cur_keyword_pos, l:cur_keyword_str, l:complete_words]

  " Start complete.
  return "\<C-x>\<C-u>\<C-p>"
endfunction"}}}
function! neocomplcache#start_manual_complete_list(cur_keyword_pos, cur_keyword_str, complete_words)"{{{
  let [s:cur_keyword_pos, s:cur_keyword_str, s:complete_words] = [a:cur_keyword_pos, a:cur_keyword_str, a:complete_words]

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

  return (pumvisible() ? "\<C-e>" : '')
        \ . repeat("\<BS>", len(l:cur_keyword_str)) . l:old_keyword_str
endfunction"}}}

function! neocomplcache#complete_common_string()"{{{
  if !exists(':NeoComplCacheDisable')
    return ''
  endif

  " Get cursor word.
  let l:cur_keyword_str = neocomplcache#match_word(s:get_cur_text())

  " Save options.
  let l:ignorecase_save = &ignorecase

  if g:neocomplcache_enable_smart_case && l:cur_keyword_str =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase = g:neocomplcache_enable_ignore_case
  endif

  let l:complete_words = neocomplcache#keyword_filter(copy(s:old_complete_words), l:cur_keyword_str)
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
    call s:do_complete(0)
  endif
endfunction"}}}
function! s:on_moved_i()"{{{
  call s:do_complete(1)
endfunction"}}}
function! s:do_complete(is_moved)"{{{
  " Detect global completefunc.
  if &g:completefunc != 'neocomplcache#manual_complete' && &g:completefunc != 'neocomplcache#auto_complete'
    99verbose set completefunc
    echohl Error | echoerr 'Other plugin Use completefunc! Disabled neocomplcache.' | echohl None
    return
  endif

  " Detect AutoComplPop.
  if exists('g:acp_enableAtStartup') && g:acp_enableAtStartup
    echohl Error | echoerr 'Detected enabled AutoComplPop! Disabled neocomplcache.' | echohl None
    return
  endif

  if (&buftype !~ 'nofile\|nowrite' && b:changedtick == s:changedtick) || &paste
        \|| (g:neocomplcache_lock_buffer_name_pattern != '' && bufname('%') =~ g:neocomplcache_lock_buffer_name_pattern)
        \|| (has_key(s:complete_lock, bufnr('%')) && s:complete_lock[bufnr('%')])
        \|| g:neocomplcache_disable_auto_complete
        \|| (&l:completefunc != 'neocomplcache#manual_complete' && &l:completefunc != 'neocomplcache#auto_complete')
    return
  endif

  " Get cursor word.
  let l:cur_text = s:get_cur_text()
  " Prevent infinity loop.
  " Not complete multi byte character for ATOK X3.
  if l:cur_text == '' || l:cur_text == s:old_cur_text
        \|| (!neocomplcache#is_eskk_enabled() && (l:cur_text[-1] >= 0x80  || (exists('b:skk_on') && b:skk_on)))
    let s:complete_words = []
    let s:old_complete_words = []
    return
  endif

  let l:quickmatch_pattern = s:get_quickmatch_pattern()
  if g:neocomplcache_enable_quick_match && l:cur_text =~ l:quickmatch_pattern.'[a-z0-9;,./]$'
    " Select quickmatch list.
    let l:complete_words = s:select_quickmatch_list(l:cur_text[-1:])
    let s:prev_numbered_list = []

    if !empty(l:complete_words)
      let s:complete_words = l:complete_words
      let s:cur_keyword_pos = s:old_cur_keyword_pos

      " Set function.
      let &l:completefunc = 'neocomplcache#auto_complete'
      call feedkeys("\<C-x>\<C-u>", 'n')
      let s:old_cur_text = l:cur_text
      return 
    endif
  elseif g:neocomplcache_enable_quick_match 
        \&& !empty(s:old_complete_words)
        \&& l:cur_text =~ l:quickmatch_pattern.'$'
        \&& l:cur_text !~ l:quickmatch_pattern . l:quickmatch_pattern.'$'

    " Print quickmatch list.
    let s:cur_keyword_pos = s:old_cur_keyword_pos
    let l:cur_keyword_str = neocomplcache#match_word(l:cur_text[: -len(matchstr(l:cur_text, l:quickmatch_pattern.'$'))-1])
    let s:complete_words = s:make_quickmatch_list(s:old_complete_words, l:cur_keyword_str) 

    let &l:completefunc = 'neocomplcache#auto_complete'
    call feedkeys("\<C-x>\<C-u>\<C-p>", 'n')
    let s:old_cur_text = l:cur_text
    return
  elseif a:is_moved && g:neocomplcache_enable_cursor_hold_i
        \&& !s:used_match_filter
    if l:cur_text !=# s:moved_cur_text
      let s:moved_cur_text = l:cur_text
      " Dummy cursor move.
      call feedkeys("a\<BS>", 'n')
      return
    endif
  endif

  let s:old_cur_text = l:cur_text
  if s:skip_next_complete
    let s:skip_next_complete = 0
    return
  endif
  
  " Clear flag.
  let s:used_match_filter = 0

  let l:is_quickmatch_list = 0
  let s:prev_numbered_list = []
  let s:complete_words = []
  let s:old_complete_words = []
  let s:changedtick = b:changedtick

  " Set function.
  let &l:completefunc = 'neocomplcache#auto_complete'

  " Get complete result.
  let [l:cur_keyword_pos, l:cur_keyword_str, l:complete_words] = s:integrate_completion(s:get_complete_result(l:cur_text))

  if empty(l:complete_words)
    let &l:completefunc = 'neocomplcache#manual_complete'
    let s:changedtick = b:changedtick
    let s:used_match_filter = 0
    return
  endif

  let [s:cur_keyword_pos, s:cur_keyword_str, s:complete_words] = 
        \[l:cur_keyword_pos, l:cur_keyword_str, l:complete_words]

  " Start auto complete.
  if g:neocomplcache_enable_auto_select
    call feedkeys("\<C-x>\<C-u>\<C-p>\<Down>", 'n')
  else
    call feedkeys("\<C-x>\<C-u>\<C-p>", 'n')
  endif
  let s:changedtick = b:changedtick
endfunction"}}}
function! s:get_complete_result(cur_text, ...)"{{{
  " Set context filetype.
  call s:set_context_filetype()
  
  let l:complfuncs = a:0 == 0 ? s:global_complfuncs : a:1
  
  " Try complfuncs completion."{{{
  let l:complete_result = {}
  for [l:complfunc_name, l:complfunc] in items(l:complfuncs)
    let l:cur_keyword_pos = call(l:complfunc . 'get_keyword_pos', [a:cur_text])

    if l:cur_keyword_pos >= 0
      let l:cur_keyword_str = a:cur_text[l:cur_keyword_pos :]
      if len(l:cur_keyword_str) < neocomplcache#get_completion_length(l:complfunc_name)
        " Skip.
        continue
      endif

      " Save options.
      let l:ignorecase_save = &ignorecase

      if g:neocomplcache_enable_smart_case && l:cur_keyword_str =~ '\u'
        let &ignorecase = 0
      else
        let &ignorecase = g:neocomplcache_enable_ignore_case
      endif

      let l:words = call(l:complfunc . 'get_complete_words', [l:cur_keyword_pos, l:cur_keyword_str])

      let &ignorecase = l:ignorecase_save

      if !empty(l:words)
        let l:complete_result[l:complfunc_name] = {
              \'complete_words' : l:words, 
              \'cur_keyword_pos' : l:cur_keyword_pos, 
              \'cur_keyword_str' : l:cur_keyword_str, 
              \}
      endif
    endif
  endfor
  "}}}
  
  return l:complete_result
endfunction"}}}
function! s:integrate_completion(complete_result)"{{{
  if empty(a:complete_result)
    if neocomplcache#get_cur_text() =~ '\s\+$'
      " Caching current cache line.
      call neocomplcache#plugin#buffer_complete#caching_current_cache_line()
    endif
    
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

    for l:keyword in l:result.complete_words
      let l:word = l:keyword.word
      if has_key(l:frequencies, l:word)
        let l:keyword.rank = l:keyword.rank * l:frequencies[l:word]
      endif
    endfor

    let l:complete_words += s:remove_next_keyword(l:complfunc_name, l:result.complete_words)
  endfor

  " Sort.
  if !neocomplcache#is_eskk_enabled()
    call sort(l:complete_words, 'neocomplcache#compare_rank')
  endif
  let l:complete_words = filter(l:complete_words[: g:neocomplcache_max_list], 'v:val.word !=# '.string(l:cur_keyword_str))
  
  let l:icase = g:neocomplcache_enable_ignore_case && 
        \!(g:neocomplcache_enable_smart_case && l:cur_keyword_str =~ '\u')
  for l:keyword in l:complete_words
    let l:keyword.icase = l:icase
    if !has_key(l:keyword, 'abbr')
      let l:keyword.abbr = l:keyword.word
    endif
  endfor

  " Delimiter check.
  let l:filetype = neocomplcache#get_context_filetype()
  if has_key(g:neocomplcache_delimiter_patterns, l:filetype)"{{{
    for l:delimiter in g:neocomplcache_delimiter_patterns[l:filetype]
      " Count match.
      let l:delim_cnt = 0
      let l:matchend = matchend(l:cur_keyword_str, l:delimiter)
      while l:matchend >= 0
        let l:matchend = matchend(l:cur_keyword_str, l:delimiter, l:matchend)
        let l:delim_cnt += 1
      endwhile

      for l:keyword in l:complete_words
        let l:split_list = split(l:keyword.word, l:delimiter)
        if len(l:split_list) > 1
          let l:delimiter_sub = substitute(l:delimiter, '\\\([.^$]\)', '\1', 'g')
          let l:keyword.word = join(l:split_list[ : l:delim_cnt], l:delimiter_sub)
          let l:keyword.abbr = join(split(l:keyword.abbr, l:delimiter)[ : l:delim_cnt], l:delimiter_sub)

          if len(l:keyword.abbr) > g:neocomplcache_max_keyword_width
            let l:keyword.abbr = substitute(l:keyword.abbr, '\(\h\)\w*'.l:delimiter, '\1'.l:delimiter_sub, 'g')
          endif
          if l:delim_cnt+1 < len(l:split_list)
            let l:keyword.abbr .= l:delimiter_sub . '~'
          endif
        endif
      endfor
    endfor
  endif"}}}
  
  " Abbr check.
  let l:abbr_pattern = printf('%%.%ds..%%s', g:neocomplcache_max_keyword_width-15)
  for l:keyword in l:complete_words
    if len(l:keyword.abbr) > g:neocomplcache_max_keyword_width
      let l:keyword.abbr = printf(l:abbr_pattern, l:keyword.abbr, l:keyword.abbr[-13:])
    endif
  endfor

  return [l:cur_keyword_pos, l:cur_keyword_str, l:complete_words]
endfunction"}}}
function! s:on_insert_enter()"{{{
  if &updatetime > g:neocomplcache_cursor_hold_i_time
        \&& g:neocomplcache_enable_cursor_hold_i
    let s:update_time_save = &updatetime
    let &updatetime = g:neocomplcache_cursor_hold_i_time
  endif
endfunction"}}}
function! s:on_insert_leave()"{{{
  let s:cur_keyword_pos = -1
  let s:cur_keyword_str = ''
  let s:complete_words = []
  let s:used_match_filter = 0
  let s:context_filetype = ''
  let s:skip_next_complete = 0

  if &updatetime < s:update_time_save
        \&& g:neocomplcache_enable_cursor_hold_i
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

  let l:next_keyword_str = matchstr('a'.getline('.')[col('.') - 1 :], l:pattern)[1:]
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

let s:quickmatch_table = {
      \'a' : 0, 's' : 1, 'd' : 2, 'f' : 3, 'g' : 4, 'h' : 5, 'j' : 6, 'k' : 7, 'l' : 8, ';' : 9,
      \'q' : 10, 'w' : 11, 'e' : 12, 'r' : 13, 't' : 14, 'y' : 15, 'u' : 16, 'i' : 17, 'o' : 18, 'p' : 19, 
      \'z' : 20, 'x' : 21, 'c' : 22, 'v' : 23, 'b' : 24, 'n' : 25, 'm' : 26, ',' : 27, '.' : 28, '/' : 29,
      \'1' : 30, '2' : 31, '3' : 32, '4' : 33, '5' : 34, '6' : 35, '7' : 36, '8' : 37, '9' : 38, '0' : 39
      \}
function! s:make_quickmatch_list(list, cur_keyword_str)"{{{
  " Check dup.
  let l:dup_check = {}
  let l:num = 0
  let l:qlist = []
  let l:key = 
        \'asdfghjkl;'.
        \'qwertyuiop'.
        \'zxcvbnm,./'.
        \'1234567890'

  " Save options.
  let l:ignorecase_save = &ignorecase

  if g:neocomplcache_enable_smart_case && a:cur_keyword_str =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase = g:neocomplcache_enable_ignore_case
  endif

  for keyword in a:list
    if keyword.word != '' && 
          \(keyword.word == a:cur_keyword_str || keyword.word[: len(a:cur_keyword_str)-1] == a:cur_keyword_str)
          \&& (!has_key(l:dup_check, keyword.word) || (has_key(keyword, 'dup') && keyword.dup))
      let l:dup_check[keyword.word] = 1
      let l:keyword = deepcopy(l:keyword)
      let keyword.abbr = printf('%s: %s', l:key[l:num], keyword.abbr)

      call add(l:qlist, keyword)
      let l:num += 1
    endif
  endfor
  
  let &ignorecase = l:ignorecase_save
  
  " Trunk too many items.
  let l:qlist = l:qlist[: len(s:quickmatch_table)]

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
  let l:filetype = neocomplcache#get_context_filetype()

  let l:pattern = has_key(g:neocomplcache_quick_match_patterns, l:filetype)?  
        \ g:neocomplcache_quick_match_patterns[l:filetype] : g:neocomplcache_quick_match_patterns['default']

  return l:pattern
endfunction"}}}
function! s:get_cur_text()"{{{
  let l:pos = mode() ==# 'i' ? 2 : 1

  let s:cur_text = col('.') < l:pos ? '' : matchstr(getline('.'), '.*')[: col('.') - l:pos]

  " Save cur_text.
  return s:cur_text
endfunction"}}}
function! s:set_context_filetype()"{{{
  let l:filetype = &filetype
  if l:filetype == ''
    let l:filetype = 'nothing'
  endif
  
  if !has_key(g:neocomplcache_filetype_include_lists, l:filetype)
        \|| empty(g:neocomplcache_filetype_include_lists[l:filetype])
    let s:context_filetype = l:filetype
    return
  endif

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
        let s:context_filetype = l:include.filetype
        return 
      endif
    endif
  endfor

  let s:context_filetype = l:filetype
endfunction"}}}

" vim: foldmethod=marker
