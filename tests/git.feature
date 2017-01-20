Feature: git integration

  Scenario:  make ghpages
	  Given a configured git repo with a Kramdown draft
     when make ghpages is run
		 then it succeeds
		 and documents are added to gh-pages

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
