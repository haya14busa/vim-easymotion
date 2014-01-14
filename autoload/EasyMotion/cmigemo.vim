"=============================================================================
" FILE: autoload/EasyMotion/cmigemo.vim
" AUTHOR: haya14busa
" Last Change: 14 Jan 2014.
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
scriptencoding utf-8
" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

function! s:has_vimproc() "{{{
  if !exists('s:exists_vimproc')
    try
      silent call vimproc#version()
      let s:exists_vimproc = 1
    catch
      let s:exists_vimproc = 0
    endtry
  endif

  return s:exists_vimproc
endfunction "}}}

function! EasyMotion#cmigemo#system(...) "{{{
    return call(s:has_vimproc() ? 'vimproc#system' : 'system', a:000)
endfunction "}}}

function! s:SearchDict2(name) "{{{
    let path = $VIM . ',' . &runtimepath
    let dict = globpath(path, "dict/".a:name)
    if dict == ''
        let dict = globpath(path, a:name)
    endif
    if dict == ''
        for path in [
                \ '/usr/local/share/migemo/',
                \ '/usr/local/share/cmigemo/',
                \ '/usr/local/share/',
                \ '/usr/share/cmigemo/',
                \ '/usr/share/',
                \ ]
            let path = path . a:name
            if filereadable(path)
                let dict = path
                break
            endif
        endfor
    endif
    let dict = matchstr(dict, "^[^\<NL>]*")
    return dict
endfunction "}}}

function! s:SearchDict() "{{{
  for path in [
        \ 'migemo/'.&encoding.'/migemo-dict',
        \ &encoding.'/migemo-dict',
        \ 'migemo-dict',
        \ ]
    let dict = s:SearchDict2(path)
    if dict != ''
      return dict
    endif
  endfor
  echoerr 'a dictionary for migemo is not found'
  echoerr 'your encoding is '.&encoding
endfunction "}}}

function! EasyMotion#cmigemo#getMigemoPattern(input) "{{{
    if !exists('s:migemodict')
        let s:migemodict = s:SearchDict()
    endif

    if !exists('s:init_flag')
        call s:init()
        let s:init_flag = 1
    endif

    if has('migemo')
        " Use migemo().
        return migemo(a:input)
    elseif executable('cmigemo')
        " Use cmigemo.
        if !s:P.is_available()
            return EasyMotion#cmigemo#system('cmigemo -v -w "'.a:input.'" -d "'.s:migemodict.'"')
        endif
        let t = s:P.touch('easymotion', 'cmigemo -v -d ' . s:migemodict)
        if t ==# 'new'
            " wait for longer time to make sure cmigemo runs, since cmigemo is
            " really slow to be ready.
            call s:P.read_wait('easymotion', 2.0, ['PATTERN: '])
        endif
        return substitute(matchstr(s:f(a:input),
                \ 'PATTERN:\s\zs.*\ze',),
                \ '.$', '', '')
    else
        " Not supported
        return input
    endif
endfunction "}}}

function! s:init() "{{{
    let s:V = vital#of('vital')
    let s:P = s:V.import('ProcessManager')
endfunction "}}}

function! s:f(msg) "{{{
    if !s:P.is_available()
        return 'vimproc is required'
    endif
    call s:P.writeln('easymotion', a:msg)
    let [out, err, type] = s:P.read('easymotion', ['PATTERN: '])

    return out
endfunction "}}}

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
unlet s:save_cpo
" }}}

