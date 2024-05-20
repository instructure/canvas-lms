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
class Assignment::BulkUpdate
  include SubmittablesGradingPeriodProtection

  def initialize(context, user)
    @context = context
    @current_user = user
  end

  def grading_periods?
    @context.grading_periods?
  end

  def run(progress, assignment_data)
    # assignment_data looks like [:id, :all_dates => [:id, :base, :due_at, :unlock_at, :lock_at]]
    assignment_data_hash = assignment_data.index_by { |a| a["id"] }
    assignments = @context.active_assignments.where(id: assignment_data_hash.keys).preload(:assignment_overrides).index_by(&:id)
    assignments_to_save = Set.new

    # 1. update AR models (in memory!)
    assignment_data_hash.each do |id, data|
      dates = data["all_dates"]
      next unless dates.present?

      base, overrides = dates.partition { |date| date["base"] }

      # 1a. update the assignment
      assignment = assignments[id.to_i]
      raise ActiveRecord::RecordNotFound, "invalid assignment id #{id}" unless assignment

      if base.any?
        assignment.content_being_saved_by(@current_user)
        assignment.updating_user = @current_user
        assignment.assign_attributes(base.first.slice(*%w[due_at unlock_at lock_at]))
        assignments_to_save << assignment if assignment.changed?
      end

      # 1b. update associated overrides
      overrides.each do |override_data|
        override = assignment.assignment_overrides.detect { |o| o.id == override_data["id"].to_i }
        raise ActiveRecord::RecordNotFound, "invalid assignment override id #{override_data["id"]} for assignment #{assignment.id}" unless override

        %w[due_at unlock_at lock_at].each do |date|
          if override_data.key?(date)
            override.send(:"#{date}=", override_data[date])
            override.send(:"#{date}_overridden=", true)
          else
            override.send(:"#{date}=", nil)
            override.send(:"#{date}_overridden=", false)
          end
        end
        assignments_to_save << assignment if override.changed?
      end
    end

    progress_count = 0
    progress_total = assignments_to_save.size * 2

    # 2. validate all assignments and overrides
    all_errors = []
    assignments_to_save.each do |assignment|
      if !grading_periods_allow_submittable_update?(assignment, {}) || !assignment.valid?
        all_errors << { "assignment_id" => assignment.id }
                      .merge(assignment.errors.to_hash.deep_stringify_keys)
      end
      assignment.assignment_overrides.each do |override|
        if !grading_periods_allow_assignment_override_update?(override) || !override.valid?
          all_errors << { "assignment_id" => assignment.id, "assignment_override_id" => override.id }
                        .merge(override.errors.to_hash.deep_stringify_keys)
        end
      end
      progress.calculate_completion!(progress_count, progress_total)
      progress_count += 1
    end
    if all_errors.any?
      progress.fail
      progress.set_results(all_errors)
      return
    end

    # 3. save everything
    Assignment.suspend_due_date_caching do
      Assignment.suspend_grading_period_grade_recalculation do
        assignments_to_save.each do |assignment|
          assignment.transaction do
            assignment.save_without_broadcasting!
            assignment.assignment_overrides.each(&:save!)
          end
          progress.calculate_completion!(progress_count, progress_total)
          progress_count += 1
          assignment.delay_if_production.do_notifications!
        end
      end
    end

    # 4. clear caches
    Assignment.clear_cache_keys(assignments_to_save, :availability)
    quizzes = assignments_to_save.select(&:quiz?).map(&:quiz)
    Quizzes::Quiz.clear_cache_keys(quizzes, :availability) if quizzes.any?
    SubmissionLifecycleManager.recompute_course(@context, assignments: assignments_to_save, update_grades: true, executing_user: @current_user)

    progress.complete
    progress.set_results({ "updated_count" => assignments_to_save.size })
  rescue ActiveRecord::RecordNotFound => e
    progress.fail
    progress.set_results({ "message" => e.message })
  end
end
