#
# Copyright (C) 2013 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# @API Outcome Results
# @beta
#
# API for accessing learning outcome results
#
# @object OutcomeRollupScore
#     {
#
#       // The id of the related outcome
#       "outcome_id": 42,
#
#       // The rollup score for the outcome, based on the student assessment
#       // scores related to the outcome. This could be null if the student has
#       // no related scores.
#       "score": 3
#     }
#
# @object OutcomeRollup
#     {
#       // an array of OutcomeRollupScore objects
#       "scores": ["OutcomeRollupScore"],
#
#       // The id of the resource for this rollup. For example, the user id.
#       "id": 42,
#
#       // The name of the resource for this rollup. For example, the user name.
#       "name": "John Doe"
#     }
#

class OutcomeResultsController < ApplicationController
  include Api::V1::OutcomeResults
  include Outcomes::ResultAnalytics

  before_filter :require_user
  before_filter :require_context
  before_filter :require_outcome_context

  # @API Get outcome result rollups
  # @beta
  #
  # Gets the outcome rollups for the users and outcomes in the specified
  # context.
  #
  # @example_response
  #    {
  #      "rollups": [OutcomeRollup],
  #      "linked": {
  #        "outcomes": [Outcome]
  #      }
  #    }
  def rollups
    @outcomes = @context.linked_learning_outcomes
    @users = users_for_outcome_context
    # TODO: will this work if users are spread across shards?
    @users = Api.paginate(@users, self, api_v1_course_outcome_rollups_url(@context))
    @results = find_outcome_results(users: @users, context: @context, outcomes: @outcomes)
    rollups = rollup_results(@results)
    json = outcome_results_rollup_json(rollups, @outcomes)
    render :json => json
  end

  # Internal: Makes sure the context is a valid context for outcome_results and
  #   the current_user has appropriate permissions. This method is meant to be
  #   used as a before_filter.
  #
  # Returns nothing. May render if current_user does not have permissions.
  def require_outcome_context
    unless @context.is_a?(Course)
      return render :json => {message: "invalid context type"}, :status => :bad_request
    end

    return unless authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
  end

  # Internal: Gets a list of users that should have results returned based on
  #   @context. For courses, this will only return students.
  #
  # Returns an Enumeration of User objects.
  def users_for_outcome_context
    # this only works for courses; when other context types are added, this will
    # need to treat them differently.
    @context.students
  end

end
