" File: wikilink.vim
" Author: Henri Bourcereau 
" Version: 0.3
" Last Modified: June 15, 2011
"
" "WikiLink" is a Vim plugin which eases the navigation between files 
" in a personnal wiki
" Links syntax currently supported follows Github's Gollum (https://github.com/github/gollum)  ie [[My displayed link|My link]]
" This plugin also detects footer and sidebar files and splits the window
" accordingly (again, see Gollum for syntax)
"
" Installation
" ------------
" Copy the wikilink.vim file into the $HOME/.vim/plugin/ directory
"
" Usage
" -----
" Hit the ENTER key when the cursor is on a wiki link
" The corresponding file is loaded in the current buffer
"
" Contribute
" ----------
" You can fork this project on Github : https://github.com/mmai/wikilink


"Initialize constants
let s:footer = "_Footer"
let s:sidebar = "_Sidebar"

let s:startWord = '[['
let s:endWord = ']]'
let s:sepWord = '|'

"Move the cursor to the main window (not the sidebar or the bottombar)
function! WikiLinkGotoMainWindow()
  let cur_file_name = fnamemodify(bufname("%"), ":t:r")
  if (cur_file_name == s:footer)
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
    if word =~ s:sepWord
      let word = split(word, s:sepWord)[1]
    else
      let word = split(word, s:sepWord)[0]
    endif

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
    let dir = fnamemodify(cur_file_name, ":h")
    if !empty(dir)
      if (dir == ".")
        let dir = ""
      else
        let dir = dir."/"
      endif
    endif
    let extension = fnamemodify(cur_file_name, ":e")
    let file_name = dir.a:word.".".extension
  endif
  return file_name
endfunction

function! WikiLinkGotoLink()
  let link = WikiLinkWordFilename(WikiLinkGetWord())
  if !empty(link)
    call WikiLinkGotoMainWindow()
    "Search in subdirectories
    let mypath =  fnamemodify(bufname("%"), ":p:h")."/**"
    let existing_link = findfile(link, mypath)
    if !empty(existing_link)
      let link = existing_link
    endif
    exec "edit " . link 
  endif
endfunction

"search file in the current directory and its ancestors
function! WikiLinkFindFile(afile)
  "XXX does not work : return findfile(a:afile, '.;')
  let afile = fnamemodify(a:afile, ":p")
  if filereadable(afile)
    return afile
  else
    let filename = fnamemodify(afile, ":t")
    let file_parentdir = fnamemodify(afile, ":h:h")
    if file_parentdir == "//"
      "We've reached the root, no more parents
      return ""
    else
      return WikiLinkFindFile(file_parentdir . "/" . filename)
    endif
  endif
endfunction

function! WikiLinkDetectFile(word)
  return WikiLinkFindFile(WikiLinkWordFilename(a:word))
endfunction

function! WikiLinkShowStructure()
  let cur_file_name = fnamemodify(bufname("%"), ":t:r")
  if cur_file_name != s:footer && cur_file_name != s:sidebar
    "close all windows except active one
    exec "winc o"

    "Detect footer
    let footer_bar = WikiLinkDetectFile(s:footer)
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
  endif
endfunction

nmap <silent> <CR> :call WikiLinkGotoLink()<CR>

augroup wikilink
au!
au BufNewFile,BufRead *.asciidoc,*.creole,*.markdown,*.mdown,*.mkdn,*.mkd,*.md,*.org,*.pod,*.rdoc,*.rest.txt,*.rst.txt,*.rest,*.rst,*.textile,*.mediawiki,*.wiki	call WikiLinkShowStructure()
augroup END

