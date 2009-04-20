"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 19 Apr 2009
" Usage: Just source this file.
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
" Version: 2.32, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
" ChangeLog NeoCompleCache2: "{{{
"   2.32:
"     - Implemented variable cache line.
"     - Don't complete '/cygdrive/'.
"   2.31:
"     - Optimized caching.
"     - Improved html omni syntax.
"     - Changed g:NeoComplCache_MaxInfoList default value.
"     - Try empty keyword completion if candidate is empty in manual complete.
"     - Delete candidate from source if rank is low.
"     - Disable filename completion in tex filetype.
"   2.30:
"     - Deleted MFU.
"     - Optimized match.
"     - Fixed cpp keyword bugs.
"     - Improved snippets_complete.
"   2.29:
"     - Improved plugin interface.
"     - Refactoring.
"   2.28:
"     - Improved autocmd.
"     - Fixed delete source bug when g:NeoComplCache_EnableMFU is set.
"     - Implemented snippets_complete.
"     - Optimized abbr.
"   2.27:
"     - Improved filtering.
"     - Supported actionscript.
"     - Improved syntax.
"     - Added caching percent support.
"   2.26:
"     - Improved ruby and vim and html syntax.
"     - Fixed escape.
"     - Supported erlang and eruby and etc.
"     - Refactoring autocmd.
"   2.25:
"     - Optimized syntax caching.
"     - Fixed ruby and ocaml syntax.
"     - Fixed error when g:NeoComplCache_AlphabeticalOrder is set.
"     - Improved syntax_complete caching event.
"   2.24:
"     - Optimized calc rank.
"     - Optimized keyword pattern.
"     - Implemented operator completion.
"     - Don't use include completion.
"     - Fixed next keyword bug.
"   2.23:
"     - Fixed compound keyword pattern.
"     - Optimized keyword pattern.
"     - Fixed can't quick match bug on g:NeoComplCache_EnableCamelCaseCompletion is 1.
"   2.22:
"     - Improved tex syntax.
"     - Improved keyword completion.
"     - Fixed sequential caching bug.
"   2.21:
"     - Fixed haskell and ocaml and perl syntax.
"     - Fixed g:NeoComplCache_EnableCamelCaseCompletion default value.
"     - Extend skip time.
"     - Added NeoCompleCacheAutoCompletionLength and NeoCompleCachePartialCompletionLength command.
"     - Fixed extend complete length bug.
"     - Improved camel case completion.
"   2.20:
"     - Improved dictionary check.
"     - Fixed manual complete wildcard bug.
"     - Fixed assuming filetype bug.
"     - Implemented camel case completion.
"     - Improved filetype and filename check.
"   2.19:
"     - Plugin interface changed.
"     - Patterns use very magic.
"     - Fixed syntax_complete.
"   2.18:
"     - Implemented tags_complete plugin.
"     - Fixed default completion bug.
"     - Extend complete length when consecutive skipped.
"     - Auto complete on CursorMovedI.
"     - Deleted similar match.
"   2.17:
"     - Loadable autoload/neocomplcache/*.vim plugin.
"     - Implemented syntax_complete plugin.
"   2.16:
"     - Fixed caching initialize bug.
"     - Supported vim help file.
"     - Created manual.
"     - Fixed variables name.
"     - Deleted g:NeoComplCache_CalcRankMaxLists option.
"   2.15:
"     - Improved C syntax.
"     - Added g:NeoComplCache_MaxTryKeywordLength option.
"     - Improved prev rank.
"     - Optimized if keyword is empty.
"   2.14:
"     - Optimized calc rank.
"   2.13:
"     - Optimized caching.
"     - Optimized calc rank.
"     - Fixed calc rank bugs.
"     - Optimized similar match.
"     - Fixed dictionary bug.
"   2.12:
"     - Added g:NeoComplCache_CachingRandomize option.
"     - Changed g:NeoComplCache_CacheLineCount default value.
"     - Optimized caching.
"     - Caching current cache line on idle.
"     - Fixed key not present error.
"     - Fixed caching bug.
"   2.11:
"     - Implemented prev_rank.
"     - Fixed disable auto complete bug.
"     - Changed g:NeoComplCache_MinKeywordLength default value.
"     - Changed g:NeoComplCache_CacheLineCount default value.
"     - Fixed MFU.
"     - Optimized calc rank.
"     - Fixed freeze bug when InsertEnter and InsertLeave.
"   2.10:
"     - Divided as plugin.
"     - NeoCompleCacheToggle uses lock() and unlock()
"     - Abbreviation indication of the end.
"     - Don't load MFU when MFU is empty.
"     - Changed g:AltAutoComplPop_EnableAsterisk into g:NeoComplCache_EnableWildCard.
"     - Added wildcard '-'.
"     - Fixed key not present error.
"   2.02:
"     - Supported compound filetype.
"     - Disable partial match when skipped.
"     - Fixed wildcard bug.
"     - Optimized info.
"     - Added g:NeoComplCache_EnableInfo option.
"     - Disable try keyword completion when wildcard.
"   2.01:
"     - Caching on InsertLeave.
"     - Changed g:Neocomplcache_CacheLineCount default value.
"     - Fixed update tags bug.
"     - Enable asterisk when cursor_word is (, $, #, @, ...
"     - Improved wildcard.
"   2.00:
"     - Save keyword found line.
"     - Changed g:Neocomplcache_CacheLineCount default value.
"     - Fixed skipped bug.
"     - Improved commands.
"     - Deleted g:NeoComplCache_DrawWordsRank option.
"     "}}}
" ChangeLog NeoCompleCache: "{{{
"   1.60:
"     - Improved calc similar algorithm.
"   1.59:
"     - Improved NeoCompleCacheSetBufferDictionary.
"     - Fixed MFU bug.
"     - Don't try keyword completion when input non word character.
"   1.58:
"     - Fixed s:SetOmniPattern() and s:SetKeywordPattern() bugs.
"     - Changed g:NeoComplCache_MinKeywordLength default value.
"     - Implemented same filetype completion.
"   1.57:
"     - Deleted g:NeoComplCache_FirstHeadMatching option. 
"     - Deleted prev_rank.
"     - Implemented 3-gram completion.
"     - Fixed MFU bug.
"   1.56:
"     - Use vim commands completion in vim filetype.
"   1.55:
"     - Implemented NeoCompleCacheCreateTags command.
"     - Fixed tags auto update bug.
"     - Added g:NeoComplCache_TryKeywordCompletion option.
"   1.54:
"     - Added tags syntax keyword.
"     - Implemented local tags.
"     - Implemented local tags auto update.
"     - Fixed s:prepre_numbered_list bug.
"   1.53:
"     - Disable similar completion when auto complete.
"     - Calc rank when NeoComplCacheCachingBuffer command.
"     - Added NeoCompleCacheOutputKeyword command.
"   1.52:
"     - Fixed syntax keyword bug.
"     - Improved syntax keyword.
"     - Implemented similar completion.
"   1.51:
"     - Added g:NeoComplCache_PartialCompletionStartLength option.
"     - Fixed syntax keyword bug.
"   1.50:
"     - Deleted g:NeoComplCache_CompleteFuncLists.
"     - Set filetype 'nothing' if filetype is empty.
"     - Implemented omni completion.
"     - Added debug command.
"     - Improved syntax keyword.
"   1.49:
"     - Fixed g:NeoComplCache_MFUDirectory error.
"     - Changed g:NeoComplCache_KeywordPatterns['default'] value.
"   1.48:
"     - Implemented NeoCompleCacheSetBufferDictionary command.
"     - Implemented 2-gram MFU.
"     - Improved syntax completion.
"     - Fixed "complete from same filetype buffer" bug.
"   1.47:
"     - Implemented 2-gram completion.
"     - Improved ruby keyword.
"   1.46:
"     - Complete from same filetype buffer.
"   1.45:
"     - Fixed g:NeoComplCache_MFUDirectory bug.
"     - Improved syntax keyword.
"     - Deleted g:NeoComplCache_FirstCurrentBufferWords option.
"     - Implemented previous keyword completion.
"   1.44:
"     - Improved most frequently used dictionary.
"     - Improved if bufname changed.
"     - Restore wildcard substitution '.\+' into '.*'.
"     - Fixed next keyword completion bug.
"   1.43:
"     - Refactoring when caching source.
"     - Initialize source if bufname changed.
"     - Implemented most frequently used dictionary.
"   1.42:
"     - Caching when InsertLeave event.
"     - Changed g:NeoComplCache_CacheLineCount value.
"     - Changed wildcard substitution '.*' into '.\+'.
"     - Allow word's tail '*' if g:NeoComplCache_EnableAsterisk.
"     - Allow word's head '*' on lisp.
"     - Allow word's head '&' on perl.
"     - Optimized global options definition.
"   1.41:
"     - Added g:NeoComplCache_SmartCase option.
"     - Optimized on completion and caching.
"     - Fixed g:NeoComplCache_ManualCompleteFunc bug.
"   1.40:
"     - Fixed freeze bug when many - inputed.
"     - Improved next keyword completion.
"     - Improved caching.
"     - Fixed next keyword completion bug.
"   1.39:
"     - Fixed filename completion bug.
"     - Fixed dup bug.
"     - Implemented next keyword completion.
"   1.38:
"     - Fixed PHP completion bug.
"     - Improved filetype detection.
"     - Added space between keyword and file name.
"     - Implemented randomize rank calculation.
"     - Added g:NeoComplCache_CalcRankRandomize option.
"   1.37:
"     - Improved file complete.
"     - Fixed file complete bug.
"   1.36:
"     - Added g:NeoComplCache_FirstHeadMatching option.
"     - Fixed list order bug.
"     - Changed g:NeoComplCache_QuickMatchMaxLists default value.
"     - Optimized when buffer renamed.
"   1.35:
"     - Improved syntax complete.
"     - Improved NeoCompleCacheToggle.
"   1.34:
"     - Fixed g:NeoComplCache_FirstCurrentBufferWords bug.
"     - Fixed quick match bug.
"     - Not change lazyredraw.
"   1.33:
"     - Added g:NeoComplCache_QuickMatchMaxLists option.
"     - Changed g:NeoComplCache_QuickMatch into g:NeoComplCache_QuickMatchEnable.
"     - Implemented two digits quick match.
"   1.32:
"     - Improved completion cancel.
"     - Improved syntax keyword vim, sh, zsh, vimshell.
"     - Implemented g:NeoComplCache_NonBufferFileTypeDetect option.
"   1.31:
"     - Added g:NeoComplCache_MinKeywordLength option.
"     - Caching keyword_pattern.
"     - Fixed current buffer filtering bug.
"     - Fixed rank calculation bug.
"     - Optimized keyword caching.
"     - Fixed lazyredraw bug.
"   1.30:
"     - Added NeoCompleCachingTags, NeoCompleCacheDictionary command.
"     - Renamed NeoCompleCachingBuffer command.
"   1.29:
"     - Added NeoCompleCacheLock, NeoCompleCacheUnlock command.
"     - Dup check when quick match.
"     - Fixed error when manual complete.
"   1.28:
"     - Improved filetype detection.
"     - Changed g:NeoComplCache_MaxFilenameWidth default value.
"     - Improved list.
"   1.27:
"     - Improved syntax keyword.
"     - Improved calc rank timing.
"     - Fixed keyword filtering bug.
"   1.26:
"     - Ignore if dictionary file doesn't exists.
"     - Due to optimize, filtering len(cur_keyword_str) >.
"     - Auto complete when InsertEnter.
"   1.25:
"     - Exclude cur_keyword_str from keyword lists.
"   1.24:
"     - Due to optimize, filtering len(cur_keyword_str) >=.
"     - Fixed buffer dictionary bug.
"   1.23:
"     - Fixed on lazyredraw bug.
"     - Optimized when no dictionary and tags.
"     - Not echo calculation time.
"   1.22:
"     - Optimized source.
"   1.21:
"     - Fixed overwrite completefunc bug.
"   1.20:
"     - Implemented buffer dictionary.
"   1.10:
"     - Implemented customizable complete function.
"   1.00:
"     - Renamed.
"     - Initial version.
"     "}}}
" ChangeLog AltAutoComplPop: "{{{
"   2.62:
"     - Set lazyredraw at auto complete.
"     - Added g:AltAutoComplPop_CalcRankMaxLists option.
"     - Improved calc rank timing.
"     - Improved filetype check.
"   2.61:
"     - Improved keyword patterns.
"     - Changed g:AltAutoComplPop_CacheLineCount default value.
"     - Implemented :Neco command.
"   2.60:
"     - Cleanuped code.
"     - Show '[T]' or '[D]' at completing.
"     - Implemented tab pages tags completion.
"     - Fixed error when tab created.
"     - Changed g:AltAutoComplPop_CalcRankCount default value.
"   2.50:
"     - Implemented filetype dictionary completion.
"   2.14:
"     - Fixed 'Undefined Variable: s:cur_keyword_pos' bug.
"     - Implemented tags completion.
"   2.13:
"     - Added g:AltAutoComplPop_DictionaryLists option.
"     - Implemented dictionary completion.
"   2.12:
"     - Added g:AltAutoComplPop_CalcRankCount option.
"   2.11:
"     - Added g:AltAutoComplPop_SlowCompleteSkip option.
"     - Removed g:AltAutoComplPop_OptimiseLevel option.
"   2.10:
"     - Added g:AltAutoComplPop_QuickMatch option.
"     - Changed g:AltAutoComplPop_MaxList default value.
"     - Don't cache help file.
"   2.09:
"     - Added g:AltAutoComplPop_EnableAsterisk option.
"     - Fixed next cache line cleared bug.
"   2.08:
"     - Added g:AltAutoComplPop_OptimiseLevel option.
"       If list has many keyword, will optimise complete. 
"     - Added g:AltAutoComplPop_DisableAutoComplete option.
"   2.07:
"     - Fixed caching miss when BufRead.
"   2.06:
"     - Improved and customizable keyword patterns.
"   2.05:
"     - Added g:AltAutoComplPop_DeleteRank0 option.
"     - Implemented lazy caching.
"     - Cleanuped code.
"   2.04:
"     - Fixed caching bug.
"   2.03:
"     - Fixed rank calculation bug.
"   2.02:
"     - Fixed GVim problem at ATOK X3
"   2.01:
"     - Fixed rank calculation bug.
"     - Faster at caching.
"   2.0:
"     - Implemented Updates current buffer cache at InsertEnter.
"   1.13:
"     - Licence changed.
"     - Fix many bugs.
"   1.1:
"     - Implemented smart completion.
"       It works in vim, c, cpp, ruby, ...
"     - Implemented file completion.
"   1.0:
"     - Initial version.
""}}}
" }}}
"-----------------------------------------------------------------------------
" TODO: "{{{
"     - Nothing.
""}}}
" Bugs"{{{
"     - Nothing.
""}}}
"=============================================================================

