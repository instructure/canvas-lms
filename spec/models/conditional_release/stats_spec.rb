# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
require_relative "../../conditional_release_spec_helper"

module ConditionalRelease
  describe Stats do
    before :once do
      @course = course_factory(active_all: true)
      @students = n_students_in_course(4, course: @course)
      @rule = create(:rule, course: @course)
      @sr1 = create(:scoring_range_with_assignments, rule: @rule, upper_bound: nil, lower_bound: 0.7, assignment_set_count: 2, assignment_count: 5)
      @sr2 = create(:scoring_range_with_assignments, rule: @rule, upper_bound: 0.7, lower_bound: 0.4, assignment_set_count: 2, assignment_count: 5)
      @sr3 = create(:scoring_range_with_assignments, rule: @rule, upper_bound: 0.4, lower_bound: nil, assignment_set_count: 2, assignment_count: 5)
      @as1 = @sr1.assignment_sets.first
      @as2 = @sr2.assignment_sets.first

      @trigger = @rule.trigger_assignment
      @a1, @a2, @a3, @a4, @a5 = @as1.assignment_set_associations.to_a.map(&:assignment)
      @b1, @b2, @b3, @b4, @b5 = @as2.assignment_set_associations.to_a.map(&:assignment)
    end

    def expected_assignment_set(user_ids, assignment_set)
      user_ids.each do |id|
        AssignmentSetAction.create_from_sets(assignment_set, [], student_id: id, action: "assign", source: "select_assignment_set")
      end
    end

    describe "students_per_range" do
      # turning the student ids from 1, 2, 3, etc to real user ids
      def get_student(idx)
        @students[idx - 1]
      end

      def get_student_ids(indexes)
        indexes.map { |idx| get_student(idx).id }
      end

      # admittedly this is terrible but rewriting every spec would be too so just stuff the formerly "mock" data into the db
      def set_user_submissions(user_idx, user_name, submissions)
        student = get_student(user_idx)
        student.update_attribute(:short_name, user_name)
        submissions.map do |data|
          assignment, score, points_possible = data
          Assignment.where(id: assignment).update_all(points_possible:)
          Submission.where(assignment_id: assignment, user_id: student).update_all(score:)
        end
      end

      def set_trigger_submissions
        set_user_submissions(1, "foo", [[@trigger, 10, 100]])
        set_user_submissions(2, "bar", [[@trigger, 20, 100]])
        set_user_submissions(3, "baz", [[@trigger, 50, 100]])
        set_user_submissions(4, "bat", [])
      end

      it "sums up assignments" do
        set_trigger_submissions
        rollup = Stats.students_per_range(@rule, false).with_indifferent_access
        expect(rollup[:enrolled]).to eq 4
        expect(rollup[:ranges][0][:size]).to eq 0
        expect(rollup[:ranges][1][:size]).to eq 1
        expect(rollup[:ranges][2][:size]).to eq 2
        expect(rollup[:ranges][2][:students].map { |s| s[:user][:id] }).to match_array get_student_ids([1, 2])
      end

      it "does not include trend data" do
        set_trigger_submissions
        rollup = Stats.students_per_range(@rule, false).with_indifferent_access
        expect(rollup.dig(:ranges, 2, :students, 0)).not_to have_key "trend"
      end

      it "treats 0 points possible as /100" do
        set_trigger_submissions
        @trigger.update_attribute(:points_possible, 0)

        rollup = Stats.students_per_range(@rule, false).with_indifferent_access
        expect(rollup[:enrolled]).to eq 4
        expect(rollup[:ranges][0][:size]).to eq 0
        expect(rollup[:ranges][1][:size]).to eq 1
        expect(rollup[:ranges][2][:size]).to eq 2
      end

      context "with trend data" do
        let(:trends) { @rollup.dig(:ranges, 0, :students).pluck(:trend) }

        it "has trend == nil if no follow on assignments have been completed" do
          set_user_submissions(1, "foo", [[@trigger, 32, 40]])
          rollup = Stats.students_per_range(@rule, true).with_indifferent_access
          expect(rollup.dig(:ranges, 0, :students, 0)).to have_key "trend"
          expect(rollup.dig(:ranges, 0, :students, 0, :trend)).to be_nil
        end

        it "returns the correct trend for a single follow on assignment" do
          set_user_submissions(1, "foo", [[@trigger, 30, 40], [@a1, 4, 4]])
          set_user_submissions(2, "bar", [[@trigger, 30, 40], [@a1, 3, 4]])
          set_user_submissions(3, "baz", [[@trigger, 30, 40], [@a1, 2, 4]])

          expected_assignment_set(get_student_ids([1, 2, 3]), @as1)

          @rollup = Stats.students_per_range(@rule, true).with_indifferent_access
          expect(trends).to eq [1, 0, -1]
        end

        it "averages the follow on assignments based on percent" do
          set_user_submissions(1, "foo", [[@trigger, 8, 10], [@a1, 3500, 5000], [@a2, 5, 5]])
          set_user_submissions(2, "bar", [[@trigger, 9, 10], [@a1, 5000, 5000], [@a2, 4, 5]])

          expected_assignment_set(get_student_ids([1, 2]), @as1)

          @rollup = Stats.students_per_range(@rule, true).with_indifferent_access
          expect(trends).to eq [1, 0]
        end

        it "averages over a large number of assignments" do
          set_user_submissions(1, "foo", [[@trigger, 8, 10], [@a1, 3900, 5000], [@a2, 5, 5], [@a3, 9, 10], [@a4, 12, 1000], [@a5, 3.2, 3]])
          expected_assignment_set(get_student_ids([1]), @as1)

          @rollup = Stats.students_per_range(@rule, true).with_indifferent_access
          expect(trends).to eq [-1]
        end

        it "ignores assignments outside of assigned set" do
          set_user_submissions(1, "foo", [[@trigger, 80, 100], [@a1, 75, 100], [@b1, 5, 5], [@b2, 10, 10], [@b3, 1000, 1000], [@b4, 3, 3]])
          expected_assignment_set(get_student_ids([1]), @as1)

          @rollup = Stats.students_per_range(@rule, true).with_indifferent_access
          expect(trends).to eq [-1]
        end
      end
    end

    describe "student_details" do
      before :once do
        @student_id = @students.first.id
      end

      def set_assignments(points_possible_per_id = nil)
        ids = [@trigger.id] + @rule.assignment_set_associations.pluck(:assignment_id)
        ids.each do |id|
          points_possible = 100
          points_possible = points_possible_per_id[id] if points_possible_per_id
          Assignment.where(id:).update_all(title: "assn #{id}", points_possible:)
        end
      end

      def set_submissions(submissions)
        submissions.map do |data|
          assignment, score, points_possible = data
          Assignment.where(id: assignment).update_all(points_possible:)
          Submission.where(assignment_id: assignment, user_id: @student_id).update_all(score:)
        end
      end

      it "includes assignments from the correct scoring range" do
        set_assignments
        set_submissions [[@trigger, 90, 100], [@a3, 80, 100], [@b1, 45, 100]]
        expected_assignment_set([@student_id], @as1)

        details = Stats.student_details(@rule, @student_id).with_indifferent_access
        expect(details.dig(:trigger_assignment, :score)).to eq 0.9
        expect(details[:follow_on_assignments].map { |f| f[:assignment][:id] }).to match_array [@a1, @a2, @a3, @a4, @a5].map(&:id)
        expect(details[:follow_on_assignments].pluck(:score)).to match_array [nil, nil, 0.8, nil, nil]
      end

      it "matches assignment info and submission info" do
        set_assignments
        set_submissions [[@trigger, 50, 100], [@b1, 3, 100], [@b2, 88, 100], [@b4, 93, 100]]
        expected_assignment_set([@student_id], @as2)

        details = Stats.student_details(@rule, @student_id).with_indifferent_access
        details_by_id = details[:follow_on_assignments].index_by { |f| f.dig(:assignment, :id) }
        expect(details_by_id.map { |k, v| [k, v.dig(:submission, :score)] }).to match_array [
          [@b1.id, 3], [@b2.id, 88], [@b3.id, nil], [@b4.id, 93], [@b5.id, nil]
        ]
      end

      it "includes score and trend data" do
        set_assignments
        set_submissions [[@trigger, 50, 100], [@b1, 3, 5], [@b2, 1, 20], [@b4, 0, 0]]
        expected_assignment_set([@student_id], @as2)

        details = Stats.student_details(@rule, @student_id).with_indifferent_access
        details[:follow_on_assignments].each do |detail|
          expect(detail).to have_key :score
          expect(detail).to have_key :trend
        end
      end

      it "includes course_id for trigger_assignment" do
        set_assignments
        set_submissions [[@trigger, 50, 100]]
        expected_assignment_set([@student_id], @as1)

        details = Stats.student_details(@rule, @student_id).with_indifferent_access
        expect(details.dig(:trigger_assignment, :assignment, :course_id)).to eq @course.id
      end

      it "does not crash if you try to get student details for a student who is not assigned to the trigger assignment" do
        student1, student2 = @students.first(2)
        set_assignments
        @trigger.update!(only_visible_to_overrides: true)
        override = @trigger.assignment_overrides.create!(set_type: "ADHOC")
        override.assignment_override_students.create!(user: student1)
        set_submissions [[@trigger, 50, 100]]

        details = Stats.student_details(@rule, student2).with_indifferent_access
        expect(details.dig(:trigger_assignment, :submission)).to be_nil
      end

      context "trends per assignment" do
        before do
          @rule.scoring_ranges.destroy_all
          @sr = create(:scoring_range_with_assignments, assignment_count: 1, rule: @rule, upper_bound: nil, lower_bound: 0)
          @trigger = @rule.trigger_assignment
          @follow_on = @sr.assignment_set_associations.first.assignment
        end

        def check_trend(orig_score, orig_points_possible, new_score, new_points_possible, expected_trend)
          set_assignments({ @trigger => orig_points_possible, @follow_on => new_points_possible })
          set_submissions [[@trigger, orig_score, orig_points_possible], [@follow_on, new_score, new_points_possible]]
          expected_assignment_set([@student_id], @sr.assignment_sets.first)
          details = Stats.student_details(@rule, @student_id).with_indifferent_access
          trend = details.dig(:follow_on_assignments, 0, :trend)
          expect(trend).to eq(expected_trend), "expected #{orig_score}/#{orig_points_possible}:#{new_score}/#{new_points_possible} => #{expected_trend}, got #{trend}"
        end

        it "trends upward if new percentage at least 3 % points higher of base percentage" do
          check_trend(100, 100, 103, 100, 1)
          check_trend(7, 35, 23, 100, 1)
          check_trend(1, 2, 528, 995, 1)
        end

        it "trends downward if score at least 3 % points lower than base score" do
          check_trend(100, 100, 97, 100, -1)
          check_trend(7, 35, 17, 100, -1)
          check_trend(1, 2, 467, 995, -1)
        end

        it "trends stable if score within 3 % points of base score" do
          check_trend(100, 100, 102, 100, 0)
          check_trend(100, 100, 98, 100, 0)
          check_trend(7, 35, 22, 100, 0)
          check_trend(7, 35, 19, 100, 0)
          check_trend(1, 2, 512, 995, 0)
          check_trend(1, 2, 480, 995, 0)
        end

        it "trends nil if follow-on score is not present" do
          check_trend(100, 100, nil, 0, nil)
        end
      end
    end
  end
end
