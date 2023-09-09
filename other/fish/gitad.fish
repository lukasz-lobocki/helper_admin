function gitad
gita shell \
  "{ \
    git log --pretty=format:'^%ct^%cr^' --date-order -n 1; \
    git rev-parse --show-toplevel \
      | tr -d '\n'; \
    git branch -v \
      | grep -o '\[[^]]*\]' \
      | sed 's/^/\^/'; \
  };" \
  | grep --invert-match '^$' \
  | sort --ignore-leading-blanks --field-separator='^' --key=2 --reverse \
  | cut --delimiter='^' --fields=2 --complement \
  | column --table --separator '^' --output-separator '  ' \
    --table-columns 'Repo,Last commit,Working tree,Local is'
end
