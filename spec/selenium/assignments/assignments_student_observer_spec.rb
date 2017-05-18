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

require_relative '../common'
require_relative '../helpers/assignments_common'

describe "assignments" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  context "as observer" do
    before(:each) do
      @course   = course_factory(active_all: true)
      @student  = user_factory(active_all: true, :active_state => 'active')
      @observer = user_factory(active_all: true, :active_state => 'active')
      user_session(@observer)

      @due_date = Time.now.utc + 12.days
      @assignment = @course.assignments.create!(:title => 'assignment 1', :name => 'assignment 1', :due_at => @due_date)

      setup_sections_and_overrides_all_future
    end

    context "when not linked to student" do
      before(:each) do
        @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active')
      end

      it "should see own section's lock dates" do
        extend TextHelper
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        expected_unlock = datetime_string(@override.unlock_at).gsub(/\s+/, ' ')
        expected_lock_at = datetime_string(@override.lock_at).gsub(/\s+/, ' ')
        expect(f('#content')).to include_text "locked until #{expected_unlock}."
      end

      context "with multiple section enrollments in same course" do
        it "should have the earliest 'lock until' date and the latest 'lock after' date" do
          @assignment.update_attributes :lock_at => @lock_at + 22.days
          @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section1, :enrollment_state => 'active')
          extend TextHelper
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          expected_unlock = datetime_string(@override.unlock_at).gsub(/\s+/, ' ')
          expected_lock_at = datetime_string(@assignment.lock_at).gsub(/\s+/, ' ')   # later than section2
          expect(f('#content')).to include_text "locked until #{expected_unlock}."
        end
      end
    end

    context "when linked to student" do
      before(:each) do
        @student_enrollment = @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active', :section => @section2)
        @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :section => @section2)
        @observer_enrollment.update_attribute(:associated_user_id, @student.id)
      end

      it "should return student's lock dates" do
        extend TextHelper
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        expected_unlock = datetime_string(@override.unlock_at).gsub(/\s+/, ' ')
        expected_lock_at = datetime_string(@override.lock_at).gsub(/\s+/, ' ')
        expect(f('#content')).to include_text "locked until #{expected_unlock}."
      end

      context "overridden lock_at" do
        before(:each) do
          setup_sections_and_overrides_all_future
          @course.enroll_user(@student, 'StudentEnrollment', :section => @section2, :enrollment_state => 'active')
        end

        it "should show overridden lock dates for student" do
          extend TextHelper
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          expected_unlock = datetime_string(@override.unlock_at).gsub(/\s+/, ' ')
          expected_lock_at = datetime_string(@override.lock_at).gsub(/\s+/, ' ')
          expect(f('#content')).to include_text "locked until #{expected_unlock}."
        end
      end
    end
  end
end
