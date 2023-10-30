# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Api::V1::AssignmentGroup
  include Api::V1::Json
  include Api::V1::Assignment
  include Api::V1::Submission

  API_ALLOWED_ASSIGNMENT_GROUP_INPUT_FIELDS = %w[
    name
    position
    group_weight
    rules
    sis_source_id
    integration_data
  ].freeze

  def assignment_group_json(group, user, session, includes = [], opts = {})
    includes ||= []
    opts.reverse_merge!(override_assignment_dates: true, exclude_response_fields: [])

    hash = api_json(group, user, session, only: %w[id name position group_weight sis_source_id integration_data])
    hash["rules"] = group.rules_hash(stringify_json_ids: opts[:stringify_json_ids])

    if includes.include?("assignments")
      assignments = opts[:assignments] || group.visible_assignments(user)

      # Preload assignments' post policies for Assignment#assignment_json.
      if assignments.present?
        ActiveRecord::Associations.preload(assignments, :post_policy)
        Assignment.preload_unposted_anonymous_submissions(assignments)
      end

      user_content_attachments = opts[:preloaded_user_content_attachments]
      unless opts[:exclude_response_fields].include?("description")
        user_content_attachments ||= api_bulk_load_user_content_attachments(assignments.map(&:description), group.context)
      end

      needs_grading_course_proxy = if group.context.grants_right?(user, session, :manage_grades)
                                     Assignments::NeedsGradingCountQuery::CourseProxy.new(group.context, user)
                                   else
                                     nil
                                   end

      unless includes.include?("module_ids") || group.context.grants_right?(user, session, :read_as_admin)
        Assignment.preload_context_module_tags(assignments) # running this again is fine
      end

      unless opts[:exclude_response_fields].include?("in_closed_grading_period")
        closed_grading_period_hash = opts[:closed_grading_period_hash] ||
                                     in_closed_grading_period_hash(group.context, assignments)
      end

      if includes.include?("score_statistics")
        ActiveRecord::Associations.preload(assignments, :score_statistic)
      end

      hash["assignments"] = assignments.map do |assignment|
        overrides = if opts[:overrides].present?
                      opts[:overrides].select { |override| override.assignment_id == assignment.id }
                    end
        assignment.context = group.context
        exclude_fields = opts[:exclude_response_fields] | ["in_closed_grading_period"] # array union

        json = assignment_json(assignment,
                               user,
                               session,
                               include_discussion_topic: includes.include?("discussion_topic"),
                               include_all_dates: includes.include?("all_dates"),
                               include_can_edit: includes.include?("can_edit"),
                               include_module_ids: includes.include?("module_ids"),
                               include_grades_published: includes.include?("grades_published"),
                               override_dates: opts[:override_assignment_dates],
                               preloaded_user_content_attachments: user_content_attachments,
                               include_visibility: includes.include?("assignment_visibility"),
                               include_score_statistics: includes.include?("score_statistics"),
                               assignment_visibilities: opts[:assignment_visibilities].try(:[], assignment.id),
                               exclude_response_fields: exclude_fields,
                               overrides:,
                               include_overrides: opts[:include_overrides],
                               needs_grading_course_proxy:,
                               submission: includes.include?("submission") ? opts[:submissions][assignment.id] : nil,
                               master_course_status: opts[:master_course_status],
                               include_assessment_requests: includes.include?("assessment_requests"),
                               include_checkpoints: includes.include?("checkpoints"))

        unless opts[:exclude_response_fields].include?("in_closed_grading_period")
          assignment_closed_grading_period_hash = closed_grading_period_hash[json[:id]] || {}
          json["in_closed_grading_period"] =
            assignment_closed_grading_period_hash.any? { |_k, v| v[:in_closed_grading_period] }
        end

        json
      end

      unless opts[:exclude_response_fields].include?("in_closed_grading_period")
        hash["any_assignment_in_closed_grading_period"] =
          hash["assignments"].any? { |assignment| assignment["in_closed_grading_period"] }
      end
    end

    hash
  end

  def in_closed_grading_period_hash(context, assignments)
    return {} if assignments.empty?

    grading_periods = GradingPeriodGroup.for_course(context)&.grading_periods
    closed_grading_periods = grading_periods&.closed

    # If there are no closed grading periods, assignments can't be considered
    # to be in a closed grading period.
    return {} if closed_grading_periods.blank?

    assignments_hash = {}
    assignment_ids = assignments.pluck(:id).join(",")
    last_grading_period = grading_periods.order(end_date: :desc).first

    submissions = ActiveRecord::Base.connection.select_all(<<~SQL.squish)
      SELECT DISTINCT ON (assignment_id) assignment_id, user_id
      FROM #{Submission.quoted_table_name}
      WHERE
        assignment_id IN (#{assignment_ids}) AND
        grading_period_id IN (#{closed_grading_periods.pluck(:id).join(",")}) AND
        workflow_state <> 'deleted'

      UNION

      SELECT DISTINCT ON (assignment_id) assignment_id, user_id
      FROM #{Submission.quoted_table_name}
      WHERE
        assignment_id IN (#{assignment_ids}) AND
        grading_period_id IS NULL AND NOW() > '#{last_grading_period.close_date}'::timestamptz AND
        workflow_state <> 'deleted'
    SQL

    # The DISTINCT above will only have 1 submission per assignment, but that
    # works fine for our purposes as an assignment is considered in a closed
    # grading period if at least 1 submission is in a closed grading period.
    # This is defined behavior from the
    # `assignment_closed_grading_period_hash.any?` check in
    # #assignment_group_json.
    # Assignments that do not have at least 1 submission in a closed period
    # will not be present in this hash.
    submissions.as_json.each do |submission|
      submission_hash = { in_closed_grading_period: true }
      assignment_id = submission["assignment_id"]
      user_id = submission["user_id"]
      assignments_hash[assignment_id] ||= {}
      assignments_hash[assignment_id][user_id] = submission_hash
    end

    assignments_hash
  end

  def update_assignment_group(assignment_group, params)
    return nil unless params.is_a?(ActionController::Parameters)

    update_params = params.permit(*API_ALLOWED_ASSIGNMENT_GROUP_INPUT_FIELDS,
                                  integration_data: strong_anything)
    update_params.delete(:integration_data) if update_params[:integration_data] == ""

    rules = params.delete("rules")
    if rules
      assignment_group.rules_hash = rules
      assignment_group.validate_rules = true
    end

    assignment_group.integration_data = assignment_group.integration_data.to_h.merge(
      update_params[:integration_data].to_h
    )

    updated_attributes = update_params.except(:integration_data)
    assignment_group.attributes = updated_attributes

    assignment_group
  end
end
