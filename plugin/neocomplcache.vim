"=============================================================================
" FILE: neocomplcache.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 28 Aug 2009
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
" Version: 2.73, for Vim 7.0
"-----------------------------------------------------------------------------
" ChangeLog: "{{{
" ChangeLog NeoComplCache2: "{{{
"   2.73:
"    - Improved manual completion.
"    - Fixed error in manual omni completion when omnifunc is empty.
"    - Improved filename completion.
"    - Improved check candidate.
"    - Improved omni completion.
"    - Fixed dup bug in snippets_complete.
"
"   2.72:
"    - Improved quickmatch behaivior.
"    - Fixed expand() bug in snippets_complete.
"    - Fixed prefix bug in filename completion.
"    - Improved filename completion.
"    - Substitute $HOME into '~' in filename completion.
"    - Dispay 'cdpath' files in filename completion.
"    - Dispay 'w:vimshell_directory_stack' files in filename completion.
"
"   2.71:
"    - Create g:NeoComplCache_TemporaryDir directory if not exists.
"    - Create g:NeoComplCache_SnippetsDir directory if not exists.
"    - Implemented direct expantion in snippet complete.
"    - Implemented snippet alias in snippet complete.
"    - Added g:NeoComplCache_PluginCompletionLength option.
"    - Improved get cursour word.
"    - Added Objective-C/C++ support.
"    - Fixed filename completion bug when environment variable used.
"    - Improved skipped behaivior.
"    - Implemented short filename completion.
"    - Check cdpath in filename completion.
"    - Fixed expand jump bug in snippets completion.
"
"   2.70:
"    - Improved omni completion.
"    - Display readonly files.
"    - Fixed filename completion bug.
"    - No ignorecase in next keyword completion.
"
"   2.69: - Improved quick match.
"    - Fixed html omni completion error.
"    - Improved html omni completion pattern.
"    - Improved g:NeoComplCache_CtagsArgumentsList in vim filetype.
"    - Delete quick match cache when BufWinEnter.
"    - Convert string omni completion.
"
"   2.68:
"    - Improved quick match in filename completion.
"    - Deleted g:NeoComplCache_FilenameCompletionSkipItems option.
"    - Search quick match if no keyword match.
"    - Fixed manual_complete wildcard bug.
"    - Caching from cache in syntax_complete.
"    - Added NeoComplCacheCachingSyntax command.
"
"   2.67:
"    - Fixed snippet without default value expand bug.
"    - Added snippet file snippet.
"    - Improved keyword pattern.
"    - Insert quickmatched candidate immediately.
"    - The quick match input does not make a cash.
"
"   2.66:
"    - Improved manual.
"    - Fixed snippet expand bugs.
"    - Caching snippets when file open.
"    - g:NeoComplCache_SnippetsDir is comma-separated list.
"    - Supported escape sequence in filename completion.
"    - Improved set complete function timing.
"
"   2.65:
"    - Deleted wildcard from filename completion.
"    - Fixed ATOK X3 on when snippets expanded.
"    - Fixed syntax match timing(Thanks thinca!).
"    - Improved vimshell keyword pattern.
"    - Added snippet delete.
"    - Added English manual.
"
"   2.64:
"    - Substitute \ -> / in Windows.
"    - Improved NeoComplCacheCachingBuffer command.
"    - Added g:NeoComplCache_CachingLimitFileSize option.
"    - Added g:NeoComplCache_CachingDisablePattern option.
"    - Don't caching readonly file.
"    - Improved neocomplcache#keyword_complete#caching_percent.
"
"   2.63:
"    - Substitute ... -> ../.. .
"    - Changed short filename into ~.
"    - Improved filename completion.
"    - Callable get_complete_words() and word_caching_current_line() function.
"    - Erb is same filetype with ruby.
"    - Improved html and erb filetype.
"    - Improved erb snippets.
"    - Improved css omni completion.
"    - Improved vimshell keyword pattern.
"
"   2.62:
"    - Added make syntax.
"    - Put up the priority of directory in filename completion.
"    - Draw executable files in filename completion.
"    - Added g:NeoComplCache_FilenameCompletionSkipItems option.
"    - Fixed filename completion bug on enable quick match.
"
"   2.61:
"    - Fixed ATOK X3 on when snippets expanded.
"    - Improved vimshell syntax.
"    - Improved skip completion.
"
"   2.60: Improved filename completion.
"    - Improved long filename view.
"    - Improved filtering.
"    - Fixed keyword sort bug.
"
"   2.59: Fixed caching bug.
"
"   2.58: Improved caching timing.
"    - Optimized caching.
"
"   2.57: Improved snippets_complete.
"    - Fixed feedkeys.
"    - Improved skip completion.
"    - Changed g:NeoComplCache_PartialCompletionStartLength default value.
"    - Improved camel case completion and underbar completion.
"    - Fixed add rank bug in snippet completion.
"    - Loadable snipMate snippets file in snippet completion.
"    - Implemented _ snippets in snippet completion.
"
"   2.56: Implemented filename completion.
"    - Don't caching when not buflisted in syntax complete.
"    - Implemented neocomplcache#manual_filename_complete().
"    - Improved filename toriming.
"    - Fixed E220 in tex filetype.
"    - Improved edit snippet.
"
"   2.55: Output cache file.
"    - Added g:NeoComplCache_TemporaryDir option.
"    - Improved garbage collect.
"
"   2.52: Fixed bugs.
"    - Changed g:NeoComplCache_PreviousKeywordCompletion default value.
"    - Fixed NeoComplCacheDisable bug.
"    - Fixed neocomplcache#keyword_complete#caching_percent() bug.
"    - Fixed analyze caching bug.
"    - Fixed quick match.
"    - Improved wildcard.
"
"   2.51: Optimized dictionary and fixed bug.
"    - Deleted g:NeoComplCache_MaxTryKeywordLength options.
"    - Deleted NeoComplCacheCachingDictionary command.
"    - Improved caching echo.
"    - Optimized calc rank.
"    - Fixed abbr_save error.
"    - Don't caching on BufEnter.
"    - Optimized manual_complete behaivior.
"    - Added g:NeoComplCache_ManualCompletionStartLength option.
"    - Fixed next keyword completion bug.
"    - Fixed caching initialize bug.
"    - Fixed on InsertLeave error.
"
"   2.50: Caching on editing file.
"    - Optimized NeoComplCacheCachingBuffer.
"    - Implemented neocomplcache#close_popup() and neocomplcache#cancel_popup().
"    - Fixed ignore case behaivior.
"    - Fixed escape error.
"    - Improved caching.
"    - Deleted g:NeoComplCache_TryKeywordCompletion and g:NeoComplCache_TryDefaultCompletion options.
"    - Deleted g:NeoComplCache_MaxInfoList and g:NeoComplCache_DeleteRank0 option.
"    - Don't save info in keyword completion.
"
"   2.44: Improved popup menu in tags completion.
"    - Improved popup menu in tags completion.
"    - Fixed escape error.
"    - Fixed help.
"
"   2.43: Improved wildcard.
"    - Improved wildcard.
"    - Changed 'abbr_save' into 'abbr'.
"    - Fixed :NeoComplCacheCachingBuffer bug.
"
"   2.42:
"    - Call completefunc when original completefunc.
"    - Added g:NeoComplCache_TryFilenameCompletion option.
"    - Fixed g:NeoComplCache_TryKeywordCompletion bug.
"    - Fixed menu padding.
"    - Fixed caching error.
"    - Implemented underbar completion.
"    - Added g:NeoComplCache_EnableUnderbarCompletion option.
"
"   2.41:
"    - Improved empty check.
"    - Fixed eval bug in snippet complete.
"    - Fixed include bug in snippet complete.
"
"   2.40:
"    - Optimized caching in small files.
"    - Deleted buffer dictionary.
"    - Display cached from buffer.
"    - Changed g:NeoComplCache_MaxInfoList default value.
"    - Improved calc rank.
"    - Improved caching timing.
"    - Added NeoComplCacheCachingDisable and g:NeoComplCacheCachingEnable commands.
"    - Fixed commentout bug in snippet complete.
"
"   2.39:
"    - Fixed syntax highlight.
"    - Overwrite snippet if name is same.
"    - Caching on InsertLeave.
"    - Manual completion add wildcard when input non alphabetical character.
"    - Fixed menu error in syntax complete.
"
"   2.38:
"    - Fixed typo.
"    - Optimized caching.
"
"   2.37:
"    - Added g:NeoComplCache_SkipCompletionTime option.
"    - Added g:NeoComplCache_SkipInputTime option.
"    - Changed g:NeoComplCache_SlowCompleteSkip option into g:NeoComplCache_EnableSkipCompletion.
"    - Improved ruby omni pattern.
"    - Optimized syntax complete.
"    - Delete command abbreviations in vim filetype.
"
"   2.36:
"    - Implemented snipMate like snippet.
"    - Added syntax file.
"    - Detect snippet file.
"    - Fixed default value selection bug.
"    - Fixed ignorecase.
"
"   2.35:
"    - Fixed NeoComplCacheDisable bug.
"    - Implemented <Plug>(neocomplcache_keyword_caching) keymapping.
"    - Improved operator completion.
"    - Added syntax highlight.
"    - Implemented g:NeoComplCache_SnippetsDir.
"
"   2.34:
"    - Increment rank when snippet expanded.
"    - Use selection.
"    - Fixed place holder's default value bug.
"    - Added g:NeoComplCache_MinSyntaxLength option.
"
"   2.33:
"    - Implemented <Plug>(neocomplcache_snippets_expand) keymapping.
"    - Implemented place holder.
"    - Improved place holder's default value behaivior.
"    - Enable filename completion in lisp filetype.
"
"   2.32:
"     - Implemented variable cache line.
"     - Don't complete '/cygdrive/'.
"     - Fixed popup preview window bug if g:NeoComplCache_EnableInfo is 0.
"
"   2.31:
"     - Optimized caching.
"     - Improved html omni syntax.
"     - Changed g:NeoComplCache_MaxInfoList default value.
"     - Try empty keyword completion if candidate is empty in manual complete.
"     - Delete candidate from source if rank is low.
"     - Disable filename completion in tex filetype.
"
"   2.30:
"     - Deleted MFU.
"     - Optimized match.
"     - Fixed cpp keyword bugs.
"     - Improved snippets_complete.
"
"   2.29:
"     - Improved plugin interface.
"     - Refactoring.
"
"   2.28:
"     - Improved autocmd.
"     - Fixed delete source bug when g:NeoComplCache_EnableMFU is set.
"     - Implemented snippets_complete.
"     - Optimized abbr.
"
"   2.27:
"     - Improved filtering.
"     - Supported actionscript.
"     - Improved syntax.
"     - Added caching percent support.
"
"   2.26:
"     - Improved ruby and vim and html syntax.
"     - Fixed escape.
"     - Supported erlang and eruby and etc.
"     - Refactoring autocmd.
"
"   2.25:
"     - Optimized syntax caching.
"     - Fixed ruby and ocaml syntax.
"     - Fixed error when g:NeoComplCache_AlphabeticalOrder is set.
"     - Improved syntax_complete caching event.
"
"   2.24:
"     - Optimized calc rank.
"     - Optimized keyword pattern.
"     - Implemented operator completion.
"     - Don't use include completion.
"     - Fixed next keyword bug.
"
"   2.23:
"     - Fixed compound keyword pattern.
"     - Optimized keyword pattern.
"     - Fixed can't quick match bug on g:NeoComplCache_EnableCamelCaseCompletion is 1.
"
"   2.22:
"     - Improved tex syntax.
"     - Improved keyword completion.
"     - Fixed sequential caching bug.
"
"   2.21:
"     - Fixed haskell and ocaml and perl syntax.
"     - Fixed g:NeoComplCache_EnableCamelCaseCompletion default value.
"     - Extend skip time.
"     - Added NeoComplCacheAutoCompletionLength and NeoComplCachePartialCompletionLength command.
"     - Fixed extend complete length bug.
"     - Improved camel case completion.
"
"   2.20:
"     - Improved dictionary check.
"     - Fixed manual complete wildcard bug.
"     - Fixed assuming filetype bug.
"     - Implemented camel case completion.
"     - Improved filetype and filename check.
"
"   2.19:
"     - Plugin interface changed.
"     - Patterns use very magic.
"     - Fixed syntax_complete.
"
"   2.18:
"     - Implemented tags_complete plugin.
"     - Fixed default completion bug.
"     - Extend complete length when consecutive skipped.
"     - Auto complete on CursorMovedI.
"     - Deleted similar match.
"
"   2.17:
"     - Loadable autoload/neocomplcache/*.vim plugin.
"     - Implemented syntax_complete plugin.
"
"   2.16:
"     - Fixed caching initialize bug.
"     - Supported vim help file.
"     - Created manual.
"     - Fixed variables name.
"     - Deleted g:NeoComplCache_CalcRankMaxLists option.
"
"   2.15:
"     - Improved C syntax.
"     - Added g:NeoComplCache_MaxTryKeywordLength option.
"     - Improved prev rank.
"     - Optimized if keyword is empty.
"
"   2.14:
"     - Optimized calc rank.
"
"   2.13:
"     - Optimized caching.
"     - Optimized calc rank.
"     - Fixed calc rank bugs.
"     - Optimized similar match.
"     - Fixed dictionary bug.
"
"   2.12:
"     - Added g:NeoComplCache_CachingRandomize option.
"     - Changed g:NeoComplCache_CacheLineCount default value.
"     - Optimized caching.
"     - Caching current cache line on idle.
"     - Fixed key not present error.
"     - Fixed caching bug.
"
"   2.11:
"     - Implemented prev_rank.
"     - Fixed disable auto complete bug.
"     - Changed g:NeoComplCache_MinKeywordLength default value.
"     - Changed g:NeoComplCache_CacheLineCount default value.
"     - Fixed MFU.
"     - Optimized calc rank.
"     - Fixed freeze bug when InsertEnter and InsertLeave.
"
"   2.10:
"     - Divided as plugin.
"     - NeoComplCacheToggle uses lock() and unlock()
"     - Abbreviation indication of the end.
"     - Don't load MFU when MFU is empty.
"     - Changed g:AltAutoComplPop_EnableAsterisk into g:NeoComplCache_EnableWildCard.
"     - Added wildcard '-'.
"     - Fixed key not present error.
"
"   2.02:
"     - Supported compound filetype.
"     - Disable partial match when skipped.
"     - Fixed wildcard bug.
"     - Optimized info.
"     - Added g:NeoComplCache_EnableInfo option.
"     - Disable try keyword completion when wildcard.
"
"   2.01:
"     - Caching on InsertLeave.
"     - Changed g:Neocomplcache_CacheLineCount default value.
"     - Fixed update tags bug.
"     - Enable asterisk when cursor_word is (, $, #, @, ...
"     - Improved wildcard.
"
"   2.00:
"     - Save keyword found line.
"     - Changed g:Neocomplcache_CacheLineCount default value.
"     - Fixed skipped bug.
"     - Improved commands.
"     - Deleted g:NeoComplCache_DrawWordsRank option.
"     "}}}
" ChangeLog NeoComplCache: "{{{
"   1.60:
"     - Improved calc similar algorithm.
"   1.59:
"     - Improved NeoComplCacheSetBufferDictionary.
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
"     - Implemented NeoComplCacheCreateTags command.
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
"     - Added NeoComplCacheOutputKeyword command.
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
"     - Implemented NeoComplCacheSetBufferDictionary command.
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
"     - Improved NeoComplCacheToggle.
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
"     - Added NeoCompleCachingTags, NeoComplCacheDictionary command.
"     - Renamed NeoCompleCachingBuffer command.
"   1.29:
"     - Added NeoComplCacheLock, NeoComplCacheUnlock command.
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

command! -nargs=0 NeoComplCacheEnable call neocomplcache#enable()
command! -nargs=0 NeoComplCacheToggle call neocomplcache#toggle()

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
if !exists('g:NeoComplCache_ManualCompletionStartLength')
    let g:NeoComplCache_ManualCompletionStartLength = 2
endif
if !exists('g:NeoComplCache_PartialCompletionStartLength')
    let g:NeoComplCache_PartialCompletionStartLength = 4
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
if !exists('g:NeoComplCache_EnableSkipCompletion')
    let g:NeoComplCache_EnableSkipCompletion = has('reltime')
endif
if !exists('g:NeoComplCache_SkipCompletionTime')
    let g:NeoComplCache_SkipCompletionTime = '0.2'
endif
if !exists('g:NeoComplCache_SkipInputTime')
    let g:NeoComplCache_SkipInputTime = '0.0'
endif
if !exists('g:NeoComplCache_PreviousKeywordCompletion')
    let g:NeoComplCache_PreviousKeywordCompletion = 1
endif
if !exists('g:NeoComplCache_TagsAutoUpdate')
    let g:NeoComplCache_TagsAutoUpdate = 0
endif
if !exists('g:NeoComplCache_TryFilenameCompletion')
    let g:NeoComplCache_TryFilenameCompletion = 1
endif
if !exists('g:NeoComplCache_EnableInfo')
    let g:NeoComplCache_EnableInfo = 0
endif
if !exists('g:NeoComplCache_CachingRandomize')
    let g:NeoComplCache_CachingRandomize = has('reltime')
endif
if !exists('g:NeoComplCache_EnableCamelCaseCompletion')
    let g:NeoComplCache_EnableCamelCaseCompletion = 0
endif
if !exists('g:NeoComplCache_EnableUnderbarCompletion')
    let g:NeoComplCache_EnableUnderbarCompletion = 0
endif
if !exists('g:NeoComplCache_CachingLimitFileSize')
    let g:NeoComplCache_CachingLimitFileSize = 1000000
endif
if !exists('g:NeoComplCache_CachingDisablePattern')
    let g:NeoComplCache_CachingDisablePattern = ''
endif
if !exists('g:NeoComplCache_PluginCompletionLength')
    let g:NeoComplCache_PluginCompletionLength = {}
endif
if !exists('g:NeoComplCache_TemporaryDir')
    let g:NeoComplCache_TemporaryDir = $HOME . '/.neocon'

    if !isdirectory(g:NeoComplCache_TemporaryDir)
         call mkdir(g:NeoComplCache_TemporaryDir, 'p')
    endif
endif
if exists('g:NeoComplCache_EnableAtStartup') && g:NeoComplCache_EnableAtStartup
    " Enable startup.
    call neocomplcache#enable()
endif"}}}

let g:loaded_neocomplcache = 1

" vim: foldmethod=marker
