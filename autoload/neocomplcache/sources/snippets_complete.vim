"=============================================================================
" FILE: snippets_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 04 Nov 2010
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

let s:begin_snippet = 0
let s:end_snippet = 0

if !exists('s:snippets')
  let s:snippets = {}
endif

let s:source = {
      \ 'name' : 'snippets_complete',
      \ 'kind' : 'plugin',
      \}

function! s:source.initialize()"{{{
  " Initialize.
  let s:snippets = {}
  let s:begin_snippet = 0
  let s:end_snippet = 0
  let s:snippet_holder_cnt = 1

  " Set snips_author.
  if !exists('snips_author')
    let g:snips_author = 'Me'
  endif

  " Set snippets dir.
  let s:runtime_dir = split(globpath(&runtimepath, 'autoload/neocomplcache/sources/snippets_complete'), '\n')
  let s:snippets_dir = split(globpath(&runtimepath, 'snippets'), '\n') + s:runtime_dir
  if exists('g:neocomplcache_snippets_dir')
    for l:dir in split(g:neocomplcache_snippets_dir, ',')
      let l:dir = expand(l:dir)
      if !isdirectory(l:dir)
        call mkdir(l:dir, 'p')
      endif
      call add(s:snippets_dir, l:dir)
    endfor
  endif

  augroup neocomplcache"{{{
    " Set caching event.
    autocmd FileType * call s:caching()
    " Recaching events
    autocmd BufWritePost *.snip,*.snippets call s:caching_snippets(expand('<afile>:t:r')) 
    " Detect syntax file.
    autocmd BufNewFile,BufRead *.snip,*.snippets set filetype=snippet
    autocmd BufNewFile,BufWinEnter * syn match   NeoComplCacheExpandSnippets         
          \'\${\d\+\%(:.\{-}\)\?\\\@<!}\|\$<\d\+\%(:.\{-}\)\?\\\@<!>\|\$\d\+'
  augroup END"}}}

  command! -nargs=? -complete=customlist,neocomplcache#filetype_complete NeoComplCacheEditSnippets call s:edit_snippets(<q-args>, 0)
  command! -nargs=? -complete=customlist,neocomplcache#filetype_complete NeoComplCacheEditRuntimeSnippets call s:edit_snippets(<q-args>, 1)
  command! -nargs=? -complete=customlist,neocomplcache#filetype_complete NeoComplCachePrintSnippets call s:print_snippets(<q-args>)

  hi def link NeoComplCacheExpandSnippets Special

  " Select mode mappings.
  if !exists('g:neocomplcache_disable_select_mode_mappings')
    snoremap <CR>     a<BS>
    snoremap <BS> a<BS>
    snoremap <right> <ESC>a
    snoremap <left> <ESC>bi
    snoremap ' a<BS>'
    snoremap ` a<BS>`
    snoremap % a<BS>%
    snoremap U a<BS>U
    snoremap ^ a<BS>^
    snoremap \ a<BS>\
    snoremap <C-x> a<BS><c-x>
  endif

  " Caching _ snippets.
  call s:caching_snippets('_')

  " Initialize check.
  call s:caching()

  if neocomplcache#exists_echodoc()
    call echodoc#register('snippets_complete', s:doc_dict)
  endif
endfunction"}}}

function! s:source.finalize()"{{{
  delcommand NeoComplCacheEditSnippets
  delcommand NeoComplCacheEditRuntimeSnippets
  delcommand NeoComplCachePrintSnippets

  hi clear NeoComplCacheExpandSnippets
  
  if neocomplcache#exists_echodoc()
    call echodoc#unregister('snippets_complete')
  endif
endfunction"}}}

