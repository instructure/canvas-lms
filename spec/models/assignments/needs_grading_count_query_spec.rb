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
require_dependency "assignments/needs_grading_count_query"

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
        @assignment.grade_student(@user1, grade: "1", grader: @teacher)
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
        querier.count_by_section.each do |count|
          expect(count[:needs_grading_count]).to eql(1)
        end
      end

      it "should cache" do
        @assignment = @course.assignments.create(
          title: "some assignment",
          submission_types: ['online_text_entry']
        )
        querier = NeedsGradingCountQuery.new(@assignment, @teacher)
        @assignment.expects(:moderated_grading?).twice
        enable_cache do
          querier.count
          querier.count
          @assignment.update_attribute(:updated_at, Time.now.utc + 1.minute)
          querier.count
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

          @ta1 = ta_in_course(:course => course_factory, :active_all => true).user
          @ta2 = ta_in_course(:course => course_factory, :active_all => true).user
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

    describe "#manual_count" do
      before :once do
        @assignment = @course.assignments.create(title: "some assignment", submission_types: ['online_text_entry'])
        @section2 = @course.course_sections.create!(name: 'section 2')
      end

      it "should count submissions in all section(s)" do
        @user1 = user_with_pseudonym(active_all: true, name: 'Student1', username: 'student1@instructure.com')
        @user2 = user_with_pseudonym(active_all: true, name: 'Student2', username: 'student2@instructure.com')
        @section2.enroll_user(@user2, 'StudentEnrollment', 'active')
        @course.enroll_student(@user1).update_attribute(:workflow_state, 'active')

        # make a submission in each section
        @assignment.submit_homework @user1, submission_type: "online_text_entry", body: "o hai"
        @assignment.submit_homework @user2, submission_type: "online_text_entry", body: "haldo"
        @assignment.reload

        expect(NeedsGradingCountQuery.new(@assignment).manual_count).to be(2)

        # grade an assignment
        @assignment.grade_student(@user1, grade: "1", grader: @teacher)
        @assignment.reload

        # check that the numbers changed
        expect(NeedsGradingCountQuery.new(@assignment).manual_count).to be(1)
      end

      it "should not count submissions multiple times" do
        @user = user_with_pseudonym(active_all: true, name: 'Student1', username: 'student1@instructure.com')
        @section1 = @course.course_sections.create!(name: 'section 1')
        @section1.enroll_user(@user, 'StudentEnrollment', 'active')
        @section2.enroll_user(@user, 'StudentEnrollment', 'active')

        @assignment.submit_homework @user, submission_type: "online_text_entry", body: "o hai"
        @assignment.reload

        expect(NeedsGradingCountQuery.new(@assignment).manual_count).to be(1)
      end

      context "with submission" do
        before :once do
          @assignment.submit_homework(@user, submission_type: 'online_text_entry', body: 'blah')
        end

        it "should count ungraded submissions" do
          expect(NeedsGradingCountQuery.new(@assignment).manual_count).to be(1)
          @assignment.grade_student(@user, grade: "0", grader: @teacher)
          @assignment.reload
          expect(NeedsGradingCountQuery.new(@assignment).manual_count).to be(0)
        end

        it "should not count non-student submissions" do
          assignment_model(course: @course)
          s = @assignment.find_or_create_submission(@teacher)
          s.submission_type = 'online_quiz'
          s.workflow_state = 'submitted'
          s.save!
          expect(NeedsGradingCountQuery.new(@assignment).manual_count).to be(0)
          s.workflow_state = 'graded'
          s.save!
          @assignment.reload
          expect(NeedsGradingCountQuery.new(@assignment).manual_count).to be(0)
        end

        it "should count only enrolled student submissions" do
          expect(NeedsGradingCountQuery.new(@assignment).manual_count).to be(1)
          @course.enrollments.where(user_id: @user.id).first.destroy
          @assignment.reload
          expect(NeedsGradingCountQuery.new(@assignment).manual_count).to be(0)
          e = @course.enroll_student(@user)
          e.invite
          e.accept
          @assignment.reload
          expect(NeedsGradingCountQuery.new(@assignment).manual_count).to be(1)

          # multiple enrollments should not cause double-counting (either by creating as or updating into "active")
          section2 = @course.course_sections.create!(name: 's2')
          e2 = @course.enroll_student(@user,
                                      enrollment_state: 'invited',
                                      section: section2,
                                      allow_multiple_enrollments: true)
          e2.accept
          section3 = @course.course_sections.create!(name: 's2')
          e3 = @course.enroll_student(@user,
                                      enrollment_state: 'active',
                                      section: section3,
                                      allow_multiple_enrollments: true)
          expect(@user.enrollments.where(workflow_state: 'active').count).to be(3)
          @assignment.reload
          expect(NeedsGradingCountQuery.new(@assignment).manual_count).to be(1)

          # and as long as one enrollment is still active, the count should not change
          e2.destroy
          e3.complete
          @assignment.reload
          expect(NeedsGradingCountQuery.new(@assignment).manual_count).to be(1)

          # ok, now gone for good
          e.destroy
          @assignment.reload
          expect(NeedsGradingCountQuery.new(@assignment).manual_count).to be(0)
          expect(@user.enrollments.where(workflow_state: 'active').count).to be(0)

          # enroll the user as a teacher, it should have no effect
          e4 = @course.enroll_teacher(@user)
          e4.accept
          @assignment.reload
          expect(NeedsGradingCountQuery.new(@assignment).manual_count).to be(0)
          expect(@user.enrollments.where(workflow_state: 'active').count).to be(1)
        end
      end
    end
  end
end
