##
## Bindings
##

() {
	local widgets=(
		up-line-or-beginning-search
		down-line-or-beginning-search
		edit-command-line
	)
	local widget
	for widget in "${widgets[@]}"; do
		autoload -U "$widget"
		zle -N "$widget"
	done
}

[[ -n "${key[Up]}"      ]] && bindkey "${key[Up]}"      up-line-or-beginning-search
[[ -n "${key[Down]}"    ]] && bindkey "${key[Down]}"    down-line-or-beginning-search
[[ -n "${key[C-Tab]}"   ]] && bindkey "${key[C-Tab]}"   reverse-menu-complete
[[ -n "${key[C-Left]}"  ]] && bindkey "${key[C-Left]}"  backward-word
[[ -n "${key[C-Right]}" ]] && bindkey "${key[C-Right]}" forward-word
bindkey ' ' magic-space # space
bindkey '^ ' autosuggest-accept # c-space
bindkey '^H' backward-kill-word # c-bs
bindkey '^d' kill-whole-line

# bindings
zle-run() {
	zle push-input
	BUFFER="$@"
	zle accept-line
}
zle -N zle-run

_fg() { zle-run fg }
zle -N _fg
bindkey "^z" _fg

autoload -U add-zsh-hook
add-zsh-hook chpwd (){
	# see https://github.com/desyncr/auto-ls/blob/master/auto-ls.zsh
	if ! zle \
	|| { [[ "$WIDGET" == accept-line ]] && [[ $#BUFFER -eq 0 ]]  }; then
		zle && echo
		# don't show for cd that is not run by user
		ls --color=auto -FhH
	fi
}

bindkey "^_" run-help

_cd-up() { builtin cd .. && zle reset-prompt }
zle -N _cd-up
bindkey "^u" _cd-up

_popd() { builtin popd && zle reset-prompt }
zle -N _popd
bindkey "^p" _popd

_git-info() { zle-run git info }
zle -N _git-info
bindkey "^g^i" _git-info

_git-ap() { zle-run git ap }
zle -N _git-ap
bindkey "^g^a" _git-ap

_copy-buffer() { wl-copy "$BUFFER" && notify-send -t 5000 $'copied:\n'"$BUFFER" }
zle -N _copy-buffer
bindkey "^o" _copy-buffer

_fzf-insert-file() {
	# TODO pre-fill fzf with current LBUFFER argument
	local selected
	selected=$(
		fzf </dev/tty --height 10 --reverse --exact \
			--bind 'tab:accept-non-empty' \
			--bind 'enter:execute(echo {})+abort'
	)
	local ret=$?
	if [[ -n "$selected" ]]; then
		if [[ "$ret" == 0 ]]; then
			LBUFFER+="${(q)selected} "
		elif [[ "$ret" == 130 ]]; then
			# HACK using non-empty abort as "enter and run"
			LBUFFER+="${(q)selected} "
			zle accept-line
		fi
	fi
	zle redisplay
}
zle -N _fzf-insert-file
bindkey "^f" _fzf-insert-file

_fzf-history() {
	local selected
	selected=$(
		sed 's/^: [0-9]*:[0-9]*;//; :a; /\\$/ { s/\\$//; N; ba }; s/\n/\r/g' "$HISTFILE" |
		fzf --height 10 --reverse --exact \
			--no-sort --no-multi --no-info -q "$BUFFER" --tac \
			--bind 'tab:accept-non-empty' |
		tr '\r' '\n'
	)
	local ret=$?
	if [[ "$ret" == 0 ]]; then
		BUFFER="${selected}"
		CURSOR="$#BUFFER"
	fi
	zle redisplay
}
zle -N _fzf-history
bindkey "^r" _fzf-history

# TODO ranger-like cd. In quick-cd mode:
# - h adds .. to current path (or strips one path element)
# - j goes to next suggestion
# - k goes to previous suggestion
# - l enters directory to dir/.
# you are also shown a summary of the contents of the directory
