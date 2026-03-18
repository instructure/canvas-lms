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
#

module Assignments
  # Shared behavioural examples for NeedsGradingCountQuery.
  # Run once for the legacy implementation (feature flag off) and once for the
  # optimized implementation (feature flag on), so both paths are fully covered
  # without duplicating test code.
  shared_examples "NeedsGradingCountQuery behavior" do
    describe "#count" do
      it "only counts submissions in the user's visible section(s)" do
        @section = @course.course_sections.create!(name: "section 2")
        @user2 = user_with_pseudonym(active_all: true, name: "Student2", username: "student2@instructure.com")
        @section.enroll_user(@user2, "StudentEnrollment", "active")
        @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
        @course.enroll_student(@user1).update_attribute(:workflow_state, "active")

        # enroll a section-limited TA
        @ta = user_with_pseudonym(active_all: true, name: "TA1", username: "ta1@instructure.com")
        ta_enrollment = @course.enroll_ta(@ta)
        ta_enrollment.limit_privileges_to_course_section = true
        ta_enrollment.workflow_state = "active"
        ta_enrollment.save!

        # make a submission in each section
        @assignment = @course.assignments.create(title: "some assignment", submission_types: ["online_text_entry"])
        @assignment.submit_homework @user1, submission_type: "online_text_entry", body: "o hai"
        @assignment.submit_homework @user2, submission_type: "online_text_entry", body: "haldo"
        @assignment.reload

        # check the teacher sees both, the TA sees one
        expect(NeedsGradingCountQuery.new([@assignment], @teacher).count[@assignment.global_id]).to be(2)
        expect(NeedsGradingCountQuery.new([@assignment], @ta).count[@assignment.global_id]).to be(1)

        # grade an assignment
        @assignment.grade_student(@user1, grade: "1", grader: @teacher)
        @assignment.reload

        # check that the numbers changed
        expect(NeedsGradingCountQuery.new([@assignment], @teacher).count[@assignment.global_id]).to be(1)
        expect(NeedsGradingCountQuery.new([@assignment], @ta).count[@assignment.global_id]).to be(0)

        # test limited enrollment in multiple sections
        @course.enroll_user(@ta,
                            "TaEnrollment",
                            enrollment_state: "active",
                            section: @section,
                            allow_multiple_enrollments: true,
                            limit_privileges_to_course_section: true)
        @assignment.reload
        expect(NeedsGradingCountQuery.new([@assignment], @ta).count[@assignment.global_id]).to be(1)
      end

      it "breaks them out by section if the by_section flag is passed" do
        @section = @course.course_sections.create!(name: "section 2")
        @user2 = user_with_pseudonym(active_all: true, name: "Student2", username: "student2@instructure.com")
        @section.enroll_user(@user2, "StudentEnrollment", "active")
        @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
        @course.enroll_student(@user1).update_attribute(:workflow_state, "active")

        @assignment = @course.assignments.create(title: "some assignment", submission_types: ["online_text_entry"])
        @assignment.submit_homework @user1, submission_type: "online_text_entry", body: "o hai"
        @assignment.submit_homework @user2, submission_type: "online_text_entry", body: "haldo"
        @assignment.reload

        querier = NeedsGradingCountQuery.new([@assignment], @teacher)
        expect(querier.count[@assignment.global_id]).to be(2)
        sections_grading_counts = querier.count_by_section[@assignment.global_id]
        expect(sections_grading_counts).to be_a(Array)
        @course.course_sections.each do |section|
          expect(sections_grading_counts).to include({
                                                       section_id: section.id,
                                                       needs_grading_count: 1
                                                     })
        end
      end

      it "does not count submissions multiple times" do
        @section1 = @course.course_sections.create!(name: "section 1")
        @section2 = @course.course_sections.create!(name: "section 2")
        @user = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
        @section1.enroll_user(@user, "StudentEnrollment", "active")
        @section2.enroll_user(@user, "StudentEnrollment", "active")

        @assignment = @course.assignments.create(title: "some assignment", submission_types: ["online_text_entry"])
        @assignment.submit_homework @user, submission_type: "online_text_entry", body: "o hai"
        @assignment.reload

        querier = NeedsGradingCountQuery.new([@assignment], @teacher)

        expect(querier.count[@assignment.global_id]).to be(1)
        querier.count_by_section[@assignment.global_id].each do |count|
          expect(count[:needs_grading_count]).to be(1)
        end
      end

      context "moderated grading count" do
        before do
          @assignment = @course.assignments.create(
            title: "some assignment",
            submission_types: ["online_text_entry"],
            moderated_grading: true,
            grader_count: 2,
            points_possible: 3
          )
          @students = []
          3.times do
            student = student_in_course(course: @course, active_all: true).user
            @assignment.submit_homework(student, submission_type: "online_text_entry", body: "o hai")
            @students << student
          end

          @ta1 = ta_in_course(course: @course, active_all: true).user
          @ta2 = ta_in_course(course: @course, active_all: true).user
        end

        it "only includes students with no marks when unmoderated" do
          querier = NeedsGradingCountQuery.new([@assignment], @teacher)
          expect(querier.count[@assignment.global_id]).to eq 3

          @students[0].submissions.first.find_or_create_provisional_grade!(@teacher)
          expect(querier.count[@assignment.global_id]).to eq 3 # should only update when they add a score

          @students[0].submissions.first.find_or_create_provisional_grade!(@teacher, score: 3)
          expect(querier.count[@assignment.global_id]).to eq 2

          @students[1].submissions.first.find_or_create_provisional_grade!(@ta1)
          expect(querier.count[@assignment.global_id]).to eq 2
        end

        it "only includes students without two marks when moderated" do
          querier = NeedsGradingCountQuery.new([@assignment], @teacher)
          expect(querier.count[@assignment.global_id]).to eq 3

          @students[0].submissions.first.find_or_create_provisional_grade!(@teacher, score: 2)
          expect(querier.count[@assignment.global_id]).to eq 2 # should not show because @teacher graded it

          @students[1].submissions.first.find_or_create_provisional_grade!(@ta1)
          expect(querier.count[@assignment.global_id]).to eq 2 # should still count because it needs another mark

          @students[1].submissions.first.find_or_create_provisional_grade!(@ta2)
          expect(querier.count[@assignment.global_id]).to eq 1 # should not count because it has two marks now
        end

        it "only counts submissions in the section-limited TA's visible sections" do
          section2 = @course.course_sections.create!(name: "section 2")
          student1 = student_in_course(course: @course, active_all: true).user
          student2 = user_with_pseudonym(active_all: true)
          section2.enroll_user(student2, "StudentEnrollment", "active")

          # Use a fresh assignment so the 3 students from the before block don't interfere
          mod_assignment = @course.assignments.create!(
            title: "moderated section test",
            submission_types: ["online_text_entry"],
            moderated_grading: true,
            grader_count: 2,
            points_possible: 3
          )
          mod_assignment.submit_homework(student1, submission_type: "online_text_entry", body: "s1")
          mod_assignment.submit_homework(student2, submission_type: "online_text_entry", body: "s2")

          ta = user_with_pseudonym(active_all: true, name: "SectionTA", username: "section_ta_mod@instructure.com")
          ta_enrollment = @course.enroll_ta(ta)
          ta_enrollment.limit_privileges_to_course_section = true
          ta_enrollment.workflow_state = "active"
          ta_enrollment.save!

          # TA is only in the default section → visibility_level == :sections →
          # needs_moderated_grading_count uses section_filtered_submissions (line 154 TRUE path)
          expect(NeedsGradingCountQuery.new([mod_assignment], ta).count[mod_assignment.global_id]).to eq(1)
        end
      end

      it "only includes visible sections in count_by_section for a section-limited user" do
        section2 = @course.course_sections.create!(name: "section 2")
        student1 = student_in_course(course: @course, active_all: true).user
        student2 = user_with_pseudonym(active_all: true)
        section2.enroll_user(student2, "StudentEnrollment", "active")

        ta = user_with_pseudonym(active_all: true, name: "TA", username: "ta_section@instructure.com")
        ta_enrollment = @course.enroll_ta(ta)
        ta_enrollment.limit_privileges_to_course_section = true
        ta_enrollment.workflow_state = "active"
        ta_enrollment.save!

        assignment = @course.assignments.create!(title: "by-section visibility", submission_types: ["online_text_entry"])
        assignment.submit_homework(student1, submission_type: "online_text_entry", body: "s1")
        assignment.submit_homework(student2, submission_type: "online_text_entry", body: "s2")

        sections = NeedsGradingCountQuery.new([assignment], ta).count_by_section[assignment.global_id]

        # TA is only in the default section, so only that section's count is returned
        expect(sections.sum { |s| s[:needs_grading_count] }).to eq(1)
        expect(sections.pluck(:section_id)).to contain_exactly(@course.default_section.id)
      end

      context "when viewer has no course enrollment (:restricted visibility)" do
        before :once do
          @outsider = user_model
          @restricted_assignment = @course.assignments.create!(
            title: "restricted test",
            submission_types: ["online_text_entry"]
          )
          student_in_course(course: @course, active_all: true).user.tap do |s|
            @restricted_assignment.submit_homework(s, submission_type: "online_text_entry", body: "hi")
          end
        end

        it "returns 0 for a regular assignment" do
          expect(NeedsGradingCountQuery.new([@restricted_assignment], @outsider).count[@restricted_assignment.global_id]).to eq(0)
        end

        it "returns 0 for a moderated assignment (early return in needs_moderated_grading_count)" do
          moderated = @course.assignments.create!(
            title: "moderated restricted",
            submission_types: ["online_text_entry"],
            moderated_grading: true,
            grader_count: 2,
            points_possible: 1
          )
          student_in_course(course: @course, active_all: true).user.tap do |s|
            moderated.submit_homework(s, submission_type: "online_text_entry", body: "hi")
          end
          expect(NeedsGradingCountQuery.new([moderated], @outsider).count[moderated.global_id]).to eq(0)
        end
      end

      context "with sub_assignments" do
        before :once do
          @parent_assignment = @course.assignments.create!(
            title: "parent assignment",
            has_sub_assignments: true,
            submission_types: "online_text_entry"
          )
          @sub_assignment1 = @parent_assignment.sub_assignments.create!(
            context: @course,
            sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
            points_possible: 5,
            due_at: 2.days.from_now
          )
          @sub_assignment2 = @parent_assignment.sub_assignments.create!(
            context: @course,
            sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY,
            points_possible: 5,
            due_at: 3.days.from_now
          )
        end

        it "only counts submissions in the user's visible section(s)" do
          @section = @course.course_sections.create!(name: "section 2")
          @user2 = user_with_pseudonym(active_all: true, name: "Student2", username: "student2@instructure.com")
          @section.enroll_user(@user2, "StudentEnrollment", "active")
          @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
          @course.enroll_student(@user1).update_attribute(:workflow_state, "active")

          # enroll a section-limited TA
          @ta = user_with_pseudonym(active_all: true, name: "TA1", username: "ta1@instructure.com")
          ta_enrollment = @course.enroll_ta(@ta)
          ta_enrollment.limit_privileges_to_course_section = true
          ta_enrollment.workflow_state = "active"
          ta_enrollment.save!

          # make a submission in each section
          @sub_assignment1.submit_homework @user1, submission_type: "online_text_entry", body: "o hai"
          @sub_assignment1.submit_homework @user2, submission_type: "online_text_entry", body: "haldo"

          # check the teacher sees both, the TA sees one
          expect(NeedsGradingCountQuery.new([@parent_assignment], @teacher).count[@parent_assignment.global_id]).to be(2)
          expect(NeedsGradingCountQuery.new([@parent_assignment], @ta).count[@parent_assignment.global_id]).to be(1)

          # grade an assignment
          @sub_assignment1.grade_student(@user1, grade: "3", grader: @teacher)

          # check that the numbers changed
          expect(NeedsGradingCountQuery.new([@parent_assignment], @teacher).count[@parent_assignment.global_id]).to be(1)
          expect(NeedsGradingCountQuery.new([@parent_assignment], @ta).count[@parent_assignment.global_id]).to be(0)

          # test limited enrollment in multiple sections
          @course.enroll_user(@ta,
                              "TaEnrollment",
                              enrollment_state: "active",
                              section: @section,
                              allow_multiple_enrollments: true,
                              limit_privileges_to_course_section: true)
          expect(NeedsGradingCountQuery.new([@parent_assignment], @ta).count[@parent_assignment.global_id]).to be(1)
        end

        it "breaks them out by section if count_by_section is called" do
          @section = @course.course_sections.create!(name: "section 2")
          @user2 = user_with_pseudonym(active_all: true, name: "Student2", username: "student2@instructure.com")
          @section.enroll_user(@user2, "StudentEnrollment", "active")
          @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
          @course.enroll_student(@user1).update_attribute(:workflow_state, "active")

          @sub_assignment1.submit_homework @user1, submission_type: "online_text_entry", body: "o hai"
          @sub_assignment2.submit_homework @user2, submission_type: "online_text_entry", body: "haldo"

          querier = NeedsGradingCountQuery.new([@parent_assignment], @teacher)
          expect(querier.count[@parent_assignment.global_id]).to be(2)
          sections_grading_counts = querier.count_by_section[@parent_assignment.global_id]
          expect(sections_grading_counts).to be_a(Array)
          @course.course_sections.each do |section|
            expect(sections_grading_counts).to include({
                                                         section_id: section.id,
                                                         needs_grading_count: 1
                                                       })
          end
        end

        it "counts each user once per section even with multiple sub_assignment submissions" do
          @section = @course.course_sections.create!(name: "section 2")
          @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
          @user2 = user_with_pseudonym(active_all: true, name: "Student2", username: "student2@instructure.com")
          @course.enroll_student(@user1).update_attribute(:workflow_state, "active")
          @section.enroll_user(@user2, "StudentEnrollment", "active")

          # User1 submits to both sub_assignments in default section
          @sub_assignment1.submit_homework @user1, submission_type: "online_text_entry", body: "reply 1"
          @sub_assignment2.submit_homework @user1, submission_type: "online_text_entry", body: "reply 2"

          # User2 submits to both sub_assignments in section 2
          @sub_assignment1.submit_homework @user2, submission_type: "online_text_entry", body: "reply 3"
          @sub_assignment2.submit_homework @user2, submission_type: "online_text_entry", body: "reply 4"

          sections_grading_counts = NeedsGradingCountQuery.new([@parent_assignment], @teacher).count_by_section[@parent_assignment.global_id]

          # Each section should have count of 1, not 2
          default_section_count = sections_grading_counts.find { |s| s[:section_id] == @course.default_section.id }
          section2_count = sections_grading_counts.find { |s| s[:section_id] == @section.id }

          expect(default_section_count[:needs_grading_count]).to be(1)
          expect(section2_count[:needs_grading_count]).to be(1)
        end

        it "returns correct counts when multiple parent assignments are batched together" do
          # Regression test: sub-assignment IDs are fetched in a single bulk query
          # (WHERE parent_assignment_id IN (...)) rather than one query per parent.
          # If that regresses, counts would silently return 0.
          @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
          @user2 = user_with_pseudonym(active_all: true, name: "Student2", username: "student2@instructure.com")
          @course.enroll_student(@user1).update_attribute(:workflow_state, "active")
          @course.enroll_student(@user2).update_attribute(:workflow_state, "active")

          parent2 = @course.assignments.create!(
            title: "parent assignment 2",
            has_sub_assignments: true,
            submission_types: "online_text_entry"
          )
          sub3 = parent2.sub_assignments.create!(
            context: @course,
            sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
            points_possible: 5,
            due_at: 2.days.from_now
          )

          @sub_assignment1.submit_homework(@user1, submission_type: "online_text_entry", body: "reply")
          sub3.submit_homework(@user2, submission_type: "online_text_entry", body: "reply")

          result = NeedsGradingCountQuery.new([@parent_assignment, parent2], @teacher).count
          expect(result[@parent_assignment.global_id]).to eq(1)
          expect(result[parent2.global_id]).to eq(1)
        end
      end
    end

    describe "#manual_count" do
      before :once do
        @assignment = @course.assignments.create(title: "some assignment", submission_types: ["online_text_entry"])
        @section2 = @course.course_sections.create!(name: "section 2")
      end

      it "counts submissions in all section(s)" do
        @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
        @user2 = user_with_pseudonym(active_all: true, name: "Student2", username: "student2@instructure.com")
        @section2.enroll_user(@user2, "StudentEnrollment", "active")
        @course.enroll_student(@user1).update_attribute(:workflow_state, "active")

        # make a submission in each section
        @assignment.submit_homework @user1, submission_type: "online_text_entry", body: "o hai"
        @assignment.submit_homework @user2, submission_type: "online_text_entry", body: "haldo"
        @assignment.reload

        expect(NeedsGradingCountQuery.new([@assignment]).manual_count[@assignment.global_id]).to be(2)

        # grade an assignment
        @assignment.grade_student(@user1, grade: "1", grader: @teacher)
        @assignment.reload

        # check that the numbers changed
        expect(NeedsGradingCountQuery.new([@assignment]).manual_count[@assignment.global_id]).to be(1)
      end

      it "does not count submissions multiple times" do
        @user = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
        @section1 = @course.course_sections.create!(name: "section 1")
        @section1.enroll_user(@user, "StudentEnrollment", "active")
        @section2.enroll_user(@user, "StudentEnrollment", "active")

        @assignment.submit_homework @user, submission_type: "online_text_entry", body: "o hai"
        @assignment.reload

        expect(NeedsGradingCountQuery.new([@assignment]).manual_count[@assignment.global_id]).to be(1)
      end

      context "with submission" do
        before :once do
          @assignment.submit_homework(@user, submission_type: "online_text_entry", body: "blah")
        end

        it "counts ungraded submissions" do
          expect(NeedsGradingCountQuery.new([@assignment]).manual_count[@assignment.global_id]).to be(1)
          @assignment.grade_student(@user, grade: "0", grader: @teacher)
          @assignment.reload
          expect(NeedsGradingCountQuery.new([@assignment]).manual_count[@assignment.global_id]).to be(0)
        end

        it "does not count non-student submissions" do
          assignment_model(course: @course)
          s = @assignment.find_or_create_submission(@teacher)
          s.submission_type = "online_quiz"
          s.workflow_state = "submitted"
          s.save!
          expect(NeedsGradingCountQuery.new([@assignment]).manual_count[@assignment.global_id]).to be(0)
          s.workflow_state = "graded"
          s.save!
          @assignment.reload
          expect(NeedsGradingCountQuery.new([@assignment]).manual_count[@assignment.global_id]).to be(0)
        end

        it "counts only enrolled student submissions" do
          expect(NeedsGradingCountQuery.new([@assignment]).manual_count[@assignment.global_id]).to be(1)
          @course.enrollments.where(user_id: @user.id).first.destroy
          @assignment.reload
          expect(NeedsGradingCountQuery.new([@assignment]).manual_count[@assignment.global_id]).to be(0)
          e = @course.enroll_student(@user)
          e.invite
          e.accept
          @assignment.reload
          expect(NeedsGradingCountQuery.new([@assignment]).manual_count[@assignment.global_id]).to be(1)

          # multiple enrollments should not cause double-counting (either by creating as or updating into "active")
          section2 = @course.course_sections.create!(name: "s2")
          e2 = @course.enroll_student(@user,
                                      enrollment_state: "invited",
                                      section: section2,
                                      allow_multiple_enrollments: true)
          e2.accept
          section3 = @course.course_sections.create!(name: "s2")
          e3 = @course.enroll_student(@user,
                                      enrollment_state: "active",
                                      section: section3,
                                      allow_multiple_enrollments: true)
          expect(@user.enrollments.where(workflow_state: "active").count).to be(3)
          @assignment.reload
          expect(NeedsGradingCountQuery.new([@assignment]).manual_count[@assignment.global_id]).to be(1)

          # and as long as one enrollment is still active, the count should not change
          e2.destroy
          e3.complete
          @assignment.reload
          expect(NeedsGradingCountQuery.new([@assignment]).manual_count[@assignment.global_id]).to be(1)

          # ok, now gone for good
          e.destroy
          @assignment.reload
          expect(NeedsGradingCountQuery.new([@assignment]).manual_count[@assignment.global_id]).to be(0)
          expect(@user.enrollments.where(workflow_state: "active").count).to be(0)

          # enroll the user as a teacher, it should have no effect
          e4 = @course.enroll_teacher(@user)
          e4.accept
          @assignment.reload
          expect(NeedsGradingCountQuery.new([@assignment]).manual_count[@assignment.global_id]).to be(0)
          expect(@user.enrollments.where(workflow_state: "active").count).to be(1)
        end
      end

      context "with sub_assignments" do
        before :once do
          @parent_assignment = @course.assignments.create!(
            title: "parent assignment",
            has_sub_assignments: true,
            submission_types: "online_text_entry"
          )
          @sub_assignment1 = @parent_assignment.sub_assignments.create!(
            context: @course,
            sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC,
            points_possible: 5,
            due_at: 2.days.from_now
          )
          @sub_assignment2 = @parent_assignment.sub_assignments.create!(
            context: @course,
            sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY,
            points_possible: 5,
            due_at: 3.days.from_now
          )
        end

        it "counts distinct users with sub_assignment submissions needing grading" do
          @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
          @user2 = user_with_pseudonym(active_all: true, name: "Student2", username: "student2@instructure.com")
          @course.enroll_student(@user1).update_attribute(:workflow_state, "active")
          @course.enroll_student(@user2).update_attribute(:workflow_state, "active")

          @sub_assignment1.submit_homework(@user1, submission_type: "online_text_entry", body: "reply 1")
          @sub_assignment2.submit_homework(@user2, submission_type: "online_text_entry", body: "reply 2")

          expect(NeedsGradingCountQuery.new([@parent_assignment]).manual_count[@parent_assignment.global_id]).to be(2)
        end

        it "counts each user only once even with multiple sub_assignment submissions" do
          @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
          @course.enroll_student(@user1).update_attribute(:workflow_state, "active")

          # User submits to both sub_assignments
          @sub_assignment1.submit_homework(@user1, submission_type: "online_text_entry", body: "reply to topic")
          @sub_assignment2.submit_homework(@user1, submission_type: "online_text_entry", body: "reply to entry")

          # Should only count the user once
          expect(NeedsGradingCountQuery.new([@parent_assignment]).manual_count[@parent_assignment.global_id]).to be(1)
        end

        it "ignores parent assignment submissions when sub_assignments exist" do
          @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
          @course.enroll_student(@user1).update_attribute(:workflow_state, "active")

          # Create a submission on the parent (this should be ignored)
          parent_submission = @parent_assignment.find_or_create_submission(@user1)
          parent_submission.submission_type = "online_text_entry"
          parent_submission.body = "parent submission"
          parent_submission.workflow_state = "submitted"
          parent_submission.submitted_at = Time.zone.now
          parent_submission.save!

          # Should not count the parent submission
          expect(NeedsGradingCountQuery.new([@parent_assignment]).manual_count[@parent_assignment.global_id]).to be(0)

          # Now add a sub_assignment submission
          @sub_assignment1.submit_homework(@user1, submission_type: "online_text_entry", body: "sub reply")

          # Should count the user once for the sub_assignment submission
          expect(NeedsGradingCountQuery.new([@parent_assignment]).manual_count[@parent_assignment.global_id]).to be(1)
        end

        it "updates count when sub_assignment submissions are graded" do
          @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
          @user2 = user_with_pseudonym(active_all: true, name: "Student2", username: "student2@instructure.com")
          @course.enroll_student(@user1).update_attribute(:workflow_state, "active")
          @course.enroll_student(@user2).update_attribute(:workflow_state, "active")

          @sub_assignment1.submit_homework(@user1, submission_type: "online_text_entry", body: "reply 1")
          @sub_assignment1.submit_homework(@user2, submission_type: "online_text_entry", body: "reply 2")

          expect(NeedsGradingCountQuery.new([@parent_assignment]).manual_count[@parent_assignment.global_id]).to be(2)

          # Grade one submission
          @sub_assignment1.grade_student(@user1, grade: "5", grader: @teacher)

          # User1 should not be counted anymore
          expect(NeedsGradingCountQuery.new([@parent_assignment]).manual_count[@parent_assignment.global_id]).to be(1)
        end

        it "does not count user if all their sub_assignment submissions are graded" do
          @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
          @course.enroll_student(@user1).update_attribute(:workflow_state, "active")

          @sub_assignment1.submit_homework(@user1, submission_type: "online_text_entry", body: "reply to topic")
          @sub_assignment2.submit_homework(@user1, submission_type: "online_text_entry", body: "reply to entry")

          expect(NeedsGradingCountQuery.new([@parent_assignment]).manual_count[@parent_assignment.global_id]).to be(1)

          # Grade only the first sub_assignment
          @sub_assignment1.grade_student(@user1, grade: "5", grader: @teacher)

          # User should still be counted because sub_assignment2 is not graded
          expect(NeedsGradingCountQuery.new([@parent_assignment]).manual_count[@parent_assignment.global_id]).to be(1)

          # Grade the second sub_assignment
          @sub_assignment2.grade_student(@user1, grade: "5", grader: @teacher)

          # Now user should not be counted
          expect(NeedsGradingCountQuery.new([@parent_assignment]).manual_count[@parent_assignment.global_id]).to be(0)
        end

        it "does not count submissions multiple times for users with multiple enrollments" do
          @user1 = user_with_pseudonym(active_all: true, name: "Student1", username: "student1@instructure.com")
          @section1 = @course.course_sections.create!(name: "section 1")
          @section2 = @course.course_sections.create!(name: "section 2")
          @section1.enroll_user(@user1, "StudentEnrollment", "active")
          @section2.enroll_user(@user1, "StudentEnrollment", "active")

          @sub_assignment1.submit_homework(@user1, submission_type: "online_text_entry", body: "reply")
          @sub_assignment2.submit_homework(@user1, submission_type: "online_text_entry", body: "reply 2")

          # Should count user only once
          expect(NeedsGradingCountQuery.new([@parent_assignment]).manual_count[@parent_assignment.global_id]).to be(1)
        end

        it "returns 0 when parent has has_sub_assignments: true but no sub_assignments exist" do
          parent = @course.assignments.create!(
            title: "parent with no subs",
            has_sub_assignments: true,
            submission_types: "online_text_entry"
          )
          expect(NeedsGradingCountQuery.new([parent]).manual_count[parent.global_id]).to eq(0)
        end
      end

      it "counts StudentViewEnrollment (test student) submissions" do
        test_student = @course.student_view_student
        assignment = @course.assignments.create!(
          title: "test student assignment",
          submission_types: ["online_text_entry"]
        )
        assignment.submit_homework(test_student, submission_type: "online_text_entry", body: "test")
        expect(NeedsGradingCountQuery.new([assignment]).manual_count[assignment.global_id]).to eq(1)
      end
    end

    describe "default values" do
      it "returns 0 for unknown keys in count result" do
        result = NeedsGradingCountQuery.new([], @teacher).count
        expect(result[999_999_999]).to eq(0)
      end

      it "returns 0 for unknown keys in manual_count result" do
        result = NeedsGradingCountQuery.new([], @teacher).manual_count
        expect(result[999_999_999]).to eq(0)
      end

      it "returns [] for unknown keys in count_by_section result" do
        result = NeedsGradingCountQuery.new([], @teacher).count_by_section
        expect(result[999_999_999]).to eq([])
      end
    end

    describe "CourseProxy reuse" do
      it "initializes only one CourseProxy per course for multiple assignments" do
        assignment1 = @course.assignments.create!(title: "a1", submission_types: ["online_text_entry"])
        assignment2 = @course.assignments.create!(title: "a2", submission_types: ["online_text_entry"])
        expect(CourseProxyCache::CourseProxy).to receive(:new).once.and_call_original
        NeedsGradingCountQuery.new([assignment1, assignment2], @teacher).count
      end

      it "returns results keyed by global_id" do
        assignment = @course.assignments.create!(title: "a1", submission_types: ["online_text_entry"])
        result = NeedsGradingCountQuery.new([assignment], @teacher).count
        expect(result.keys).to eq([assignment.global_id])
      end
    end

    context "cross-shard" do
      specs_require_sharding

      it "counts submissions for an assignment on a remote shard" do
        assignment = nil
        teacher = nil

        @shard2.activate do
          account = Account.create!
          course = Course.create!(account:, workflow_state: "available")
          teacher = User.create!
          course.enroll_teacher(teacher).accept!
          student = User.create!
          course.enroll_student(student).update_attribute(:workflow_state, "active")
          assignment = course.assignments.create!(
            title: "shard2 assignment",
            submission_types: ["online_text_entry"]
          )
          assignment.submit_homework(student, submission_type: "online_text_entry", body: "from shard2")
        end

        result = NeedsGradingCountQuery.new([assignment], teacher).count
        expect(result[assignment.global_id]).to eq(1)
      end

      it "returns results for assignments on two shards in a single batch" do
        student1 = student_in_course(course: @course, active_all: true).user
        a1 = @course.assignments.create!(title: "default shard a", submission_types: ["online_text_entry"])
        a1.submit_homework(student1, submission_type: "online_text_entry", body: "s1")

        a2 = nil
        @shard2.activate do
          account = Account.create!
          course2 = Course.create!(account:, workflow_state: "available")
          student2 = User.create!
          course2.enroll_student(student2).update_attribute(:workflow_state, "active")
          a2 = course2.assignments.create!(title: "shard2 a", submission_types: ["online_text_entry"])
          a2.submit_homework(student2, submission_type: "online_text_entry", body: "s2")
        end

        # Use manual_count (nil user) since teacher has no enrollment in the shard2 course
        result = NeedsGradingCountQuery.new([a1, a2]).manual_count

        expect(result[a1.global_id]).to eq(1)
        expect(result[a2.global_id]).to eq(1)
      end

      it "does not share CourseProxy between courses on different shards" do
        course_with_teacher(active_all: true)
        shard2_course = @shard2.activate { Course.create!(account: Account.create!, workflow_state: "available") }
        a1 = @course.assignments.create!(title: "a1", submission_types: ["online_text_entry"])
        a2 = @shard2.activate { shard2_course.assignments.create!(title: "a2", submission_types: ["online_text_entry"]) }

        expect(CourseProxyCache::CourseProxy).to receive(:new).twice.and_call_original
        NeedsGradingCountQuery.new([a1, a2]).count
      end

      it "uses global_id in RequestCache key so shard2 assignments are correctly cached" do
        assignment = nil
        @shard2.activate do
          account = Account.create!
          course = Course.create!(account:, workflow_state: "available")
          student = User.create!
          course.enroll_student(student).update_attribute(:workflow_state, "active")
          assignment = course.assignments.create!(title: "shard2 rc", submission_types: ["online_text_entry"])
          assignment.submit_homework(student, submission_type: "online_text_entry", body: "hi")
        end

        RequestCache.enable do
          NeedsGradingCountQuery.new([assignment]).manual_count

          expect(RequestCache.exist?("ngcq_manual_count", assignment.global_id, nil)).to be true

          result = NeedsGradingCountQuery.new([assignment]).manual_count
          expect(result[assignment.global_id]).to eq(1)
        end
      end
    end
  end

  describe NeedsGradingCountQuery do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true, user_name: "some user")
    end

    context "with legacy implementation" do
      before { Account.site_admin.disable_feature!(:optimized_needs_grading_count) }

      it "delegates to NeedsGradingCountQueryLegacy, not optimized" do
        assignment = @course.assignments.create!(title: "dispatch", submission_types: ["online_text_entry"])
        expect(NeedsGradingCountQueryOptimized).not_to receive(:new)
        NeedsGradingCountQuery.new([assignment], @teacher).count
      end

      it_behaves_like "NeedsGradingCountQuery behavior"
    end

    context "with optimized implementation" do
      before { Account.site_admin.enable_feature!(:optimized_needs_grading_count) }

      it "delegates to NeedsGradingCountQueryOptimized, not legacy" do
        assignment = @course.assignments.create!(title: "dispatch", submission_types: ["online_text_entry"])
        expect(NeedsGradingCountQueryOptimized).to receive(:new).and_call_original
        NeedsGradingCountQuery.new([assignment], @teacher).count
      end

      it_behaves_like "NeedsGradingCountQuery behavior"
    end

    describe "optimized? memoization" do
      it "looks up the feature flag only once per instance across multiple calls" do
        assignment = @course.assignments.create!(title: "flag test", submission_types: ["online_text_entry"])
        query = NeedsGradingCountQuery.new([assignment], @teacher)
        expect(Account.site_admin).to receive(:feature_enabled?)
          .with(:optimized_needs_grading_count).once.and_return(false)
        query.count
        query.count
      end
    end
  end

  # Tests the Legacy implementation's Rails.cache layer specifically.
  # The optimized implementation does not use Rails.cache.fetch_with_batched_keys,
  # so these tests are intentionally not inside the shared_examples.
  describe "Rails.cache caching" do
    before { Account.site_admin.disable_feature!(:optimized_needs_grading_count) }

    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true, user_name: "some user")
    end

    it "serves count from cache until the cache key is cleared" do
      student = student_in_course(course: @course, active_all: true).user
      assignment = @course.assignments.create!(
        title: "cached assignment",
        submission_types: ["online_text_entry"]
      )
      assignment.submit_homework(student, submission_type: "online_text_entry", body: "hi")

      enable_cache do
        expect(NeedsGradingCountQuery.new([assignment], @teacher).count[assignment.global_id]).to eq(1)

        # Change DB state bypassing callbacks so the cache key is NOT invalidated
        Submission.where(assignment:, user: student).update_all(
          workflow_state: "graded", score: 1, graded_at: Time.zone.now
        )

        # Cache should still serve the pre-grading value
        expect(NeedsGradingCountQuery.new([assignment], @teacher).count[assignment.global_id]).to eq(1)

        # Explicitly clearing the cache key forces a recompute on the next call
        Timecop.freeze(1.minute.from_now) do
          assignment.clear_cache_key(:needs_grading)
          expect(NeedsGradingCountQuery.new([assignment], @teacher).count[assignment.global_id]).to eq(0)
        end
      end
    end

    it "serves count_by_section from cache until the cache key is cleared" do
      course_with_teacher(active_all: true)
      section2 = @course.course_sections.create!(name: "section 2")
      student1 = student_in_course(course: @course, active_all: true).user
      student2 = user_with_pseudonym(active_all: true)
      section2.enroll_user(student2, "StudentEnrollment", "active")
      assignment = @course.assignments.create!(
        title: "by-section cached",
        submission_types: ["online_text_entry"]
      )
      assignment.submit_homework(student1, submission_type: "online_text_entry", body: "s1")
      assignment.submit_homework(student2, submission_type: "online_text_entry", body: "s2")

      enable_cache do
        sections = NeedsGradingCountQuery.new([assignment], @teacher).count_by_section[assignment.global_id]
        expect(sections.sum { |s| s[:needs_grading_count] }).to eq(2)

        Submission.where(assignment:).update_all(
          workflow_state: "graded", score: 1, graded_at: Time.zone.now
        )

        sections_cached = NeedsGradingCountQuery.new([assignment], @teacher).count_by_section[assignment.global_id]
        expect(sections_cached.sum { |s| s[:needs_grading_count] }).to eq(2)

        Timecop.freeze(1.minute.from_now) do
          assignment.clear_cache_key(:needs_grading)
          sections_fresh = NeedsGradingCountQuery.new([assignment], @teacher).count_by_section[assignment.global_id]
          expect(sections_fresh.sum { |s| s[:needs_grading_count] }).to eq(0)
        end
      end
    end
  end

  describe "RequestCache warming" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true, user_name: "some user")
      @rc_student = student_in_course(course: @course, active_all: true).user
      @rc_assignment1 = @course.assignments.create!(title: "rc1", submission_types: ["online_text_entry"])
      @rc_assignment2 = @course.assignments.create!(title: "rc2", submission_types: ["online_text_entry"])
      @rc_assignment1.submit_homework(@rc_student, submission_type: "online_text_entry", body: "hi")
    end

    it "populates request cache for every assignment in the batch" do
      RequestCache.enable do
        NeedsGradingCountQuery.new([@rc_assignment1, @rc_assignment2], @teacher).count

        expect(RequestCache.exist?("ngcq_count", @rc_assignment1.global_id, @teacher.global_id)).to be true
        expect(RequestCache.exist?("ngcq_count", @rc_assignment2.global_id, @teacher.global_id)).to be true
      end
    end

    it "subsequent per-assignment calls read from request cache" do
      RequestCache.enable do
        NeedsGradingCountQuery.new([@rc_assignment1, @rc_assignment2], @teacher).count

        result = NeedsGradingCountQuery.new([@rc_assignment1], @teacher).count
        expect(result[@rc_assignment1.global_id]).to eq(1)
        expect(result.keys).to eq([@rc_assignment1.global_id])
      end
    end

    it "count and count_by_section use independent cache keys" do
      RequestCache.enable do
        NeedsGradingCountQuery.new([@rc_assignment1], @teacher).count

        expect(RequestCache.exist?("ngcq_count_by_section", @rc_assignment1.global_id, @teacher.global_id)).to be false

        NeedsGradingCountQuery.new([@rc_assignment1], @teacher).count_by_section

        expect(RequestCache.exist?("ngcq_count", @rc_assignment1.global_id, @teacher.global_id)).to be true
        expect(RequestCache.exist?("ngcq_count_by_section", @rc_assignment1.global_id, @teacher.global_id)).to be true
      end
    end

    it "handles nil user in request cache key without error" do
      RequestCache.enable do
        result1 = NeedsGradingCountQuery.new([@rc_assignment1]).manual_count
        result2 = NeedsGradingCountQuery.new([@rc_assignment1]).manual_count
        expect(result1[@rc_assignment1.global_id]).to eq(result2[@rc_assignment1.global_id])
      end
    end

    it "computes only missing assignments when batch contains a mix of cached and uncached" do
      rc_student2 = student_in_course(course: @course, active_all: true).user
      rc_a3 = @course.assignments.create!(title: "rc3", submission_types: ["online_text_entry"])
      rc_a3.submit_homework(rc_student2, submission_type: "online_text_entry", body: "hi")

      RequestCache.enable do
        # Warm rc_assignment1 and rc_assignment2 only
        NeedsGradingCountQuery.new([@rc_assignment1, @rc_assignment2], @teacher).count

        expect(RequestCache.exist?("ngcq_count", @rc_assignment1.global_id, @teacher.global_id)).to be true
        expect(RequestCache.exist?("ngcq_count", @rc_assignment2.global_id, @teacher.global_id)).to be true
        expect(RequestCache.exist?("ngcq_count", rc_a3.global_id, @teacher.global_id)).to be false

        # Call with all three — only rc_a3 should be computed, the others read from cache
        result = NeedsGradingCountQuery.new([@rc_assignment1, @rc_assignment2, rc_a3], @teacher).count

        expect(result[@rc_assignment1.global_id]).to eq(1)
        expect(result[@rc_assignment2.global_id]).to eq(0)
        expect(result[rc_a3.global_id]).to eq(1)

        # rc_a3 is now cached too
        expect(RequestCache.exist?("ngcq_count", rc_a3.global_id, @teacher.global_id)).to be true
      end
    end
  end

  describe "batch queries" do
    it "returns correct counts for multiple assignments in one call" do
      course_with_teacher(active_all: true)
      student = student_in_course(course: @course, active_all: true).user
      a1 = @course.assignments.create!(title: "batch a1", submission_types: ["online_text_entry"])
      a2 = @course.assignments.create!(title: "batch a2", submission_types: ["online_text_entry"])
      a1.submit_homework(student, submission_type: "online_text_entry", body: "hi")

      result = NeedsGradingCountQuery.new([a1, a2], @teacher).count

      expect(result[a1.global_id]).to eq(1)
      expect(result[a2.global_id]).to eq(0)
    end
  end
end
