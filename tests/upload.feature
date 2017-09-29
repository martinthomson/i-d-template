Feature: Uploading drafts

  Scenario: Simple draft upload works
    Given a configured git repo with a Kramdown draft
     and the repo is tagged
     when make "upload" is run with "curl=echo"
     then it succeeds
     and generates upload files

  Scenario: Multiple draft upload works
    Given a configured git repo with multiple Kramdown drafts
     and the repo is tagged
     when make "upload" is run with "curl=echo"
     then it succeeds
     and generates upload files

  Scenario: Failing to upload shows error message
    Given a configured git repo with a Kramdown draft
     and the repo is tagged
     when make "upload" is run with "curl=! echo 'curl error: '"
     then it fails
     and generates a message "curl error"
