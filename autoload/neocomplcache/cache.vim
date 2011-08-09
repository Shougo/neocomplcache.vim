"=============================================================================
" FILE: cache.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 09 Aug 2011.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditionneocomplcache#cache#
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

" Cache loader.
function! neocomplcache#cache#check_cache(cache_dir, key, async_cache_dictionary,
      \ keyword_list_dictionary, completion_length) "{{{
  if !has_key(a:async_cache_dictionary, a:key)
    return
  endif

  for l:cache in a:async_cache_dictionary[a:key]
    " Check cache name.
    if filereadable(l:cache.cachename)
      " Caching.
      let a:keyword_list_dictionary[a:key] = {}

      let l:keyword_list = []
      for l:cache in a:async_cache_dictionary[a:key]
        let l:keyword_list += neocomplcache#cache#load_from_cache(a:cache_dir, l:cache.filename)
      endfor

      call neocomplcache#cache#list2index(
            \ l:keyword_list,
            \ a:keyword_list_dictionary[a:key],
            \ a:completion_length)

      " Delete from dictionary.
      call remove(a:async_cache_dictionary, a:key)

      return
    endif
  endfor
endfunction"}}}
function! neocomplcache#cache#load_from_cache(cache_dir, filename)"{{{
  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  if !filereadable(l:cache_name)
    return []
  endif

  try
    return map(map(readfile(l:cache_name), 'split(v:val, "|||", 1)'), '{
          \ "word" : v:val[0],
          \ "abbr" : v:val[1],
          \ "menu" : v:val[2],
          \ "kind" : v:val[3],
          \}')
  catch /^Vim\%((\a\+)\)\=:E684:/
    return []
  endtry
endfunction"}}}
function! neocomplcache#cache#index_load_from_cache(cache_dir, filename, completion_length)"{{{
  let l:keyword_lists = {}

  for l:keyword in neocomplcache#cache#load_from_cache(a:cache_dir, a:filename)
    let l:key = tolower(l:keyword.word[: a:completion_length-1])
    if !has_key(l:keyword_lists, l:key)
      let l:keyword_lists[l:key] = []
    endif
    call add(l:keyword_lists[l:key], l:keyword)
  endfor

  return l:keyword_lists
endfunction"}}}
function! neocomplcache#cache#list2index(list, dictionary, completion_length)"{{{
  for l:keyword in a:list
    let l:key = tolower(l:keyword.word[: a:completion_length-1])
    if !has_key(a:dictionary, l:key)
      let a:dictionary[l:key] = {}
    endif
    let a:dictionary[l:key][l:keyword.word] = l:keyword
  endfor

  return a:dictionary
endfunction"}}}

function! neocomplcache#cache#save_cache(cache_dir, filename, keyword_list)"{{{
  " Create cache directory.
  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)

  " Create dictionary key.
  for keyword in a:keyword_list
    if !has_key(keyword, 'abbr')
      let keyword.abbr = keyword.word
    endif
    if !has_key(keyword, 'kind')
      let keyword.kind = ''
    endif
    if !has_key(keyword, 'menu')
      let keyword.menu = ''
    endif
  endfor

  " Output cache.
  let l:word_list = []
  for keyword in a:keyword_list
    call add(l:word_list, printf('%s|||%s|||%s|||%s',
          \keyword.word, keyword.abbr, keyword.menu, keyword.kind))
  endfor

  call writefile(l:word_list, l:cache_name)
endfunction"}}}

" Cache helper.
function! neocomplcache#cache#getfilename(cache_dir, filename)"{{{
  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  return l:cache_name
endfunction"}}}
function! neocomplcache#cache#filereadable(cache_dir, filename)"{{{
  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  return filereadable(l:cache_name)
endfunction"}}}
function! neocomplcache#cache#readfile(cache_dir, filename)"{{{
  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  return filereadable(l:cache_name) ? readfile(l:cache_name) : []
endfunction"}}}
function! neocomplcache#cache#writefile(cache_dir, filename, list)"{{{
  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)

  call writefile(a:list, l:cache_name)
endfunction"}}}
function! neocomplcache#cache#encode_name(cache_dir, filename)
  " Check cache directory.
  let l:cache_dir = g:neocomplcache_temporary_dir . '/' . a:cache_dir
  if !isdirectory(l:cache_dir)
    call mkdir(l:cache_dir, 'p')
  endif

  let l:dir = printf('%s/%s/', g:neocomplcache_temporary_dir, a:cache_dir)
  return l:dir . s:create_hash(l:dir, a:filename)
endfunction
function! neocomplcache#cache#check_old_cache(cache_dir, filename)"{{{
  " Check old cache file.
  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  let l:ret = getftime(l:cache_name) == -1 || getftime(l:cache_name) <= getftime(a:filename)
  if l:ret && filereadable(l:cache_name)
    " Delete old cache.
    call delete(l:cache_name)
  endif

  return l:ret
endfunction"}}}

" Check md5.
try
  call md5#md5()
  let s:exists_md5 = 1
catch
  let s:exists_md5 = 0
endtry

function! s:create_hash(dir, str)"{{{
  if len(a:dir) + len(a:str) < 150
    let l:hash = substitute(substitute(a:str, ':', '=-', 'g'), '[/\\]', '=+', 'g')
  elseif s:exists_md5
    " Use md5.vim.
    let l:hash = md5#md5(a:str)
  else
    " Use simple hash.
    let l:sum = 0
    for i in range(len(a:str))
      let l:sum += char2nr(a:str[i]) * (i + 1)
    endfor

    let l:hash = printf('%x', l:sum)
  endif

  return l:hash
