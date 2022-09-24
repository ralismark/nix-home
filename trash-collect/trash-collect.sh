#!/bin/bash
set -eu

trash=~/.local/share/Trash
for f in "$trash/info/"*; do
	name=$(basename "$f")
	name=${name%.trashinfo}
	deletion_date=$(sed -ne '/^DeletionDate=/{s/^DeletionDate=//;p}' "$f")

	# shellcheck disable=SC2071
	# TODO timezones?
	if [[ "$deletion_date" < "$(date -d "30 days ago" +'%Y-%m-%dT%H:%M:%S')" ]]; then
		rm -r "$trash/files/$name" "$f"
	fi
done
