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

  # We should keep this in sync with GradeCalculatorSpec.js
  context "GradeCalculatorSpec.js examples" do
    before do
      @group = @group1 = @course.assignment_groups.create!(name: "group 1")
    end

    def set_default_grades
      set_grades [[100, 100], [42, 91], [14, 55], [3, 38], [nil, 1000]]
    end

    def set_grades(grades, group = @group1)
      @grades = grades
      @assignments = @grades.map do |_score, possible|
        @course.assignments.create! title: "homework",
                                    points_possible: possible,
                                    assignment_group: group
      end
      @assignments.each_with_index do |a, i|
        score = @grades[i].first
        next unless score # don't grade nil submissions

        a.grade_student @student, grade: score, grader: @teacher
      end

      # This set of tests expects all submissions to be posted to the student
      # (in the pre-post-policies world these assignments were all unmuted),
      # even if we didn't issue a grade. Set them to posted but don't trigger a
      # grade calculation.
      Submission.where(user: @student).update_all(posted_at: Time.zone.now)
    end

    def check_grades(current, final, check_current: true, check_final: true)
      GradeCalculator.recompute_final_score(@student.id, @course.id)
      @enrollment.reload

      if check_current
        expect(@enrollment.computed_current_score).to be_nil if current.nil?
        expect(@enrollment.computed_current_score).to equal current unless current.nil?
      end

      if check_final
        expect(@enrollment.computed_final_score).to be_nil if final.nil?
        expect(@enrollment.computed_final_score).to equal final unless final.nil?
      end
    end

    def check_current_grade(current)
      check_grades(current, nil, check_current: true, check_final: false)
    end

    def check_final_grade(final)
      check_grades(nil, final, check_current: false, check_final: true)
    end

    it "works without assignments or submissions" do
      @group.assignments.clear
      check_grades(nil, nil)
    end

    it "works without submissions" do
      @course.assignments.create! title: "asdf",
                                  points_possible: 1,
                                  assignment_group: @group
      check_grades(nil, 0.0)
    end

    it "works with submissions that have 0 points possible" do
      set_grades [[10, 0], [10, 10], [10, 10], [nil, 10]]
      check_grades(150.0, 100.0)

      @group.update_attribute(:rules, "drop_lowest:1")
      check_grades(200.0, 150.0)
    end

    it "muted assignments are not considered for the drop list when computing " \
       "current grade for students (they are just excluded from the computation entirely)" do
      set_grades([[4, 10], [3, 10], [9, 10]])
      @group.update_attribute(:rules, "drop_lowest:1")
      @assignments.first.mute!
      # 4/10 is excluded from the computation because it's muted
      # 3/10 is dropped for being the lowest
      # 9/10 is included
      # 9/10 => 90.0%
      check_current_grade(90.0)
    end

    it "ungraded assignments are not considered for the drop list when computing " \
       "current grade for students (they are just excluded from the computation entirely)" do
      set_grades([[nil, 20], [3, 10], [9, 10]])
      @group.update_attribute(:rules, "drop_lowest:1")
      # nil/20 is excluded from the computation because it's not graded
      # 3/10 is dropped for being the lowest
      # 9/10 is included
      # 9/10 => 90.0%
      check_current_grade(90.0)
    end

    it "ungraded + muted assignments are not considered for the drop list when " \
       "computing current grade for students (they are just excluded from the computation entirely)" do
      set_grades([[nil, 20], [4, 10], [3, 10], [9, 10]])
      @group.update_attribute(:rules, "drop_lowest:1")
      @assignments.second.mute!
      # nil/20 is excluded from the computation because it's not graded
      # 4/10 is exclued from the computation because it's muted
      # 3/10 is dropped for being the lowest
      # 9/10 is included
      # 9/10 => 90.0%
      check_current_grade(90.0)
    end

    it "muted assignments are treated as 0/points_possible for the drop list when " \
       "computing final grade for students" do
      set_grades([[4, 10], [3, 10], [9, 10]])
      @group.update_attribute(:rules, "drop_lowest:1")
      @assignments.first.mute!
      # 4/10 is treated as 0/10 because it is muted. Since it's treated as 0/10,
      # it is dropped for being the lowest
      # 3/10 is included
      # 9/10 is included
      # 12/20 => 60.0%
      check_final_grade(60.0)
    end

    it "ungraded assignments are treated as 0/points_possible for the drop list " \
       "when computing final grade for students" do
      set_grades([[nil, 20], [3, 10], [9, 10]])
      @group.update_attribute(:rules, "drop_lowest:1")
      # nil/20 is treated as 0/20 because it's not graded
      # 3/10 is included
      # 9/10 is included
      # 12/20 => 60.0%
      check_final_grade(60.0)
    end

    it "ungraded are treated as 0/points_possible for the drop list and muted " \
       "assignments are ignored for the drop list when computing final grade for students" do
      set_grades([[nil, 20], [4, 10], [3, 10], [9, 10]])
      @group.update_attribute(:rules, "drop_lowest:1")
      @assignments.second.mute!
      # nil/20 is treated as 0/20 because it's not graded. it is dropped.
      # 4/10 is ignored for drop rules because it is muted. it is included.
      # 3/10 is included
      # 9/10 is included
      # (4/10 is treated as 0/10 because it is muted) + 3/10 + 9/10 = 12/30 => 40.0%
      check_final_grade(40.0)
    end

    it '"work"s when no submissions have points possible' do
      set_grades [[10, 0], [5, 0], [20, 0], [0, 0]]
      @group.update_attribute(:rules, "drop_lowest:1")
      check_grades(nil, nil)
    end

    it "works with no drop rules" do
      set_default_grades
      check_grades(55.99, 12.38)
    end

    it "supports drop_lowest" do
      set_default_grades
      @group.update_attribute(:rules, "drop_lowest:1")
      check_grades(63.41, 55.99)

      @group.update_attribute(:rules, "drop_lowest:2")
      check_grades(74.64, 63.41)
    end

    it "really supports drop_lowest" do
      set_grades [[30, nil],
                  [30, nil],
                  [30, nil],
                  [31, 31],
                  [21, 21],
                  [30, 30],
                  [30, 30],
                  [30, 30],
                  [30, 30],
                  [30, 30],
                  [30, 30],
                  [30, 30],
                  [30, 30],
                  [30, 30],
                  [30, 30],
                  [29.3, 30],
                  [30, 30],
                  [30, 30],
                  [30, 30],
                  [12, 0],
                  [30, nil]]
      @group.update_attribute(:rules, "drop_lowest:2")
      check_grades(132.12, 132.12)
    end

    it "supports drop_highest" do
      set_default_grades
      @group.update_attribute(:rules, "drop_highest:1")
      check_grades(32.07, 4.98)

      @group.update_attribute(:rules, "drop_highest:2")
      check_grades(18.28, 1.56)

      @group.update_attribute(:rules, "drop_highest:3")
      check_grades(7.89, 0.29)
    end

    it "really supports drop_highest" do
      grades = [[0, 10], [10, 20], [28, 50], [91, 100]]
      set_grades(grades)

      @group.update_attribute(:rules, "drop_highest:1")
      check_grades(47.5, 47.5)

      @group.update_attribute(:rules, "drop_highest:2")
      check_grades(33.33, 33.33)

      @group.update_attribute(:rules, "drop_highest:3")
      check_grades(0.0, 0.0)
    end

    it "works with unreasonable drop rules" do
      set_grades([[10, 10], [9, 10], [8, 10]])
      @group.update_attribute :rules, "drop_lowest:1000\ndrop_highest:1000"
      check_grades(100.0, 100.0)
    end

    it "works with drop rules that result in only unpointed assignments going to the drop lowest phase" do
      set_grades([[9, 0], [10, 0], [2, 2]])
      @group.update_attribute :rules, "drop_lowest:1\ndrop_highest:1"
      check_grades(nil, nil)
    end

    describe "support for never_drop" do
      it "supports never_drop (1)" do
        set_default_grades
        rules = "drop_lowest:1\nnever_drop:#{@assignments[3].id}" # 3/38
        @group.update_attribute(:rules, rules)
        check_grades(63.32, 55.99)
      end

      it "supports never_drop (2)" do
        set_grades [[10, 20], [5, 10], [20, 40], [0, 100]]
        rules = "drop_lowest:1\nnever_drop:#{@assignments[3].id}" # 0/100
        @group.update_attribute(:rules, rules)
        check_grades(18.75, 18.75)
      end

      it "supports never_drop (3)" do
        set_grades [[10, 20], [5, 10], [20, 40], [100, 100]]
        rules = "drop_lowest:1\nnever_drop:#{@assignments[3].id}" # 100/100
        @group.update_attribute(:rules, rules)
        check_grades(88.46, 88.46)
      end

      it "supports never_drop (4)" do
        set_grades [[101.9, 100], [105.65, 100], [103.8, 100], [0, 0]]
        rules = "drop_lowest:1\nnever_drop:#{@assignments[2].id}" # 103.8/100
        @group.update_attribute(:rules, rules)
        check_grades(104.73, 104.73)
      end
    end

    it "grade dropping should work even in ridiculous circumstances" do
      set_grades [[nil, 20],
                  [3, 10],
                  [nil, 10],
                  [nil, 999_999_999],
                  [nil, nil]]

      @group.update_attribute(:rules, "drop_lowest:2")
      check_grades(30.0, 15.0)
    end

    context "assignment groups with 0 points possible" do
      before do
        @group1.group_weight = 50
        @group1.save!
        @group2 = @course.assignment_groups.create! name: "group 2",
                                                    group_weight: 25
        @group3 = @course.assignment_groups.create! name: "empty group",
                                                    group_weight: 25
        @group4 = @course.assignment_groups.create! name: "extra credit",
                                                    group_weight: 10

        set_grades [[9, 10]], @group1
        set_grades [[5, 10]], @group2
        # @group3 is emtpy
        set_grades [[10, 0], [5, 0]], @group3
      end

      it "ignores them if the group_weighting_scheme is percent" do
        # NOTE: in addition to ignoring invalid assignment groups, we also
        # have to scale up the valid ones
        @course.update_attribute :group_weighting_scheme, "percent"
        grade = 76.67 # ((9/10)*50 + (5/10)*25) * (1/75)
        check_grades(grade, grade)
      end

      it "doesn't ignore them if the group_weighting_scheme is equal" do
        @course.update_attribute :group_weighting_scheme, "equal"
        grade = 145.0 # ((9 + 5 + 10 + 5) / (10 + 10)) * 100
        check_grades(grade, grade)
      end
    end

    context "grading periods" do
      before do
        student_in_course active_all: true
        @gp1, @gp2 = grading_periods count: 2
        @a1, @a2 = [@gp1, @gp2].map do |gp|
          @course.assignments.create! due_at: 1.minute.from_now(gp.start_date),
                                      points_possible: 100
        end
        @a1.grade_student(@student, grade: 25, grader: @teacher)
        @a2.grade_student(@student, grade: 75, grader: @teacher)
      end

      it "can compute grades for a grading period" do
        gc = GradeCalculator.new([@student.id], @course, grading_period: @gp1)
        current = gc.compute_scores.first[:current]
        expect(current[:grade]).to equal 25.0

        gc = GradeCalculator.new([@student.id], @course, grading_period: @gp2)
        current = gc.compute_scores.first[:current]
        expect(current[:grade]).to equal 75.0
      end
    end

    context "differentiated assignments grade calculation" do
      def set_up_course_for_differentiated_assignments
        set_grades [[5, 20], [15, 20], [10, 20], [nil, 20], [20, 20], [10, 20], [nil, 20]]
        @assignments.each do |a|
          a.only_visible_to_overrides = true
          a.save!
        end
        @overridden_lowest = @assignments[0]
        @overridden_highest = @assignments[1]
        @overridden_middle = @assignments[2]
        @non_overridden_lowest = @assignments[3]
        @non_overridden_highest = @assignments[4]
        @non_overridden_middle = @assignments[5]
        @not_graded = @assignments.last

        @user.enrollments.each(&:destroy)
        @section = @course.course_sections.create!(name: "test section")
        student_in_section(@section, user: @user)

        create_section_override_for_assignment(@overridden_lowest, course_section: @section)
        create_section_override_for_assignment(@overridden_highest, course_section: @section)
        create_section_override_for_assignment(@overridden_middle, course_section: @section)
      end

      def final_grade_info(user, course)
        GradeCalculator.new([user.id], course.id).compute_scores.first[:final]
      end

      def find_submission(assignment)
        assignment.submissions.where(user_id: @user.id).first.id
      end

      context "DA" do
        before do
          set_up_course_for_differentiated_assignments
        end

        it "calculates scores based on visible assignments only" do
          # Non-overridden assignments are not visible to this student at all even though she's been graded on them
          # because the assignment is only visible to overrides. Therefore only the (first three) overridden assignments
          # ever count towards her final grade in all these specs
          # 5 + 15 + 10
          expect(final_grade_info(@user, @course)[:total]).to equal 30.0
          expect(final_grade_info(@user, @course)[:possible]).to equal 60.0
        end

        it "drops the lowest visible when that rule is in place" do
          @group.update_attribute(:rules, "drop_lowest:1")
          # 5 + 15 + 10 - 5
          expect(final_grade_info(@user, @course)[:total]).to equal 25.0
          expect(final_grade_info(@user, @course)[:possible]).to equal 40.0
          expect(final_grade_info(@user, @course)[:dropped]).to eq [find_submission(@overridden_lowest)]
        end

        it "drops the highest visible when that rule is in place" do
          @group.update_attribute(:rules, "drop_highest:1")
          # 5 + 15 + 10 - 15
          expect(final_grade_info(@user, @course)[:total]).to equal 15.0
          expect(final_grade_info(@user, @course)[:possible]).to equal 40.0
          expect(final_grade_info(@user, @course)[:dropped]).to eq [find_submission(@overridden_highest)]
        end

        it "does not count an invisible assignment with never drop on" do
          @group.update_attribute(:rules, "drop_lowest:2\nnever_drop:#{@overridden_lowest.id}")
          # 5 + 15 + 10 - 10
          expect(final_grade_info(@user, @course)[:total]).to equal 20.0
          expect(final_grade_info(@user, @course)[:possible]).to equal 40.0
          expect(final_grade_info(@user, @course)[:dropped]).to eq [find_submission(@overridden_middle)]
        end

        it "saves scores for all assignment group and enrollment combinations" do
          @group.update_attribute(:rules, "drop_lowest:2\nnever_drop:#{@overridden_lowest.id}")
          user_ids = @course.enrollments.map(&:user_id).uniq
          group_ids = @assignments.map(&:assignment_group_id).uniq
          GradeCalculator.new(user_ids, @course.id).compute_and_save_scores
          expect(Score.where(assignment_group_id: group_ids).count).to eq @course.enrollments.count * group_ids.length
          expect(ScoreMetadata.where(score_id: Score.where(assignment_group_id: group_ids)).count).to eq 2
        end

        it "saves dropped submission to group score metadata" do
          @group.update_attribute(:rules, "drop_lowest:2\nnever_drop:#{@overridden_lowest.id}")
          GradeCalculator.new(@user.id, @course.id).compute_and_save_scores
          enrollment = Enrollment.find_by(user_id: @user.id, course_id: @course.id)
          score = enrollment.find_score(assignment_group: @group)
          expect(score.score_metadata.calculation_details).to eq({
                                                                   "current" => { "dropped" => [find_submission(@overridden_middle)] },
                                                                   "final" => { "dropped" => [find_submission(@overridden_middle)] }
                                                                 })
        end

        it "does not include muted assignments in the dropped submission list in group score metadata" do
          @group.update_attribute(:rules, "drop_lowest:2\nnever_drop:#{@overridden_lowest.id}")
          @overridden_middle.mute!
          GradeCalculator.new(@user.id, @course.id).compute_and_save_scores
          enrollment = Enrollment.where(user_id: @user.id, course_id: @course.id).first
          score = enrollment.find_score(assignment_group: @group)
          expect(score.score_metadata.calculation_details).to eq({
                                                                   "current" => { "dropped" => [] },
                                                                   "final" => { "dropped" => [] }
                                                                 })
        end

        it "saves dropped submissions to course score metadata" do
          @group.update_attribute(:rules, "drop_lowest:2\nnever_drop:#{@overridden_lowest.id}")
          GradeCalculator.new(@user.id, @course.id).compute_and_save_scores
          enrollment = Enrollment.where(user_id: @user.id, course_id: @course.id).first
          score = enrollment.find_score(course_score: true)
          expect(score.score_metadata.calculation_details).to eq({
                                                                   "current" => { "dropped" => [find_submission(@overridden_middle)] },
                                                                   "final" => { "dropped" => [find_submission(@overridden_middle)] }
                                                                 })
        end

        it "does not include muted assignments in the dropped submission list in course score metadata" do
          @group.update_attribute(:rules, "drop_lowest:2\nnever_drop:#{@overridden_lowest.id}")
          @overridden_middle.mute!
          GradeCalculator.new(@user.id, @course.id).compute_and_save_scores
          enrollment = Enrollment.where(user_id: @user.id, course_id: @course.id).first
          score = enrollment.find_score(course_score: true)
          expect(score.score_metadata.calculation_details).to eq({
                                                                   "current" => { "dropped" => [] },
                                                                   "final" => { "dropped" => [] }
                                                                 })
        end

        it "updates existing course score metadata" do
          @group.update_attribute(:rules, "drop_lowest:2\nnever_drop:#{@overridden_lowest.id}")
          GradeCalculator.new(@user.id, @course.id).compute_and_save_scores
          enrollment = Enrollment.where(user_id: @user.id, course_id: @course.id).first
          score = enrollment.find_score(course_score: true)
          metadata = score.score_metadata

          @group.update_attribute(:rules, "drop_highest:1")
          expect { GradeCalculator.new(@user.id, @course.id).compute_and_save_scores }.not_to change { ScoreMetadata.count }
          metadata.reload
          expect(metadata.calculation_details).to eq({
                                                       "current" => { "dropped" => [find_submission(@overridden_highest)] },
                                                       "final" => { "dropped" => [find_submission(@overridden_highest)] }
                                                     })
        end
      end
    end

    context "excused assignments" do
      before do
        student_in_course(active_all: true)
        @a1 = @course.assignments.create! points_possible: 10
        @a2 = @course.assignments.create! points_possible: 90
      end

      it "works" do
        enrollment = @student.enrollments.first
        @a1.grade_student(@student, grade: 10, grader: @teacher)
        expect(enrollment.reload.computed_final_score).to equal(10.0)

        @a2.grade_student(@student, excuse: 1, grader: @teacher)
        expect(enrollment.reload.computed_final_score).to equal(100.0)
      end
    end
  end
end
