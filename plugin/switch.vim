vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

nno <c-a> <cmd>call switch#replace()<cr>
nno <c-x> <cmd>call switch#replace(v:false)<cr>

nno s<c-a> <cmd>call switch#jump()<cr>
nno S<c-a> <cmd>call switch#jump(v:false)<cr>

