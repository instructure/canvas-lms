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
# @model OutcomeResult
#     {
#       "id": "OutcomeResult",
#       "description": "A student's result for an outcome",
#       "properties": {
#         "id": {
#           "example": "42",
#           "type": "integer",
#           "description": "A unique identifier for this result"
#         },
#         "score": {
#           "example": 6,
#           "type": "integer",
#           "description": "The student's score"
#         },
#         "links": {
#           "example": "{\"user\"=>\"3\", \"learning_outcome\"=>\"97\", \"alignment\"=>\"53\"}",
#           "description": "Unique identifiers of objects associated with this result"
#         }
#       }
#     }
#
# @model OutcomeRollupScoreLinks
#     {
#       "id": "OutcomeRollupScoreLinks",
#       "description": "",
#       "properties": {
#         "outcome": {
#           "description": "The id of the related outcome",
#           "example": 42,
#           "type": "integer"
#         }
#       }
#     }
#
# @model OutcomeRollupScore
#     {
#       "id": "OutcomeRollupScore",
#       "description": "",
#       "properties": {
#         "score": {
#           "description": "The rollup score for the outcome, based on the student assessment scores related to the outcome. This could be null if the student has no related scores.",
#           "example": 3,
#           "type": "integer"
#         },
#         "links": {
#           "example": "{\"outcome\"=>\"42\"}",
#           "$ref": "OutcomeRollupScoreLinks"
#         }
#       }
#     }
#
# @model OutcomeRollupLinks
#     {
#       "id": "OutcomeRollupLinks",
#       "description": "",
#       "properties": {
#         "course": {
#           "description": "If an aggregate result was requested, the course field will be present Otherwise, the user and section field will be present (Optional) The id of the course that this rollup applies to",
#           "example": 42,
#           "type": "integer"
#         },
#         "user": {
#           "description": "(Optional) The id of the user that this rollup applies to",
#           "example": 42,
#           "type": "integer"
#         },
#         "section": {
#           "description": "(Optional) The id of the section the user is in",
#           "example": 57,
#           "type": "integer"
#         }
#       }
#     }
#
# @model OutcomeRollup
#     {
#       "id": "OutcomeRollup",
#       "description": "",
#       "properties": {
#         "scores": {
#           "description": "an array of OutcomeRollupScore objects",
#           "$ref": "OutcomeRollupScore"
#         },
#         "name": {
#           "description": "The name of the resource for this rollup. For example, the user name.",
#           "example": "John Doe",
#           "type": "string"
#         },
#         "links": {
#           "example": "{\"course\"=>42, \"user\"=>42, \"section\"=>57}",
#           "$ref": "OutcomeRollupLinks"
#         }
#       }
#     }
#
# @model OutcomeAlignment
#     {
#       "id": "OutcomeAlignment",
#       "description": "An asset aligned with this outcome",
#       "properties": {
#         "id": {
#           "description": "A unique identifier for this alignment",
#           "example": "quiz_3",
#           "type": "string"
#         },
#         "name": {
#           "description": "",
#           "example": "Big mid-term test",
#           "type": "string"
#         },
#         "html_url": {
#           "description": "(Optional) A URL for details about this alignment",
#           "type": "string"
#         }
#       }
#     }

