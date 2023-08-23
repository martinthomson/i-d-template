Feature: Initial setup

  Scenario:  Run setup script on correctly-set-up directory
    Given a git repo with a single Kramdown draft
     when the setup script is run
     then it succeeds
     and a file is created called "Makefile"
     and a file is created called "README.md"
     and a file is created called "CONTRIBUTING.md"
     and a file is created called "LICENSE.md"
     and a file is created called ".gitignore"
     and a file is created called ".circleci/config.yml"
     and a file is created called ".github/workflows/ghpages.yml"
     and a file is created called ".github/workflows/publish.yml"
     and a file is created called ".github/workflows/archive.yml"
     and a file is created called ".github/CODEOWNERS"
     and a file is created called ".editorconfig"
     and a branch is created called "gh-pages" containing "index.html"
     and a branch is created called "gh-pages" containing "archive.json"
     and gitignore lists xml files
     and gitignore negation rules come last
     and a precommit hook is installed

  Scenario:  Run setup script with XSLT on correctly-set-up directory
    Given a git repo with a single Kramdown draft
     when the setup script is run with "USE_XSLT=true"
     then it succeeds
     and a file is created called "Makefile" which contains "USE_XSLT := true"
     and a file is created called "README.md"
     and a file is created called "CONTRIBUTING.md"
     and a file is created called "LICENSE.md"
     and a file is created called ".gitignore"
     and a file is created called ".circleci/config.yml"
     and a file is created called ".github/workflows/ghpages.yml"
     and a file is created called ".github/workflows/publish.yml"
     and a file is created called ".github/workflows/archive.yml"
     and a file is created called ".github/CODEOWNERS"
     and a file is created called ".editorconfig"
     and a branch is created called "gh-pages" containing "index.html"
     and a branch is created called "gh-pages" containing "archive.json"
     and gitignore lists xml files
     and gitignore negation rules come last
     and a precommit hook is installed

  Scenario:  Run setup script with INDEX_FORMAT set
    Given a git repo with a single Kramdown draft
     when the setup script is run with "INDEX_FORMAT=md"
     then it succeeds
     and a file is created called "Makefile" which contains "INDEX_FORMAT := md"
     and a file is created called "README.md"
     and a file is created called "CONTRIBUTING.md"
     and a file is created called "LICENSE.md"
     and a file is created called ".gitignore"
     and a file is created called ".circleci/config.yml"
     and a file is created called ".github/workflows/ghpages.yml"
     and a file is created called ".github/workflows/publish.yml"
     and a file is created called ".github/workflows/archive.yml"
     and a file is created called ".github/CODEOWNERS"
     and a file is created called ".editorconfig"
     and a branch is created called "gh-pages" containing "index.md"
     and a branch is created called "gh-pages" containing "archive.json"
     and gitignore lists xml files
     and gitignore negation rules come last
     and a precommit hook is installed

  Scenario:  Run setup script when the file contains the wrong name
    Given a git repo with a single Kramdown draft
     and drafts are modified with sed -e "s/-latest/-01/g"
     when the setup script is run
     then it fails
     and generates a message "Check names"

  Scenario:  Run setup script on directory with no draft
    Given an empty git repo
      and lib is cloned in
      when the setup script is run
      then it fails
      and generates a message "Create a draft file"

  Scenario:  Run setup script on directory with multiple drafts
    Given a git repo with multiple Kramdown drafts
     when the setup script is run
     then it succeeds
     and gitignore lists xml files

  Scenario:  Run setup script on directory with no origin remote
    Given a git repo with no origin
     and lib is cloned in
     and a Kramdown draft is created
     when the setup script is run
     then it fails
     and generates a message "remote"

  Scenario:  Run setup script on directory without pushing
    Given a git repo with no origin
     and an empty origin remote is added
     and lib is cloned in
     and a Kramdown draft is created
     when the setup script is run
     then it fails
     and generates a message "push"

  Scenario:  Retain .gitignore when running setup
    Given a git repo with a single Kramdown draft
     and a .gitignore with the line "IGNORE-ME"
     when the setup script is run
     then it succeeds
     and gitignore lists "IGNORE-ME"
     and gitignore lists xml files
     and gitignore negation rules come last
