#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper.rb')

module Alerts
  describe Alerts::UngradedCount do

    describe "#should_not_receive_message?" do
      before :once do
        course_with_teacher(:active_all => 1)
        @teacher = @user
        @user = nil
        student_in_course(:active_all => 1)
        @assignment = @course.assignments.new(:title => "some assignment")
        @assignment.workflow_state = "published"
        @assignment.save
        @opts = {
          submission_type: 'online_text_entry',
          body: 'submission body'
        }
      end


      it 'returns true when the student submissions are below the threshold' do

        @assignment.submit_homework(@user, @opts)

        ungraded_count = Alerts::UngradedCount.new(@course, [@student.id])
        ungraded_count.should_not_receive_message?(@student.id, 2).should == true
      end

      it 'returns false when the student submissions are above or equal to the threshold' do
        second_assignment = @course.assignments.new(:title => "some assignment")
        second_assignment.workflow_state = "published"
        second_assignment.save

        @assignment.submit_homework(@user, @opts)
        second_assignment.submit_homework(@user, @opts)

        ungraded_count = Alerts::UngradedCount.new(@course, [@student.id])
        ungraded_count.should_not_receive_message?(@student.id, 2).should == false
      end

      it 'returns true when the student has no submissions' do
        ungraded_count = Alerts::UngradedCount.new(@course, [@student.id])
        ungraded_count.should_not_receive_message?(@student.id, 2).should == true
      end

      it 'handles submissions from multiple students' do
        student_1 = @student
        course_with_student({course: @course})
        student_2 = @student
        @assignment.submit_homework(student_1, @opts)
        @assignment.submit_homework(student_2, @opts)

        ungraded_count = Alerts::UngradedCount.new(@course, [student_1.id, student_2.id])
        ungraded_count.should_not_receive_message?(student_1.id, 2).should == true
      end

    end

  end
end
