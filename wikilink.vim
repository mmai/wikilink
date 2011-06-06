" File: wikilink.vim
" Author: Henri Bourcereau 
" Version: 0.1
" Last Modified: June 06, 2011
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


function! WikiLinkGetWord()
  let word = ''

  "delimitors
  let startWord = '[['
  let endWord = ']]'
  let sepWord = '|'

  "Get string between <startWord> and <endWord>
  let origPos = getpos('.')
  let endPos = searchpos(endWord, 'W', line('.'))
  let startPos = searchpos(startWord, 'bW', line('.'))
  let ok = cursor(origPos[1], origPos[2]) "Return to the original position

  if (startPos[1] < origPos[2])
    let ll = getline(line('.'))
    let word = strpart(ll, startPos[1] + 1, endPos[1] - startPos[1] - 2)
  endif

  if !empty(word)
    "Only return the link part
    let word = split(word, sepWord)[0]

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
    exec "edit " . link 
  endif
endfunction

nmap <silent> <CR> :call WikiLinkGotoLink()<CR>
