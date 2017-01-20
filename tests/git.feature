Feature: git integration

  Scenario:  make ghpages
	  Given a configured git repo with a Kramdown draft
     when make ghpages is run
		 then it succeeds
		 and documents are added to gh-pages

#	Scenario:  git pre-commit hook
#	  Given a configured git repo with a Kramdown doc
#		 when we break a draft and commit
#		 then the commit fails
