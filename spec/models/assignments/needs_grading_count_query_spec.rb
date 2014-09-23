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
#
require_relative "../../spec_helper.rb"

module Assignments
  describe NeedsGradingCountQuery do

    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true, user_name: "some user")
    end

    describe "#count" do

      it "should only count submissions in the user's visible section(s)" do
        @section = @course.course_sections.create!(:name => 'section 2')
        @user2 = user_with_pseudonym(:active_all => true, :name => 'Student2', :username => 'student2@instructure.com')
        @section.enroll_user(@user2, 'StudentEnrollment', 'active')
        @user1 = user_with_pseudonym(:active_all => true, :name => 'Student1', :username => 'student1@instructure.com')
        @course.enroll_student(@user1).update_attribute(:workflow_state, 'active')

        # enroll a section-limited TA
        @ta = user_with_pseudonym(:active_all => true, :name => 'TA1', :username => 'ta1@instructure.com')
        ta_enrollment = @course.enroll_ta(@ta)
        ta_enrollment.limit_privileges_to_course_section = true
        ta_enrollment.workflow_state = 'active'
        ta_enrollment.save!

        # make a submission in each section
        @assignment = @course.assignments.create(:title => "some assignment", :submission_types => ['online_text_entry'])
        @assignment.submit_homework @user1, :submission_type => "online_text_entry", :body => "o hai"
        @assignment.submit_homework @user2, :submission_type => "online_text_entry", :body => "haldo"
        @assignment.reload

        # check the teacher sees both, the TA sees one
        NeedsGradingCountQuery.new(@assignment, @teacher).count.should eql(2)
        NeedsGradingCountQuery.new(@assignment, @ta).count.should eql(1)

        # grade an assignment
        @assignment.grade_student(@user1, :grade => "1")
        @assignment.reload

        # check that the numbers changed
        NeedsGradingCountQuery.new(@assignment, @teacher).count.should eql(1)
        NeedsGradingCountQuery.new(@assignment, @ta).count.should eql(0)

        # test limited enrollment in multiple sections
        @course.enroll_user(@ta, 'TaEnrollment', :enrollment_state => 'active', :section => @section,
                            :allow_multiple_enrollments => true, :limit_privileges_to_course_section => true)
        @assignment.reload
        NeedsGradingCountQuery.new(@assignment, @ta).count.should eql(1)
      end

      it 'breaks them out by section if the by_section flag is passed' do
        @section = @course.course_sections.create!(:name => 'section 2')
        @user2 = user_with_pseudonym(:active_all => true, :name => 'Student2', :username => 'student2@instructure.com')
        @section.enroll_user(@user2, 'StudentEnrollment', 'active')
        @user1 = user_with_pseudonym(:active_all => true, :name => 'Student1', :username => 'student1@instructure.com')
        @course.enroll_student(@user1).update_attribute(:workflow_state, 'active')

        @assignment = @course.assignments.create(:title => "some assignment", :submission_types => ['online_text_entry'])
        @assignment.submit_homework @user1, :submission_type => "online_text_entry", :body => "o hai"
        @assignment.submit_homework @user2, :submission_type => "online_text_entry", :body => "haldo"
        @assignment.reload

        NeedsGradingCountQuery.new(@assignment, @teacher).count.should eql(2)
        sections_grading_counts = NeedsGradingCountQuery.new(@assignment, @teacher).count_by_section
        sections_grading_counts.should be_a(Array)
        @course.course_sections.each do |section|
          sections_grading_counts.should include({
            section_id: section.id,
            needs_grading_count: 1
          })
        end
      end
    end
  end
end
