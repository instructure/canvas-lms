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
  class UngradedTimespan
    def initialize(course, student_ids, _ = nil)
      @ungraded_timespan_for_student = {}
      @today = Time.now.beginning_of_day
      ungraded_timespans = course.submissions
                                 .group("submissions.user_id")
                                 .where(user_id: student_ids)
                                 .where(Submission.needs_grading_conditions)
                                 .except(:order)
                                 .minimum(:submitted_at)
      ungraded_timespans.each do |user_id, timespan|
        @ungraded_timespan_for_student[user_id] = timespan
      end
    end

    def should_not_receive_message?(user_id, threshold)
      !@ungraded_timespan_for_student[user_id] || @ungraded_timespan_for_student[user_id] + threshold.days > @today
    end
  end
end
