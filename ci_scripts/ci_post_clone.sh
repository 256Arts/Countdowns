#!/bin/sh
# Writes the git-ignored Secrets.swift from the TMDB_API_KEY Xcode Cloud environment variable.
set -eu

repo="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/.." && pwd)}"
secrets="$repo/Countdowns/Models/Secrets.swift"

[ -f "$secrets" ] && exit 0

if [ -z "${TMDB_API_KEY:-}" ]; then
    echo "error: TMDB_API_KEY is unset; add it as a secret environment variable in Xcode Cloud" >&2
    exit 1
fi

cat > "$secrets" <<SWIFT
enum Secrets {
    
    static let tmdbAPIKey = "$TMDB_API_KEY"
    
}
SWIFT
