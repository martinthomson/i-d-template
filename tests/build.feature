Feature: Building drafts

  Scenario: Single Kramdown draft can build
    Given a configured git repo with a Kramdown draft
     when make is run
     then it succeeds
     and generates documents

  Scenario: Multiple Kramdown drafts can build
    Given a configured git repo with multiple Kramdown drafts
     when make is run
     then it succeeds
     and generates documents

  Scenario: Incorrect Kramdown draft fails
     Given a configured git repo with a Kramdown draft
     when the draft is broken
     and make is run
     then it fails

#   Scenario: Mmark draft can build
#     Given a configured git repo with an Mmark draft
#      when we run make
#      then make succeeds and generates documents
#
#  Scenario: Incorrect Mmark draft fails
#    Given a configured git repo with a Mmark draft
#    when we break the draft and run make
#    then make fails
