# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex
# Updated files in paths in code_coverage_file_list.json will trigger code coverage workflows.
# Updates in a pull request will generate a code coverage report in a PR.

# Get most rescent ancestor commit.
common_commit=$(git merge-base remotes/origin/${pr_branch} remotes/origin/${GITHUB_BASE_REF})
target_branch_head=$(git rev-parse remotes/origin/${GITHUB_BASE_REF})
echo "The common commit is ${common_commit}."
echo "The target branch head commit is ${target_branch_head}."
# Set target branch head and this will be used to compare diffs of coverage to the current commit.
echo "::set-output name=target_branch_head::${target_branch_head}"

cd scripts/health_metrics/generate_code_coverage_report

# List changed file from the base commit. This is generated by comparing the
# head of the branch and the common commit from the master branch.
git diff --name-only remotes/origin/${GITHUB_BASE_REF} ${GITHUB_SHA} > updated_files.txt

swift run UpdatedFilesCollector --changed-file-paths updated_files.txt --code-coverage-file-patterns ../code_coverage_file_list.json
