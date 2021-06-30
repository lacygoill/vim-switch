vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Config {{{1

const SWITCHABLE_TOKENS: list<list<string>> = [
    ['==', '!='],
    ['=~', '!~'],
    ['>', '<', '>=', '<='],
    ['enable', 'disable'],
    ['on', 'off'],
    ['true', 'false'],
    ['True', 'False'],
    ['✔', '✘'],
]

# Init {{{1

const TOKENS_PAT: string = SWITCHABLE_TOKENS
    ->flattennew()
    ->join('\|')

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
    if !&modifiable
        return
    endif
    var cnt: number = v:count

    var token: string
    var startcol: number
    [token, startcol] = GetTokenAndStartCol()
    var map: dict<string> = TOKENS_MAP[increment ? 'increment' : 'decrement']
    if !map->has_key(token)
        # if there is no known token under the cursor,
        # fall back on the default C-a/C-x command
        execute 'normal! ' .. (cnt == 0 ? '' : cnt) .. (increment ? "\<C-A>" : "\<C-X>")
    else
        # there is a known token; find out the new desired token
        var new_token: string = map[token]
        # support a possible count
        if cnt > 1
            for i in range(cnt - 1)
                new_token = map[new_token]
            endfor
        endif
        # position the cursor at the start of the token
        cursor(0, startcol)
        var col: number = col('.')
        # replace the token
        var pat: string = '\%' .. col .. 'c.\{' .. token->strcharlen() .. '}'
        getline('.')
            ->substitute(pat, new_token, '')
            ->setline('.')
        # position the cursor at the end of the token
        # (to emulate the behavior of the default C-a command)
        cursor(0, col + new_token->len() - 1)
    endif
enddef

def GetTokenAndStartCol(): list<any> #{{{2
# Return the token under the cursor (if any).
# If you find one, give us the
    var token_under_cursor: string
    var startcol: number

    var line: string = getline('.')
    var col: number = col('.')
    var match: bool
    # iterate over our chains of tokens
    for tokens in SWITCHABLE_TOKENS
        # iterate over the tokens in a given chain
        for token in tokens
            # Try to match the token; the cursor can be anywhere inside.{{{
            #
            #     token
            #     ^
            #     token
            #      ^
            #     token
            #       ^
            #     token
            #        ^
            #     token
            #         ^
            #
            # If it doesn't match right away, don't give up.
            # Try again, but just one byte earlier.
            # Go on  until you've  moved back  too far  away for  a match  to be
            # possible.
            #}}}
            var len: number = token->len()
            for offset in len->range()
                if line->strpart(col - 1 - offset, len) == token
                    [token_under_cursor, startcol] = [token, col('.') - offset]
                    match = true
                    break
                endif
            endfor
        endfor
        if match
            break
        endif
    endfor
    return [token_under_cursor, startcol]
enddef
