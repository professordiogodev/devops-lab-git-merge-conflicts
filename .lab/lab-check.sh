#!/usr/bin/env bash
rc=0
grep -q 'ALL CHECKS PASSED' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
grep -qE '^(<<<<<<<|>>>>>>>)' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows the conflict markers" || { echo "- ❌ paste a conflict (with its markers) into SUBMISSION.md"; rc=1; }
exit $rc
