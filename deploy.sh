#!/bin/bash

set -o errexit -o nounset

rev=$(git rev-parse --short HEAD)

cd _site

git init
git config user.name "Travis the automation"
git config user.email "travis@travi.s"

git remote add upstream "https://$GH_TOKEN@github.com/Gibberlings3/iesdp.git"
git fetch upstream
git reset upstream/gh-pages

touch .nojekyll
touch .

git add -A .
git commit -m "rebuild pages at ${rev}"
git push -q upstream HEAD:gh-pages
