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
        expect(NeedsGradingCountQuery.new(@assignment, @teacher).count).to eql(2)
        expect(NeedsGradingCountQuery.new(@assignment, @ta).count).to eql(1)

        # grade an assignment
        @assignment.grade_student(@user1, :grade => "1")
        @assignment.reload

        # check that the numbers changed
        expect(NeedsGradingCountQuery.new(@assignment, @teacher).count).to eql(1)
        expect(NeedsGradingCountQuery.new(@assignment, @ta).count).to eql(0)

        # test limited enrollment in multiple sections
        @course.enroll_user(@ta, 'TaEnrollment', :enrollment_state => 'active', :section => @section,
                            :allow_multiple_enrollments => true, :limit_privileges_to_course_section => true)
        @assignment.reload
        expect(NeedsGradingCountQuery.new(@assignment, @ta).count).to eql(1)
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

        expect(NeedsGradingCountQuery.new(@assignment, @teacher).count).to eql(2)
        sections_grading_counts = NeedsGradingCountQuery.new(@assignment, @teacher).count_by_section
        expect(sections_grading_counts).to be_a(Array)
        @course.course_sections.each do |section|
          expect(sections_grading_counts).to include({
            section_id: section.id,
            needs_grading_count: 1
          })
        end
      end

      it "should not count submissions multiple times" do
        @section1 = @course.course_sections.create!(:name => 'section 1')
        @section2 = @course.course_sections.create!(:name => 'section 2')
        @user = user_with_pseudonym(:active_all => true, :name => 'Student1', :username => 'student1@instructure.com')
        @section1.enroll_user(@user, 'StudentEnrollment', 'active')
        @section2.enroll_user(@user, 'StudentEnrollment', 'active')

        @assignment = @course.assignments.create(:title => "some assignment", :submission_types => ['online_text_entry'])
        @assignment.submit_homework @user, :submission_type => "online_text_entry", :body => "o hai"
        @assignment.reload

        querier = NeedsGradingCountQuery.new(@assignment, @teacher)

        expect(querier.count).to eql(1)
        expect(querier.manual_count).to eql(1)
        querier.count_by_section.each do |count|
          expect(count[:needs_grading_count]).to eql(1)
        end
      end

      context "moderated grading count" do
        before do
          @assignment = @course.assignments.create(:title => "some assignment",
            :submission_types => ['online_text_entry'], :moderated_grading => true, :points_possible => 3)
          @students = []
          3.times do
            student = student_in_course(:course => @course, :active_all => true).user
            @assignment.submit_homework(student, :submission_type => "online_text_entry", :body => "o hai")
            @students << student
          end

          @ta1 = ta_in_course(:course => course, :active_all => true).user
          @ta2 = ta_in_course(:course => course, :active_all => true).user
        end

        it "should only include students with no marks when unmoderated" do
          querier = NeedsGradingCountQuery.new(@assignment, @teacher)
          expect(querier.count).to eq 3

          @students[0].submissions.first.find_or_create_provisional_grade!(@teacher)
          expect(querier.count).to eq 3 # should only update when they add a score

          @students[0].submissions.first.find_or_create_provisional_grade!(@teacher, score: 3)
          expect(querier.count).to eq 2

          @students[1].submissions.first.find_or_create_provisional_grade!(@ta1)
          expect(querier.count).to eq 1
        end

        it "should only include students without two marks when moderated" do
          @students.each{|s| @assignment.moderated_grading_selections.create!(:student => s)}

          querier = NeedsGradingCountQuery.new(@assignment, @teacher)
          expect(querier.count).to eq 3

          @students[0].submissions.first.find_or_create_provisional_grade!(@teacher, score: 2)
          expect(querier.count).to eq 2 # should not show because @teacher graded it

          @students[1].submissions.first.find_or_create_provisional_grade!(@ta1)
          expect(querier.count).to eq 2 # should still count because it needs another mark

          @students[1].submissions.first.find_or_create_provisional_grade!(@ta2)
          expect(querier.count).to eq 1 # should not count because it has two marks now
        end
      end
    end
  end
end
