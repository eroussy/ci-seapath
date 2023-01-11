#!/bin/bash

GITHUB_REF=$1
CI_DIR=/home/eroussy/Documents/RTE/ci-seapath

PR_N=`echo $GITHUB_REF | cut -d '/' -f 3`
TIME=`date +%Hh%Mm%S`

# Get sources
CLONE_DIR=/tmp/ansible_PR-${PR_N}_${TIME}
git clone git@github.com:eroussy/ansible.git $CLONE_DIR
cd $CLONE_DIR
git fetch origin ${GITHUB_REF}
git checkout FETCH_HEAD


# Launch tests
CUKINIA_TEST_DIR=/tmp/cukinia-test_PR-${PR_N}_${TIME}
mkdir $CUKINIA_TEST_DIR
cukinia -f junitxml -o $CUKINIA_TEST_DIR/cukinia.xml $CLONE_DIR/cukinia.conf


# Create report
REPORT=test-report_pr-${PR_N}_${TIME}.pdf
cd $CI_DIR/report-generator
CQFD_EXTRA_RUN_ARGS="-v ${CUKINIA_TEST_DIR}:/tmp/cukinia-res" cqfd run
cd ..


# Upload report
REPORT_PR_DIR=PR-${PR_N}
mkdir -p docs/reports/$REPORT_PR_DIR
mv report-generator/main.pdf docs/reports/${REPORT_PR_DIR}/${REPORT}
# TODO : what if local changes
git switch site
git add docs/reports/${REPORT_PR_DIR}/${REPORT}
git commit -m "upload report $REPORT"
git push origin site
gh api --method POST   -H "Accept: application/vnd.github+json" \
/repos/eroussy/ansible/pulls/${PR_N}/reviews -f event='COMMENT' \
-f body="Report available at \
https://eroussy.github.io/ci-seapath/reports/${REPORT_PR_DIR}/${REPORT}"
git switch main

# grep for succes
if grep -q "<failure" $CUKINIA_TEST_DIR/*; then
  exit 1
else
  exit 0
fi

# remove github clone dir and cukinia test dir
rm -rf $CLONE_DIR $CUKINIA_TEST_DIR
