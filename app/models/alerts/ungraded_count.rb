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

module Alerts
  class UngradedCount

    def initialize(course, student_ids, _ = nil)
      @ungraded_count_for_student = {}
      ungraded_counts = course.submissions.
        group("submissions.user_id").
        where(:user_id => student_ids).
        where(Submission.needs_grading_conditions).
        except(:order).
        count
      ungraded_counts.each do |user_id, count|
        @ungraded_count_for_student[user_id] = count
      end
    end

    def should_not_receive_message?(user_id, threshold)
      (@ungraded_count_for_student[user_id].to_i < threshold)
    end

  end
end