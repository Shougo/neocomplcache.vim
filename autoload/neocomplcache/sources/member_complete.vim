"=============================================================================
" FILE: member_complete.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 04 Feb 2012.
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

" Important variables.
if !exists('s:member_sources')
  let s:member_sources = {}
endif

let s:source = {
      \ 'name' : 'member_complete',
      \ 'kind' : 'complfunc',
      \}

function! s:source.initialize()"{{{
  augroup neocomplcache"{{{
    " Caching events
    autocmd CursorHold * call s:caching_current_buffer(line('.')-10, line('.')+10)
    autocmd InsertEnter,InsertLeave *
          \ call neocomplcache#sources#member_complete#caching_current_line()
  augroup END"}}}

  " Set rank.
  call neocomplcache#set_dictionary_helper(g:neocomplcache_source_rank,
        \ 'member_complete', 5)

  " Set completion length.
  call neocomplcache#set_completion_length('member_complete', 0)

  " Initialize member prefix patterns."{{{
  if !exists('g:neocomplcache_member_prefix_patterns')
    let g:neocomplcache_member_prefix_patterns = {}
  endif
  call neocomplcache#set_dictionary_helper(g:neocomplcache_member_prefix_patterns,
        \'c,cpp,objc,objcpp', '\.\|->')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_member_prefix_patterns,
        \'perl,php', '->')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_member_prefix_patterns,
        \'cs,java,javascript,d,vim,ruby,python,perl6,scala,vb', '\.')
  call neocomplcache#set_dictionary_helper(g:neocomplcache_member_prefix_patterns,
        \'lua', '\.\|:')
  "}}}

  " Initialize member patterns."{{{
  if !exists('g:neocomplcache_member_patterns')
    let g:neocomplcache_member_patterns = {}
  endif
  call neocomplcache#set_dictionary_helper(g:neocomplcache_member_patterns,
        \'default', '\h\w*\%(()\?\)\?')
  "}}}

  " Initialize script variables."{{{
  let s:member_sources = {}
  "}}}
endfunction
"}}}

function! s:source.get_keyword_pos(cur_text)"{{{
  " Check member prefix pattern.
  let filetype = neocomplcache#get_context_filetype()
  if !has_key(g:neocomplcache_member_prefix_patterns, filetype)
        \ || g:neocomplcache_member_prefix_patterns[filetype] == ''
    return -1
  endif

  let cur_keyword_pos = matchend(a:cur_text,
        \ '\%(' . s:get_member_pattern(filetype) . '\%(' .
        \ g:neocomplcache_member_prefix_patterns[filetype] . '\m\)\)\+\ze\w*$')
  return cur_keyword_pos
endfunction"}}}

function! s:source.get_complete_words(cur_keyword_pos, cur_keyword_str)"{{{
  " Check member prefix pattern.
  let filetype = neocomplcache#get_context_filetype()
  let cur_text = neocomplcache#get_cur_text()
  let var_name = matchstr(cur_text,
        \ '\%(' . s:get_member_pattern(filetype) . '\%(' .
        \ g:neocomplcache_member_prefix_patterns[filetype] . '\m\)\)\+\ze\w*$')
  if var_name == ''
    return []
  endif

  return neocomplcache#keyword_filter(
        \ copy(s:get_member_list(cur_text, var_name)), a:cur_keyword_str)
endfunction"}}}

function! neocomplcache#sources#member_complete#define()"{{{
  return s:source
endfunction"}}}

function! neocomplcache#sources#member_complete#caching_current_line()"{{{
  " Current line caching.
  return s:caching_current_buffer(line('.')-1, line('.')+1)
endfunction"}}}
function! s:caching_current_buffer(start, end)"{{{
  " Current line caching.

  if !has_key(s:member_sources, bufnr('%'))
    call s:initialize_source(bufnr('%'))
  endif

  let filetype = neocomplcache#get_context_filetype(1)
  if !has_key(g:neocomplcache_member_prefix_patterns, filetype)
        \ || g:neocomplcache_member_prefix_patterns[filetype] == ''
    return
  endif

  let source = s:member_sources[bufnr('%')]
  let menu = '[M] member'
  let keyword_pattern =
        \ '\%(' . s:get_member_pattern(filetype) . '\%('
        \ . g:neocomplcache_member_prefix_patterns[filetype]
        \ . '\m\)\)\+' . s:get_member_pattern(filetype)
  let keyword_pattern2 = '^'.keyword_pattern
  let member_pattern = s:get_member_pattern(filetype) . '$'

  " Cache member pattern.
  let [line_num, max_lines] = [a:start, a:end]
  for line in getline(a:start, a:end)
    let match = match(line, keyword_pattern)

    while match >= 0"{{{
      let match_str = matchstr(line, keyword_pattern2, match)

      " Next match.
      let match = matchend(line, keyword_pattern, match + len(match_str))

      while match_str != ''
        let member_name = matchstr(match_str, member_pattern)
        if member_name == ''
          break
        endif
        let var_name = match_str[ : -len(member_name)-1]

        if !has_key(source.member_cache, var_name)
          let source.member_cache[var_name] = {}
        endif
        if !has_key(source.member_cache[var_name], member_name)
          let source.member_cache[var_name][member_name] =
                \ { 'word' : member_name, 'menu' : menu }
        endif

        let match_str = matchstr(var_name, keyword_pattern2)
      endwhile
    endwhile"}}}
  endfor
endfunction"}}}

function! s:get_member_list(cur_text, var_name)"{{{
  let keyword_list = []
  for [key, source] in filter(s:get_sources_list(),
        \ 'has_key(v:val[1].member_cache, a:var_name)')
    let keyword_list +=
          \ values(source.member_cache[a:var_name])
  endfor

  return keyword_list
endfunction"}}}

function! s:get_sources_list()"{{{
  let sources_list = []

  let filetypes_dict = {}
  for filetype in neocomplcache#get_source_filetypes(
        \ neocomplcache#get_context_filetype())
    let filetypes_dict[filetype] = 1
  endfor

  for [key, source] in items(s:member_sources)
    if has_key(filetypes_dict, source.filetype)
          \ || bufnr('%') == key
          \ || (bufname('%') ==# '[Command Line]' && bufnr('#') == key)
      call add(sources_list, [key, source])
    endif
  endfor

  return sources_list
endfunction"}}}

function! s:initialize_source(srcname)"{{{
  let path = fnamemodify(bufname(a:srcname), ':p')
  let filename = fnamemodify(path, ':t')
  if filename == ''
    let filename = '[No Name]'
    let path .= '/[No Name]'
  endif

  " Set cache line count.
  let buflines = getbufline(a:srcname, 1, '$')
  let end_line = len(buflines)

  let ft = getbufvar(a:srcname, '&filetype')
  if ft == ''
    let ft = 'nothing'
  endif

  let s:member_sources[a:srcname] = {
        \ 'member_cache' : {}, 'filetype' : ft,
        \ 'keyword_pattern' : neocomplcache#get_keyword_pattern(ft),
        \}
endfunction"}}}

function! s:get_member_pattern(filetype)"{{{
  return has_key(g:neocomplcache_member_patterns, a:filetype) ?
        \ g:neocomplcache_member_patterns[a:filetype] :
        \ g:neocomplcache_member_patterns['default']
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
