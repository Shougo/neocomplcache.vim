"=============================================================================
" FILE: cache.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 19 Sep 2011.
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

  for cache in a:async_cache_dictionary[a:key]
    " Check cache name.
    if filereadable(cache.cachename)
      " Caching.
      let a:keyword_list_dictionary[a:key] = {}

      let keyword_list = []
      for cache in a:async_cache_dictionary[a:key]
        let keyword_list += neocomplcache#cache#load_from_cache(a:cache_dir, cache.filename)
      endfor

      call neocomplcache#cache#list2index(
            \ keyword_list,
            \ a:keyword_list_dictionary[a:key],
            \ a:completion_length)

      " Delete from dictionary.
      call remove(a:async_cache_dictionary, a:key)

      return
    endif
  endfor
endfunction"}}}
function! neocomplcache#cache#load_from_cache(cache_dir, filename)"{{{
  let cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  if !filereadable(cache_name)
    return []
  endif

  try
    return map(map(readfile(cache_name), 'split(v:val, "|||", 1)'), '{
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
  let keyword_lists = {}

  for keyword in neocomplcache#cache#load_from_cache(a:cache_dir, a:filename)
    let key = tolower(keyword.word[: a:completion_length-1])
    if !has_key(keyword_lists, key)
      let keyword_lists[key] = []
    endif
    call add(keyword_lists[key], keyword)
  endfor

  return keyword_lists
endfunction"}}}
function! neocomplcache#cache#list2index(list, dictionary, completion_length)"{{{
  for keyword in a:list
    let key = tolower(keyword.word[: a:completion_length-1])
    if !has_key(a:dictionary, key)
      let a:dictionary[key] = {}
    endif
    let a:dictionary[key][keyword.word] = keyword
  endfor

  return a:dictionary
endfunction"}}}

function! neocomplcache#cache#save_cache(cache_dir, filename, keyword_list)"{{{
  " Create cache directory.
  let cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)

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
  let word_list = []
  for keyword in a:keyword_list
    call add(word_list, printf('%s|||%s|||%s|||%s',
          \keyword.word, keyword.abbr, keyword.menu, keyword.kind))
  endfor

  call writefile(word_list, cache_name)
endfunction"}}}

" Cache helper.
function! neocomplcache#cache#getfilename(cache_dir, filename)"{{{
  let cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  return cache_name
endfunction"}}}
function! neocomplcache#cache#filereadable(cache_dir, filename)"{{{
  let cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  return filereadable(cache_name)
endfunction"}}}
function! neocomplcache#cache#readfile(cache_dir, filename)"{{{
  let cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  return filereadable(cache_name) ? readfile(cache_name) : []
endfunction"}}}
function! neocomplcache#cache#writefile(cache_dir, filename, list)"{{{
  let cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)

  call writefile(a:list, cache_name)
endfunction"}}}
function! neocomplcache#cache#encode_name(cache_dir, filename)
  " Check cache directory.
  let cache_dir = g:neocomplcache_temporary_dir . '/' . a:cache_dir
  if !isdirectory(cache_dir)
    call mkdir(cache_dir, 'p')
  endif

  let dir = printf('%s/%s/', g:neocomplcache_temporary_dir, a:cache_dir)
  return dir . s:create_hash(dir, a:filename)
endfunction
function! neocomplcache#cache#check_old_cache(cache_dir, filename)"{{{
  " Check old cache file.
  let cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  let ret = getftime(cache_name) == -1 || getftime(cache_name) <= getftime(a:filename)
  if ret && filereadable(cache_name)
    " Delete old cache.
    call delete(cache_name)
  endif

  return ret
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
    let hash = substitute(substitute(a:str, ':', '=-', 'g'), '[/\\]', '=+', 'g')
  elseif s:exists_md5
    " Use md5.vim.
    let hash = md5#md5(a:str)
  else
    " Use simple hash.
    let sum = 0
    for i in range(len(a:str))
      let sum += char2nr(a:str[i]) * (i + 1)
    endfor

    let hash = printf('%x', sum)
  endif

  return hash
endfunction"}}}

let s:sdir = fnamemodify(expand('<sfile>'), ':p:h')

