#!/usr/bin/env sh

set -euf

# https://stackoverflow.com/a/40167919
expand_vars_strict() {
    _x4=$(printf '\x4')
    # the `||` clause ensures that the last line is read even if it doesn't end with \n
    while IFS= read -r line || [ -n "${line}" ]; do
        # Escape ALL chars. that could trigger an expansion..
        lineEscaped=$(
            printf %s "$line" |
                tr '`([$' '\1\2\3\4' |
                # ... then selectively reenable ${ references
                sed -e "s/$_x4{/\${/g" |
                # Finally, escape embedded double quotes to preserve them.
                sed -e 's/"/\\\"/g'
        )
        eval "printf '%s\n' \"$lineEscaped\"" | tr '\1\2\3\4' '`([$'
    done
}
