if [[ -f "$CINNABAR_USER_ZDOTDIR/.zshrc" ]]; then
  source "$CINNABAR_USER_ZDOTDIR/.zshrc"
fi

if [[ -n ${CINNABAR_DEV_PATH-} ]]; then
  # User startup files may reorder PATH; restore the dev shell first.
  typeset +U path 2>/dev/null
  export PATH="${CINNABAR_DEV_PATH}:${PATH}"
fi
