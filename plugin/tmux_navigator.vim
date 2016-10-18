" Maps <C-h/j/k/l> to switch vim splits in the given direction. If there are
" no more windows in that direction, forwards the operation to tmux.

if exists("g:loaded_tmux_navigator") || &cp || v:version < 700
    finish
endif
let g:loaded_tmux_navigator = 1

function! s:InTmuxSession()
    return $TMUX != ''
endfunction

function! s:WinmoveCommand(args)
    let cmd = 'winmove' . ' tmux ' . a:args
    return system(cmd)
endfunction

let s:tmux_is_last_pane = 0
augroup tmux_navigator
    au!
    autocmd WinEnter * let s:tmux_is_last_pane = 0
augroup END

" Like `wincmd` but also change tmux panes instead of vim windows when needed.
function! s:TmuxWinCmd(direction)
    if s:InTmuxSession()
        call s:TmuxAwareNavigate(a:direction)
    else
        call s:VimNavigate(a:direction)
    endif
endfunction

function! s:NeedsVitalityRedraw()
    return exists('g:loaded_vitality') && v:version < 704 && !has("patch481")
endfunction

function! s:TmuxAwareNavigate(direction)
    let nr = winnr()
    let tmux_last_pane = (a:direction == 'p' && s:tmux_is_last_pane)
    if !tmux_last_pane
        call s:VimNavigate(a:direction)
    endif
    " Forward the switch panes command to tmux if:
    " a) we're toggling between the last tmux pane;
    " b) we tried switching windows in vim but it didn't have effect.
    if tmux_last_pane || nr == winnr()
        try
            wall " save all the buffers. See :help wall
        catch /^Vim\%((\a\+)\)\=:E141/ " catches the no file name error 
        endtry
        let map = {'h': 'left', 'j': 'down', 'k': 'up', 'l': 'right'}
        silent call s:WinmoveCommand(map[a:direction])
        if s:NeedsVitalityRedraw()
            redraw!
        endif
        let s:tmux_is_last_pane = 1
    else
        let s:tmux_is_last_pane = 0
    endif
endfunction

function! s:VimNavigate(direction)
    try
        execute 'wincmd ' . a:direction
    catch
        echohl ErrorMsg | echo 'E11: Invalid in command-line window; <CR> executes, CTRL-C quits: wincmd k' | echohl None
    endtry
endfunction

command! TmuxNavigateLeft call s:TmuxWinCmd('h')
command! TmuxNavigateDown call s:TmuxWinCmd('j')
command! TmuxNavigateUp call s:TmuxWinCmd('k')
command! TmuxNavigateRight call s:TmuxWinCmd('l')

nnoremap <silent> <c-h> :TmuxNavigateLeft<cr>
nnoremap <silent> <c-j> :TmuxNavigateDown<cr>
nnoremap <silent> <c-k> :TmuxNavigateUp<cr>
nnoremap <silent> <c-l> :TmuxNavigateRight<cr>
