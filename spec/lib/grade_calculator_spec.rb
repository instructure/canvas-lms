# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe GradeCalculator do
  before :once do
    course_with_student active_all: true
  end

  context "computing grades" do
    it "computes grades without dying" do
      @group = @course.assignment_groups.create!(name: "some group", group_weight: 100)
      @assignment = @course.assignments.create!(title: "Some Assignment", points_possible: 10, assignment_group: @group)
      @assignment2 = @course.assignments.create!(title: "Some Assignment2", points_possible: 10, assignment_group: @group)
      @submission = @assignment2.grade_student(@user, grade: "5", grader: @teacher)
      expect(@user.enrollments.first.computed_current_score).to equal(50.0)
      expect(@user.enrollments.first.computed_final_score).to equal(25.0)
    end

    it "weighted grading periods: gracefully handles (by skipping) enrollments from other courses" do
      first_course = @course
      course_with_student active_all: true
      grading_period_set = @course.root_account.grading_period_groups.create!(weighted: true)
      grading_period_set.enrollment_terms << @course.enrollment_term
      grading_period_set.grading_periods.create!(
        title: "A Grading Period",
        start_date: 10.days.ago,
        end_date: 10.days.from_now,
        weight: 50
      )
      expect do
        GradeCalculator.recompute_final_score(@student.id, first_course.id)
      end.not_to raise_error
    end

    it "weighted grading periods: gracefully handles (by skipping) deleted enrollments" do
      grading_period_set = @course.root_account.grading_period_groups.create!(weighted: true)
      grading_period_set.enrollment_terms << @course.enrollment_term
      grading_period_set.grading_periods.create!(
        title: "A Grading Period",
        start_date: 10.days.ago,
        end_date: 10.days.from_now,
        weight: 50
      )
      @user.enrollments.first.destroy
      expect do
        GradeCalculator.recompute_final_score(@user.id, @course.id)
      end.not_to raise_error
    end

    it "weighted grading periods: compute_scores does not raise an error if no grading period score objects exist" do
      grading_period_set = @course.root_account.grading_period_groups.create!(weighted: true)
      grading_period_set.enrollment_terms << @course.enrollment_term
      grading_period_set.grading_periods.create!(
        title: "A Grading Period",
        start_date: 10.days.ago,
        end_date: 10.days.from_now,
        weight: 50
      )
      Score.where(enrollment: @course.student_enrollments).destroy_all

      grade_calculator = GradeCalculator.new(@user.id, @course.id)

      expect { grade_calculator.compute_scores }.not_to raise_error
    end

    it "can compute scores for users with deleted enrollments when grading periods are used" do
      grading_period_set = @course.root_account.grading_period_groups.create!
      grading_period_set.enrollment_terms << @course.enrollment_term
      period = grading_period_set.grading_periods.create!(
        title: "A Grading Period",
        start_date: 10.days.ago,
        end_date: 10.days.from_now
      )
      @user.enrollments.first.destroy
      expect do
        GradeCalculator.recompute_final_score(@user.id, @course.id, grading_period_id: period.id)
      end.not_to raise_error
    end

    it "deletes irrelevant scores for inactive grading periods" do
      grading_period_set = @course.root_account.grading_period_groups.create!
      grading_period_set.enrollment_terms << @course.enrollment_term
      grading_period_set.grading_periods.create!(
        title: "A Grading Period",
        start_date: 20.days.ago,
        end_date: 10.days.ago
      )
      period2 = grading_period_set.grading_periods.create!(
        title: "Another Grading Period",
        start_date: 8.days.ago,
        end_date: 7.days.from_now
      )
      stale_score = Score.find_by(enrollment: @user.enrollments.first, grading_period: period2)
      period2.destroy
      stale_score.reload.undestroy
      expect do
        GradeCalculator.recompute_final_score(@user.id, @course.id)
      end.to change { stale_score.reload.workflow_state }.from("active").to("deleted")
    end

    it "gracefully handles missing submissions" do
      # Create at least one alternate section for this course
      section = @course.course_sections.create!(name: "Section #2")

      # Enroll multiple students in a course
      students = [@student]
      students << course_with_student(active_all: true, course: @course).user
      students << course_with_student(active_all: true, course: @course).user

      # Enroll the last student into both sections
      course_with_student(active_all: true, course: @course, user: students[-1], section:, allow_multiple_enrollments: true)

      # Create an assignment...
      assignments = []
      assignments << @course.assignments.create!(title: "Assignment #1", points_possible: 10)

      # ...and grade it for the three students
      students.each { |student| assignments[0].grade_student(student, grade: "5", grader: @teacher) }

      # Conclude all enrollments for the last student so no submissions are created for them...
      @course.enrollments.where(user_id: students.last).map(&:conclude)

      # ...and create an assignment now so there's no corresponding submission for the concluded user
      assignments << @course.assignments.create!(title: "Assignment #2", points_possible: 10)
      assignments << @course.assignments.create!(title: "Assignment #3", points_possible: 10)

      # ...and grade it for the first two students
      assignments[1..2].each do |assignment|
        students[0..1].each { |student| assignment.grade_student(student, grade: "6", grader: @teacher) }
      end

      # Update the assignment group to drop the lowest score
      assignments.first.assignment_group.rules_hash = { drop_lowest: 1 }
      assignments.first.assignment_group.save!

      calculator = GradeCalculator.new(students.map(&:id), @course)
      computed_scores = calculator.compute_scores

      # Verify the grades for the third student are what we expect
      expect(computed_scores[2][:current][:grade]).to equal(50.0)
      expect(computed_scores[2][:final][:grade]).to equal(50.0)
    end

    context "sharding" do
      specs_require_sharding

      let(:seed_assignment_groups_with_scores) do
        now = Time.zone.now
        groups = []
        assignments = []
        submissions = []
        @shard1.activate do
          account = Account.create!
          course_with_student(active_all: true, account:, user: @user)
          @course.update_attribute(:group_weighting_scheme, "percent")
          groups <<
            @course.assignment_groups.create!(name: "some group 1", group_weight: 50) <<
            @course.assignment_groups.create!(name: "some group 2", group_weight: 50)
          asgt_opts = { due_at: now, points_possible: 10 }
          assignments <<
            @course.assignments.create!(title: "Some Assignment 1", assignment_group: groups[0], **asgt_opts) <<
            @course.assignments.create!(title: "Some Assignment 2", assignment_group: groups[1], **asgt_opts) <<
            @course.assignments.create!(title: "Some Assignment 3", assignment_group: groups[1], **asgt_opts)
          submissions <<
            assignments[0].submissions.find_by!(user: @user) <<
            assignments[1].submissions.find_by!(user: @user)

          assignments[0].grade_student(@user, grade: "5", grader: @teacher)
          assignments[1].grade_student(@user, grade: "2.5", grader: @teacher)
        end

        groups
      end

      it "deletes irrelevant cross-shard scores" do
        @user = User.create!

        @shard1.activate do
          account = Account.create!
          course_with_student(active_all: true, account:, user: @user)
          grading_period_set = account.grading_period_groups.create!
          grading_period_set.enrollment_terms << @course.enrollment_term
          grading_period_set.grading_periods.create!(
            title: "A Grading Period",
            start_date: 20.days.ago,
            end_date: 10.days.ago
          )
          period2 = grading_period_set.grading_periods.create!(
            title: "Another Grading Period",
            start_date: 8.days.ago,
            end_date: 7.days.from_now
          )
          @stale_score = Score.find_by(enrollment: @enrollment, grading_period: period2)
          period2.destroy
          @stale_score.reload.undestroy
        end

        expect do
          GradeCalculator.recompute_final_score(@user.id, @course.id)
        end.to change { @stale_score.reload.workflow_state }.from("active").to("deleted")
      end

      it "updates cross-shard scores" do
        @user = User.create!

        @shard1.activate do
          account = Account.create!
          course_with_student(active_all: true, account:, user: @user)
          @group = @course.assignment_groups.create!(name: "some group", group_weight: 100)
          @assignment = @course.assignments.create!(title: "Some Assignment", points_possible: 10, assignment_group: @group)
          @assignment2 = @course.assignments.create!(title: "Some Assignment2", points_possible: 10, assignment_group: @group)
        end

        @assignment2.grade_student(@user, grade: "5", grader: @teacher)

        expect(Enrollment.shard(@course.shard).where(user_id: @user.global_id).first.computed_current_score).to equal(50.0)
        expect(Enrollment.shard(@course.shard).where(user_id: @user.global_id).first.computed_final_score).to equal(25.0)
      end

      it "updates cross-shard scores with grading periods" do
        now = Time.zone.now
        @user = User.create!

        @shard1.activate do
          account = Account.create!
          course_with_student(active_all: true, account:, user: @user)
          grading_period_set = account.grading_period_groups.create!
          grading_period_set.enrollment_terms << @course.enrollment_term
          @grading_period = grading_period_set.grading_periods.create!(
            title: "Fall Semester",
            start_date: 1.month.from_now(now),
            end_date: 3.months.from_now(now)
          )
          @group = @course.assignment_groups.create!(name: "some group", group_weight: 100)
          @assignment = @course.assignments.create!(title: "Some Assignment", due_at: now, points_possible: 10, assignment_group: @group)
          @course.assignments.create!(title: "Some Assignment2", due_at: now, points_possible: 10, assignment_group: @group)
          @assignment_in_period = @course.assignments.create!(title: "In a Grading Period", due_at: 2.months.from_now(now), points_possible: 10)
          @course.assignments.create!(title: "In a Grading Period", due_at: 2.months.from_now(now), points_possible: 10)
        end

        @assignment.grade_student(@user, grade: "5", grader: @teacher)
        @assignment_in_period.grade_student(@user, grade: "2", grader: @teacher)

        expect(Enrollment.shard(@course.shard).where(user_id: @user.global_id).first.computed_current_score).to equal(35.0)
        expect(Enrollment.shard(@course.shard).where(user_id: @user.global_id).first.computed_final_score).to equal(17.5)
        expect(Enrollment.shard(@course.shard).where(user_id: @user.global_id).first.computed_current_score(grading_period_id: @grading_period.id)).to equal(20.0)
        expect(Enrollment.shard(@course.shard).where(user_id: @user.global_id).first.computed_final_score(grading_period_id: @grading_period.id)).to equal(10.0)
      end

      it("updates cross-shard scores with assignment groups") do
        @user = User.create!

        groups = seed_assignment_groups_with_scores
        @shard1.activate do
          GradeCalculator.recompute_final_score(@user.id, @course.id)
        end

        enrollment = Enrollment.shard(@course.shard).where(user_id: @user.global_id).first
        expect(enrollment.computed_current_score).to be(37.5)
        expect(enrollment.computed_final_score).to be(31.25)
        expect(enrollment.computed_current_score(assignment_group_id: groups[0].id)).to be(50.0)
        expect(enrollment.computed_final_score(assignment_group_id: groups[0].id)).to be(50.0)
        expect(enrollment.computed_current_score(assignment_group_id: groups[1].id)).to be(25.0)
        expect(enrollment.computed_final_score(assignment_group_id: groups[1].id)).to be(12.5)
      end
    end

    it "recomputes when an assignment's points_possible changes'" do
      @group = @course.assignment_groups.create!(name: "some group", group_weight: 100)
      @assignment = @course.assignments.create!(title: "Some Assignment", points_possible: 10, assignment_group: @group)
      @submission = @assignment.grade_student(@user, grade: "5", grader: @teacher)
      expect(@user.enrollments.first.computed_current_score).to equal(50.0)
      expect(@user.enrollments.first.computed_final_score).to equal(50.0)

      @assignment.points_possible = 5
      @assignment.save!

      expect(@user.enrollments.first.computed_current_score).to equal(100.0)
      expect(@user.enrollments.first.computed_final_score).to equal(100.0)
    end

    it "recomputes when an assignment group's weight changes'" do
      @course.group_weighting_scheme = "percent"
      @course.save
      @group = @course.assignment_groups.create!(name: "some group", group_weight: 50)
      @group2 = @course.assignment_groups.create!(name: "some group2", group_weight: 50)
      @assignment = @course.assignments.create!(title: "Some Assignment", points_possible: 10, assignment_group: @group)
      @assignment.grade_student(@user, grade: "10", grader: @teacher)
      @course.assignments.create! points_possible: 1,
                                  assignment_group: @group2
      expect(@user.enrollments.first.computed_current_score).to equal(100.0)
      expect(@user.enrollments.first.computed_final_score).to equal(50.0)

      @group.group_weight = 60
      @group2.group_weight = 40
      @group.save!
      @group2.save!

      expect(@user.enrollments.first.computed_current_score).to equal(100.0)
      expect(@user.enrollments.first.computed_final_score).to equal(60.0)
    end

    it "recomputes when an assignment is flagged as omit from final grade" do
      @group = @course.assignment_groups.create!(name: "some group", group_weight: 100)
      assignment = @course.assignments.create!(
        title: "Some Assignment",
        points_possible: 10,
        assignment_group: @group
      )
      assignment2 = @course.assignments.create!(
        title: "Some Assignment2",
        points_possible: 10,
        assignment_group: @group,
        omit_from_final_grade: true
      )
      # grade first assignment for student
      assignment.grade_student(@user, grade: "5", grader: @teacher)

      # assert that at this point both current and final scores are 50%
      expect(@user.enrollments.first.computed_current_score).to equal(50.0)
      expect(@user.enrollments.first.computed_final_score).to equal(50.0)

      # grade second assignment for same student with a different score
      assignment2.grade_student(@user, grade: "10", grader: @teacher)

      # assert that current and final scores have not changed since second assignment
      # is flagged to be omitted from final grade
      expect(@user.enrollments.first.computed_current_score).to equal(50.0)
      expect(@user.enrollments.first.computed_final_score).to equal(50.0)
    end

    it "recomputes when an assignment changes assignment groups" do
      @course.update_attribute :group_weighting_scheme, "percent"
      ag1 = @course.assignment_groups.create! name: "Group 1", group_weight: 80
      ag2 = @course.assignment_groups.create! name: "Group 2", group_weight: 20
      a1 = ag1.assignments.create! points_possible: 10,
                                   name: "Assignment 1",
                                   context: @course
      a2 = ag2.assignments.create! points_possible: 10,
                                   name: "Assignment 2",
                                   context: @course

      a1.grade_student(@student, grade: 0, grader: @teacher)
      a2.grade_student(@student, grade: 10, grader: @teacher)

      enrollment = @student.enrollments.first

      expect(enrollment.computed_final_score).to equal 20.0

      a2.update assignment_group: ag1
      expect(enrollment.reload.computed_final_score).to equal 50.0
    end

    it "recomputes during #run_if_overrides_changed!" do
      a = @course.assignments.create! name: "Foo",
                                      points_possible: 10,
                                      context: @assignment
      a.grade_student(@student, grade: 10, grader: @teacher)

      e = @student.enrollments.first
      expect(e.computed_final_score).to equal 100.0

      Submission.update_all(score: 5, grade: 5)
      a.only_visible_to_overrides = true
      a.run_if_overrides_changed!
      expect(e.reload.computed_final_score).to equal 50.0
    end

    context "live events" do
      let(:assignment) { @course.assignments.create!(title: "Assignment #1", points_possible: 10) }

      before do
        # Enroll student into two sections
        section = @course.course_sections.create!(name: "Section #2")
        course_with_student(active_all: true,
                            course: @course,
                            user: @student,
                            section:,
                            allow_multiple_enrollments: true)
        assignment.grade_student(@student, grade: "5", grader: @teacher)
      end

      it "emits one live event per student" do
        expect(Canvas::LiveEvents).to receive(:course_grade_change).once do |score, old_score_values, enrollment|
          expect(enrollment.user_id).to eq(@student.id)
          expect(enrollment.course_id).to eq(@course.id)
          expect(score.current_score).to eq(60)
          expect(old_score_values[:current_score]).to eq(50)
          expect(old_score_values[:final_score]).to eq(50)
        end

        assignment.grade_student(@student, grade: "6", grader: @teacher)
      end

      it "does not emit a live event if the course grade does not change" do
        expect(Canvas::LiveEvents).to_not receive(:course_grade_change)
        assignment.grade_student(@student, grade: "5", grader: @teacher)
        GradeCalculator.new([@user.id], @course.id).compute_scores
      end
    end

    def two_groups_two_assignments(g1_weight, a1_possible, g2_weight, a2_possible)
      @group = @course.assignment_groups.create!(name: "some group", group_weight: g1_weight)
      @assignment = @group.assignments.build(title: "some assignments", points_possible: a1_possible)
      @assignment.context = @course
      @assignment.save!
      @group2 = @course.assignment_groups.create!(name: "some other group", group_weight: g2_weight)
      @assignment2 = @group2.assignments.build(title: "some assignments", points_possible: a2_possible)
      @assignment2.context = @course
      @assignment2.save!
    end

    describe "group with no grade or muted grade" do
      before do
        two_groups_two_assignments(50, 10, 50, 10)
        @submission = @assignment.grade_student(@user, grade: "5", grader: @teacher)
      end

      it "ignores no grade for current grade calculation, even when weighted" do
        @course.group_weighting_scheme = "percent"
        @course.save!
        @user.reload
        expect(@user.enrollments.first.computed_current_score).to equal(50.0)
        expect(@user.enrollments.first.computed_final_score).to equal(25.0)
      end

      it "ignores no grade for current grade but not final grade" do
        @user.reload
        expect(@user.enrollments.first.computed_current_score).to equal(50.0)
        expect(@user.enrollments.first.computed_final_score).to equal(25.0)
      end

      describe "hidden scores" do
        context "when post policies are enabled" do
          let(:auto_assignment) { @assignment }
          let(:manual_assignment) { @assignment2 }

          before do
            # We assigned this above, but repeat it for the sake of clarity
            auto_assignment.grade_student(@user, grade: "5", grader: @teacher)

            manual_assignment.ensure_post_policy(post_manually: true)
            manual_assignment.grade_student(@user, grade: "10", grader: @teacher)

            @course.update!(group_weighting_scheme: "percent")
          end

          context "when including unposted submissions" do
            let(:calculator) { GradeCalculator.new([@user.id], @course.id, ignore_muted: false) }
            let(:computed_score_data) { calculator.compute_scores.first }

            it "incorporates unposted submissions when calculating the current grade" do
              expect(computed_score_data[:current][:grade]).to eq 75.0
            end

            it "incorporates unposted submissions when calculating the final grade" do
              expect(computed_score_data[:final][:grade]).to eq 75.0
            end
          end

          context "when ignoring unposted submissions" do
            let(:calculator) { GradeCalculator.new([@user.id], @course.id) }
            let(:computed_score_data) { calculator.compute_scores.first }

            it "does not incorporate unposted submissions when calculating the current grade" do
              expect(computed_score_data[:current][:grade]).to eq 50.0
            end

            it "does not incorporate unposted submissions when calculating the final grade" do
              expect(computed_score_data[:final][:grade]).to eq 25.0
            end
          end

          context "with unposted anonymous assignments" do
            let(:calculator) { GradeCalculator.new([@user.id], @course.id, ignore_muted: false) }
            let(:computed_score_data) { calculator.compute_scores.first }

            before do
              @anonymized_assignment = @course.assignments.create!(anonymous_grading: true)
              @anonymized_assignment.grade_student(@user, grade: "10", grader: @teacher)
            end

            it "does not incorporate submissions for unposted anonymous assignments" do
              expect(computed_score_data[:current][:grade]).to eq 75.0
            end

            it "incorporates submissions for posted anonymous assignments" do
              @anonymized_assignment.post_submissions
              expect(computed_score_data[:current][:grade]).to eq 125.0
            end

            context "when including unposted anonymous assignments in grade calculations" do
              let(:calculator) { GradeCalculator.new([@user.id], @course.id, ignore_muted: false, ignore_unposted_anonymous: false) }

              it "incorporates submissions for unposted anonymous assignments" do
                expect(computed_score_data[:current][:grade]).to eq 125.0
              end

              it "incorporates submissions for posted anonymous assignments" do
                @anonymized_assignment.post_submissions
                expect(computed_score_data[:current][:grade]).to eq 125.0
              end
            end
          end

          describe "persisting score data" do
            let(:calculator) { GradeCalculator.new([@user.id], @course.id, ignore_muted: true) }
            let(:enrollment) { Enrollment.find_by!(user: @user, course: @course) }

            # Calling compute_and_save_scores when ignore_muted is true will start
            # a separate run calculating hidden scores
            before { calculator.compute_and_save_scores }

            it "ignores unposted submissions when calculating the current score" do
              expect(enrollment.computed_current_score).to eq 50.0
            end

            it "ignores unposted submissions when calculating the final score" do
              expect(enrollment.computed_final_score).to eq 25.0
            end

            it "always incorporates unposted submissions into the Score object's unposted current score" do
              expect(enrollment.unposted_current_score).to eq 75.0
            end

            it "always incorporates unposted submissions into the Score object's unposted final score" do
              expect(enrollment.unposted_final_score).to eq 75.0
            end
          end
        end
      end
    end

    it "returns assignment group info" do
      two_groups_two_assignments(25, 10, 75, 10)
      @assignment.grade_student @user, grade: 5, grader: @teacher
      @assignment2.grade_student @user, grade: 10, grader: @teacher
      calc = GradeCalculator.new [@user.id], @course.id

      computed_scores = calc.compute_scores.first
      current_groups  = computed_scores[:current_groups]
      final_groups    = computed_scores[:final_groups]

      expect(current_groups).to eq final_groups
      expect(current_groups[@group.id][:grade]).to equal 50.0
      expect(current_groups[@group2.id][:grade]).to equal 100.0
    end

    it "calculates the grade without floating point calculation errors" do
      @course.update!(group_weighting_scheme: "percent")
      two_groups_two_assignments(50, 200, 50, 100)
      @assignment.grade_student(@user, grade: 267.9, grader: @teacher)
      @assignment2.grade_student(@user, grade: 53.7, grader: @teacher)
      calc = GradeCalculator.new([@user.id], @course.id)
      computed_scores = calc.compute_scores.first
      # floating point calculation: 66.975 + 26.95 = 93.82499999999999 => 93.82%
      # correct calcuation: 66.975 + 26.95 = 93.825 => 93.83%
      expect(computed_scores.dig(:current, :grade)).to equal 93.83
    end

    it "calculates the grade without floating point calculation errors due to points possible" do
      @course.update!(group_weighting_scheme: "points")
      @assignment_group = @course.assignment_groups.create!(name: "Assignments")

      @assignments = Array.new(2) do |i|
        @course.assignments.create!(
          assignment_group: @assignment_group,
          points_possible: 100,
          title: "Assignment #{i + 1}"
        )
      end

      @assignments[0].grade_student(@user, grade: 88.56, grader: @teacher)
      @assignments[1].grade_student(@user, grade: 69.71, grader: @teacher)
      calc = GradeCalculator.new([@user.id], @course.id)
      computed_scores = calc.compute_scores.first
      # floating point calculation: 88.56 + 69.71 / 2 = 79.13499999999999 => 79.13%
      # correct calcuation: 88.56 + 69.71 / 2 = 79.135 => 79.14%
      expect(computed_scores.dig(:current, :grade)).to equal 79.14
    end

    it "computes a weighted grade when specified" do
      two_groups_two_assignments(50, 10, 50, 40)
      expect(@user.enrollments.first.computed_current_score).to equal(nil)
      expect(@user.enrollments.first.computed_final_score).to equal(0.0)
      @submission = @assignment.grade_student(@user, grade: "9", grader: @teacher)
      expect(@submission[0].score).to equal(9.0)
      expect(@user.enrollments).not_to be_empty
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(90.0)
      expect(@user.enrollments.first.computed_final_score).to equal(18.0)
      @course.group_weighting_scheme = "percent"
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(90.0)
      expect(@user.enrollments.first.computed_final_score).to equal(45.0)
      @submission2 = @assignment2.grade_student(@user, grade: "20", grader: @teacher)
      expect(@submission2[0].score).to equal(20.0)
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(70.0)
      expect(@user.enrollments.first.computed_final_score).to equal(70.0)
      @course.group_weighting_scheme = nil
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(58.0)
      expect(@user.enrollments.first.computed_final_score).to equal(58.0)
    end

    it "incorporates extra credit when the weighted total is more than 100%" do
      two_groups_two_assignments(50, 10, 60, 40)
      expect(@user.enrollments.first.computed_current_score).to equal(nil)
      expect(@user.enrollments.first.computed_final_score).to equal(0.0)
      @submission = @assignment.grade_student(@user, grade: "10", grader: @teacher)
      expect(@submission[0].score).to equal(10.0)
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(100.0)
      expect(@user.enrollments.first.computed_final_score).to equal(20.0)
      @course.group_weighting_scheme = "percent"
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(100.0)
      expect(@user.enrollments.first.computed_final_score).to equal(50.0)
      @submission2 = @assignment2.grade_student(@user, grade: "40", grader: @teacher)
      expect(@submission2[0].score).to equal(40.0)
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(110.0)
      expect(@user.enrollments.first.computed_final_score).to equal(110.0)
      @course.group_weighting_scheme = nil
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(100.0)
      expect(@user.enrollments.first.computed_final_score).to equal(100.0)
    end

    it "incorporates extra credit when the total is more than the possible" do
      two_groups_two_assignments(50, 10, 60, 40)
      expect(@user.enrollments.first.computed_current_score).to equal(nil)
      expect(@user.enrollments.first.computed_final_score).to equal(0.0)
      @submission = @assignment.grade_student(@user, grade: "11", grader: @teacher)
      expect(@submission[0].score).to equal(11.0)
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(110.0)
      expect(@user.enrollments.first.computed_final_score).to equal(22.0)
      @course.group_weighting_scheme = "percent"
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(110.0)
      expect(@user.enrollments.first.computed_final_score).to equal(55.0)
      @submission2 = @assignment2.grade_student(@user, grade: "45", grader: @teacher)
      expect(@submission2[0].score).to equal(45.0)
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(122.5)
      expect(@user.enrollments.first.computed_final_score).to equal(122.5)
      @course.group_weighting_scheme = nil
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(112.0)
      expect(@user.enrollments.first.computed_final_score).to equal(112.0)
    end

    it "properly calculates the grade when total weight is less than 100%" do
      two_groups_two_assignments(50, 10, 40, 40)
      @submission = @assignment.grade_student(@user, grade: "10", grader: @teacher)
      @course.group_weighting_scheme = "percent"
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(100.0)
      expect(@user.enrollments.first.computed_final_score).to equal(55.56)

      @submission2 = @assignment2.grade_student(@user, grade: "40", grader: @teacher)
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(100.0)
      expect(@user.enrollments.first.computed_final_score).to equal(100.0)
    end

    it "properly calculates the grade when there are 'not graded' assignments with scores" do
      @group = @course.assignment_groups.create!(name: "some group")
      @assignment = @group.assignments.build(title: "some assignments", points_possible: 10)
      @assignment.context = @course
      @assignment.save!
      @assignment2 = @group.assignments.build(title: "Not graded assignment", submission_types: "not_graded")
      @assignment2.context = @course
      @assignment2.save!
      @submission = @assignment.grade_student(@user, grade: "9", grader: @teacher)
      @submission2 = @assignment2.grade_student(@user, grade: "1", grader: @teacher)
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(90.0)
      expect(@user.enrollments.first.computed_final_score).to equal(90.0)
    end

    def two_graded_assignments
      @group = @course.assignment_groups.create!(name: "some group")
      @assignment = @group.assignments.build(title: "some assignments", points_possible: 5)
      @assignment.context = @course
      @assignment.save!
      @assignment2 = @group.assignments.build(title: "yet another", points_possible: 5)
      @assignment2.context = @course
      @assignment2.save!
      @submission = @assignment.grade_student(@user, grade: "2", grader: @teacher)
      @submission2 = @assignment2.grade_student(@user, grade: "4", grader: @teacher)
      @course.save!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(60.0)
      expect(@user.enrollments.first.computed_final_score).to equal(60.0)
    end

    it "recalculates all cached grades when an assignment is deleted/restored" do
      two_graded_assignments
      @assignment2.destroy
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(40.0) # 2/5
      expect(@user.enrollments.first.computed_final_score).to equal(40.0)

      @assignment2.restore
      @assignment2.publish if @assignment2.unpublished?
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(60.0)
      expect(@user.enrollments.first.computed_final_score).to equal(60.0)
    end

    it "recalculates all cached grades when an assignment is muted/unmuted" do
      two_graded_assignments
      @assignment2.mute!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(40.0) # 2/5
      expect(@user.enrollments.first.computed_final_score).to equal(20.0) # 2/10

      @assignment2.unmute!
      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(60.0)
      expect(@user.enrollments.first.computed_final_score).to equal(60.0)
    end

    def nil_graded_assignment
      @group = @course.assignment_groups.create!(name: "group2", group_weight: 50)
      @assignment_1 = @group.assignments.build(title: "some assignments", points_possible: 10)
      @assignment_1.context = @course
      @assignment_1.save!
      @assignment_2 = @group.assignments.build(title: "some assignments", points_possible: 4)
      @assignment_2.context = @course
      @assignment_2.save!
      @group2 = @course.assignment_groups.create!(name: "assignments", group_weight: 40)
      @assignment2_1 = @group2.assignments.build(title: "some assignments", points_possible: 40)
      @assignment2_1.context = @course
      @assignment2_1.save!

      @assignment_1.grade_student(@user, grade: nil, grader: @teacher)
      @assignment_2.grade_student(@user, grade: "1", grader: @teacher)
      @assignment2_1.grade_student(@user, grade: "40", grader: @teacher)
    end

    it "properly handles submissions with no score" do
      nil_graded_assignment

      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(93.18)
      expect(@user.enrollments.first.computed_final_score).to equal(75.93)

      @course.group_weighting_scheme = "percent"
      @course.save!

      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(58.33)
      expect(@user.enrollments.first.computed_final_score).to equal(48.41)
    end

    it "treats muted assignments as if there is no submission" do
      # should have same scores as previous spec despite having a grade
      nil_graded_assignment

      @assignment_1.post_policy.update!(post_manually: true)
      @assignment_1.grade_student(@user, grade: 500, grader: @teacher)

      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(93.18)
      expect(@user.enrollments.first.computed_final_score).to equal(75.93)

      @course.group_weighting_scheme = "percent"
      @course.save!

      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(58.33)
      expect(@user.enrollments.first.computed_final_score).to equal(48.41)
    end

    it "ignores pending_review submissions" do
      a1 = @course.assignments.create! name: "fake quiz", points_possible: 50
      a2 = @course.assignments.create! name: "assignment", points_possible: 50

      s1 = a1.grade_student(@student, grade: 25, grader: @teacher).first
      Submission.where(id: s1.id).update_all(workflow_state: "pending_review")

      a2.grade_student(@student, grade: 50, grader: @teacher)

      enrollment = @student.enrollments.first.reload
      expect(enrollment.computed_current_score).to equal 100.0
      expect(enrollment.computed_final_score).to equal 75.0
    end

    it "does not include unpublished assignments" do
      two_graded_assignments
      @assignment2.unpublish

      @user.reload
      expect(@user.enrollments.first.computed_current_score).to equal(40.0)
      expect(@user.enrollments.first.computed_final_score).to equal(40.0)
    end
  end

  describe "#number_or_null" do
    it "returns a valid score" do
      calc = GradeCalculator.new [@user.id], @course.id
      score = 23.4
      expect(calc.send(:number_or_null, score)).to equal(score)
    end

    it "converts NaN to NULL" do
      calc = GradeCalculator.new [@user.id], @course.id
      score = 0 / 0.0
      expect(calc.send(:number_or_null, score)).to eql("NULL::float")
    end

    it "converts nil to NULL" do
      calc = GradeCalculator.new [@user.id], @course.id
      score = nil
      expect(calc.send(:number_or_null, score)).to eql("NULL::float")
    end
  end

  describe "memoization" do
    it "only fetches groups once" do
      expect(GradeCalculator).to receive(:new).twice.and_call_original
      expect(@course).to receive(:assignment_groups).once.and_call_original
      GradeCalculator.new(@student.id, @course).compute_and_save_scores
    end

    it "only fetches assignments once" do
      expect(GradeCalculator).to receive(:new).twice.and_call_original
      expect(@course).to receive(:assignments).once.and_call_original
      GradeCalculator.new(@student.id, @course).compute_and_save_scores
    end

    it "only fetches submissions once" do
      expect(GradeCalculator).to receive(:new).twice.and_call_original
      expect(@course).to receive(:submissions).once.and_call_original
      GradeCalculator.new(@student.id, @course).compute_and_save_scores
    end

    it "only fetches grading periods once" do
      expect(GradeCalculator).to receive(:new).twice.and_call_original
      expect(GradingPeriod).to receive(:for).once.and_call_original
      GradeCalculator.new(@student.id, @course).compute_and_save_scores
    end

    it "only fetches enrollments once" do
      expect(GradeCalculator).to receive(:new).twice.and_call_original
      expect(Enrollment).to receive(:shard).once.and_call_original
      GradeCalculator.new(@student.id, @course).compute_and_save_scores
    end
  end

  describe "GradeCalculator.recompute_final_score" do
    it "accepts a course" do
      expect(GradeCalculator).to receive(:new).with([@student.id], @course, Hash)
                                              .and_return(double("GradeCalculator", compute_and_save_scores: "hi"))
      GradeCalculator.recompute_final_score(@student.id, @course)
    end

    it "accepts a course id" do
      expect(GradeCalculator).to receive(:new).with([@student.id], Course, Hash)
                                              .and_return(double("GradeCalculator", compute_and_save_scores: "hi"))
      GradeCalculator.recompute_final_score(@student.id, @course.id)
    end

    it "fetches assignments for GradeCalculator" do
      expect(@course).to receive_message_chain(:assignments, :published, :gradeable, to_a: [5, 6])
      expect(GradeCalculator).to receive(:new).with([@student.id], @course, hash_including(assignments: [5, 6]))
                                              .and_return(double("GradeCalculator", compute_and_save_scores: "hi"))
      GradeCalculator.recompute_final_score(@student.id, @course)
    end

    it "does not fetch assignments if they are already passed" do
      expect(@course).not_to receive(:assignments)
      expect(GradeCalculator).to receive(:new).with([@student.id], @course, hash_including(assignments: [5, 6]))
                                              .and_return(double("GradeCalculator", compute_and_save_scores: "hi"))
      GradeCalculator.recompute_final_score(@student.id, @course, assignments: [5, 6])
    end

    it "fetches groups for GradeCalculator" do
      expect(@course).to receive_message_chain(:assignment_groups, :active, to_a: [5, 6])
      expect(GradeCalculator).to receive(:new).with([@student.id], @course, hash_including(groups: [5, 6]))
                                              .and_return(double("GradeCalculator", compute_and_save_scores: "hi"))
      GradeCalculator.recompute_final_score(@student.id, @course)
    end

    it "does not fetch groups if they are already passed" do
      expect(@course).not_to receive(:assignment_groups)
      expect(GradeCalculator).to receive(:new).with([@student.id], @course, hash_including(groups: [5, 6]))
                                              .and_return(double("GradeCalculator", compute_and_save_scores: "hi"))
      GradeCalculator.recompute_final_score(@student.id, @course, groups: [5, 6])
    end

    it "fetches periods for GradeCalculator" do
      expect(GradingPeriod).to receive(:for).with(@course).and_return([5, 6])
      expect(GradeCalculator).to receive(:new).with([@student.id], @course, hash_including(periods: [5, 6]))
                                              .and_return(double("GradeCalculator", compute_and_save_scores: "hi"))
      GradeCalculator.recompute_final_score(@student.id, @course)
    end

    it "does not fetch periods if they are already passed" do
      expect(GradingPeriod).not_to receive(:for)
      expect(GradeCalculator).to receive(:new).with([@student.id], @course, hash_including(periods: [5, 6]))
                                              .and_return(double("GradeCalculator", compute_and_save_scores: "hi"))
      GradeCalculator.recompute_final_score(@student.id, @course, periods: [5, 6])
    end
  end

  describe "#compute_and_save_scores" do
    before do
      @now = Time.zone.now
      @grading_period_options = { count: 2, weights: [30, 70], start_dates: [1, 2].map { |n| @now + n.months } }

      assignment_group_weights = [45.0, 55.0]
      @assignment_groups = []
      @assignments = []

      @assignment_groups = Array.new(2) do |assignment_group_idx|
        assignment_group = @course.assignment_groups.create!(
          name: "Assignment Group ##{assignment_group_idx}",
          group_weight: assignment_group_weights[assignment_group_idx],
          rules: "drop_lowest:1\n"
        )
        assignments = Array.new(3) do |assignment_idx|
          @course.assignments.create!(
            title: "AG#{assignment_group_idx} Assignment ##{assignment_idx}",
            assignment_group:,
            # Each assignment group spans only one grading period
            due_at: @grading_period_options[:start_dates][assignment_group_idx] + (assignment_idx + 1).days,
            points_possible: 150 # * (assignment_idx + 1)
          )
        end

        assignments.second.post_policy.update!(post_manually: true)

        @assignments.push(*assignments)
        assignment_group
      end

      assignment_scores = [
        # Assignment Group 1
        35.0,  # dropped when we're not treating muted as 0
        99.6,  # muted
        142.7,

        # Assignment Group 2
        42.0,  # dropped when we're not treating muted as 0
        95.0,  # muted
        131.4
      ]
      @assignments.zip(assignment_scores).each do |assignment_score_pair|
        submission = Submission.find_by(user: @student, assignment: assignment_score_pair[0])

        # update_column to avoid callbacks on submission that would trigger the grade calculator.
        # For these specs we want control over when the grade calculator is kicked off
        submission.update_column(:score, assignment_score_pair[1])
      end

      # Make sure the world knows about the grades we surreptitiously assigned above
      @assignments.reject { |assignment| assignment.post_policy.post_manually? }.each do |assignment|
        # ...but, lest we kick off the calculator before we're ready, also do the posting surreptitiously
        assignment.submissions.update_all(posted_at: Time.zone.now)
      end

      @dropped_assignments = [0, 3].map { |i| @assignments[i] }
      @dropped_submissions = @dropped_assignments.map { |a| Submission.find_by(assignment: a, user: @student) }
    end

    let(:dropped_current_submissions) do
      # ignore muted submissions, drop lowest scores
      [@assignments.first, @assignments.fourth].map { |assignment| assignment.submission_for_student(@student) }
    end

    let(:student_enrollment) { @student.enrollments.first }
    let(:scores) { @student.enrollments.first.scores.preload(:score_metadata).index_by(&:grading_period_id) }
    let(:overall_course_score) { @student.enrollments.first.scores.find_by(course_score: true) }
    let(:submission_for_first_assignment) { Submission.find_by(user: @student, assignment: @assignments[1]) }
    let(:submission_for_second_assignment) { Submission.find_by(user: @student, assignment: @assignments[4]) }

    context "without grading periods" do
      describe "overall course score" do
        context "with the percent weighting scheme" do
          before do
            @course.update_column(:group_weighting_scheme, "percent")
            GradeCalculator.new(@student.id, @course).compute_and_save_scores
          end

          it "posted current course score is updated" do
            # 142.7 / 150 * 0.45 + 131.4 / 150 * 0.55
            expect(overall_course_score.current_score).to equal(90.99)
          end

          it "posted current course points are updated" do
            # 142.7 / 150 * 0.45 + 131.4 / 150 * 0.55
            expect(overall_course_score.current_points).to equal(90.99)
          end

          it "posted final course score is updated" do
            # (35.0 + 142.7) / 300 * 0.45 + (42.0 + 131.4) / 300 * 0.55
            expect(overall_course_score.final_score).to equal(58.45)
          end

          it "posted final course points are updated" do
            # (35.0 + 142.7) / 300 * 0.45 + (42.0 + 131.4) / 300 * 0.55
            expect(overall_course_score.final_points).to equal(58.45)
          end

          it "unposted current course score is updated" do
            # (99.6 + 142.7) / 300 * 0.45 + (95.0 + 131.4) / 300 * 0.55
            expect(overall_course_score.unposted_current_score).to equal(77.85)
          end

          it "unposted current course points are updated" do
            # (99.6 + 142.7) / 300 * 0.45 + (95.0 + 131.4) / 300 * 0.55
            expect(overall_course_score.unposted_current_points).to equal(77.85)
          end

          it "unposted final course score is updated" do
            # (99.6 + 142.7) / 300 * 0.45 + (95.0 + 131.4) / 300 * 0.55
            expect(overall_course_score.unposted_final_score).to equal(77.85)
          end

          it "unposted final course points are updated" do
            # (99.6 + 142.7) / 300 * 0.45 + (95.0 + 131.4) / 300 * 0.55
            expect(overall_course_score.unposted_final_points).to equal(77.85)
          end
        end

        context "without a weighting scheme" do
          before do
            GradeCalculator.new(@student.id, @course).compute_and_save_scores
          end

          it "current posted course score is updated" do
            # (142.7 + 131.4) / 300
            expect(overall_course_score.current_score).to equal(91.37)
          end

          it "current posted course points are updated" do
            # 142.7 + 131.4
            expect(overall_course_score.current_points).to equal(274.10)
          end

          it "current final course score is updated" do
            # (35 + 142.7 + 42 + 131.4) / 600
            expect(overall_course_score.final_score).to equal(58.52)
          end

          it "current final course points are updated" do
            # 35 + 142.7 + 42 + 131.4
            expect(overall_course_score.final_points).to equal(351.10)
          end

          it "unposted current course score is updated" do
            # (99.6 + 142.7 + 95.0 + 131.4) / 600
            expect(overall_course_score.unposted_current_score).to equal(78.12)
          end

          it "unposted current course points are updated" do
            # 99.6 + 142.7 + 95.0 + 131.4
            expect(overall_course_score.unposted_current_points).to equal(468.70)
          end

          it "unposted final course score is updated" do
            # (99.6 + 142.7 + 95.0 + 131.4) / 600
            expect(overall_course_score.unposted_final_score).to equal(78.12)
          end

          it "unposted final course points are updated" do
            # 99.6 + 142.7 + 95.0 + 131.4
            expect(overall_course_score.unposted_final_points).to equal(468.70)
          end
        end

        it "schedules assignment score statistic updates as a singleton" do
          calculator = GradeCalculator.new(@student.id, @course)
          expect(ScoreStatisticsGenerator).to receive(:update_score_statistics_in_singleton).with(@course)

          calculator.compute_and_save_scores
        end

        it "does not update score statistics when calculating scores for hidden assignments" do
          calculator = GradeCalculator.new(@student.id, @course, ignore_muted: false)
          expect(ScoreStatisticsGenerator).not_to receive(:update_score_statistics_in_singleton).with(@course)
          calculator.compute_and_save_scores
        end
      end

      describe "assignment group scores" do
        let(:assignment_group_scores) do
          student_enrollment.scores.where.not(assignment_group_id: nil).order(assignment_group_id: :asc)
        end

        context "with the percent weighting scheme" do
          before do
            @course.update_column(:group_weighting_scheme, "percent")
            GradeCalculator.new(@student.id, @course).compute_and_save_scores
          end

          it "posted current assignment group scores are updated" do
            # [142.7 / 150, 131.4 / 150]
            expect(assignment_group_scores.map(&:current_score)).to eq([95.13, 87.60])
          end

          it "posted current assignment group points are updated" do
            # [142.7, 131.4]
            expect(assignment_group_scores.map(&:current_points)).to eq([142.70, 131.40])
          end

          it "posted final assignment group scores are updated" do
            # [(142.7 + 35) / 300, (131.4 + 42) / 300]
            expect(assignment_group_scores.map(&:final_score)).to eq([59.23, 57.80])
          end

          it "posted final assignment group points are updated" do
            # [35 + 142.7, 42 + 131.4]
            expect(assignment_group_scores.map(&:final_points)).to eq([177.70, 173.40])
          end

          it "unposted current assignment group scores are updated" do
            # [142.7 / 150, 131.4 / 150]
            expect(assignment_group_scores.map(&:unposted_current_score)).to eq([80.77, 75.47])
          end

          it "unposted current assignment group points are updated" do
            # 99.6 + 142.7 + 95.0 + 131.4
            expect(assignment_group_scores.map(&:unposted_current_points)).to eq([242.30, 226.40])
          end

          it "unposted final assignment group scores are updated" do
            # (99.6 + 142.7 + 95.0 + 131.4) / 600
            expect(assignment_group_scores.map(&:unposted_final_score)).to eq([80.77, 75.47])
          end

          it "unposted final assignment group points are updated" do
            # 99.6 + 142.7 + 95.0 + 131.4
            expect(assignment_group_scores.map(&:unposted_final_points)).to eq([242.30, 226.40])
          end
        end

        context "without a weighting scheme" do
          before do
            GradeCalculator.new(@student.id, @course).compute_and_save_scores
          end

          it "posted current assignment group scores are updated" do
            # [142.7 / 150, 131.4 / 150]
            expect(assignment_group_scores.map(&:current_score)).to eq([95.13, 87.60])
          end

          it "posted current assignment group points are updated" do
            # [142.7, 131.4]
            expect(assignment_group_scores.map(&:current_points)).to eq([142.70, 131.40])
          end

          it "posted final assignment group scores are updated" do
            # [(35.0 + 142.7) / 300, (42.0 + 131.4) / 300]
            expect(assignment_group_scores.map(&:final_score)).to eq([59.23, 57.80])
          end

          it "posted final assignment group points are updated" do
            # [35.0 + 142.7, 42.0 + 131.4]
            expect(assignment_group_scores.map(&:final_points)).to eq([177.7, 173.40])
          end

          it "unposted current assignment group scores are updated" do
            # [142.7 / 150, 131.4 / 150]
            expect(assignment_group_scores.map(&:unposted_current_score)).to eq([80.77, 75.47])
          end

          it "unposted current assignment group points are updated" do
            # 99.6 + 142.7 + 95.0 + 131.4
            expect(assignment_group_scores.map(&:unposted_current_points)).to eq([242.30, 226.40])
          end

          it "unposted final assignment group scores are updated" do
            # (99.6 + 142.7 + 95.0 + 131.4) / 600
            expect(assignment_group_scores.map(&:unposted_final_score)).to eq([80.77, 75.47])
          end

          it "unposted final assignment group points are updated" do
            # 99.6 + 142.7 + 95.0 + 131.4
            expect(assignment_group_scores.map(&:unposted_final_points)).to eq([242.30, 226.40])
          end
        end
      end
    end

    context "with grading periods" do
      before do
        @grading_periods = grading_periods(@grading_period_options)
        @first_period, @second_period = @grading_periods
      end

      it "updates all grading period scores" do
        GradeCalculator.new(@student.id, @course).compute_and_save_scores
        expect(scores[@first_period.id].current_score).to equal(95.13)
        expect(scores[@second_period.id].current_score).to equal(87.6)
      end

      it "updates all grading period score metadata" do
        GradeCalculator.new(@student.id, @course).compute_and_save_scores
        expected_metadata = [
          {
            "current" => {
              "dropped" => [dropped_current_submissions[0].id]
            },
            "final" => {
              # we dropped a muted submission, which won't be included here
              "dropped" => []
            }
          },
          {
            "current" => {
              "dropped" => [dropped_current_submissions[1].id]
            },
            "final" => {
              # we dropped a muted submission, which won't be included here
              "dropped" => []
            }
          }
        ]
        expect(scores[@first_period.id].score_metadata.calculation_details).to eq(expected_metadata[0])
        expect(scores[@second_period.id].score_metadata.calculation_details).to eq(expected_metadata[1])
      end

      it "does not update grading period scores if update_all_grading_period_scores is false" do
        calculator = GradeCalculator.new(@student.id, @course, update_all_grading_period_scores: false)
        expect { calculator.compute_and_save_scores }.not_to change {
          @student.enrollments.first.scores.where.not(grading_period_id: nil).order(:id).pluck(:updated_at)
        }
      end

      it "schedules assignment score statistic updates as a singleton" do
        calculator = GradeCalculator.new(@student.id, @course)
        expect(ScoreStatisticsGenerator).to receive(:update_score_statistics_in_singleton).with(@course)

        calculator.compute_and_save_scores
      end

      context "when a grading period is provided" do
        it "updates the grading period score" do
          GradeCalculator.new(@student.id, @course, grading_period: @first_period).compute_and_save_scores
          expect(scores[@first_period.id].current_score).to equal(95.13)
        end

        it "updates the overall course score" do
          GradeCalculator.new(@student.id, @course, grading_period: @first_period).compute_and_save_scores
          expect(overall_course_score.current_score).to equal(91.37)
        end

        it "does not update score statistics when calculating non-course scores" do
          calculator_options = { grading_period: @first_period, update_course_score: false }
          calculator = GradeCalculator.new(@student.id, @course, **calculator_options)
          expect(ScoreStatisticsGenerator).not_to receive(:update_score_statistics_in_singleton).with(@course)
          calculator.compute_and_save_scores
        end

        it "does not update scores for other grading periods" do
          calculator = GradeCalculator.new(@student.id, @course, grading_period: @first_period)
          expect { calculator.compute_and_save_scores }.not_to change {
            @student.enrollments.first.scores.find_by!(grading_period: @second_period)
          }
        end

        it "does not update the overall course score if update_course_score is false" do
          calculator_options = { grading_period: @first_period, update_course_score: false }
          calculator = GradeCalculator.new(@student.id, @course, **calculator_options)

          expect { calculator.compute_and_save_scores }.not_to change {
            @student.enrollments.first.scores.find_by!(course_score: true)
          }
        end

        it "does not restore previously deleted score if grading period is deleted too" do
          score = scores[@first_period.id]
          @first_period.destroy
          GradeCalculator.new(@student.id, @course, grading_period: @first_period).compute_and_save_scores
          expect(score.reload).to be_deleted
        end
      end

      context "when grading periods are weighted" do
        before do
          group = @first_period.grading_period_group
          group.update!(weighted: true)
          @ungraded_assignment = @course.assignments.create!(
            due_at: 1.day.from_now(@second_period.start_date),
            points_possible: 100 # these will be considered for final scores below
          )
        end

        it "calculates the course score from weighted grading period scores" do
          @first_period.update!(weight: 25.0)
          @second_period.update!(weight: 75.0)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          # GP1: 142.7 / 150 * 100 = 95.13
          # GP2: 131.4 / 150 * 100 = 87.60
          # Course: 95.13 * 0.25 + 87.60 * 0.75 = 89.48
          expect(overall_course_score.current_score).to equal(89.48)
          # GP1: (142.7 + 35) / 300 * 100 = 59.23
          # GP2: (131.4 + 42) / (300 + 100) * 100 = 43.35
          # Course: 59.23 * 0.25 + 43.35 * 0.75 = 47.32
          expect(overall_course_score.final_score).to equal(47.32)
        end

        it "up-scales grading period weights which add up to less than 100 percent" do
          @first_period.update!(weight: 25.0)
          @second_period.update!(weight: 50.0)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          # GP1: 142.7 / 150 * 100 = 95.13
          # GP2: 131.4 / 150 * 100 = 87.60
          # Course: (95.13 * 0.25 + 87.60 * 0.50) / (0.25 + 0.50) = 90.11
          expect(overall_course_score.current_score).to equal(90.11)
          # GP1: (142.7 + 35) / 300 * 100 = 59.23
          # GP2: (131.4 + 42) / (300 + 100) * 100 = 43.35
          # Course: (59.23 * 0.25 + 43.35 * 0.50) / (0.25 + 0.50) = 37.76
          expect(overall_course_score.final_score).to equal(48.64)
        end

        it "does not down-scale grading period weights which add up to greater than 100 percent" do
          @first_period.update!(weight: 100.0)
          @second_period.update!(weight: 50.0)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          # GP1: 142.7 / 150 * 100 = 95.13
          # GP2: 131.4 / 150 * 100 = 87.60
          # Course: 95.13 * 1.00 + 87.60 * 0.50 = 138.93
          expect(overall_course_score.current_score).to equal(138.93)
          # GP1: (142.7 + 35) / 300 * 100 = 59.23
          # GP2: (131.4 + 42) / (300 + 100) * 100 = 43.35
          # Course: 59.23 * 1.00 + 43.35 * 0.50 = 64.00
          expect(overall_course_score.final_score).to equal(80.91)
        end

        it "sets current course score to zero when all grading period weights are zero" do
          @first_period.update!(weight: 0)
          @second_period.update!(weight: 0)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.current_score).to equal(0.0)
        end

        it "sets final course score to zero when all grading period weights are zero" do
          @first_period.update!(weight: 0)
          @second_period.update!(weight: 0)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.final_score).to equal(0.0)
        end

        it "sets current course score to zero when all grading period weights are nil" do
          @first_period.update!(weight: nil)
          @second_period.update!(weight: nil)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.current_score).to equal(0.0)
        end

        it "sets current course score to zero when all grading period weights are nil or zero" do
          @first_period.update!(weight: 0.0)
          @second_period.update!(weight: nil)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.current_score).to equal(0.0)
        end

        it "sets final course score to zero when all grading period weights are nil" do
          @first_period.update!(weight: nil)
          @second_period.update!(weight: nil)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.final_score).to equal(0.0)
        end

        it "sets final course score to zero when all grading period weights are nil or zero" do
          @first_period.update!(weight: 0.0)
          @second_period.update!(weight: nil)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.final_score).to equal(0.0)
        end

        it "treats grading periods with nil weights as zero when some grading period " \
           "weights are nil and computing current score" do
          @first_period.update!(weight: nil)
          @second_period.update!(weight: 50.0)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.current_score).to equal(87.6)
        end

        it "treats grading periods with nil weights as zero when some grading period " \
           "weights are nil and computing final score" do
          @first_period.update!(weight: nil)
          @second_period.update!(weight: 50.0)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          # GP1: not considered
          # GP2: (131.4 + 42) / (300 + 100) * 100 = 43.35
          expect(overall_course_score.final_score).to equal(43.35)
        end

        it "sets current course score to nil when all grading period current scores are nil" do
          @first_period.update!(weight: 25.0)
          @second_period.update!(weight: 75.0)
          # update_all to avoid callbacks on submission that would trigger the grade calculator
          @student.submissions.update_all(score: nil)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.current_score).to be_nil
        end

        it "sets final course score to zero when all grading period final scores are nil" do
          @first_period.update!(weight: 25.0)
          @second_period.update!(weight: 75.0)
          # update_all to avoid callbacks on assignment that would trigger the grade calculator
          @course.assignments.update_all(omit_from_final_grade: true)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.final_score).to equal(0.0)
        end

        it "does not consider grading periods with nil current score when computing course current score" do
          @first_period.update!(weight: 25.0)
          @second_period.update!(weight: 75.0)
          # update_column to avoid callbacks on submission that would trigger the grade calculator
          Submission.where(user: @student, assignment: @assignments[0..2]).update_all(score: nil)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          # GP1: 0 / 150 * 100 = 0
          # GP2: 131.4 / 150 * 100 = 87.60
          # Course: (0 * 0 + 87.60 * 0.75) / (0 + 0.75) = 87.60
          expect(overall_course_score.current_score).to equal(87.60)
        end

        it "considers grading periods with nil final score as having zero score when computing course final score" do
          @first_period.update!(weight: 25.0)
          @second_period.update!(weight: 75.0)
          # update_column to avoid callbacks on assignment that would trigger the grade calculator
          Assignment.where(id: @assignments[0..2].map(&:id)).update_all(omit_from_final_grade: true)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          # GP1: 0
          # GP2: (131.4 + 42) / (300 + 100) * 100 = 43.35
          # Course: 43.35 * 0.75 = 32.51
          expect(overall_course_score.final_score).to equal(32.51)
        end

        it "sets course current score to zero when all grading period current scores are zero" do
          @first_period.update!(weight: 25.0)
          @second_period.update!(weight: 75.0)
          # update_all to avoid callbacks on submission that would trigger the grade calculator
          @student.submissions.update_all(score: 0.0)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.current_score).to equal(0.0)
        end

        it "sets course final score to zero when all grading period final scores are zero" do
          @first_period.update!(weight: 25.0)
          @second_period.update!(weight: 75.0)
          # update_all to avoid callbacks on submission that would trigger the grade calculator
          @student.submissions.update_all(score: 0.0)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.final_score).to equal(0.0)
        end

        it "sets course current score to nil when all grading period current scores are nil " \
           "and all grading period weights are nil" do
          @first_period.update!(weight: nil)
          @second_period.update!(weight: nil)
          # update_all to avoid callbacks on submission that would trigger the grade calculator
          @student.submissions.update_all(score: nil)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.current_score).to be_nil
        end

        it "sets course final score to zero when all grading period final scores are nil and all " \
           "grading period weights are nil" do
          @first_period.update!(weight: nil)
          @second_period.update!(weight: nil)
          # update_all to avoid callbacks on assignment that would trigger the grade calculator
          @course.assignments.update_all(omit_from_final_grade: true)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.final_score).to equal(0.0)
        end

        it "sets course current score to zero when all grading period current scores are zero " \
           "and all grading period weights are zero" do
          @first_period.update!(weight: 0.0)
          @second_period.update!(weight: 0.0)
          # update_all to avoid callbacks on submission that would trigger the grade calculator
          @student.submissions.update_all(score: 0.0)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.current_score).to equal(0.0)
        end

        it "sets course final score to zero when all grading period final scores are zero and " \
           "all grading period weights are zero" do
          @first_period.update!(weight: 0.0)
          @second_period.update!(weight: 0.0)
          # update_all to avoid callbacks on submission that would trigger the grade calculator
          @student.submissions.update_all(score: 0.0)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.final_score).to equal(0.0)
        end

        it "sets course current score to nil when all grading period current scores are nil and " \
           "all grading period weights are zero" do
          @first_period.update!(weight: 0.0)
          @second_period.update!(weight: 0.0)
          # update_all to avoid callbacks on submission that would trigger the grade calculator
          @student.submissions.update_all(score: nil)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.current_score).to be_nil
        end

        it "sets course final score to zero when all grading period final scores are nil and all " \
           "grading period weights are zero" do
          @first_period.update!(weight: 0.0)
          @second_period.update!(weight: 0.0)
          # update_all to avoid callbacks on assignment that would trigger the grade calculator
          @course.assignments.update_all(omit_from_final_grade: true)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.final_score).to equal(0.0)
        end

        it "sets course current score to zero when all grading period current scores are zero and " \
           "all grading period weights are nil" do
          @first_period.update!(weight: nil)
          @second_period.update!(weight: nil)
          # update_all to avoid callbacks on submission that would trigger the grade calculator
          @student.submissions.update_all(score: 0.0)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.current_score).to equal(0.0)
        end

        it "sets course final score to zero when all grading period final scores are zero and all " \
           "grading period weights are nil" do
          @first_period.update!(weight: nil)
          @second_period.update!(weight: nil)
          # update_all to avoid callbacks on submission that would trigger the grade calculator
          @student.submissions.update_all(score: 0.0)
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(overall_course_score.final_score).to equal(0.0)
        end
      end

      describe "assignment group scores" do
        let(:assignment_group_scores) do
          student_enrollment.scores.where.not(assignment_group_id: nil).order(assignment_group_id: :asc)
        end

        context "with the percent weighting scheme" do
          before do
            @course.update_column(:group_weighting_scheme, "percent")
            GradeCalculator.new(@student.id, @course).compute_and_save_scores
          end

          it "posted current assignment group scores are updated" do
            # [142.7 / 150, 131.4 / 150]
            expect(assignment_group_scores.map(&:current_score)).to eq([95.13, 87.60])
          end

          it "posted current assignment group points are updated" do
            # [142.7, 131.4]
            expect(assignment_group_scores.map(&:current_points)).to eq([142.70, 131.40])
          end

          it "posted final assignment group scores are updated" do
            # [(142.7 + 35.0) / 300, (131.4 + 42.0) / 300]
            expect(assignment_group_scores.map(&:final_score)).to eq([59.23, 57.8])
          end

          it "posted final assignment group points are updated" do
            # [35 + 142.7, 42 + 131.4]
            expect(assignment_group_scores.map(&:final_points)).to eq([177.70, 173.40])
          end

          it "unposted current assignment group scores are updated" do
            # [142.7 / 150, 131.4 / 150]
            expect(assignment_group_scores.map(&:unposted_current_score)).to eq([80.77, 75.47])
          end

          it "unposted current assignment group points are updated" do
            # 99.6 + 142.7 + 95.0 + 131.4
            expect(assignment_group_scores.map(&:unposted_current_points)).to eq([242.30, 226.40])
          end

          it "unposted final assignment group scores are updated" do
            # (99.6 + 142.7 + 95.0 + 131.4) / 600
            expect(assignment_group_scores.map(&:unposted_final_score)).to eq([80.77, 75.47])
          end

          it "unposted final assignment group points are updated" do
            # 99.6 + 142.7 + 95.0 + 131.4
            expect(assignment_group_scores.map(&:unposted_final_points)).to eq([242.30, 226.40])
          end
        end

        context "without a weighting scheme" do
          before do
            GradeCalculator.new(@student.id, @course).compute_and_save_scores
          end

          it "posted current assignment group scores are updated" do
            # [142.7 / 150, 131.4 / 150]
            expect(assignment_group_scores.map(&:current_score)).to eq([95.13, 87.60])
          end

          it "posted current assignment group points are updated" do
            # [142.7, 131.4]
            expect(assignment_group_scores.map(&:current_points)).to eq([142.70, 131.40])
          end

          it "posted final assignment group scores are updated" do
            # [(142.7 + 35) / 150, (131.4 + 42) / 150]
            expect(assignment_group_scores.map(&:final_score)).to eq([59.23, 57.80])
          end

          it "posted final assignment group points are updated" do
            # [35 + 142.7, 42 + 131.4]
            expect(assignment_group_scores.map(&:final_points)).to eq([177.70, 173.40])
          end

          it "unposted current assignment group scores are updated" do
            # [142.7 / 150, 131.4 / 150]
            expect(assignment_group_scores.map(&:unposted_current_score)).to eq([80.77, 75.47])
          end

          it "unposted current assignment group points are updated" do
            # 99.6 + 142.7 + 95.0 + 131.4
            expect(assignment_group_scores.map(&:unposted_current_points)).to eq([242.30, 226.40])
          end

          it "unposted final assignment group scores are updated" do
            # (99.6 + 142.7 + 95.0 + 131.4) / 600
            expect(assignment_group_scores.map(&:unposted_final_score)).to eq([80.77, 75.47])
          end

          it "unposted final assignment group points are updated" do
            # 99.6 + 142.7 + 95.0 + 131.4
            expect(assignment_group_scores.map(&:unposted_final_points)).to eq([242.30, 226.40])
          end
        end
      end
    end

    it "updates the overall course score metadata" do
      expected_metadata = {
        "current" => {
          "dropped" => dropped_current_submissions.map(&:id)
        },
        "final" => {
          # we dropped a muted submission, which won't be included here
          "dropped" => []
        }
      }
      metadata = overall_course_score.score_metadata
      orig_updated_at = metadata.updated_at
      GradeCalculator.new(@student.id, @course).compute_and_save_scores
      metadata.reload
      expect(metadata.calculation_details).to eq(expected_metadata)
      expect(orig_updated_at).to be < metadata.updated_at
    end

    it "updates the overall course score metadata when only_update_course_gp_metadata: true" do
      expected_metadata = {
        "current" => {
          "dropped" => dropped_current_submissions.map(&:id)
        },
        "final" => {
          # we dropped a muted submission, which won't be included here
          "dropped" => []
        }
      }
      metadata = overall_course_score.score_metadata
      orig_updated_at = metadata.updated_at
      GradeCalculator.new(@student.id, @course, only_update_course_gp_metadata: true).compute_and_save_scores
      metadata.reload
      expect(metadata.calculation_details).to eq(expected_metadata)
      expect(orig_updated_at).to be < metadata.updated_at
    end

    it "does not update the overall course score when only_update_course_gp_metadata: true" do
      updated_at = overall_course_score.updated_at
      GradeCalculator.new(@student.id, @course, only_update_course_gp_metadata: true).compute_and_save_scores
      overall_course_score.reload
      expect(overall_course_score.updated_at).to eq(updated_at)
    end

    context "when given only_update_points: true" do
      before do
        GradeCalculator.new(@student.id, @course).compute_and_save_scores
        initial_scores = Score.where(enrollment: @course.enrollments.find_by(user: @student)).order(id: :asc)
        updated_score_attributes = {
          current_points: nil,
          current_score: nil,
          final_points: nil,
          final_score: nil,
          unposted_current_points: nil,
          unposted_current_score: nil,
          unposted_final_points: nil,
          unposted_final_score: nil
        }
        initial_scores.update_all(updated_score_attributes)
        GradeCalculator.new(@student.id, @course, only_update_points: true).compute_and_save_scores
        @final_scores = Score.where(enrollment: @course.enrollments.find_by(user: @student)).order(id: :asc).to_a
      end

      it "updates current_points" do
        final_current_points = @final_scores.map(&:current_points)

        expect(final_current_points).to all(be_present)
      end

      it "updates unposted_current_points" do
        final_unposted_current_points = @final_scores.map(&:unposted_current_points)

        expect(final_unposted_current_points).to all(be_present)
      end

      it "updates final_points" do
        final_final_points = @final_scores.map(&:final_points)

        expect(final_final_points).to all(be_present)
      end

      it "updates unposted_final_points" do
        final_unposted_final_points = @final_scores.map(&:unposted_final_points)

        expect(final_unposted_final_points).to all(be_present)
      end

      it "updates current_score" do
        final_current_score = @final_scores.map(&:current_score)

        expect(final_current_score).to all(be_nil)
      end

      it "updates unposted_current_score" do
        final_unposted_current_score = @final_scores.map(&:unposted_current_score)

        expect(final_unposted_current_score).to all(be_nil)
      end

      it "updates final_score" do
        final_final_score = @final_scores.map(&:final_score)

        expect(final_final_score).to all(be_nil)
      end

      it "updates unposted_final_score" do
        final_unposted_final_score = @final_scores.map(&:unposted_final_score)

        expect(final_unposted_final_score).to all(be_nil)
      end
    end

    it "restores and updates previously deleted scores" do
      overall_course_score.destroy
      GradeCalculator.new(@student.id, @course).compute_and_save_scores
      expect(overall_course_score.reload).to be_active
    end

    it "updates root_account_id on existing scores if they do not have a root_account_id set" do
      overall_course_score.update_column(:root_account_id, nil)
      expect do
        GradeCalculator.new(@student.id, @course).compute_and_save_scores
      end.to change {
        overall_course_score.reload.root_account_id
      }.from(nil).to(@course.root_account_id)
    end

    it "sets root_account_id when inserting new scores" do
      overall_course_score.destroy_permanently!
      GradeCalculator.new(@student.id, @course).compute_and_save_scores
      inserted_score = @student.enrollments.first.scores.find_by(course_score: true)
      expect(inserted_score.root_account_id).to eq @course.root_account_id
    end

    context("assignment group scores") do
      before do
        @group1 = @course.assignment_groups.create!(name: "some group 1")
        @assignment1 = @course.assignments.create!(name: "assignment 1", points_possible: 20, assignment_group: @group1)
        @assignment1.grade_student(@student, grade: 12, grader: @teacher)
        @group2 = @course.assignment_groups.create!(name: "some group 2")
        @assignment2 = @course.assignments.create!(name: "assignment 2", points_possible: 20, assignment_group: @group2)
        @assignment2.grade_student(@student, grade: 18, grader: @teacher)
        GradeCalculator.new(@student.id, @course).compute_and_save_scores
      end

      let(:student_scores) { @student.enrollments.first.scores }

      it "stores separate assignment group scores for each of a student’s enrollments" do
        (1..2).each do |i|
          section = @course.course_sections.create!(name: "section #{i}")
          @course.enroll_user(@student,
                              "StudentEnrollment",
                              section:,
                              enrollment_state: "active",
                              allow_multiple_enrollments: true)
        end
        GradeCalculator.new(@student.id, @course).compute_and_save_scores
        scored_enrollment_ids = Score.where(assignment_group_id: @group1.id).map(&:enrollment_id)
        expect(scored_enrollment_ids).to contain_exactly(*@student.enrollments.map(&:id))
      end

      it "creates a course score for the student if one does not exist, but assignment group scores exist" do
        student_enrollment = @course.student_enrollments.find_by(user_id: @student)
        student_enrollment.find_score(course_score: true).destroy_permanently!
        GradeCalculator.new(@student.id, @course).compute_and_save_scores
        expect(student_enrollment.find_score(course_score: true)).to be_present
      end

      it "updates active score rows for assignment groups if they already exist" do
        orig_score_id = student_scores.first.id
        @assignment1.grade_student(@student, grade: 15, grader: @teacher)
        GradeCalculator.new(@student.id, @course).compute_and_save_scores
        new_score_id = student_scores.first.id
        expect(orig_score_id).to be new_score_id
      end

      it "updates root_account_id on existing scores if they do not have a root_account_id set" do
        score = student_scores.first
        score.update_column(:root_account_id, nil)
        expect do
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
        end.to change { score.reload.root_account_id }.from(nil).to(@course.root_account_id)
      end

      it "activates previously soft deleted assignment group scores when updating them" do
        student_scores.update_all(workflow_state: "deleted")
        GradeCalculator.new(@student.id, @course).compute_and_save_scores
        expect(student_scores.map(&:workflow_state).uniq).to contain_exactly("active")
      end

      context "assignment group score creation" do
        before do
          @group = @course.assignment_groups.create!(name: "yet another group")
          @group.scores.each(&:destroy_permanently!)
          @group.reload
        end

        it "inserts score rows for assignment groups unless they already exist" do
          expect do
            GradeCalculator.new(@student.id, @course).compute_and_save_scores
          end.to change { Score.where(assignment_group: @group).count }.from(0).to(1)
        end

        it "assigns a root_account_id to the inserted assignment group score" do
          GradeCalculator.new(@student.id, @course).compute_and_save_scores
          expect(@group.scores.first.root_account_id).to eq @course.root_account_id
        end
      end
    end
  end

  it "returns grades in the order they are requested" do
    @student1 = @student
    student_in_course
    @student2 = @student

    a = @course.assignments.create! points_possible: 100
    a.grade_student @student1, grade: 50, grader: @teacher
    a.grade_student @student2, grade: 100, grader: @teacher

    calc = GradeCalculator.new([@student2.id, @student1.id], @course)
    grades = calc.compute_scores

    expect(grades.first[:current][:grade]).to equal 100.0
    expect(grades.first[:final][:grade]).to equal 100.0
    expect(grades.last[:current][:grade]).to equal 50.0
    expect(grades.last[:final][:grade]).to equal 50.0
  end

  it "returns point information for unweighted courses" do
    a = @course.assignments.create! points_possible: 50
    a.grade_student @student, grade: 25, grader: @teacher
    calc = GradeCalculator.new([@student.id], @course)
    grade_info = calc.compute_scores.first[:current]
    expect(grade_info).to eq({ grade: 50, total: 25, possible: 50, dropped: [] })
  end

  context "error trapping" do
    let(:calc) { GradeCalculator.new([@student.id], @course) }

    context "deadlocks" do
      it ".save_assignment_group_scores raises Delayed::RetriableError when deadlocked" do
        allow(Score.connection).to receive(:execute).and_raise(ActiveRecord::Deadlocked)

        expect { calc.send(:save_assignment_group_scores, [], []) }.to raise_error(Delayed::RetriableError)
      end

      it ".save_course_and_grading_period_scores raises Delayed::RetriableError when deadlocked" do
        allow(Score.connection).to receive(:execute).and_raise(ActiveRecord::Deadlocked)

        expect { calc.send(:save_course_and_grading_period_scores) }.to raise_error(Delayed::RetriableError)
      end
    end
  end
end
