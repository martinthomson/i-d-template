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

#	 Scenario: Incorrect Kramdown draft fails
#  	 Given a configured git repo with a Kramdown doc
#  		when we break the draft
#			  and we run make
#  		then make fails
#
#	 Scenario: Mmark draft can build
# 	  Given a configured git repo with an Mmark doc
# 		 when we run make
# 		 then make succeeds and generates documents
#
#  Scenario: Incorrect Mmark draft fails
# 	 Given a configured git repo with a Mmark doc
#		when we break the draft and run make
#		then make fails
