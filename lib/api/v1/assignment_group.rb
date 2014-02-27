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

  API_ALLOWED_ASSIGNMENT_GROUP_INPUT_FIELDS = %w(
    name
    position
    group_weight
    rules
  )

  def assignment_group_json(group, user, session, includes = [], opts = {})
    includes ||= []
    opts.reverse_merge! override_assignment_dates: true

    hash = api_json(group, user, session,
                    :only => %w(id name position group_weight))

    hash['rules'] = group.rules_hash(stringify_json_ids: opts[:stringify_json_ids])

    if includes.include?('assignments')
      assignment_scope   = opts[:assignment_group_assignment_scope]
      assignment_scope ||= assignment_group_assignment_scope(group.context, user)
      assignments = group.send(assignment_scope)

      user_content_attachments   = opts[:preloaded_user_content_attachments]
      user_content_attachments ||= api_bulk_load_user_content_attachments(
        assignments.map(&:description),
        group.context,
        user
      )
      hash['assignments'] = assignments.map { |a|
        a.context = group.context
        assignment_json(a, user, session,
          include_discussion_topic: includes.include?('discussion_topic'),
          include_all_dates: includes.include?('all_dates'),
          include_module_ids: includes.include?('module_ids'),
          override_dates: opts[:override_assignment_dates],
          preloaded_user_content_attachments: user_content_attachments)
      }
    end

    hash
  end

  def update_assignment_group(assignment_group, params)
    return nil unless params.is_a?(Hash)

    update_params = params.slice(*API_ALLOWED_ASSIGNMENT_GROUP_INPUT_FIELDS)

    if rules = update_params.delete('rules')
      assignment_group.rules_hash = rules
    end

    assignment_group.attributes = update_params

    assignment_group.save
  end

  def assignment_group_assignment_scope(context, user)
    scope = :active_assignments

    # fake assignment used for checking if the @current_user can read unpublished assignments
    fake = context.assignments.scoped.new
    fake.workflow_state = 'unpublished'
    if context.feature_enabled?(:draft_state) && !fake.grants_right?(user, session, :read)
      # user should not see unpublished assignments
      scope = :published_assignments
    end

    scope
  end
end