if exists('g:loaded_neocomplcache') || v:version < 700
  finish
endif

command! -nargs=0 NeoCompleCacheEnable call neocomplcache#enable()
command! -nargs=0 NeoCompleCacheDisable call neocomplcache#disable()
command! -nargs=0 NeoCompleCacheToggle call neocomplcache#toggle()

" Global options definition."{{{
if !exists('g:NeoComplCache_MaxList')
    let g:NeoComplCache_MaxList = 100
endif
if !exists('g:NeoComplCache_MaxKeywordWidth')
    let g:NeoComplCache_MaxKeywordWidth = 50
endif
if !exists('g:NeoComplCache_MaxFilenameWidth')
    let g:NeoComplCache_MaxFilenameWidth = 15
endif
if !exists('g:NeoComplCache_PartialMatch')
    let g:NeoComplCache_PartialMatch = 1
endif
if !exists('g:NeoComplCache_KeywordCompletionStartLength')
    let g:NeoComplCache_KeywordCompletionStartLength = 2
endif
if !exists('g:NeoComplCache_PartialCompletionStartLength')
    let g:NeoComplCache_PartialCompletionStartLength = 3
endif
if !exists('g:NeoComplCache_MinKeywordLength')
    let g:NeoComplCache_MinKeywordLength = 4
endif
if !exists('g:NeoComplCache_IgnoreCase')
    let g:NeoComplCache_IgnoreCase = 1
endif
if !exists('g:NeoComplCache_SmartCase')
    let g:NeoComplCache_SmartCase = 0
endif
if !exists('g:NeoComplCache_AlphabeticalOrder')
    let g:NeoComplCache_AlphabeticalOrder = 0
endif
if !exists('g:NeoComplCache_CacheLineCount')
    let g:NeoComplCache_CacheLineCount = 70
endif
if !exists('g:NeoComplCache_DeleteRank0')
    let g:NeoComplCache_DeleteRank0 = 0
endif
if !exists('g:NeoComplCache_DisableAutoComplete')
    let g:NeoComplCache_DisableAutoComplete = 0
endif
if !exists('g:NeoComplCache_EnableWildCard')
    let g:NeoComplCache_EnableWildCard = 1
endif
if !exists('g:NeoComplCache_EnableQuickMatch')
    let g:NeoComplCache_EnableQuickMatch = 1
endif
if !exists('g:NeoComplCache_CalcRankRandomize')
    let g:NeoComplCache_CalcRankRandomize = has('reltime')
endif
if !exists('g:NeoComplCache_QuickMatchMaxLists')
    let g:NeoComplCache_QuickMatchMaxLists = 100
endif
if !exists('g:NeoComplCache_SlowCompleteSkip')
    let g:NeoComplCache_SlowCompleteSkip = has('reltime')
endif
if !exists('g:NeoComplCache_PreviousKeywordCompletion')
    let g:NeoComplCache_PreviousKeywordCompletion = 0
endif
if !exists('g:NeoComplCache_TagsAutoUpdate')
    let g:NeoComplCache_TagsAutoUpdate = 0
endif
if !exists('g:NeoComplCache_TryKeywordCompletion')
    let g:NeoComplCache_TryKeywordCompletion = 0
endif
if !exists('g:NeoComplCache_TryDefaultCompletion')
    let g:NeoComplCache_TryDefaultCompletion = 0
endif
if !exists('g:NeoComplCache_MaxTryKeywordLength')
    let g:NeoComplCache_MaxTryKeywordLength = 5
endif
if !exists('g:NeoComplCache_EnableInfo')
    let g:NeoComplCache_EnableInfo = 0
endif
if !exists('g:NeoComplCache_MaxInfoList')
    let g:NeoComplCache_MaxInfoList = 1
endif
if !exists('g:NeoComplCache_CachingRandomize')
    let g:NeoComplCache_CachingRandomize = has('reltime')
endif
if !exists('g:NeoComplCache_EnableCamelCaseCompletion')
    let g:NeoComplCache_EnableCamelCaseCompletion = 0
endif
if exists('g:NeoComplCache_EnableAtStartup') && g:NeoComplCache_EnableAtStartup
    " Enable startup.
    call neocomplcache#enable()
endif"}}}

let g:loaded_neocomplcache = 1

" vim: foldmethod=marker
