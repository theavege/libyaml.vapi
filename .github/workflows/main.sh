#!/usr/bin/env bash

function _require_check
{
    declare -r required_tools=(vala sh{fmt,ellcheck})
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" >/dev/null; then
            printf "Missing dependency: %s\n" "${tool}"
            return 1
        fi
    done
    return 0
}

function _require_setup
{
    if ! _require_check; then
        source '/etc/os-release'
        declare -ar PKGS=(shellcheck shfmt)
        case ${ID:?} in
            msys2) return 0 ;;
            debian | ubuntu)
                sudo apt-get update
                sudo apt-get install -y "${PKGS[@]}" valac libyaml-dev
                ;;
            fedora | alma) sudo dnf install -y "${PKGS[@]}" vala libyaml-devel ;;
        esac 1>/dev/null
    fi
    shellcheck --external-sources "${0}"
    shfmt -ci -fn -i 4 -d "${0}"
}

set -xeuo pipefail
_require_setup
declare -ar VAR=(
    --verbose
    --fatal-warnings
    --Xcc=-O3
    --cc=clang
    --vapidir=src
    --enable-{checking,mem-profiler,gobject-tracing}
    --pkg={libyaml,posix}
    -X -lyaml
)

vala "${VAR[@]}" 'tests/simple.vala'
