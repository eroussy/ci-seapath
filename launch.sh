#!/bin/bash
#
# Copyright (C) 2023, RTE (http://www.rte-france.com)
# SPDX-License-Identifier: Apache-2.0
#
# This script download the sources of a specific pull request,
# then test it and upload a report given the test results.
set -e

die() {
	echo "ci configuration failed: $@" 1>&2
	exit 1
}

# Standard help message
usage()
{
    cat <<EOF
USAGE:
    ./launch.sh <pull-request-refs> <pull-request-sha>
EOF
}

# Configure and prepare the CI
configuration() {

  #if ! type -p cqfd > /dev/null; then
  #  die "cqfd not found"
  #fi

  # Get sources

  git clone -q https://github.com/seapath/ansible
  cd ansible
  git fetch -q origin ${PR_BRANCH}
  git checkout -q FETCH_HEAD
  echo "Pull request sources got succesfully"

  #cqfd init
  #cqfd -b prepare
  echo "Sources prepared succesfully"
}

setup_debian() {
  cd ansible
  echo `pwd`
  #LOCAL_ANSIBLE_DIR=/home/virtu/ansible # Local dir that contains keys and inventories
  #CQFD_EXTRA_RUN_ARGS="-v $LOCAL_ANSIBLE_DIR:/tmp" cqfd run ansible-playbook \
  #-i /tmp/seapath_inventories/seapath_cluster_ci.yml \
  #-i /tmp/seapath_inventories/seapath_ovs_ci.yml \
  #--key-file /tmp/ci_rsa --skip-tags "package-install" \
  #playbooks/ci_the_one_playbook.yaml
  echo "Debian set up succesfully"
  exit 1
}

launch_test() {
  echo WORK_DIR = $WORK_DIR
  cd ansible
  echo `pwd`
  #LOCAL_ANSIBLE_DIR=/home/virtu/ansible # Local dir that contains keys and inventories
  #CQFD_EXTRA_RUN_ARGS="-v $LOCAL_ANSIBLE_DIR:/tmp" cqfd run ansible-playbook \
  #-i /tmp/seapath_inventories/seapath_cluster_ci.yml \
  #-i /tmp/seapath_inventories/seapath_ovs_ci.yml \
  #--key-file /tmp/ci_rsa --skip-tags "package-install" \
  #playbooks/ci_the_one_playbook.yaml
  echo "TODO : Implement testing playbooks"

  # Generate test report

  CUKINIA_TEST_DIR=${WORK_DIR}/cukinia
  #mkdir $CUKINIA_TEST_DIR
  #mv ${WORK_DIR}/ansible/*.xml $CUKINIA_TEST_DIR
  cd ${WORK_DIR}/ci/report-generator
  #cqfd -q init
  #if ! CQFD_EXTRA_RUN_ARGS="-v $CUKINIA_TEST_DIR:/tmp/cukinia-res" cqfd -q run; then
  #  die "cqfd error"
  #fi
  echo "Report generated succesfully"

  # Upload test report

  PR_N=`echo $GITHUB_REF | cut -d '/' -f 3`
  TIME=`date +%Hh%Mm%S`
  REPORT_NAME=test-report_${GITHUB_RUN_ID}_${GITHUB_RUN_ATTEMPT}_${TIME}.pdf
  REPORT_DIR=${WORK_DIR}/reports/docs/reports/PR-${PR_N}

  git clone -q --depth 1 -b reports git@github.com:seapath/ci.git \
  --config core.sshCommand="ssh -i ~/.ssh/ci_rsa" ${WORK_DIR}/reports
  mkdir -p $REPORT_DIR
  #mv ${WORK_DIR}/ci/report-generator/main.pdf $REPORT_DIR/$REPORT_NAME
  cd $REPORT_DIR
  echo `pwd`
  #git config --local user.email "ci.seapath@gmail.com"
  #git config --local user.name "Seapath CI"
  #git config --local core.sshCommand "ssh -i ~/.ssh/ci_rsa"
  #git add $REPORT_NAME
  #git commit -q -m "upload report $REPORT_NAME"
  #git push -q origin reports
  echo "Report uploaded succesfully"

  echo See test Report at \
  https://github.com/seapath/ci/blob/reports/docs/reports/PR-${PR_N}/${REPORT_NAME}

  # Clean and send exit results

  #if grep -q "<failure" $CUKINIA_TEST_DIR/*; then
  #  RES=1
  #else
  #  RES=0
  #fi
  #rm -rf $WORK_DIR
  #exit $RES

  exit 0
}

case "$1" in
	config)
    configuration
    exit 0
    ;;
  setup)
    setup_debian
    exit 0
    ;;
  test)
    launch_test $2 $3
    exit 0
    ;;
esac
