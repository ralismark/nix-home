.autovenv.check() {
	if [[ -z "$VIRTUAL_ENV" ]]; then
		# Don't auto venv over sshfs
		fs=$(df . --output=fstype | sed -n 2p)
		[[ "$fs" = "fuse.sshfs" ]] && return

		# Check common venv names
		for venv_name in venv .venv; do
			if [[ -e "$venv_name/bin/activate" ]]; then
				echo "Activating venv in $PWD/$venv_name"
				# TODO bit of a hack to stop startup breaking
				VIRTUAL_ENV_DISABLE_PROMPT=1
				source "$venv_name/bin/activate"
				break
			fi
		done
	else
		# We were in a venv
		local PROJECT_ROOT=$(dirname "$VIRTUAL_ENV")
		# TODO this breaks if PWD=/ab PROJECT_ROOT=/a
		local realpwd=$(pwd -P)
		if [[ "$realpwd" = "${realpwd##$PROJECT_ROOT}" ]]; then
			# virtual env dir is no longer a prefix of pwd
			echo "Deactivating venv"
			deactivate
		fi
	fi
}
autoload -U add-zsh-hook
add-zsh-hook chpwd .autovenv.check
.autovenv.check # check on startup
