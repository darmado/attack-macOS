#/usr/bin/bash

read -r -d '' select << EOM
SELECT title, url
FROM history_visits
INNER JOIN history_items
ON history_visits.history_item = history_items.id
ORDER BY visit_time desc
LIMIT 1000;
EOM

sqlite3 -noheader -separator $'\t' ~/Library/Safari/History.db \
  "$select" 2>/dev/null \
  | uniq

fzf-safari-history-open() {
  local result=$(safari-history-dump \
	| FZF_DEFAULT_OPTS="-m --reverse --prompt \"Safari History> \" \
	--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS" $(__fzfcmd) +m \
	| cut -f2)
  if [[ -n $result ]]; then
	open "$result"
  fi
}