endfunction"}}}

let s:sdir = fnamemodify(expand('<sfile>'), ':p:h')

" Async test.
function! neocomplcache#cache#test_async()"{{{
  if !neocomplcache#cache#check_old_cache(a:cache_dir, a:filename)
    return neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  endif

  let l:filename = substitute(fnamemodify(expand('%'), ':p'), '\\', '/', 'g')
  let l:pattern_file_name = neocomplcache#cache#encode_name('keyword_patterns', 'vim')
  let l:cache_name = neocomplcache#cache#encode_name('test_cache', l:filename)

  " Create pattern file.
  call neocomplcache#cache#writefile('keyword_patterns', a:filename, [a:pattern])

  " args: funcname, outputname, filename pattern mark minlen maxfilename outputname
  let l:argv = [
        \  'load_from_file', l:cache_name, l:filename, l:pattern_file_name, '[B]',
        \  g:neocomplcache_min_keyword_length, g:neocomplcache_max_filename_width, &fileencoding
        \ ]
  return s:async_load(l:argv, 'test_cache', l:filename)
endfunction"}}}

function! neocomplcache#cache#async_load_from_file(cache_dir, filename, pattern, mark)"{{{
  if !neocomplcache#cache#check_old_cache(a:cache_dir, a:filename)
    return neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  endif

  let l:pattern_file_name = neocomplcache#cache#encode_name('keyword_patterns', a:filename)
  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)

  " Create pattern file.
  call neocomplcache#cache#writefile('keyword_patterns', a:filename, [a:pattern])

  " args: funcname, outputname, filename pattern mark minlen maxfilename outputname
  let l:fileencoding = &fileencoding == '' ? &encoding : &fileencoding
  let l:argv = [
        \  'load_from_file', l:cache_name, a:filename, l:pattern_file_name, a:mark,
        \  g:neocomplcache_min_keyword_length, g:neocomplcache_max_filename_width, l:fileencoding
        \ ]
  return s:async_load(l:argv, a:cache_dir, a:filename)
endfunction"}}}
function! neocomplcache#cache#async_load_from_tags(cache_dir, filename, filetype, mark, is_create_tags)"{{{
  if !neocomplcache#cache#check_old_cache(a:cache_dir, a:filename)
    return neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  endif

  let l:cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  let l:pattern_file_name = neocomplcache#cache#encode_name('tags_pattens', a:filename)

  if a:is_create_tags
    if !executable(g:neocomplcache_ctags_program)
      echoerr 'Create tags error! Please install ' . g:neocomplcache_ctags_program . '.'
      return neocomplcache#cache#encode_name(a:cache_dir, a:filename)
    endif

    " Create tags file.
    let l:tags_file_name = neocomplcache#cache#encode_name('tags_output', a:filename)

    let l:args = has_key(g:neocomplcache_ctags_arguments_list, a:filetype) ?
          \ g:neocomplcache_ctags_arguments_list[a:filetype]
          \ : g:neocomplcache_ctags_arguments_list['default']

    if has('win32') || has('win64')
      let l:filename = substitute(a:filename, '\\', '/', 'g')
      let l:command = printf('%s -f "%s" %s "%s" ',
            \ g:neocomplcache_ctags_program, l:tags_file_name, l:args, l:filename)
    else
      let l:command = printf('%s -f ''%s'' 2>/dev/null %s ''%s''',
            \ g:neocomplcache_ctags_program, l:tags_file_name, l:args, a:filename)
    endif

    if neocomplcache#has_vimproc()
      call vimproc#system_bg(l:command)
    else
      call system(l:command)
    endif
  else
    let l:tags_file_name = '$dummy$'
  endif

  let l:filter_pattern =
        \ (a:filetype != '' && has_key(g:neocomplcache_tags_filter_patterns, a:filetype)) ?
        \ g:neocomplcache_tags_filter_patterns[a:filetype] : ''
  call neocomplcache#cache#writefile('tags_pattens', a:filename,
        \ [neocomplcache#get_keyword_pattern(), l:tags_file_name, l:filter_pattern, a:filetype])

  " args: funcname, outputname, filename filetype mark minlen maxfilename outputname
  let l:fileencoding = &fileencoding == '' ? &encoding : &fileencoding
  let l:argv = [
        \  'load_from_tags', l:cache_name, a:filename, l:pattern_file_name, a:mark,
        \  g:neocomplcache_min_keyword_length, g:neocomplcache_max_filename_width, l:fileencoding
        \ ]
  return s:async_load(l:argv, a:cache_dir, a:filename)
endfunction"}}}
function! s:async_load(argv, cache_dir, filename)"{{{
  let l:current = getcwd()
  lcd `=s:sdir`

  " if 0
  if neocomplcache#has_vimproc()
    let l:args = ['vim', '-u', 'NONE', '-i', 'NONE', '-n',
          \       '-N', '-S', 'async_cache.vim']
          \ + a:argv
    call vimproc#system_bg(l:args)
    " call vimproc#system(l:args)
    " call system(join(l:args))
  else
    call neocomplcache#async_cache#main(a:argv)
  endif

  lcd `=l:current`

  return neocomplcache#cache#encode_name(a:cache_dir, a:filename)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
