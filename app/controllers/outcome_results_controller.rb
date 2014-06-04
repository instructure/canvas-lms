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
#           "description": "The rollup score for the outcome, based on the student alignment scores related to the outcome. This could be null if the student has no related scores.",
#           "example": 3,
#           "type": "integer"
#         },
#         "count": {
#           "example": 6,
#           "type": "integer",
#           "description": "The number of alignment scores included in this rollup."
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
#           "description": "The name of this alignment",
#           "example": "Big mid-term test",
#           "type": "string"
#         },
#         "html_url": {
#           "description": "(Optional) A URL for details about this alignment",
#           "type": "string"
#         }
#       }
#     }
#
# @model OutcomePath
#     {
#       "id": "OutcomePath",
#       "description": "The full path to an outcome",
#       "properties": {
#         "id": {
#           "example": "42",
#           "type": "integer",
#           "description": "A unique identifier for this outcome"
#         },
#         "parts": {
#           "description": "an array of OutcomePathPart objects",
#           "$ref": "OutcomePathPart"
#         }
#       }
#     }
#
# @model OutcomePathPart
#     {
#       "id": "OutcomePathPart",
#       "description": "An outcome or outcome group",
#       "properties": {
#         "name": {
#           "example": "Spelling out numbers",
#           "type": "string",
#           "description": "The title of the outcome or outcome group"
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
  # @argument include[] [Optional, String, "alignments"|"outcomes"|"outcomes.alignments"|"outcome_groups"|"outcome_links"|"outcome_paths"|"users"]
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
  # @argument include[] [Optional, String, "courses"|"outcomes"|"outcomes.alignments"|"outcome_groups"|"outcome_links"|"outcome_paths"|"users"]
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
  #        // (Optional) Included if include[] has outcome_paths
  #        "outcome_paths": [OutcomePath]
  #
  #        // (Optional) Included if include[] has outcomes.alignments
  #        "outcomes.alignments": [OutcomeAlignment]
  #      }
  #    }
  def rollups
    respond_to do |format|
      format.json do
        json = case params[:aggregate]
          when 'course' then aggregate_rollups_json
          else user_rollups_json
        end
        json[:linked] = linked_include_collections if params[:include].present?
        render json: json if json
      end
      format.csv do
        build_outcome_paths
        send_data(
          outcome_results_rollups_csv(user_rollups, @outcomes, @outcome_paths),
          :type => "text/csv",
          :filename => t('outcomes_filename', "Outcomes").gsub(/ /, "_") + "-" + @context.name.to_s.gsub(/ /, "_") + ".csv",
          :disposition => "attachment"
        )
      end
    end
  end

  private

  def user_rollups(opts = {})
    @results = find_outcome_results(users: @users, context: @context, outcomes: @outcomes).includes(:user)
    outcome_results_rollups(@results, @users)
  end

  def user_rollups_json
    @users = Api.paginate(@users, self, api_v1_course_outcome_rollups_url(@context))
    json = outcome_results_rollups_json(user_rollups)
    json[:meta] = Api.jsonapi_meta(@users, self, api_v1_course_outcome_rollups_url(@context))
    json
  end

  def aggregate_rollups_json
    # calculating averages for all users in the context and only returning one
    # rollup, so don't paginate users in ths method.
    @results = find_outcome_results(users: @users, context: @context, outcomes: @outcomes)
    aggregate_rollups = [aggregate_outcome_results_rollup(@results, @context)]
    json = aggregate_outcome_results_rollups_json(aggregate_rollups)
    # no pagination, so no meta field
    json
  end

  def linked_include_collections
    linked = {}
    includes = Api.value_to_array(params[:include])
    includes.uniq.each do |include_name|
      linked[include_name] = self.send(include_method_name(include_name))
    end
    linked
  end

  def include_courses
    outcome_results_linked_courses_json([@context])
  end

  def include_outcomes
    outcome_results_include_outcomes_json(@outcomes)
  end

  def include_outcome_groups
    outcome_results_include_outcome_groups_json(@outcome_groups)
  end

  def include_outcome_links
    outcome_results_include_outcome_links_json(@outcome_links)
  end

  def include_outcome_paths
    build_outcome_paths
    @outcome_paths
  end

  def include_users
    outcome_results_linked_users_json(@users)
  end

  def include_alignments
    alignments = ContentTag.where(id: @results.map(&:content_tag_id)).includes(:content).map(&:content).uniq
    outcome_results_include_alignments_json(alignments)
  end

  def include_outcomes_alignments
    alignments = ContentTag.learning_outcome_alignments.not_deleted.where(learning_outcome_id: @outcomes).includes(:content).map(&:content).uniq
    outcome_results_include_alignments_json(alignments)
  end

  def require_outcome_context
    reject! "invalid context type" unless @context.is_a?(Course)

    return true if is_authorized_action?(@context, @current_user, [:manage_grades, :view_all_grades])
    reject! "users not specified and no access to all grades", :forbidden unless params[:user_ids]
    user_ids = Api.value_to_array(params[:user_ids]).map(&:to_i).uniq
    enrollments = @context.enrollments.where(user_id: user_ids)
    reject! "specified users not enrolled" unless enrollments.length == user_ids.length
    reject! "not authorized to read grades for specified users", :forbidden unless enrollments.all? do |e|
      is_authorized_action?(e, @current_user, :read_grades)
    end
  end

  def verify_aggregate_parameter
    aggregate = params[:aggregate]
    reject! "invalid aggregate parameter value" if aggregate && !%w(course).include?(aggregate)
    true
  end

  def verify_include_parameter
    Api.value_to_array(params[:include]).each do |include_name|
      case include_name
      when 'courses'
        reject! "can't include courses unless aggregate is 'course'" if params[:aggregate] != 'course'
      when 'users'
        reject! "can't include users unless aggregate is not set" if params[:aggregate].present?
      else
        reject! "invalid include: #{include_name}" unless self.respond_to? include_method_name(include_name), :include_private
      end
    end
    true
  end

  def include_method_name(include_name)
    "include_#{include_name.parameterize.underscore}"
  end

  def require_outcomes
    @outcome_groups = @context.learning_outcome_groups
    outcome_group_ids = @outcome_groups.pluck(:id)
    @outcome_links = ContentTag.learning_outcome_links.active.where(associated_asset_id: outcome_group_ids).includes(:learning_outcome_content)
    reject! "can't filter by both outcome_ids and outcome_group_id" if params[:outcome_ids] && params[:outcome_group_id]
    if params[:outcome_ids]
      outcome_ids = Api.value_to_array(params[:outcome_ids]).map(&:to_i).uniq
      @outcomes = @outcome_links.map(&:learning_outcome_content).select{ |outcome| outcome_ids.include?(outcome.id) }
      reject! "can only include id's of outcomes in the outcome context" if @outcomes.count != outcome_ids.count
    elsif params[:outcome_group_id]
      group_id = params[:outcome_group_id].to_i
      reject! "can only include an outcome group id in the outcome context" unless outcome_group_ids.include?(group_id)
      @outcomes = @outcome_links.where(associated_asset_id: group_id).map(&:learning_outcome_content)
    else
      @outcomes = @outcome_links.map(&:learning_outcome_content)
    end
  end

  def build_outcome_paths
    @outcome_paths = @outcome_links.map do |link|
      parts = outcome_group_prefix(link.associated_asset).push({name: link.learning_outcome_content.title})
      {id: link.learning_outcome_content.id, parts: parts}
    end
  end

  def outcome_group_prefix(group)
    if !group.parent_outcome_group
      return []
    end
    outcome_group_prefix(group.parent_outcome_group).push({name: group.title})
  end

  def require_users
    reject! "cannot specify both user_ids and section_id" if params[:user_ids] && params[:section_id]

    if params[:user_ids]
      user_ids = Api.value_to_array(params[:user_ids]).map(&:to_i).uniq
      @users = users_for_outcome_context.where(id: user_ids).uniq
      reject!( "can only include id's of users in the outcome context") if @users.count != user_ids.count
    elsif params[:section_id]
      @section = @context.course_sections.where(id: params[:section_id].to_i).first
      reject! "invalid section id" unless @section
      @users = @section.students
    end
    @users ||= users_for_outcome_context
    @users = @users.order(:id)
  end

  def users_for_outcome_context
    # this only works for courses; when other context types are added, this will
    # need to treat them differently.
    @context.students
  end
end
