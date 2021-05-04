vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Config {{{1

const SWITCHABLE_TOKENS: list<list<string>> = [
    ['==', '!='],
    ['=~', '!~'],
    ['>', '<', '>=', '<='],
    ['true', 'false'],
    ['True', 'False'],
    ['✔', '✘'],
]

# Init {{{1

const TOKENS_PAT: string = SWITCHABLE_TOKENS->flattennew()->join('\|')

var TOKENS_MAP: dict<dict<string>> = {increment: {}, decrement: {}}
def PopulateTokensMap()
    for l in SWITCHABLE_TOKENS
        var len: number = len(l)
        var i: number
        for token in l
            extend(TOKENS_MAP.increment, {[token]: l[(i + 1) % len]})
            extend(TOKENS_MAP.decrement, {[token]: l[i == 0 ? len - 1 : i - 1]})
            ++i
        endfor
    endfor
enddef
PopulateTokensMap()
lockvar! TOKENS_MAP

# Functions {{{1
def switch#jump(forward = true) #{{{2
    var flags: string = (forward ? '' : 'b') .. 'eW'
    var stopline: number = line('.')
    searchpos('\%(^\|\s\)\%(\V' .. TOKENS_PAT .. '\m\)\ze\%(\s\|$\)', flags, stopline)
enddef

def switch#replace(increment = true) #{{{2
    var cnt: number = v:count
    var token: string = getline('.')->matchstr('\S*\%' .. col('.') .. 'c\S\+')
    var map: dict<string> = TOKENS_MAP[increment ? 'increment' : 'decrement']
    if !map->has_key(token)
        # if there is no known token under the cursor,
        # fall back on the default C-a/C-x command
        exe 'norm! ' .. (cnt == 0 ? '' : cnt) .. (increment ? "\<c-a>" : "\<c-x>")
    else
        # there is a known token; find out the new desired token
        var new_token: string = map[token]
        # support a possible count
        if cnt > 1
            for i in range(cnt - 1)
                new_token = map[new_token]
            endfor
        endif
        var stopline: number = line('.')
        # position the cursor at the start of the token
        search('\%(\s\zs\|^\)\S\+', 'bcW', stopline)
        # replace the token
        getline('.')
            ->substitute('\%' .. col('.') .. 'c\S\+', new_token, '')
            ->setline('.')
        # position the cursor at the end of the token
        # (to emulate the behavior of the default C-a command)
        search('\S\ze\s\|$', 'cW', stopline)
    endif
enddef