" Async test.
function! neocomplcache#cache#test_async()"{{{
  if !neocomplcache#cache#check_old_cache(a:cache_dir, a:filename)
    return neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  endif

  let filename = substitute(fnamemodify(expand('%'), ':p'), '\\', '/', 'g')
  let pattern_file_name = neocomplcache#cache#encode_name('keyword_patterns', 'vim')
  let cache_name = neocomplcache#cache#encode_name('test_cache', filename)

  " Create pattern file.
  call neocomplcache#cache#writefile('keyword_patterns', a:filename, [a:pattern])

  " args: funcname, outputname, filename pattern mark minlen maxfilename outputname
  let argv = [
        \  'load_from_file', cache_name, filename, pattern_file_name, '[B]',
        \  g:neocomplcache_min_keyword_length, g:neocomplcache_max_filename_width, &fileencoding
        \ ]
  return s:async_load(argv, 'test_cache', filename)
endfunction"}}}

function! neocomplcache#cache#async_load_from_file(cache_dir, filename, pattern, mark)"{{{
  if !neocomplcache#cache#check_old_cache(a:cache_dir, a:filename)
    return neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  endif

  let pattern_file_name = neocomplcache#cache#encode_name('keyword_patterns', a:filename)
  let cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)

  " Create pattern file.
  call neocomplcache#cache#writefile('keyword_patterns', a:filename, [a:pattern])

  " args: funcname, outputname, filename pattern mark minlen maxfilename outputname
  let fileencoding = &fileencoding == '' ? &encoding : &fileencoding
  let argv = [
        \  'load_from_file', cache_name, a:filename, pattern_file_name, a:mark,
        \  g:neocomplcache_min_keyword_length, g:neocomplcache_max_filename_width, fileencoding
        \ ]
  return s:async_load(argv, a:cache_dir, a:filename)
endfunction"}}}
function! neocomplcache#cache#async_load_from_tags(cache_dir, filename, filetype, mark, is_create_tags)"{{{
  if !neocomplcache#cache#check_old_cache(a:cache_dir, a:filename)
    return neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  endif

  let cache_name = neocomplcache#cache#encode_name(a:cache_dir, a:filename)
  let pattern_file_name = neocomplcache#cache#encode_name('tags_pattens', a:filename)

  if a:is_create_tags
    if !executable(g:neocomplcache_ctags_program)
      echoerr 'Create tags error! Please install ' . g:neocomplcache_ctags_program . '.'
      return neocomplcache#cache#encode_name(a:cache_dir, a:filename)
    endif

    " Create tags file.
    let tags_file_name = neocomplcache#cache#encode_name('tags_output', a:filename)

    let args = has_key(g:neocomplcache_ctags_arguments_list, a:filetype) ?
          \ g:neocomplcache_ctags_arguments_list[a:filetype]
          \ : g:neocomplcache_ctags_arguments_list['default']

    if has('win32') || has('win64')
      let filename = substitute(a:filename, '\\', '/', 'g')
      let command = printf('%s -f "%s" %s "%s" ',
            \ g:neocomplcache_ctags_program, tags_file_name, args, filename)
    else
      let command = printf('%s -f ''%s'' 2>/dev/null %s ''%s''',
            \ g:neocomplcache_ctags_program, tags_file_name, args, a:filename)
    endif

    if neocomplcache#has_vimproc()
      call vimproc#system_bg(command)
    else
      call system(command)
    endif
  else
    let tags_file_name = '$dummy$'
  endif

  let filter_pattern =
        \ (a:filetype != '' && has_key(g:neocomplcache_tags_filter_patterns, a:filetype)) ?
        \ g:neocomplcache_tags_filter_patterns[a:filetype] : ''
  call neocomplcache#cache#writefile('tags_pattens', a:filename,
        \ [neocomplcache#get_keyword_pattern(), tags_file_name, filter_pattern, a:filetype])

  " args: funcname, outputname, filename filetype mark minlen maxfilename outputname
  let fileencoding = &fileencoding == '' ? &encoding : &fileencoding
  let argv = [
        \  'load_from_tags', cache_name, a:filename, pattern_file_name, a:mark,
        \  g:neocomplcache_min_keyword_length, g:neocomplcache_max_filename_width, fileencoding
        \ ]
  return s:async_load(argv, a:cache_dir, a:filename)
endfunction"}}}
function! s:async_load(argv, cache_dir, filename)"{{{
  let current = getcwd()
  lcd `=s:sdir`

  " if 0
  if neocomplcache#has_vimproc()
    let args = ['vim', '-u', 'NONE', '-i', 'NONE', '-n',
          \       '-N', '-S', 'async_cache.vim']
          \ + a:argv
    call vimproc#system_bg(args)
    " call vimproc#system(args)
    " call system(join(args))
  else
    call neocomplcache#async_cache#main(a:argv)
  endif

  lcd `=current`

  return neocomplcache#cache#encode_name(a:cache_dir, a:filename)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
