# IESDP

Visible at: https://gibberlings3.github.io/iesdp/

# How to deploy/test

0. Install dependencies (jekyll, jekyll-liquify)
1. Run: "jekyll serve --incremental" in the top dir of this repo
2. Open the url it prints, usually http://127.0.0.1:4000/iesdp/

# How it works

Since Github pages don't allow plugins, we have to use an extra step in
deployment. Travis, when checking for syntax errors, also pushes the resulting
Jekyll build back to the gh-pages branch. That is what is displayed if you
visit the URL at the top. Actual work happens on the master branch.

Handy cheat sheet: http://jekyll.tips/jekyll-cheat-sheet/