class OutcomeResultsController < ApplicationController
  include Api::V1::OutcomeResults
  include Outcomes::ResultAnalytics

  before_filter :require_user
  before_filter :require_context
  before_filter :require_outcome_context
  before_filter :verify_aggregate_parameter, only: :rollups
  before_filter :verify_include_parameter
  before_filter :require_outcomes
  before_filter :require_users

  # @API Get outcome results
  # @beta
  #
  # Gets the outcome results for users and outcomes in the specified context.
  #
  # @argument user_ids[] [Optional, Integer]
  #   If specified, only the users whose ids are given will be included in the
  #   results. it is an error to specify an id for a user who is not a student in
  #   the context
  #
  # @argument outcome_ids[] [Optional, Integer]
  #   If specified, only the outcomes whose ids are given will be included in the
  #   results. it is an error to specify an id for an outcome which is not linked
  #   to the context.
  #
  # @argument include[] [Optional, String, "alignments"|"outcomes"|"outcomes.alignments"|"outcome_groups"|"outcome_links"|"users"]
  #   Specify additional collections to be side loaded with the result.
  #   "alignments" includes only the alignments referenced by the returned
  #   results.
  #   "outcomes.alignments" includes all alignments referenced by outcomes in the
  #   context.
  #
  # @example_response
  #    {
  #      outcome_results: [OutcomeResult]
  #    }
  def index
    @results = find_outcome_results(users: @users, context: @context, outcomes: @outcomes)
    @results = Api.paginate(@results, self, api_v1_course_outcome_results_url)
    json = outcome_results_json(@results)
    json[:linked] = linked_include_collections if params[:include].present?
    render json: json
  end

  # @API Get outcome result rollups
  # @beta
  #
  # Gets the outcome rollups for the users and outcomes in the specified
  # context.
  #
  # @argument aggregate [Optional, String, "course"]
  #   If specified, instead of returning one rollup for each user, all the user
  #   rollups will be combined into one rollup for the course that will contain
  #   the average rollup score for each outcome.
  #
  # @argument user_ids[] [Optional, Integer]
  #   If specified, only the users whose ids are given will be included in the
  #   results or used in an aggregate result. it is an error to specify an id
  #   for a user who is not a student in the context
  #
  # @argument outcome_ids[] [Optional, Integer]
  #   If specified, only the outcomes whose ids are given will be included in the
  #   results. it is an error to specify an id for an outcome which is not linked
  #   to the context.
  #
  # @argument include[] [Optional, String, "courses"|"outcomes"|"outcomes.alignments"|"outcome_groups"|"outcome_links"|"users"]
  #   Specify additional collections to be side loaded with the result.
  #
  # @example_response
  #    {
  #      "rollups": [OutcomeRollup],
  #      "linked": {
  #        // (Optional) Included if include[] has outcomes
  #        "outcomes": [Outcome],
  #
  #        // (Optional) Included if aggregate is not set and include[] has users
  #        "users": [User],
  #
  #        // (Optional) Included if aggregate is 'course' and include[] has courses
  #        "courses": [Course]
  #
  #        // (Optional) Included if include[] has outcome_groups
  #        "outcome_groups": [OutcomeGroup],
  #
  #        // (Optional) Included if include[] has outcome_links
  #        "outcome_links": [OutcomeLink]
  #
  #        // (Optional) Included if include[] has outcomes.alignments
  #        "outcomes.alignments": [OutcomeAlignment]
  #      }
  #    }
  def rollups
    json = case params[:aggregate]
      when 'course' then aggregate_rollups
      else user_rollups
    end
    json[:linked] = linked_include_collections if params[:include].present?
    render json: json if json
  end

  # Internal: Renders rollups for each user.
  #
  # Returns nothing.
  def user_rollups
    @users = Api.paginate(@users, self, api_v1_course_outcome_rollups_url(@context))
    @results = find_outcome_results(users: @users, context: @context, outcomes: @outcomes)
    rollups = outcome_results_rollups(@results, @users)
    json = outcome_results_rollups_json(rollups)
    json[:meta] = Api.jsonapi_meta(@users, self, api_v1_course_outcome_rollups_url(@context))
    json
  end

  # Internal: Renders the aggregate rollups for the context.
  #
  # Returns nothing.
  def aggregate_rollups
    # calculating averages for all users in the context and only returning one
    # rollup, so don't paginate users in ths method.
    @results = find_outcome_results(users: @users, context: @context, outcomes: @outcomes)
    aggregate_rollups = [aggregate_outcome_results_rollup(@results, @context)]
    json = aggregate_outcome_results_rollups_json(aggregate_rollups)
    # no pagination, so no meta field
    json
  end

  # Internal: Adds linked collections to rollup json result based on the
  # include[] parameter
  #
  # json - the Hash to add a linked field to.
  #
  # Returns a result Hash that should be merged into the linked section.
  def linked_include_collections
    linked = {}
    includes = Api.value_to_array(params[:include])
    includes.uniq.each do |include_name|
      linked[include_name] = self.send(include_method_name(include_name))
    end
    linked
  end

  # Internal: Serialize courses for the context.
  #
  # currently the only course we ever need is @context itself.
  #
  # Returns an Array of serialized courses.
  def include_courses
    outcome_results_linked_courses_json([@context])
  end

  # Internal: Serialize @outcomes for the context.
  #
  # Returns an Array of serialized outcomes.
  def include_outcomes
    outcome_results_include_outcomes_json(@outcomes)
  end

  # Internal: Query and serialize outcome groups for the context.
  #
  # Returns an Array of serialized outcome groups.
  def include_outcome_groups
    groups = @context.learning_outcome_groups
    outcome_results_include_outcome_groups_json(groups)
  end

  # Internal: Query and serialize outcome links for the context.
  #
  # Returns an Array of serialized outcome links.
  def include_outcome_links
    links = @context.learning_outcome_links
    outcome_results_include_outcome_links_json(links)
  end

  # Internal: Serialize users for the context.
  #
  # Returns an Array of serialized users.
  def include_users
    outcome_results_linked_users_json(@users)
  end

  # Internal: Query and serialize alignments for @results
  #
  # Returns an Array of serialized alignments
  def include_alignments
    alignments = @results.map(&:alignment).map(&:content).uniq
    outcome_results_include_alignments_json(alignments)
  end

  # Internal: Query and serialize alignments for @outcomes
  #
  # Returns an Array of serialized alignments
  def include_outcomes_alignments
    alignments = @outcomes.map(&:alignments).flatten.map(&:content).uniq
    outcome_results_include_alignments_json(alignments)
  end

  # Internal: Makes sure the context is a valid context for outcome_results and
  #   the current_user has appropriate permissions. This method is meant to be
  #   used as a before_filter.
  #
  # Returns nothing. May raise if current_user does not have permissions.
  def require_outcome_context
    reject! "invalid context type" unless @context.is_a?(Course)

    authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
  end

  # Internal: Verifies the aggregate parameter.
  #
  # Raises an ApiError error if the aggregate parameter is invalid.
  #   Returns true otherwise.
  def verify_aggregate_parameter
    aggregate = params[:aggregate]
    reject! "invalid aggregate parameter value" if aggregate && !%w(course).include?(aggregate)
    true
  end

  # Internal: Verifies the include[] parameter
  #
  # Raises an ApiError if the include parameter is invalid
  #  Returns true otherwise
  def verify_include_parameter
    params[:include] ||= []
    Api.value_to_array(params[:include]).each do |include_name|
      case include_name
      when 'courses'
        reject! "can't include courses unless aggregate is 'course'" if params[:aggregate] != 'course'
      when 'users'
        reject! "can't include users unless aggregate is not set" if params[:aggregate].present?
      else
        reject! "invalid include: #{include_name}" unless self.respond_to? include_method_name(include_name)
      end
    end
    true
  end

  # Internal: Returns the potential method name for the include parameter value.
  def include_method_name(include_name)
    "include_#{include_name.parameterize.underscore}"
  end

  # Internal: Finds context outcomes
  #
  # Returns an outcome scope
  def require_outcomes
    @outcomes = @context.linked_learning_outcomes
    reject! "can't filter by both outcome_ids and outcome_group_id" if params[:outcome_ids] && params[:outcome_group_id]
    if params[:outcome_ids]
      outcome_ids = Api.value_to_array(params[:outcome_ids]).map(&:to_i).uniq
      @outcomes = @outcomes.where(id: outcome_ids)
      reject! "can only include id's of outcomes in the outcome context" if @outcomes.count != outcome_ids.count
    elsif params[:outcome_group_id]
      outcome_group = @context.learning_outcome_groups.where(id: params[:outcome_group_id].to_i).first
      reject! "can only include an outcome group id in the outcome context" unless outcome_group
      @outcomes = outcome_group.child_outcome_links.map(&:content)
    end
  end

  # Internal: Filter context users by user_ids param (if provided), ensuring
  #  that user_ids does not include users not in the context.
  #
  # Raises an ApiError if user_ids includes a user outside the
  #  context. Returns a User scope otherwise.
  def require_users
    reject! "cannot specify both user_ids and section_id" if params[:user_ids] && params[:section_id]

    if params[:user_ids]
      user_ids = Api.value_to_array(params[:user_ids]).map(&:to_i).uniq
      @users = users_for_outcome_context.where(id: user_ids)
      reject!( "can only include id's of users in the outcome context") if @users.count != user_ids.count
    elsif params[:section_id]
      @section = @context.course_sections.where(id: params[:section_id].to_i).first
      reject! "invalid section id" unless @section
      @users = @section.students
    end
    @users ||= users_for_outcome_context
    @users = @users.order(:id)
  end

  # Internal: Gets a list of users that should have results returned based on
  #   @context. For courses, this will only return students.
  #
  # Returns a User scope.
  def users_for_outcome_context
    # this only works for courses; when other context types are added, this will
    # need to treat them differently.
    @context.students
  end
end
