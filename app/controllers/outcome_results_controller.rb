#
# Copyright (C) 2013 - present Instructure, Inc.
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
#         "submitted_or_assessed_at": {
#           "example": "2013-02-01T00:00:00-06:00",
#           "type": "datetime",
#           "description": "The datetime the resulting OutcomeResult was submitted at, or absent that, when it was assessed."
#         },
#         "links": {
#           "example": {"user": "3", "learning_outcome": "97", "alignment": "53"},
#           "type": "object",
#           "description": "Unique identifiers of objects associated with this result"
#         },
#         "percent": {
#           "example": "0.65",
#           "type": "number",
#           "description": "score's percent of maximum points possible for outcome, scaled to reflect any custom mastery levels that differ from the learning outcome"
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
#           "example": {"outcome": "42"},
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
#           "description": "If an aggregate result was requested, the course field will be present. Otherwise, the user and section field will be present (Optional) The id of the course that this rollup applies to",
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
#           "example": {"course": 42, "user": 42, "section": 57},
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
  include Outcomes::Enrollments
  include Outcomes::ResultAnalytics

  before_action :require_user
  before_action :require_context
  before_action :require_outcome_context
  before_action :verify_aggregate_parameter, only: :rollups
  before_action :verify_aggregate_stat_parameter, only: :rollups
  before_action :verify_sort_parameters, only: :rollups
  before_action :verify_include_parameter
  before_action :require_outcomes
  before_action :require_users

  # @API Get outcome results
  #
  # Gets the outcome results for users and outcomes in the specified context.
  #
  # @argument user_ids[] [Integer]
  #   If specified, only the users whose ids are given will be included in the
  #   results. SIS ids can be used, prefixed by "sis_user_id:".
  #   It is an error to specify an id for a user who is not a student in
  #   the context.
  #
  # @argument outcome_ids[] [Integer]
  #   If specified, only the outcomes whose ids are given will be included in the
  #   results. it is an error to specify an id for an outcome which is not linked
  #   to the context.
  #
  # @argument include[] [String, "alignments"|"outcomes"|"outcomes.alignments"|"outcome_groups"|"outcome_links"|"outcome_paths"|"users"]
  #   Specify additional collections to be side loaded with the result.
  #   "alignments" includes only the alignments referenced by the returned
  #   results.
  #   "outcomes.alignments" includes all alignments referenced by outcomes in the
  #   context.
  #
  # @argument include_hidden [Boolean]
  #   If true, results that are hidden from the learning mastery gradebook and student rollup
  #   scores will be included
  #
  # @example_response
  #    {
  #      outcome_results: [OutcomeResult]
  #    }
  def index
    @results = find_results(
      include_hidden: value_to_boolean(params[:include_hidden])
    )
    @results = Api.paginate(@results, self, api_v1_course_outcome_results_url)
    json = outcome_results_json(@results)
    json[:linked] = linked_include_collections if params[:include].present?
    render json: json
  end

  # @API Get outcome result rollups
  #
  # Gets the outcome rollups for the users and outcomes in the specified
  # context.
  #
  # @argument aggregate [String, "course"]
  #   If specified, instead of returning one rollup for each user, all the user
  #   rollups will be combined into one rollup for the course that will contain
  #   the average (or median, see below) rollup score for each outcome.
  #
  # @argument aggregate_stat [String, "mean"|"median"]
  #   If aggregate rollups requested, then this value determines what
  #   statistic is used for the aggregate. Defaults to "mean" if this value
  #   is not specified.
  #
  # @argument user_ids[] [Integer]
  #   If specified, only the users whose ids are given will be included in the
  #   results or used in an aggregate result. it is an error to specify an id
  #   for a user who is not a student in the context
  #
  # @argument outcome_ids[] [Integer]
  #   If specified, only the outcomes whose ids are given will be included in the
  #   results. it is an error to specify an id for an outcome which is not linked
  #   to the context.
  #
  # @argument include[] [String, "courses"|"outcomes"|"outcomes.alignments"|"outcome_groups"|"outcome_links"|"outcome_paths"|"users"]
  #   Specify additional collections to be side loaded with the result.
  #
  # @argument exclude[] [String, "missing_user_rollups"]
  #   Specify additional values to exclude. "missing_user_rollups" excludes
  #   rollups for users without results.
  #
  # @argument sort_by [String, "student"|"outcome"]
  #   If specified, sorts outcome result rollups. "student" sorting will sort
  #   by a user's sortable name. "outcome" sorting will sort by the given outcome's
  #   rollup score. The latter requires specifying the "sort_outcome_id" parameter.
  #   By default, the sort order is ascending.
  #
  # @argument sort_outcome_id [Integer]
  #   If outcome sorting requested, then this determines which outcome to use
  #   for rollup score sorting.
  #
  # @argument sort_order [String, "asc", "desc"]
  #   If sorting requested, then this allows changing the default sort order of
  #   ascending to descending.
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

  def find_results(opts = {})
    find_outcome_results(@current_user, users: @users, context: @context, outcomes: @outcomes, **opts)
  end

  def user_rollups(_opts = {})
    excludes = Api.value_to_array(params[:exclude]).uniq
    @results = find_results.preload(:user)
    outcome_results_rollups(@results, @users, excludes)
  end

  def remove_users_with_no_results
    userids_with_results = find_results.pluck(:user_id).uniq
    @users = @users.select { |u| userids_with_results.include? u.id }
  end

  def user_rollups_json
    return user_rollups_sorted_by_score_json if params[:sort_by] == 'outcome' && params[:sort_outcome_id]
    excludes = Api.value_to_array(params[:exclude]).uniq
    # exclude users with no results (if being requested) before we paginate,
    # otherwise we end up with users in the pagination that may have no rollups,
    # which will inflate the pagination total count
    remove_users_with_no_results if excludes.include? 'missing_user_rollups'
    @users = Api.paginate(@users, self, api_v1_course_outcome_rollups_url(@context))
    rollups = user_rollups
    rollups = @users.map {|u| rollups.find {|r| r.context.id == u.id }}.compact if params[:sort_by] == 'student'
    json = outcome_results_rollups_json(rollups)
    json[:meta] = Api.jsonapi_meta(@users, self, api_v1_course_outcome_rollups_url(@context))
    json
  end

  def user_rollups_sorted_by_score_json
    # since we can't sort by rollup score in the db,
    # get all rollups (for all users), order by a given outcome's rollup score
    # (sorting by name for duplicate scores), then reorder users
    # from those rollups, then paginate those users, and finally
    # only include rollups for those users
    missing_score_sort = params[:sort_order] == 'desc' ? CanvasSort::First : CanvasSort::Last
    rollups = user_rollups.sort_by do |r|
      score = r.scores.find {|s| s.outcome.id.to_s == params[:sort_outcome_id]}&.score
      [score || missing_score_sort, Canvas::ICU.collation_key(r.context.sortable_name)]
    end
    rollups.reverse! if params[:sort_order] == 'desc'
    # reorder users by score
    @users = rollups.map(&:context)
    @users = Api.paginate(@users, self, api_v1_course_outcome_rollups_url(@context))
    # only include rollups for the paginated users
    user_ids = @users.map(&:id)
    rollups = rollups.select {|r| user_ids.include? r.context.id }
    json = outcome_results_rollups_json(rollups)
    json[:meta] = Api.jsonapi_meta(@users, self, api_v1_course_outcome_rollups_url(@context))
    json
  end

  def aggregate_rollups_json
    # calculating averages for all users in the context and only returning one
    # rollup, so don't paginate users in this method.
    @results = find_results
    aggregate_rollups = [aggregate_outcome_results_rollup(@results, @context, params[:aggregate_stat])]
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
    alignments = ContentTag.where(id: @results.map(&:content_tag_id)).preload(:content).map(&:content).uniq
    outcome_results_include_alignments_json(alignments)
  end

  def include_outcomes_alignments
    alignments = ContentTag.learning_outcome_alignments.not_deleted.where(learning_outcome_id: @outcomes).preload(:content).map(&:content).uniq
    outcome_results_include_alignments_json(alignments)
  end

  def include_assignments
    assignments = @results.map(&:assignment)
    outcome_results_assignments_json(assignments)
  end

  def require_outcome_context
    reject! "invalid context type" unless @context.is_a?(Course)

    return true if @context.grants_any_right?(@current_user, session, :manage_grades, :view_all_grades)
    reject! "users not specified and no access to all grades", :forbidden unless params[:user_ids]
    user_id_params = Api.value_to_array(params[:user_ids])
    user_ids = Api.map_ids(user_id_params, users_for_outcome_context, @domain_root_account, @current_user)
    verify_readable_grade_enrollments(user_ids)
  end

  def verify_aggregate_parameter
    aggregate = params[:aggregate]
    reject! "invalid aggregate parameter value" if aggregate && !%w(course).include?(aggregate)
    true
  end

  def verify_aggregate_stat_parameter
    aggregate_stat = params[:aggregate_stat]
    reject! "invalid aggregate_stat parameter value" if aggregate_stat && !%w(mean median).include?(aggregate_stat)
    true
  end

  def verify_sort_parameters
    return true unless params[:sort_by]
    sort_by = params[:sort_by]
    reject! "invalid sort_by parameter value" if sort_by && !%w(student outcome).include?(sort_by)
    if sort_by == 'outcome'
      sort_outcome_id = params[:sort_outcome_id]
      reject! "missing required sort_outcome_id parameter value" unless sort_outcome_id
      reject! "invalid sort_outcome_id parameter value" unless sort_outcome_id =~ /\A\d+\z/
    end
    sort_order = params[:sort_order]
    reject! "invalid sort_order parameter value" if sort_by && sort_order && !%w(asc desc).include?(sort_order)
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
    reject! "can't filter by both outcome_ids and outcome_group_id" if params[:outcome_ids] && params[:outcome_group_id]

    @outcome_groups = @context.learning_outcome_groups
    outcome_group_ids = @outcome_groups.pluck(:id)

    if params[:outcome_group_id]
      group_id = params[:outcome_group_id].to_i
      reject! "can only include an outcome group id in the outcome context" unless outcome_group_ids.include?(group_id)
      @outcome_links = ContentTag.learning_outcome_links.active.where(associated_asset_id: group_id).preload(:learning_outcome_content)
      @outcomes = @outcome_links.map(&:learning_outcome_content)
    else
      if params[:outcome_ids]
        outcome_ids = Api.value_to_array(params[:outcome_ids]).map(&:to_i).uniq
        # outcomes themselves are not duped when moved into a new group, so we
        # need to instead look at the uniqueness of the associating content tag's
        # context and outcome id in order to ensure we get the correct result
        # from the query without rendering the reject! check moot

        @outcomes = ContentTag.learning_outcome_links.active.joins(:learning_outcome_content).
          where(content_id: outcome_ids, context_type: @context.class_name, context_id: @context.id).
          to_a.uniq{|tag| [tag.context, tag.content_id]}.map(&:learning_outcome_content)
        reject! "can only include id's of outcomes in the outcome context" if @outcomes.count != outcome_ids.count
      else
        @outcome_links = []
        outcome_group_ids.each_slice(100) do |outcome_group_ids_slice|
          @outcome_links += ContentTag.learning_outcome_links.active.where(associated_asset_id: outcome_group_ids_slice)
        end
        @outcome_links.each_slice(100) do |outcome_links_slice|
          ActiveRecord::Associations::Preloader.new.preload(outcome_links_slice, :learning_outcome_content)
        end
        @outcomes = @outcome_links.map(&:learning_outcome_content)
      end
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
      user_ids = Api.value_to_array(params[:user_ids]).uniq
      @users = api_find_all(users_for_outcome_context, user_ids).distinct.to_a
      reject!( "can only include id's of users in the outcome context") if @users.count != user_ids.count
    elsif params[:section_id]
      @section = @context.course_sections.where(id: params[:section_id].to_i).first
      reject! "invalid section id" unless @section
      @users = apply_sort_order(@section.students).to_a
    end
    @users ||= users_for_outcome_context.to_a
    @users.sort! {|a,b| a.id <=> b.id} unless params[:sort_by]
  end

  def users_for_outcome_context
    # this only works for courses; when other context types are added, this will
    # need to treat them differently.
    apply_sort_order(@context.students)
  end

  def apply_sort_order(relation)
    if params[:sort_by] == 'student'
      order_clause = User.sortable_name_order_by_clause(User.quoted_table_name)
      order_clause = "#{order_clause} DESC" if params[:sort_order] == 'desc'
      relation.order(Arel.sql(order_clause))
    else
      relation
    end
  end
end
