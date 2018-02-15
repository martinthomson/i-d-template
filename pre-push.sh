#!/bin/bash

err=0
while read local_ref local_sha remote_ref remote_sha; do
    if [[ "${local_ref#refs/tags/draft-}" != "${local_ref}" && \
          -z "$(git for-each-ref --format '%(taggeremail)' "${local_ref}")" ]]; then
        echo "pre-push: tag ${local_ref#refs/tags/} is not an annotated tag" 1>&2
	err=1
    fi
done
[[ $err -eq 0 ]] || echo "pre-push: Use git push --no-verify to override this check" 1>&2
exit $err
