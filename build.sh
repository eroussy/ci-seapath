#!/bin/bash
set -e

# CI_DIR=/tmp/seapath-ci-${RANDOM}
# mkdir $CI_DIR
# cd $CI_DIR
# git clone --depth 1 -b test-perso git@github.com:eroussy/ci-seapath.git ci
# ci/build.sh $GITHUB_REF

GITHUB_REF=$1
CI_DIR=`pwd`
PR_N=`echo $GITHUB_REF | cut -d '/' -f 3`
TIME=`date +%Hh%Mm%S`

# Get sources
git clone git@github.com:eroussy/ansible.git
cd ansible
git fetch origin ${GITHUB_REF}
git checkout FETCH_HEAD

# Launch tests
mkdir $CI_DIR/cukinia_tests
cukinia -f junitxml -o $CI_DIR/cukinia_tests/cukinia.xml $CI_DIR/ansible/cukinia.conf

# Create report
REPORT=test-report_pr-${PR_N}_${TIME}.pdf
cd $CI_DIR/ci/report-generator
CQFD_EXTRA_RUN_ARGS="-v ${CI_DIR}/cukinia_tests:/tmp/cukinia-res" cqfd run

# Upload report
cd $CI_DIR
REPORT_PR_DIR=PR-${PR_N}
git clone --depth 1 -b site git@github.com:eroussy/ci-seapath.git $CI_DIR/site
cd $CI_DIR/site
mkdir -p docs/reports/$REPORT_PR_DIR
mv $CI_DIR/ci/report-generator/main.pdf docs/reports/${REPORT_PR_DIR}/${REPORT}

git add docs/reports/${REPORT_PR_DIR}/${REPORT}
git commit -m "upload report $REPORT"
git push origin site

gh api --method POST   -H "Accept: application/vnd.github+json" \
/repos/eroussy/ansible/pulls/${PR_N}/reviews -f event='COMMENT' \
-f body="Report available at \
https://eroussy.github.io/ci-seapath/reports/${REPORT_PR_DIR}/${REPORT}"

# grep for succes
if grep -q "<failure" $CI_DIR/cukinia_tests/*; then
  RES=1
else
  RES=0
fi

# remove github clone dir and cukinia test dir
rm -rf $CI_DIR
exit $RES
