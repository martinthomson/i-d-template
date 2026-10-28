Feature: git integration

  Scenario:  make ghpages
    Given a configured git repo with a Kramdown draft
     when make "ghpages" is run
     then it succeeds
     and a branch is created called "gh-pages" containing "index.html" which contains "compare builds"
     and documents are added to gh-pages
     and a branch is created called "gh-pages" containing "diff.html"
     and a branch is created called "gh-pages" containing "iddiff.js"
     and a branch is created called "gh-pages" containing "builds/index.json" which contains "drafts"

  Scenario:  make ghpages with a non-main default branch
    Given a configured git repo with a Kramdown draft
     and the default branch is "kerfuffle"
     when make "ghpages" is run
     then it succeeds
     and a branch is created called "gh-pages" containing "index.html" which contains "Editor's drafts for kerfuffle branch"
     and a branch is created called "gh-pages" containing "index.html" which contains "referrer_branch = 'kerfuffle'"

  Scenario:  make gharchive
    Given a configured git repo with a Kramdown draft
     when make "ghissues" is run with "PUSH_GHPAGES=false"
     then it succeeds
     and a branch is created called "gh-pages" containing "archive.json"

  Scenario:  git pre-commit hook blocks broken drafts
    Given a configured git repo with a Kramdown draft
     when the draft is broken
     and git commit is run
     then it fails

  Scenario: git pre-commit hook does not block other drafts
    Given a configured git repo with multiple Kramdown drafts
     when the draft is broken
     and a non-broken draft is committed
     then it succeeds
