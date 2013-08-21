" Title:        Verilog HDL/SystemVerilog HDVL indent file
" Maintainer:	Mingzhi Li <limingzhi05@mail.nankai.edu.cn>
" Last Change:	2007-12-16 20:10:57 CST
"
" Buffer Variables:
"     b:verilog_indent_width   : indenting width(default value: shiftwidth)
"
" Install:
"     Drop it to ~/.vim/indent 
"
" URL:
"    http://www.vim.org/scripts/script.php?script_id=2091
"
" Revision Comments:
"     Mingzhi Li  2012-03-13 23:15:39 CST Version 1.3
"        Bug fixes
"     Mingzhi Li  2007-12-16 20:09:39 CST Version 1.2      
"        Bug fixes
"     Mingzhi Li  2007-12-13 23:47:54 CST Version 1.1      
"        Bug fix, improve performance and add introductions
"     Mingzhi Li  2007-12-7  22:16:41 CST Version 1.0  
"        Initial version
"       
" Known Limited:
"     This indent file can not work well, when you break the long line into
"     multi-line manually, such as:
"      always @(posedge a or posedge b 
"          or posedge c ) begin
"         //...
"      end 
"     Recommend to use the coding style(wraped by vim automatically) as following:
"       always @(posedge a or posedge b or posedge c ) begin
"         //...
"       end 

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetVerilog_SystemVerilogIndent()
setlocal indentkeys=!^F,o,O,0),0},0{,=begin,=end,=fork,=join,=endcase,=join_any,=join_none
setlocal indentkeys+==endmodule,=endfunction,=endtask,=endspecify
setlocal indentkeys+==endclass,=endpackage,=endsequence,=endclocking
setlocal indentkeys+==endinterface,=endgroup,=endprogram,=endproperty
setlocal indentkeys+==`else,=`endif

" Only define the function once.
if exists("*GetVerilog_SystemVerilogIndent")
  finish
endif

set cpo-=C

function s:comment_ind(lnum)
  let line = getline(a:lnum)
  if line =~ '^\s*\/\/'
    return -1
  endif

  let firstPos = match(line,'\S') + 1
  if firstPos == 0
    return -1
  endif

  let endPos   = match(line,'\s*$') 

  let flag1 = 0
  let flag2 = 0
  if (synIDattr(synID(a:lnum, firstPos, 1), "name") =~? '\(Comment\|String\)$')
    let flag1 = 1
  endif

  if (synIDattr(synID(a:lnum, endPos, 1), "name") =~? '\(Comment\|String\)$' )
    let flag2 = 1
  endif

  if ((1 == flag1)&&(1 == flag2))
    let firstPos = match(line,'\*\/') + 2

    if (synIDattr(synID(a:lnum, firstPos, 1), "name") =~? '\(Comment\|String\)$')
      return -1
    else
      return 3
    endif
  endif

  if (1 == flag1)
    return 1
  endif

  if (1 == flag2)
    return 0
  endif


  return 2

endfunction

function s:prevnonblanknoncomment(lnum)
  let lnum = prevnonblank(a:lnum)

  while lnum > 0
    if (-1 != s:comment_ind(lnum))
      break
    endif
    let lnum = prevnonblank(lnum - 1)
  endwhile
  return lnum
endfunction

function s:removecommment(line,comment_ind)

  if (a:comment_ind ==  2)
    return a:line
  endif

  if (a:comment_ind == -1)
    return ""
  endif

  if (a:comment_ind == 1)
    return substitute(a:line,'^.\{-}\*\/',"","")
  endif

  if (a:comment_ind == 3)
    return substitute(a:line,'^.\{-}\*\/',"","")
  endif

  return substitute(a:line,'\/\(\/\|\*\).*$',"","")

endfunction


function GetVerilog_SystemVerilogIndent()

  if exists('b:verilog_indent_width')
    let offset = b:verilog_indent_width
  else
    let offset = &sw
  endif


  " Find a non-blank and valid line above the current line.
  let lnum = s:prevnonblanknoncomment(v:lnum - 1)

  " At the start of the file use zero indent.
  if lnum == 0
    return 0
  endif

  let ind  = indent(lnum)

  let curr_line_ind = s:comment_ind(v:lnum)
  "if curr_line_ind == -1
  "  return ind
  "endif

  let curr_line  = s:removecommment(getline(v:lnum),curr_line_ind)
  let curr_line2 = substitute(curr_line,'^\s*','','')

  let match_result = matchstr(curr_line2,'^\<\(end\|else\|end\(case\|task\|function\|clocking\|interface\|module\|class\|specify\|package\|sequence\|group\|property\)\|join\|join_any\|join_none\)\>\|^}\|`endif\|`else')


    if len(match_result) > 0
      if match_result =~ '\<end\>'
        let match_start = '\<begin\>'
        let match_mid   = ''
        let match_end   = '\<end\>'

      elseif match_result =~ '\<else\>'
        let last_line_ind = s:comment_ind(lnum)
        let last_line  = s:removecommment(getline(lnum),last_line_ind)

        if last_line =~ '^\s*end\|^\s*}'
          return indent(lnum)
        else
          let match_start = '\<if\>'
          let match_mid   = ''
          let match_end   = '\<else\>'
        endif

      elseif match_result =~ 'join'
        let match_start = '\<fork\>'
        let match_mid   = ''
        let match_end   = '\<\(join\|join_none\|join_any\)\>'

      elseif match_result =~ '}'
        let match_start = '{'
        let match_mid   = ''
        let match_end   = '}'

      elseif match_result =~ '`else'
        let match_start = '`if'
        let match_mid   = ''
        let match_end   = '`else'

      elseif match_result =~ '`endif'
        let match_start = '`if'
        let match_mid   = '`else'
        let match_end   = '`endif'

      else
        let match_start = substitute(match_result,'^end','','')
        let match_start = '\<' . match_start . '\>'
        let match_mid   = ''
        let match_end   = '\<' . match_result. '\>'
      endif


      call cursor(v:lnum,1)
      let match_line = searchpair(match_start,match_mid,match_end,'bW',
            \" synIDattr(synID(line('.'),col('.'),1),'name')"
            \. "=~? '\\(Comment\\|String\\)$'")

      if match_line > 0
        return indent(match_line)
      endif

    endif


  let last_line_ind = s:comment_ind(lnum)
  let last_line  = s:removecommment(getline(lnum),last_line_ind)
 
  let indent0 = 0
  let indent1 = 0
  let indent2 = 0

  let de_indent0 = 0

  let pat0 = '[{(]\s*$'
  let pat1 = '\<\(begin\|fork\)\>\s*\(:\s*\w\+\s*\)\=\s*$'
  let pat2 = '`\@<!\<\(if\|else\)\>'
  let pat3 = '\<\(always\|initial\|for\|foreach\|always_comb\|always_ff\|always_latch\|final\|repeat\|while\|constraint\|do\)\>'
  let pat5 = '\<\(case\%[[zx]]\|task\|function\|class\|interface\|clocking\|randcase\|package\|specify\)\>'
  let pat6 = '^\s*\(\w\+\s*:\)\=\s*\<covergroup\>'
  let pat7 = '^\s*\<\(begin\|fork\)\>\s*\(:\s*\w\+\s*\)\='
  let pat8 = '^\s*`\<\(else\|endif\)\>'

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

  if last_line =~ pat0 || last_line =~ pat1
    let indent0 = 1
  endif

  " Indent after if/else/for/case/always/initial/specify/fork blocks

  if (last_line =~ pat2 ||  last_line =~ pat3 || last_line =~ ':\s*$') && (last_line !~ ';\s*$')
    let indent1 = 1

  elseif  last_line =~ pat5 || last_line =~ pat6
    let indent2 = 1

  elseif last_line =~ '^\s*`\<\(ifdef\|else\|ifndef\)\>'
    return ind + offset
  endif

  let sum1 = indent0 + indent1 + indent2

  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
  if (curr_line =~ pat7 || curr_line =~ pat8 || curr_line =~ '^\s*{')
    let de_indent0 = 1
  endif

  if (sum1 == 0) && (last_line !~ '^\s*end\|\<begin\>') &&
        \ (curr_line =~ ')\s*;\s*$') && 
        \ (last_line =~ ',\s*$' || last_line =~ '\w\s*$\|]\s*$\|)\s*$')
    return ind - offset
  endif

  let sum2 = de_indent0 

  if indent0 + indent1 + sum2 == 0
    let lnum2 = s:prevnonblanknoncomment(lnum - 1)
    let last_line2_ind = s:comment_ind(lnum2)
    let last_line2 = s:removecommment(getline(lnum2),last_line2_ind)

    if ((last_line2 !~ pat0 && last_line2 !~ pat1) && 
          \ (last_line2 =~ pat2 || last_line2 =~ pat3 || last_line2 =~ ':\s*$') &&
          \ (last_line =~ ';\s*$'))
      return indent(lnum2)
    endif
  endif
  

  " Return the indention
  if (indent0 == 0 && indent1 == 1 && de_indent0 == 1)
    return ind
  elseif  sum1 > 0
    return ind + offset
  elseif  sum2 > 0
    return ind - offset
  else
    return ind
  endif 

endfunction

" vim:sw=2
