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
  module Stats
    class << self
      def students_per_range(rule, include_trend_data = false)
        assignment_ids = [rule.trigger_assignment_id]
        assignment_ids += rule.assignment_set_associations.pluck(:assignment_id) if include_trend_data

        sub_attrs = %i[id user_id assignment_id score]
        all_submission_data = rule.course.submissions.where(assignment_id: assignment_ids)
                                  .pluck(*sub_attrs).map { |r| sub_attrs.zip(r).to_h }.sort_by { |s| s[:user_id] } # turns plucked rows into hashes

        assignments_by_id = rule.course.assignments.where(id: assignment_ids).to_a.index_by(&:id)
        users_by_id = User.where(id: all_submission_data.pluck(:user_id).uniq).to_a.index_by(&:id)

        trigger_submissions = all_submission_data.select { |s| s[:assignment_id] == rule.trigger_assignment_id }

        # { user_id => [Submission] }
        follow_on_submissions_hash = {}
        if include_trend_data
          student_ids = trigger_submissions.pluck(:user_id)
          all_previous_assignment_ids = AssignmentSetAction.current_assignments(student_ids, rule.assignment_sets)
                                                           .preload(assignment_set: :assignment_set_associations)
                                                           .each_with_object({}) { |action, acc| acc[action.student_id] = action.assignment_set.assignment_set_associations.map(&:assignment_id) }
          student_ids.each do |student_id|
            previous_assignment_ids = all_previous_assignment_ids[student_id]
            follow_on_submissions_hash[student_id] = if previous_assignment_ids
                                                       all_submission_data.select { |s| s[:user_id] == student_id && previous_assignment_ids.include?(s[:assignment_id]) }
                                                     else
                                                       []
                                                     end
          end
        end

        ranges = rule.scoring_ranges.map { |sr| { scoring_range: sr, size: 0, students: [] } }
        trigger_submissions.each do |submission|
          next unless submission

          user_id = submission[:user_id]
          raw_score = submission[:score]
          assignment = assignments_by_id[submission[:assignment_id]]
          score = percent_from_points(raw_score, assignment.points_possible)
          next unless score

          user = users_by_id[user_id]
          user_details = nil
          ranges.each do |b|
            next unless b[:scoring_range].contains_score score

            user_details ||= if assignment.anonymize_students?
                               { name: t("Anonymous User") }
                             else
                               {
                                 id: user.id,
                                 name: user.short_name,
                                 avatar_image_url: AvatarHelper.avatar_url_for_user(user, nil, root_account: rule.root_account)
                               }
                             end
            student_record = {
              score:,
              submission_id: submission[:id],
              user: user_details
            }
            if include_trend_data
              student_record[:trend] = compute_trend_from_submissions(score, follow_on_submissions_hash[user_id], assignments_by_id)
            end
            b[:size] += 1
            b[:students] << student_record
          end
        end
        ranges.each do |r|
          r[:scoring_range] = r[:scoring_range].as_json(include_root: false, except: [:root_account_id, :deleted_at]) # can't rely on normal json serialization
        end
        { rule:, ranges:, enrolled: users_by_id.count }
      end

      def student_details(rule, student_id)
        previous_assignment = AssignmentSetAction.current_assignments(student_id, rule.assignment_sets).take
        follow_on_assignment_ids = if previous_assignment
                                     previous_assignment.assignment_set.assignment_set_associations.pluck(:assignment_id)
                                   else
                                     []
                                   end
        possible_assignment_ids = follow_on_assignment_ids + [rule.trigger_assignment_id]

        submissions_by_assignment_id = rule.course.submissions.where(assignment_id: possible_assignment_ids, user_id: student_id).to_a.index_by(&:assignment_id)
        assignments_by_id = rule.course.assignments.where(id: possible_assignment_ids).to_a.index_by(&:id)

        trigger_assignment = assignments_by_id[rule.trigger_assignment_id]
        trigger_submission = submissions_by_assignment_id[rule.trigger_assignment_id]
        trigger_points = trigger_submission.score if trigger_submission
        trigger_points_possible = trigger_assignment.points_possible if trigger_assignment
        trigger_score = percent_from_points(trigger_points, trigger_points_possible)

        {
          rule:,
          trigger_assignment: assignment_detail(trigger_assignment, trigger_submission),
          follow_on_assignments: follow_on_assignment_ids.map do |id|
            assignment_detail(
              assignments_by_id[id],
              submissions_by_assignment_id[id],
              trend_score: trigger_score
            )
          end
        }
      end

      def percent_from_points(points, points_possible)
        return points.to_f / points_possible.to_f if points.present? && points_possible.to_f.nonzero?

        points.to_f / 100 if points.present? # mirror Canvas rule
      end

      private

      def assignment_detail(assignment, submission, trend_score: nil)
        score = submission ? percent_from_points(submission.score, assignment.points_possible) : nil
        detail = {
          assignment: { id: assignment.id, course_id: assignment.context_id, name: assignment.title, submission_types: assignment.submission_types_array, grading_type: assignment.grading_type },
          score:
        }
        detail[:submission] = { id: submission.id, score: submission.score, grade: submission.grade, submitted_at: submission.submitted_at } if submission
        detail[:trend] = compute_trend(trend_score, score) if trend_score
        detail
      end

      def compute_trend(old_score, new_score_or_scores)
        new_scores = Array.wrap(new_score_or_scores).compact
        return unless old_score && new_scores.present?

        average = new_scores.sum / new_scores.length
        percentage_points_improvement = average - old_score
        return 1 if percentage_points_improvement >= 0.03
        return -1 if percentage_points_improvement <= -0.03

        0
      end

      def compute_trend_from_submissions(score, submissions, assignments_by_id)
        return unless submissions.present?

        new_scores = submissions.map do |s|
          percent_from_points(s[:score], assignments_by_id[s[:assignment_id]].points_possible)
        end
        compute_trend(score, new_scores)
      end
    end
  end
end
