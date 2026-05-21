Feature: Uploading drafts

  Scenario: Simple draft upload works
    Given a configured git repo with a Kramdown draft
     and the repo is tagged
     when make "upload" is run with "curl=f() { echo "HTTP/1.1 200 OK" >>"$$HEADER"; echo "curl $$@" >> $@; };f"
     then it succeeds
     and generates upload files

  Scenario: HTTP/2 draft upload works
    Given a configured git repo with a Kramdown draft
     and the repo is tagged
     when make "upload" is run with "curl=f() { echo "HTTP/2 200" >>"$$HEADER"; echo "curl $$@" >> $@; };f"
     then it succeeds
     and generates upload files

  Scenario: Multiple draft upload works
    Given a configured git repo with multiple Kramdown drafts
     and the repo is tagged
     when make "upload" is run with "curl=f() { echo "HTTP/1.1 200 OK" >>"$$HEADER"; echo "curl $$@" >> $@; };f"
     then it succeeds
     and generates upload files

  Scenario: Failing to upload shows error message
    Given a configured git repo with a Kramdown draft
     and the repo is tagged
     when make "upload" is run with "curl=f() { echo "HTTP/1.1 400 Bad Request" >>"$$HEADER"; echo "curl $$@" >> $@; echo '{"messages": ["Invalid request"] }' >>$@; };f"
     then it fails
     and generates a message "Invalid request"
