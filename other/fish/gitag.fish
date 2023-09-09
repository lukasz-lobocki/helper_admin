function gitag
gita shell \
  "{ \
    git log --pretty=format:'^%ct^%cr^' --date-order -n 1; \
    git config --get remote.origin.url \
      | tr -d '\n' \
      | sed 's/^git@github.com:/ssh@https:\/\/github.com\//'; \
    git branch -v \
      | grep -o '\[[^]]*\]' \
      | sed 's/^/\^/'; \
  };" \
  | grep --invert-match '^$' \
  | sort --ignore-leading-blanks --field-separator='^' --key=2 --reverse \
  | cut --delimiter='^' --fields=2 --complement \
  | column --table --separator '^' --output-separator '  ' \
    --table-columns 'Repo,Last commit,Github,Local is'
end
