" File: wikilink.vim
" Author: Henri Bourcereau 
" Version: 0.2
" Last Modified: June 14, 2011
"
" "WikiLink" is a Vim plugin which eases the navigation between files 
" in a personnal wiki
" Links syntax currently supported follows Github's Gollum (https://github.com/github/gollum)
" ie [[My link|My displayed link]]
"
" Installation
" ------------
"  Copy the wikilink.vim file into the $HOME/.vim/plugin/ directory
"
" Usage
" -----
"  Hit the ENTER key when the cursor is on a wiki link
"  The corresponding file is loaded in the current buffer


"Initialize constants
let s:footerbar = "_Footerbar"
let s:sidebar = "_Sidebar"

let s:startWord = '[['
let s:endWord = ']]'
let s:sepWord = '|'

"Move the cursor to the main window (not the sidebar or the bottombar)
function! WikiLinkGotoMainWindow()
  let cur_file_name = bufname("%")
  let cur_file_name = strpart(cur_file_name, 0, strridx(cur_file_name, '.'))
  let cur_file_name = strpart(cur_file_name, strridx(cur_file_name, '/') + 1)
  if (cur_file_name == s:footerbar)
    exec "winc k "
  elseif (cur_file_name == s:sidebar)
    exec "winc l "
  endif
endfunction

function! WikiLinkGetWord()
  let word = ''

  "Get string between <startWord> and <endWord>
  let origPos = getpos('.')
  let endPos = searchpos(s:endWord, 'W', line('.'))
  let startPos = searchpos(s:startWord, 'bW', line('.'))
  let ok = cursor(origPos[1], origPos[2]) "Return to the original position

  if (startPos[1] < origPos[2])
    let ll = getline(line('.'))
    let word = strpart(ll, startPos[1] + 1, endPos[1] - startPos[1] - 2)
  endif

  if !empty(word)
    "Only return the link part
    let word = split(word, s:sepWord)[0]

    "substitute spaces by dashes
    let word = substitute(word, '[ /]', '-', 'g')
  end

  return word
endfunction

function! WikiLinkWordFilename(word)
  let file_name = ''
  "Same directory and same extension as the current file
  if !empty(a:word)
    let cur_file_name = bufname("%")
    let dir = strpart(cur_file_name, 0, strridx(cur_file_name, '/'))
    if !empty(dir)
      let dir = dir."/"
    endif
    let extension = strpart(cur_file_name, strridx(cur_file_name, '.'))
    let file_name = dir.a:word.extension
  endif
  return file_name
endfunction

function! WikiLinkGotoLink()
  let link = WikiLinkWordFilename(WikiLinkGetWord())
  if !empty(link)
    call WikiLinkGotoMainWindow()
    exec "edit " . link 
  endif
endfunction

"search file in the current directory and its ancestors
function! WikiLinkFindFile(afile)
  let afile = a:afile
  echo afile
  if filereadable(afile)
    return afile
  else
    let filedir = strpart(afile, 0, strridx(afile, '/'))
    let filename = strpart(afile, strridx(afile, '/'))
    if !isdirectory(filedir)
      return ""
    else
      return WikiLinkFindFile(filedir . "/.." . filename)
    endif
  endif
endfunction

function! WikiLinkDetectFile(word)
  let bar_filename = WikiLinkFindFile(WikiLinkWordFilename(a:word))
  return bar_filename
endfunction

function! WikiLinkShowStructure()
  "close all windows except active one
  exec "winc o"

  "Detect footerbar
  let footer_bar = WikiLinkDetectFile(s:footerbar)
  if filereadable(footer_bar)
    exec "botright 7 split " . footer_bar
    call WikiLinkGotoMainWindow()
  endif

  "Detect sidebar
  let side_bar = WikiLinkDetectFile(s:sidebar)
  if filereadable(side_bar)
    exec "topleft 30 vsplit " . side_bar
    call WikiLinkGotoMainWindow()
  endif
endfunction

nmap <silent> <CR> :call WikiLinkGotoLink()<CR>

"au BufNewFile,BufRead .asciidoc,.creole,.markdown,.mdown,.mkdn,.mkd,.md,.org,.pod,.rdoc,.rest.txt,.rst.txt,.rest,.rst,.textile,.mediawiki,.wiki	call WikiLinkShowStructure()
nmap <silent> R :call WikiLinkShowStructure()<CR>

