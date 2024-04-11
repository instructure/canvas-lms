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

module ConditionalRelease
  module OverrideHandler
    class << self
      # handle the parts of the service that was making API calls back to canvas to create/remove assignment overrides

      def handle_grade_change(submission)
        return unless submission.graded? && submission.posted? # sanity check

        sets_to_assign, sets_to_unassign = find_assignment_sets(submission)

        set_assignment_overrides(submission.user_id, sets_to_assign, sets_to_unassign)
        ConditionalRelease::AssignmentSetAction.create_from_sets(sets_to_assign,
                                                                 sets_to_unassign,
                                                                 student_id: submission.user_id,
                                                                 actor_id: submission.grader_id,
                                                                 source: "grade_change")
      end

      def handle_assignment_set_selection(student, trigger_assignment, assignment_set_id)
        # just going to raise a 404 if the choice is invalid because i'm too lazy to return more specific errors
        rule_ids = trigger_assignment.conditional_release_rules.active.pluck(:id)
        submission = trigger_assignment.submissions.for_user(student).in_workflow_state(:graded).posted.take!
        relative_score = ConditionalRelease::Stats.percent_from_points(submission.score, trigger_assignment.points_possible)
        assignment_set = AssignmentSet.active.where(id: assignment_set_id,
                                                    scoring_range: ScoringRange.active.where(rule_id: rule_ids).for_score(relative_score)).take!

        other_assignment_sets = assignment_set.scoring_range.assignment_sets - [assignment_set]
        previous_set_ids = AssignmentSetAction.current_assignments(student.id, other_assignment_sets).pluck(:assignment_set_id)
        sets_to_unassign = other_assignment_sets.select { |set| previous_set_ids.include?(set.id) }

        set_assignment_overrides(submission.user_id, [assignment_set], sets_to_unassign)
        ConditionalRelease::AssignmentSetAction.create_from_sets([assignment_set],
                                                                 sets_to_unassign,
                                                                 student_id: submission.user_id,
                                                                 source: "select_assignment_set")
        assignment_set.assignment_set_associations.map(&:assignment_id)
      end

      def find_assignment_sets(submission)
        rules = submission.course.conditional_release_rules.active.where(trigger_assignment_id: submission.assignment).preload(:assignment_sets).to_a
        relative_score = ConditionalRelease::Stats.percent_from_points(submission.score, submission.assignment.points_possible)

        sets_to_assign = []
        sets_to_unassign = []
        rules.each do |rule|
          new_sets = relative_score ? rule.assignment_sets_for_score(relative_score).to_a : []
          if new_sets.length == 1 # otherwise they have to choose between sets
            sets_to_assign += new_sets
          end
          sets_to_unassign += rule.assignment_sets.to_a - new_sets
        end
        sets_to_unassign = ConditionalRelease::AssignmentSetAction.current_assignments(submission.user_id, sets_to_unassign).preload(:assignment_set).map(&:assignment_set)
        [sets_to_assign, sets_to_unassign]
      end

      def set_assignment_overrides(student_id, sets_to_assign, sets_to_unassign)
        assignments_to_assign = assignments_for_sets(sets_to_assign)
        assignments_to_unassign = assignments_for_sets(sets_to_unassign) - assignments_to_assign # don't unassign anything we're trying to assign to

        existing_overrides = AssignmentOverride.active
                                               .where(assignment_id: assignments_to_assign + assignments_to_unassign, set_type: "ADHOC").to_a
        ActiveRecord::Associations.preload(existing_overrides,
                                           :assignment_override_students,
                                           AssignmentOverrideStudent.where(user_id: student_id)) # only care about records for this student
        existing_overrides_map = existing_overrides.group_by(&:assignment_id)

        assignments_to_assign.each do |to_assign|
          overrides = existing_overrides_map[to_assign.id]
          if overrides
            unless overrides.any? { |o| o.assignment_override_students.map(&:user_id).include?(student_id) }
              override = overrides.min_by(&:id) # kind of arbitrary but may as well be consistent and always pick the earliest
              # we can pass in :no_enrollment to skip some queries - i assume they have an enrollment since they have a submission
              override.assignment_override_students.create!(user_id: student_id, no_enrollment: false)
            end
          else
            # have to create an override
            new_override = to_assign.assignment_overrides.create!(
              set_type: "ADHOC",
              assignment_override_students: [
                AssignmentOverrideStudent.new(assignment: to_assign, user_id: student_id, no_enrollment: false)
              ]
            )
            existing_overrides_map[to_assign.id] = [new_override]
          end
        end

        assignments_to_unassign.each do |to_unassign|
          overrides = existing_overrides_map[to_unassign.id] || []
          overrides.each do |o|
            o.assignment_override_students.detect { |aos| aos.user_id == student_id }&.destroy!
          end
        end
      end

      def assignments_for_sets(sets)
        sets.any? ? Assignment.active.where(id: ConditionalRelease::AssignmentSetAssociation.active.where(assignment_set_id: sets).select(:assignment_id)).to_a : []
      end
    end
  end
end
