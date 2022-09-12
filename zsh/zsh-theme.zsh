#!/usr/bin/env zsh

SCRIPT_DIR=${0:A:h}

.prompt.git.script() {
	# TODO make this not a relative path
	local data=$(tunnel-run sh < "$SCRIPT_DIR/git-status-script.zsh")
	cat <<EOF
	_prompt_git_script=${(q)data}
	zle reset-prompt
EOF
}

.async.eval() {
	if [[ "$2" = 0 ]]; then
		eval "$3"
	elif [[ "$1" != "[async]" ]]; then
		printf '\e7\e[H\e[41;30m'
		printf '\e[2K%s\n' \
			"$1: returned $2" \
			"stdout: $3" \
			"stderr: $5"
		printf %b '\e[0m\e8'
	fi
}

add-zsh-hook precmd .prompt.git.precmd() {
	_prompt_git_script=undefined
	async_stop_worker .prompt.git
	async_start_worker .prompt.git
	async_register_callback .prompt.git .async.eval
}

.prompt.git() {
	if [[ "$_prompt_git_script" = "undefined" ]]; then
		_prompt_git_script=""
		async_job .prompt.git .prompt.git.script
	fi
	echo "$_prompt_git_script"
}

VIRTUAL_ENV_DISABLE_PROMPT=1
.prompt.venv() {
	[[ -z "$VIRTUAL_ENV" ]] && return
	echo " %F{blue}venv%f"
}

.prompt.zdotdir() {
	[[ -z "$ZDOTDIR" ]] && return
	echo " %F{green}zdotdir=%F{243}${ZDOTDIR//\%/%%}%f"
}

.prompt.cwd() {
	if [[ "$PWD" -ef . ]]; then
		echo "%~"
		return
	fi
	echo "%F{black}%K{red}%~%f%k"
}

() { # Make this in its own scope
	local leader='%(?,%F{green},%F{red})┃%f '
	local errno='%(?,,%B%F{red}$?%f%b )'
	local jobline='%(1j,%F{green}$(jobs -r | wc -l | sed "s/0//")&$(jobs -s | wc -l | sed "s/0//")%f ,)'

	PS1="
${leader}${errno}\$(.prompt.cwd)\$(.prompt.venv)\$(.prompt.git)\$(.prompt.zdotdir)
${leader}${jobline}%(!,%F{red}#%f,$) "

	PS2="... "
}
