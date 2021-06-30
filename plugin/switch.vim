vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

nnoremap <C-A> <Cmd>call switch#replace()<CR>
nnoremap <C-X> <Cmd>call switch#replace(v:false)<CR>

nnoremap s<C-A> <Cmd>call switch#jump()<CR>
nnoremap S<C-A> <Cmd>call switch#jump(v:false)<CR>

