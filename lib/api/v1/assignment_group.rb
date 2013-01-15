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

  def assignment_group_json(group, user, session, includes = [])
    includes ||= []

    hash = api_json(group, user, session,
                    :only => %w(id name position group_weight))
    hash['group_weight'] = nil unless group.context.apply_group_weights?
    hash['rules'] = group.rules_hash

    include_discussion_topic = includes.include?('discussion_topic')
    if includes.include?('assignments')
      extend Api::V1::Assignment
      hash['assignments'] = group.assignments.active.map { |a|
        assignment_json(a, user, session, include_discussion_topic)
      }
    end

    hash
  end
end
