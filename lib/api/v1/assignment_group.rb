#
# Copyright (C) 2012 Instructure, Inc.
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

  API_ALLOWED_ASSIGNMENT_GROUP_INPUT_FIELDS = %w(
    name
    position
    group_weight
    rules
    sis_source_id
    integration_data
  ).freeze

  def assignment_group_json(group, user, session, includes = [], opts = {})
    includes ||= []
    opts.reverse_merge!(override_assignment_dates: true, exclude_response_fields: [])

    hash = api_json(group, user, session,:only => %w(id name position group_weight sis_source_id integration_data))
    hash['rules'] = group.rules_hash(stringify_json_ids: opts[:stringify_json_ids])

    if includes.include?('assignments')
      assignments = opts[:assignments] || group.visible_assignments(user)

      user_content_attachments = opts[:preloaded_user_content_attachments]
      unless opts[:exclude_response_fields].include?('description')
        user_content_attachments ||= api_bulk_load_user_content_attachments(assignments.map(&:description), group.context)
      end

      needs_grading_course_proxy = group.context.grants_right?(user, session, :manage_grades) ?
        Assignments::NeedsGradingCountQuery::CourseProxy.new(group.context, user) : nil

      unless includes.include?('module_ids') || group.context.grants_right?(user, session, :read_as_admin)
        Assignment.preload_context_module_tags(assignments) # running this again is fine
      end

      unless opts[:exclude_response_fields].include?('in_closed_grading_period')
        closed_grading_period_hash = opts[:closed_grading_period_hash] ||
          EffectiveDueDates.for_course(group.context, assignments).to_hash([:in_closed_grading_period])
      end

      hash['assignments'] = assignments.map { |a|
        overrides = opts[:overrides].select{|override| override.assignment_id == a.id } unless opts[:overrides].nil?
        a.context = group.context
        exclude_fields = opts[:exclude_response_fields] | ['in_closed_grading_period'] #array union
        assignment = assignment_json(a, user, session,
          include_discussion_topic: includes.include?('discussion_topic'),
          include_all_dates: includes.include?('all_dates'),
          include_module_ids: includes.include?('module_ids'),
          override_dates: opts[:override_assignment_dates],
          preloaded_user_content_attachments: user_content_attachments,
          include_visibility: includes.include?('assignment_visibility'),
          assignment_visibilities: opts[:assignment_visibilities].try(:[], a.id),
          exclude_response_fields: exclude_fields,
          overrides: overrides,
          include_overrides: opts[:include_overrides],
          needs_grading_course_proxy: needs_grading_course_proxy,
          submission: includes.include?('submission') ? opts[:submissions][a.id] : nil
        )

        unless opts[:exclude_response_fields].include?('in_closed_grading_period')
          assignment_closed_grading_period_hash = closed_grading_period_hash[assignment[:id]] || {}
          assignment['in_closed_grading_period'] =
            assignment_closed_grading_period_hash.any? do |_, student_grading_period_status|
              student_grading_period_status[:in_closed_grading_period]
            end
        end
        assignment
      }

      unless opts[:exclude_response_fields].include?('in_closed_grading_period')
        hash['any_assignment_in_closed_grading_period'] =
          hash["assignments"].any?{ |assn| assn["in_closed_grading_period"] }
      end
    end

    hash
  end

  def update_assignment_group(assignment_group, params)
    return nil unless params.is_a?(ActionController::Parameters)

    integration_data_keys = params["integration_data"].nil? ? {} : params["integration_data"].keys
    update_params = params.permit(*API_ALLOWED_ASSIGNMENT_GROUP_INPUT_FIELDS,
                                   "integration_data": integration_data_keys)
    rules = params.delete('rules')
    if rules
      assignment_group.rules_hash = rules
    end

    assignment_group.integration_data = assignment_group.integration_data.to_h.merge(
      update_params[:integration_data].to_h
    )

    updated_attributes = update_params.except(:integration_data)
    assignment_group.attributes = updated_attributes

    assignment_group
  end
end
