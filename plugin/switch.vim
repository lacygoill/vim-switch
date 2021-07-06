vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

nnoremap <unique> <C-A> <Cmd>call switch#replace()<CR>
nnoremap <unique> <C-X> <Cmd>call switch#replace(v:false)<CR>

map <unique> s<C-A> <Plug>(next-switchable-token)
map <unique> s<C-X> <Plug>(prev-switchable-token)
noremap <Plug>(next-switchable-token) <Cmd>call switch#jump()<CR>
noremap <Plug>(prev-switchable-token) <Cmd>call switch#jump(v:false)<CR>

