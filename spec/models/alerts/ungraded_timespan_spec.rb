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
#

module Alerts
  describe UngradedTimespan do
    describe "#should_not_receive_message?" do
      before :once do
        course_with_teacher(active_all: 1)
        @teacher = @user
        @user = nil
        student_in_course(active_all: 1)
        @assignment = @course.assignments.new(title: "some assignment")
        @assignment.workflow_state = "published"
        @assignment.save
        @opts = {
          submission_type: "online_text_entry",
          body: "submission body"
        }
      end

      it "returns true when the student submission is not past the threshold" do
        @assignment.submit_homework(@user, @opts)

        ungraded_timespan = Alerts::UngradedTimespan.new(@course, [@student.id])
        expect(ungraded_timespan.should_not_receive_message?(@student.id, 2)).to be true
      end

      it "returns false when the student submissions is past the threshold" do
        submission = @assignment.submit_homework(@user, @opts)
        submission.submitted_at = Time.now - 10.days
        submission.save!

        ungraded_timespan = Alerts::UngradedTimespan.new(@course, [@student.id])
        expect(ungraded_timespan.should_not_receive_message?(@student.id, 2)).to be false
      end

      it "returns true when the student has no submissions" do
        ungraded_timespan = Alerts::UngradedTimespan.new(@course, [@student.id])
        expect(ungraded_timespan.should_not_receive_message?(@student.id, 2)).to be true
      end

      it "handles submissions from multiple students" do
        student_1 = @student
        course_with_student({ course: @course })
        student_2 = @student
        @assignment.submit_homework(student_1, @opts)
        @assignment.submit_homework(student_2, @opts)

        ungraded_timespan = Alerts::UngradedTimespan.new(@course, [student_1.id, student_2.id])
        expect(ungraded_timespan.should_not_receive_message?(student_1.id, 2)).to be true
      end
    end
  end
end
