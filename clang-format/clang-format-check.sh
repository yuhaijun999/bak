#!/bin/bash -eo pipefail
git ls-files | grep -E  '\.(cpp|h|cu|cuh|cxx|hpp|hxx)$' | xargs clang-format -i
if git diff --quiet; then
  echo "Formatting OK!"
else
  echo "Formatting not OK!"
  echo "------------------"
  git --no-pager diff --color
  exit 1
fi
