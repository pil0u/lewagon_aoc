# frozen_string_literal: true

module Snippets
  class BoxComponent < ApplicationComponent
    include ApplicationHelper

    with_collection_parameter :snippet

    def initialize(snippet:, user:)
      @user = user
      @snippet = snippet

      @user_can_edit_snippet = @snippet.user == @user
      @user_can_discuss_snippet = @snippet.user != @user && @snippet.user.slack_linked? && @user.slack_linked?
      @user_reaction_vote_value = @snippet.reactions.find { _1.user_id == @user.id }

      @discuss_confirm_message = "By clicking this button, you will create a new Slack thread on #aoc and notify the author of the solution. Do you want to proceed?" if @snippet.slack_url.nil?
    end
  end
end
