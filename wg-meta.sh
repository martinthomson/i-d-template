# This script isn't run directly.

# Populates values for:
# wg_name, wg_type, wg_mail, and wg_arch for the identified working group.
wgmeta() {
    wg="$1"
    [[ -n "$wg" ]] || return 2
    api="https://datatracker.ietf.org"
    wgmeta="$api/api/v1/group/group/?format=xml&acronym=$wg"
    tmp=$(mktemp)
    trap 'rm -f $tmp' EXIT
    if hash xmllint && curl -SsLf "$wgmeta" -o "$tmp" &&
            [[ "$(xmllint --xpath '/response/meta/total_count/text()' "$tmp")" == "1" ]]; then
        wg_area_url="$(xmllint --xpath '/response/objects/object[1]/parent/text()' "$tmp")"
        wg_area="$(curl -Ssf "${api}${wg_area_url}?format=xml" | \
                      xmllint --xpath '/object/name/text()' /dev/stdin)"
        wg_area="${wg_area% Area}"
        wg_name="$(xmllint --xpath '/response/objects/object[1]/name/text()' "$tmp")"
        wg_type_url="$(xmllint --xpath '/response/objects/object[1]/type/text()' "$tmp")"
        wg_type="$(curl -Ssf "${api}${wg_type_url}?format=xml" | \
                xmllint --xpath '/object/verbose_name/text()' /dev/stdin)"
        wg_mail="$(xmllint --xpath '/response/objects/object[1]/list_email/text()' "$tmp")"
        wg_arch="$(xmllint --xpath '/response/objects/object[1]/list_archive/text()' "$tmp")"
        wg_arch="${wg_arch/#http:/https:}" # Upgrade URLs to https
        rm -f "$tmp"
        trap - EXIT
    else
        rm -f "$tmp"
        trap - EXIT
        return 1
    fi
}
