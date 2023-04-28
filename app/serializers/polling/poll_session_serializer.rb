# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Polling
  class PollSessionSerializer < Canvas::APISerializer
    attributes :id,
               :is_published,
               :has_public_results,
               :results,
               :course_id,
               :course_section_id,
               :created_at,
               :poll_id,
               :poll_submissions,
               :has_submitted

    def_delegators :object, :results, :poll

    # has_many relationships with embedded objects doesn't work, so we override it this way
    def poll_submissions
      @poll_submissions ||= begin
        submissions = if can_view_results?
                        object.poll_submissions
                      else
                        object.poll_submissions.where(user_id: current_user)
                      end
        submissions.map do |submission|
          Polling::PollSubmissionSerializer.new(submission, controller: @controller, scope: @scope, root: false)
        end
      end
    end

    def has_submitted
      object.has_submission_from?(current_user)
    end

    def filter(_keys)
      if can_view_results?
        student_keys + teacher_keys
      else
        student_keys
      end
    end

    private

    def can_view_results?
      object.has_public_results? || poll.grants_right?(current_user, session, :update)
    end

    def teacher_keys
      [:has_public_results, :results]
    end

    def student_keys
      %i[id is_published course_id course_section_id created_at poll_id has_submitted poll_submissions]
    end
  end
end
