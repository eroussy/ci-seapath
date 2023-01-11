#!/bin/bash
set -e

GITHUB_REF=$1
CI_DIR=`pwd`
PR_N=`echo $GITHUB_REF | cut -d '/' -f 3`
TIME=`date +%Hh%Mm%S`

# Get sources
git clone git@github.com:seapath/ansible.git
cd ansible
git fetch origin ${GITHUB_REF}
git checkout FETCH_HEAD

# Launch tests
# TODO: call ansible commands
# TODO: specify directory for cukinia result
CUKINIA_XML_DIR=?


# Create report
REPORT=test-report_pr-${PR_N}_${TIME}.pdf
cd $CI_DIR/ci/report-generator
cqfd init
CQFD_EXTRA_RUN_ARGS="-v ${CUKINIA_XML_DIR}:/tmp/cukinia-res" cqfd run

# Upload report
cd $CI_DIR
REPORT_PR_DIR=PR-${PR_N}
git clone --depth 1 -b site git@github.com:seapath/ci.git $CI_DIR/site
cd $CI_DIR/site
mkdir -p docs/reports/$REPORT_PR_DIR
mv $CI_DIR/ci/report-generator/main.pdf docs/reports/${REPORT_PR_DIR}/${REPORT}
git add docs/reports/${REPORT_PR_DIR}/${REPORT}
git commit -m "upload report $REPORT"
git push origin site

# Give link
echo See test Report at \
https://seapath.github.io/ci/reports/${REPORT_PR_DIR}/${REPORT}

# grep for succes
if grep -q "<failure" $CUKINIA_XML_DIR; then
  RES=1
else
  RES=0
fi

# remove ci temporary directory
rm -rf $CI_DIR
exit $RES
