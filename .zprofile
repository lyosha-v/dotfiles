# Homebrew.
#
# Homebrew installs itself by dropping /opt/homebrew/bin into /etc/paths.d, but
# path_helper (run from /etc/zprofile) *appends* those entries, so they land
# after /usr/bin and every brew-installed tool loses to its macOS counterpart --
# `brew install curl` would still resolve to /usr/bin/curl. This runs after
# /etc/zprofile and prepends, which is what puts brew back in front.
eval "$(/opt/homebrew/bin/brew shellenv)"

# Keep $PATH free of duplicate entries, whatever order things get added in.
typeset -U path PATH

# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:$HOME/.docker/bin"
# End of Docker Desktop section.