function! s:source.get_keyword_list(cur_keyword_str)"{{{
  if !has_key(s:snippets, '_')
    " Caching _ snippets.
    call s:caching_snippets('_')
  endif
  let l:snippets = values(s:snippets['_'])

  let l:filetype = neocomplcache#get_context_filetype()
  if !has_key(s:snippets, l:filetype)
    " Caching snippets.
    call s:caching_snippets(l:filetype)
  endif
  for l:source in neocomplcache#get_sources_list(s:snippets, l:filetype)
    let l:snippets += values(l:source)
  endfor

  return s:keyword_filter(neocomplcache#dup_filter(l:snippets), a:cur_keyword_str)
endfunction"}}}

function! neocomplcache#sources#snippets_complete#define()"{{{
  return s:source
endfunction"}}}

function! s:compare_words(i1, i2)
  return a:i1.menu - a:i2.menu
endfunction

" For echodoc."{{{
let s:doc_dict = {
      \ 'name' : 'snippets_complete',
      \ 'rank' : 100,
      \ 'filetypes' : {},
      \ }
function! s:doc_dict.search(cur_text)"{{{
  if mode() !=# 'i'
    return []
  endif
  
  let l:snippets = s:get_snippets()

  let l:cur_word = s:get_cursor_snippet(l:snippets, a:cur_text)
  if l:cur_word == ''
    return []
  endif

  let l:snip = l:snippets[l:cur_word]
  let l:ret = []
  call add(l:ret, { 'text' : l:snip.word, 'highlight' : 'String' })
  call add(l:ret, { 'text' : ' ' })
  call add(l:ret, { 'text' : l:snip.menu, 'highlight' : 'Special' })
  call add(l:ret, { 'text' : ' ' })
  call add(l:ret, { 'text' : l:snip.snip})

  return l:ret
endfunction"}}}
"}}}

function! s:keyword_filter(list, cur_keyword_str)"{{{
  let l:keyword_escape = neocomplcache#keyword_escape(a:cur_keyword_str)

  let l:prev_word = neocomplcache#get_prev_word(a:cur_keyword_str)
  " Keyword filter.
  let l:pattern = printf('v:val.word =~ %s && (!has_key(v:val, "prev_word") || v:val.prev_word == %s)', 
        \string('^' . l:keyword_escape), string(l:prev_word))

  let l:list = filter(a:list, l:pattern)

  " Substitute abbr.
  let l:abbr_pattern = printf('%%.%ds..%%s', g:neocomplcache_max_keyword_width-10)
  for snippet in l:list
    if snippet.snip =~ '\\\@<!`.*\\\@<!`'
      let snippet.menu = s:eval_snippet(snippet.snip)

      if len(snippet.menu) > g:neocomplcache_max_keyword_width 
        let snippet.menu = printf(l:abbr_pattern, snippet.menu, snippet.menu[-8:])
      endif
      let snippet.menu = '`Snip` ' . snippet.menu
    endif
  endfor

  return l:list
endfunction"}}}

function! neocomplcache#sources#snippets_complete#expandable()"{{{
  let l:snippets = s:get_snippets()
  let l:cur_text = neocomplcache#get_cur_text(1)

  if s:get_cursor_snippet(l:snippets, l:cur_text) != ''
    " Found snippet trigger.
    return 1
  elseif search('\${\d\+\%(:.\{-}\)\?\\\@<!}\|\$<\d\+\%(:.\{-}\)\?\\\@<!>', 'nw') > 0
    " Found snippet placeholder.
    return 2
  else
    " Not found.
    return 0
  endif
endfunction"}}}

function! s:caching()"{{{
  for l:filetype in keys(neocomplcache#get_source_filetypes(neocomplcache#get_context_filetype(1)))
    if !has_key(s:snippets, l:filetype)
      call s:caching_snippets(l:filetype)
    endif
  endfor
endfunction"}}}

function! s:set_snippet_pattern(dict)"{{{
  let l:abbr_pattern = printf('%%.%ds..%%s', g:neocomplcache_max_keyword_width-10)

  let l:word = substitute(a:dict.word, '\%(<\\n>\)\+$', '', '')
  let l:menu_pattern = a:dict.word =~ '\${\d\+\%(:.\{-}\)\?\\\@<!}' ? '<Snip> ' : '[Snip] '

  let l:abbr = has_key(a:dict, 'abbr')? a:dict.abbr : 
        \substitute(a:dict.word, '\${\d\+\%(:.\{-}\)\?\\\@<!}\|\$<\d\+\%(:.\{-}\)\?\\\@<!>\|\$\d\+\|<\%(\\n\|\\t\)>\|\s\+', ' ', 'g')
  let l:abbr = (len(l:abbr) > g:neocomplcache_max_keyword_width)? 
        \ printf(l:abbr_pattern, l:abbr, l:abbr[-8:]) : l:abbr

  let l:dict = {
        \'word' : a:dict.name, 'snip' : l:word, 'abbr' : a:dict.name, 
        \'menu' : l:menu_pattern . l:abbr, 'dup' : 1
        \}
  if has_key(a:dict, 'prev_word')
    let l:dict.prev_word = a:dict.prev_word
  endif
  return l:dict
endfunction"}}}

function! s:edit_snippets(filetype, isruntime)"{{{
  if a:filetype == ''
    let l:filetype = neocomplcache#get_context_filetype(1)
  else
    let l:filetype = a:filetype
  endif

  " Edit snippet file.
  if a:isruntime
    if empty(s:runtime_dir)
      return
    endif

    let l:filename = s:runtime_dir[0].'/'.l:filetype.'.snip'
  else
    if empty(s:snippets_dir) 
      return
    endif

    let l:filename = s:snippets_dir[-1].'/'.l:filetype.'.snip'
  endif

  " Split nicely.
  if winheight(0) > &winheight
    split
  else
    vsplit
  endif

  if filereadable(l:filename)
    edit `=l:filename`
  else
    enew
    setfiletype snippet
    saveas `=l:filename`
  endif
endfunction"}}}
function! s:print_snippets(filetype)"{{{
  let l:list = values(s:snippets['_'])

  let l:filetype = (a:filetype != '')?    a:filetype : neocomplcache#get_context_filetype(1)

  if l:filetype != ''
    if !has_key(s:snippets, l:filetype)
      call s:caching_snippets(l:filetype)
    endif

    let l:list += values(s:snippets[l:filetype])
  endif

  for snip in sort(l:list, 's:compare_words')
    echohl String
    echo snip.word
    echohl Special
    echo snip.menu
    echohl None
    echo snip.snip
    echo ' '
  endfor

  echohl None
endfunction"}}}

function! s:caching_snippets(filetype)"{{{
  let l:snippet = {}
  let l:snippets_files = split(globpath(join(s:snippets_dir, ','), a:filetype .  '.snip*'), '\n')
  for snippets_file in l:snippets_files
    call extend(l:snippet, s:load_snippets(snippets_file))
  endfor

  let s:snippets[a:filetype] = l:snippet
endfunction"}}}

function! s:load_snippets(snippets_file)"{{{
  let l:snippet = {}
  let l:snippet_pattern = { 'word' : '' }
  let l:abbr_pattern = printf('%%.%ds..%%s', g:neocomplcache_max_keyword_width-10)

  let l:linenr = 1

  for line in readfile(a:snippets_file)
    if line =~ '^\h\w*.*\s$'
      " Delete spaces.
      let line = substitute(line, '\s\+$', '', '')
    endif

    if line =~ '^include'
      " Include snippets.
      let l:snippet_file = matchstr(line, '^include\s\+\zs.*$')
      for snippets_file in split(globpath(join(s:snippets_dir, ','), l:snippet_file), '\n')
        call extend(l:snippet, s:load_snippets(snippets_file))
      endfor
    elseif line =~ '^delete\s'
      let l:name = matchstr(line, '^delete\s\+\zs.*$')
      if l:name != '' && has_key(l:snippet, l:name)
        call remove(l:snippet, l:name)
      endif
    elseif line =~ '^snippet\s'
      if has_key(l:snippet_pattern, 'name')
        let l:pattern = s:set_snippet_pattern(l:snippet_pattern)
        let l:snippet[l:snippet_pattern.name] = l:pattern
        if has_key(l:snippet_pattern, 'alias')
          for l:alias in l:snippet_pattern.alias
            let l:alias_pattern = copy(l:pattern)
            let l:alias_pattern.word = l:alias

            let l:abbr = (len(l:alias) > g:neocomplcache_max_keyword_width)? 
                  \ printf(l:abbr_pattern, l:alias, l:alias[-8:]) : l:alias
            let l:alias_pattern.abbr = l:abbr

            let l:snippet[alias] = l:alias_pattern
          endfor
        endif
        let l:snippet_pattern = { 'word' : '' }
      endif

      let l:snippet_pattern.name = matchstr(line, '^snippet\s\+\zs.*$')

      " Check for duplicated names.
      if has_key(l:snippet, l:snippet_pattern.name)
        call neocomplcache#print_error('Warning: ' . a:snippets_file . ':' . l:linenr . ': duplicated snippet name `' . l:snippet_pattern.name . '`')
        call neocomplcache#print_error('Please delete this snippet name before.')
      endif
    elseif has_key(l:snippet_pattern, 'name')
      " Only in snippets.
      if line =~ '^abbr\s'
        let l:snippet_pattern.abbr = matchstr(line, '^abbr\s\+\zs.*$')
      elseif line =~ '^alias\s'
        let l:snippet_pattern.alias = split(matchstr(line, '^alias\s\+\zs.*$'), '[,[:space:]]\+')
      elseif line =~ '^prev_word\s'
        let l:snippet_pattern.prev_word = matchstr(line, '^prev_word\s\+[''"]\zs.*\ze[''"]$')
      elseif line =~ '^\s'
        if l:snippet_pattern.word == ''
          let l:snippet_pattern.word = matchstr(line, '^\s\+\zs.*$')
        elseif line =~ '^\t'
          let line = substitute(line, '^\s', '', '')
          let l:snippet_pattern.word .= '<\n>' . 
                \substitute(line, '^\t\+', repeat('<\\t>', matchend(line, '^\t\+')), '')
        else
          let l:snippet_pattern.word .= '<\n>' . matchstr(line, '^\s\+\zs.*$')
        endif
      elseif line =~ '^$'
        " Blank line.
        let l:snippet_pattern.word .= '<\n>'
      endif
    endif

    let l:linenr += 1
  endfor

  if has_key(l:snippet_pattern, 'name')
    let l:pattern = s:set_snippet_pattern(l:snippet_pattern)
    let l:snippet[l:snippet_pattern.name] = l:pattern
    if has_key(l:snippet_pattern, 'alias')
      for l:alias in l:snippet_pattern.alias
        " Check for duplicated names.
        if has_key(l:snippet, l:alias)
          call neocomplcache#print_error('Warning: ' . a:snippets_file . ':' . l:linenr . ': duplicated snippet name `' . l:alias . '`')
          call neocomplcache#print_error('Please delete this snippet name before.')
        endif

        let l:alias_pattern = copy(l:pattern)
        let l:alias_pattern.word = l:alias

        let l:abbr = (len(l:alias) > g:neocomplcache_max_keyword_width)? 
              \ printf(l:abbr_pattern, l:alias, l:alias[-8:]) : l:alias
        let l:alias_pattern.abbr = l:abbr

        let l:snippet[alias] = l:alias_pattern
      endfor
    endif
  endif

  return l:snippet
endfunction"}}}

function! s:get_cursor_snippet(snippets, cur_text)"{{{
  let l:cur_word = matchstr(a:cur_text, '\S\+$')
  while l:cur_word != '' && !has_key(a:snippets, l:cur_word)
    let l:cur_word = l:cur_word[1:]
  endwhile

  return l:cur_word
endfunction"}}}
function! s:snippets_expand(cur_text, col)"{{{
  let l:snippets = s:get_snippets()

  let l:cur_word = s:get_cursor_snippet(l:snippets, a:cur_text)
  if l:cur_word == ''
    " Not found.
    call s:snippets_jump(a:cur_text, a:col)
    return
  endif

  let l:snippet = l:snippets[l:cur_word]
  let l:cur_text = a:cur_text[: -1-len(l:cur_word)]

  let l:snip_word = l:snippet.snip
  if l:snip_word =~ '\\\@<!`.*\\\@<!`'
    let l:snip_word = s:eval_snippet(l:snip_word)
  endif
  if l:snip_word =~ '\n'
    let snip_word = substitute(l:snip_word, '\n', '<\\n>', 'g')
  endif

  " Substitute escaped `.
  let snip_word = substitute(l:snip_word, '\\`', '`', 'g')

  " Insert snippets.
  let l:next_line = getline('.')[a:col-1 :]
  call setline(line('.'), l:cur_text . l:snip_word . l:next_line)
  call setpos('.', [0, line('.'), len(l:cur_text)+len(l:snip_word)+1, 0])
  let l:old_col = len(l:cur_text)+len(l:snip_word)+1

  if l:snip_word =~ '<\\t>'
    call s:expand_tabline()
  else
    call s:expand_newline()
  endif
  if l:old_col < col('$')
    startinsert
  else
    startinsert!
  endif

  if l:snip_word =~ '\${\d\+\%(:.\{-}\)\?\\\@<!}'
    call s:snippets_jump(a:cur_text, a:col)
  endif

  let &l:iminsert = 0
  let &l:imsearch = 0
endfunction"}}}
function! s:expand_newline()"{{{
  let l:match = match(getline('.'), '<\\n>')
  let s:snippet_holder_cnt = 1
  let s:begin_snippet = line('.')
  let s:end_snippet = line('.')

  let l:formatoptions = &l:formatoptions
  setlocal formatoptions-=r

  let l:pos = col('.')

  while l:match >= 0
    let l:end = getline('.')[matchend(getline('.'), '<\\n>') :]
    " Substitute CR.
    silent! s/<\\n>//

    " Return.
    call setpos('.', [0, line('.'), l:match+1, 0])
    silent execute 'normal!' (l:match+1 >= col('$')? 'a' : 'i')."\<CR>"

    " Next match.
    let l:match = match(getline('.'), '<\\n>')
    let s:end_snippet += 1
  endwhile

  let &l:formatoptions = l:formatoptions
endfunction"}}}
function! s:expand_tabline()"{{{
  let l:tablines = split(getline('.'), '<\\n>')

  let l:indent = matchstr(l:tablines[0], '^\s\+')
  let l:line = line('.')
  call setline(line, l:tablines[0])
  for l:tabline in l:tablines[1:]
    if &expandtab
      let l:tabline = substitute(l:tabline, '<\\t>', repeat(' ', &softtabstop ? &softtabstop : &shiftwidth), 'g')
    else
      let l:tabline = substitute(l:tabline, '<\\t>', '\t', 'g')
    endif

    call append(l:line, l:indent . l:tabline)
    let l:line += 1
  endfor

  let s:snippet_holder_cnt = 1
  let s:begin_snippet = line('.')
  let s:end_snippet = line('.') + len(l:tablines) - 1
endfunction"}}}
function! s:snippets_jump(cur_text, col)"{{{
  if !s:search_snippet_range(s:begin_snippet, s:end_snippet)
    if s:snippet_holder_cnt != 0
      " Search placeholder 0.
      let s:snippet_holder_cnt = 0
      if s:search_snippet_range(s:begin_snippet, s:end_snippet)
        let &iminsert = 0
        let &imsearch = 0
        return
      endif
    endif

    " Not found.
    let s:begin_snippet = 1
    let s:end_snippet = 0
    let s:snippet_holder_cnt = 1

    call s:search_outof_range(a:col)
  endif

  let &iminsert = 0
  let &imsearch = 0
endfunction"}}}
function! s:search_snippet_range(start, end)"{{{
  call s:substitute_marker(a:start, a:end)

  let l:pattern = '\${'.s:snippet_holder_cnt.'\%(:.\{-}\)\?\\\@<!}'
  let l:pattern2 = '\${'.s:snippet_holder_cnt.':\zs.\{-}\ze\\\@<!}'

  let l:line = a:start
  while l:line <= a:end
    let l:match = match(getline(l:line), l:pattern)
    if l:match >= 0
      let l:default = substitute(matchstr(getline(l:line), l:pattern2), '\\\ze.', '', 'g')
      let l:match_len2 = len(l:default)

      if s:search_sync_placeholder(a:start, a:end, s:snippet_holder_cnt)
        " Substitute holder.
        call setline(l:line, substitute(getline(l:line), l:pattern, '\$<'.s:snippet_holder_cnt.':'.escape(l:default, '\').'>', ''))
        call setpos('.', [0, l:line, l:match+1 + len('$<'.s:snippet_holder_cnt.':'), 0])
        let l:pos = l:match+1 + len('$<'.s:snippet_holder_cnt.':')
      else
        " Substitute holder.
        call setline(l:line, substitute(getline(l:line), l:pattern, escape(l:default, '\'), ''))
        call setpos('.', [0, l:line, l:match+1, 0])
        let l:pos = l:match+1
      endif

      if l:match_len2 > 0
        " Select default value.
        let l:len = l:match_len2-1
        if &l:selection == "exclusive"
          let l:len += 1
        endif

        execute 'normal! v'. repeat('l', l:len) . "\<C-g>"
      elseif l:pos < col('$')
        startinsert
      else
        startinsert!
      endif

      " Next count.
      let s:snippet_holder_cnt += 1
      return 1
    endif

    " Next line.
    let l:line += 1
  endwhile

  return 0
endfunction"}}}
function! s:search_outof_range(col)"{{{
  call s:substitute_marker(1, 0)

  let l:pattern = '\${\d\+\%(:.\{-}\)\?\\\@<!}'
  if search(l:pattern, 'w') > 0
    let l:line = line('.')
    let l:match = match(getline(l:line), l:pattern)
    let l:pattern2 = '\${\d\+:\zs.\{-}\ze\\\@<!}'
    let l:default = substitute(matchstr(getline(l:line), l:pattern2), '\\\ze.', '', 'g')
    let l:match_len2 = len(l:default)

    " Substitute holder.
    let l:cnt = matchstr(getline(l:line), '\${\zs\d\+\ze\%(:.\{-}\)\?\\\@<!}')
    if search('\$'.l:cnt.'\d\@!', 'nw') > 0
      let l:pattern = '\${' . l:cnt . '\%(:.\{-}\)\?\\\@<!}'
      call setline(l:line, substitute(getline(l:line), l:pattern, '\$<'.s:snippet_holder_cnt.':'.escape(l:default, '\').'>', ''))
      call setpos('.', [bufnr('.'), l:line, l:match+1 + len('$<'.l:cnt.':'), 0])
      let l:pos = l:match+1 + len('$<'.l:cnt.':')
    else
      " Substitute holder.
      call setline(l:line, substitute(getline(l:line), l:pattern, escape(l:default, '\'), ''))
      call setpos('.', [bufnr('.'), l:line, l:match+1, 0])
      let l:pos = l:match+1
    endif

    if l:match_len2 > 0
      " Select default value.
      let l:len = l:match_len2-1
      if &l:selection == 'exclusive'
        let l:len += 1
      endif

      execute 'normal! v'. repeat('l', l:len) . "\<C-g>"

      return
    endif

    if l:pos < col('$')
      startinsert
    else
      startinsert!
    endif
  elseif a:col == 1
    call setpos('.', [bufnr('.'), line('.'), 1, 0])
    startinsert
  elseif a:col == col('$')
    startinsert!
  else
    call setpos('.', [0, line('.'), a:col+1, 0])
    startinsert
  endif
endfunction"}}}
function! s:search_sync_placeholder(start, end, number)"{{{
  let l:line = a:start
  let l:pattern = '\$'.a:number.'\d\@!'

  while l:line <= a:end
    if getline(l:line) =~ l:pattern
      return 1
    endif

    " Next line.
    let l:line += 1
  endwhile

  return 0
endfunction"}}}
function! s:substitute_marker(start, end)"{{{
  if s:snippet_holder_cnt > 1
    let l:cnt = s:snippet_holder_cnt-1
    let l:marker = '\$<'.l:cnt.'\%(:.\{-}\)\?\\\@<!>'
    let l:line = a:start
    while l:line <= a:end
      if getline(l:line) =~ l:marker
        let l:sub = escape(matchstr(getline(l:line), '\$<'.l:cnt.':\zs.\{-}\ze\\\@<!>'), '/\')
        silent! execute printf('%d,%ds/$%d\d\@!/%s/g', 
              \a:start, a:end, l:cnt, l:sub)
        silent! execute l:line.'s/'.l:marker.'/'.l:sub.'/'
        break
      endif

      let l:line += 1
    endwhile
  elseif search('\$<\d\+\%(:.\{-}\)\?\\\@<!>', 'wb') > 0
    let l:sub = escape(matchstr(getline('.'), '\$<\d\+:\zs.\{-}\ze\\\@<!>'), '/\')
    let l:cnt = matchstr(getline('.'), '\$<\zs\d\+\ze\%(:.\{-}\)\?\\\@<!>')
    silent! execute printf('%%s/$%d\d\@!/%s/g', l:cnt, l:sub)
    silent! execute '%s/'.'\$<'.l:cnt.'\%(:.\{-}\)\?\\\@<!>'.'/'.l:sub.'/'
  endif
endfunction"}}}
function! s:trigger(function)"{{{
  let l:cur_text = neocomplcache#get_cur_text(1)
  return printf("\<ESC>:call %s(%s,%d)\<CR>", a:function, string(l:cur_text), col('.'))
endfunction"}}}
function! s:eval_snippet(snippet_text)"{{{
  let l:snip_word = ''
  let l:prev_match = 0
  let l:match = match(a:snippet_text, '\\\@<!`.\{-}\\\@<!`')

  try
    while l:match >= 0
      if l:match - l:prev_match > 0
        let l:snip_word .= a:snippet_text[l:prev_match : l:match - 1]
      endif
      let l:prev_match = matchend(a:snippet_text, '\\\@<!`.\{-}\\\@<!`', l:match)
      let l:snip_word .= eval(a:snippet_text[l:match+1 : l:prev_match - 2])

      let l:match = match(a:snippet_text, '\\\@<!`.\{-}\\\@<!`', l:prev_match)
    endwhile
    if l:prev_match >= 0
      let l:snip_word .= a:snippet_text[l:prev_match :]
    endif
  catch
    return ''
  endtry

  return l:snip_word
endfunction"}}}
function! s:get_snippets()"{{{
  " Get buffer filetype.
  let l:ft = neocomplcache#get_context_filetype(1)

  let l:snippets = copy(s:snippets['_'])
  for l:t in split(l:ft, '\.')
    if has_key(s:snippets, l:t)
      call extend(l:snippets, s:snippets[l:t])
    endif
  endfor

  " Get same filetype.
  if has_key(g:neocomplcache_same_filetype_lists, l:ft)
    for l:same_ft in split(g:neocomplcache_same_filetype_lists[l:ft], ',')
      if has_key(s:snippets, l:same_ft)
        call extend(l:snippets, s:snippets[l:same_ft], 'keep')
      endif
    endfor
  endif

  return l:snippets
endfunction"}}}

function! s:SID_PREFIX()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endfunction

" Plugin key-mappings.
inoremap <silent><expr> <Plug>(neocomplcache_snippets_expand) <SID>trigger(<SID>SID_PREFIX().'snippets_expand')
snoremap <silent><expr> <Plug>(neocomplcache_snippets_expand) <SID>trigger(<SID>SID_PREFIX().'snippets_expand')
inoremap <silent><expr> <Plug>(neocomplcache_snippets_jump) <SID>trigger(<SID>SID_PREFIX().'snippets_jump')
snoremap <silent><expr> <Plug>(neocomplcache_snippets_jump) <SID>trigger(<SID>SID_PREFIX().'snippets_jump')

" vim: foldmethod=marker
