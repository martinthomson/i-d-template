#!/usr/bin/env bash

err=0
while read -r local_ref local_sha remote_ref remote_sha; do
    if [[ "${local_ref#refs/tags/draft-}" != "${local_ref}" ]]; then
	tag="${local_ref#refs/tags/}"
        if [[ -z "$(git for-each-ref --format '%(taggeremail)' "${local_ref}")" ]]; then
            echo "pre-push: tag $tag is not an annotated tag" 1>&2
	    err=1
	fi
	if ! git ls-tree --name-only "$local_sha" | grep -q "^${tag%-*}\."; then
	    echo "pre-push: tag $tag does not match an existing file" 1>&2
	    err=1
	fi
    fi
done
[[ $err -eq 0 ]] || echo "pre-push: use git push --no-verify to override this check" 1>&2
exit $err
