# iesdp

Visible at: https://gibberlings3.github.io/iesdp/

# structural changes so far
- partly jekyllized
- all pages have the same header and footer (with search)
- index page date display is automatically refreshed on each change
- fixed logo overlaying text, making the FAQ inaccessible
- logo is a link to the main page
- added quickjump menu to opcode lists
- added quickjump button to all pages (hidden by default)
- added forum link to the main menu
- added forum&github links to the landing page
- opcodes are now in individual files and partly merged for easier comparison
- opcodes partly use styled notes
- opcodes now have links to versions in other engines

# content changes
- fixed chargen title
- changelog note added
- imported old releases back to 2002
- integrated Argent77's fixes
- removed various typos and copy/paste errors
- fixed opcode count for totl
- clarified missing opcodes for iwd2 (20, 36-37, 182, 187) and pst (80, 81)
- fixed inaccessible iwd1 ids file

# how it works
Since Github pages don't allow plugins, we have to use an extra step in
deployment. Travis, when checking for syntax errors, also pushes the resulting
Jekyll build back to the gh-pages branch. That is what is displayed if you
visit the URL at the top. Actual work happens on the master branch.

Handy cheat sheet: http://jekyll.tips/jekyll-cheat-sheet/
