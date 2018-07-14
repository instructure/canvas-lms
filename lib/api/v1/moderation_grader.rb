#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Api::V1::ModerationGrader
  include Api::V1::Json

  def moderation_graders_json(assignment, user, session)
    if assignment.can_view_other_grader_identities?(user)
      graders = assignment.provisional_moderation_graders.preload(:user)
      graders_by_id = graders.each_with_object({}) {|grader, map| map[grader.id] = grader}

      api_json(graders, user, session, only: %w(id user_id)).tap do |hash|
        hash.each do |grader_json|
          grader_json['grader_name'] = graders_by_id[grader_json['id']].user.short_name
        end
      end
    else
      api_json(assignment.provisional_moderation_graders, user, session, only: %w(id anonymous_id))
    end
  end
end
