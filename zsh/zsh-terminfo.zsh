# modified from: https://gist.github.com/AbigailBuccaneer/1fcf12edf13e03e45030
# to view terminfo entries, run:
# for key val in ${(kv)terminfo}; do printf "%8s" "$key:"; printf "%s" "${val}" | od -Anone -c -w9999; done | less

# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -A key

key[C-Tab]=${terminfo[kcbt]}

key[Left]=${terminfo[kcub1]}
key[Down]=${terminfo[kcud1]}
key[Up]=${terminfo[kcuu1]}
key[Right]=${terminfo[kcuf1]}
key[C-Left]=${terminfo[kLFT5]}
key[C-Down]=${terminfo[kDN5]}
key[C-Up]=${terminfo[kUP5]}
key[C-Right]=${terminfo[kRIT5]}

key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}

# TODO more comprehensive listing here

# setup key accordingly
[[ -n "${key[Home]}"    ]] && bindkey "${key[Home]}"   beginning-of-line
[[ -n "${key[End]}"     ]] && bindkey "${key[End]}"    end-of-line
[[ -n "${key[Insert]}"  ]] && bindkey "${key[Insert]}" overwrite-mode
[[ -n "${key[Delete]}"  ]] && bindkey "${key[Delete]}" delete-char
[[ -n "${key[Up]}"      ]] && bindkey "${key[Up]}"     up-line-or-history
[[ -n "${key[Down]}"    ]] && bindkey "${key[Down]}"   down-line-or-history
[[ -n "${key[Left]}"    ]] && bindkey "${key[Left]}"   backward-char
[[ -n "${key[Right]}"   ]] && bindkey "${key[Right]}"  forward-char

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if echoti smkx >&/dev/null; then
	function zle-line-init () { echoti smkx }
	function zle-line-finish () { echoti rmkx }
	zle -N zle-line-init
	zle -N zle-line-finish
fi
