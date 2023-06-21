# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

module AssignmentUtil
  def self.due_date_required?(assignment)
    assignment.post_to_sis.present? && due_date_required_for_account?(assignment.context)
  end

  def self.in_date_range?(date, start_date, end_date)
    # due dates are considered equal if they're the same up to the minute
    date = Assignment.due_date_compare_value date
    start_date = Assignment.due_date_compare_value start_date
    end_date = Assignment.due_date_compare_value end_date
    (start_date.nil? || date >= start_date) && (end_date.nil? || date <= end_date)
  end

  def self.due_date_ok?(assignment)
    !due_date_required?(assignment) ||
      assignment.due_at.present? ||
      assignment.grading_type == "not_graded"
  end

  def self.assignment_name_length_required?(assignment)
    assignment.post_to_sis.present? && name_length_required_for_account?(assignment.context)
  end

  def self.assignment_max_name_length(context)
    account = Context.get_account(context)
    account.try(:sis_assignment_name_length_input).try(:[], :value).to_i
  end

  def self.post_to_sis_friendly_name(context)
    account = Context.get_account(context)
    account.try(:root_account).try(:settings).try(:[], :sis_name) || "SIS"
  end

  def self.name_length_required_for_account?(context)
    account = Context.get_account(context)
    account.try(:sis_syncing).try(:[], :value) &&
      account.try(:sis_assignment_name_length).try(:[], :value) &&
      sis_integration_settings_enabled?(context)
  end

  def self.due_date_required_for_account?(context)
    account = Context.get_account(context)
    account.try(:sis_syncing).try(:[], :value).present? &&
      account.try(:sis_require_assignment_due_date).try(:[], :value) &&
      sis_integration_settings_enabled?(context)
  end

  def self.sis_integration_settings_enabled?(context)
    account = Context.get_account(context)
    account.try(:feature_enabled?, "new_sis_integrations").present?
  end

  def self.process_due_date_reminder(context_type, context_id)
    analyzer = StudentAwarenessAnalyzer.new(context_type, context_id)
    notification = BroadcastPolicy.notification_finder.by_name("Upcoming Assignment Alert")

    # in the rather unlikely case where the due date gets reset *while* we're
    # scheduled to do this work, we don't want to end up alerting students for
    # something that's no longer due...
    unless analyzer.assignment&.due_at.nil?
      analyzer.apply do |**kwargs|
        alert_unaware_student(notification, **kwargs)
      end
    end
  end

  def self.alert_unaware_student(notification, assignment:, submission:)
    BroadcastPolicy.notifier.send_notification(
      assignment,
      notification.name,
      notification,
      [submission.student],
      assignment_due_date: submission.cached_due_date,
      root_account_id: assignment.root_account_id,
      course_id: assignment.context_id
    )
  end

  class StudentAwarenessAnalyzer
    attr_reader :assignment

    def initialize(context_type, context_id)
      @context = case context_type
                 when "Assignment"
                   Assignment.active.where(id: context_id).first
                 when "AssignmentOverride"
                   AssignmentOverride.active.where(id: context_id).first
                 end

      @assignment = case context_type
                    when "Assignment"
                      @context
                    when "AssignmentOverride"
                      @context&.assignment
                    end
    end

    def apply
      submissions.find_each do |submission|
        unless seen_assignment_recently?(submission.student)
          yield assignment:, submission:
        end
      end
    end

    private

    def seen_assignment_recently?(student, since: 3.days.ago)
      AssetUserAccess
        .where(user_id: student.id, asset_code: "assignment_#{assignment.id}")
        .where(AssetUserAccess.arel_table[:last_access].gteq(since))
        .exists?
    end

    def submissions
      case @context
      when Assignment
        @context.submissions.active.where(workflow_state: "unsubmitted")
      when AssignmentOverride
        students = case @context.set_type
                   when "ADHOC"
                     @context.assignment_override_students
                   when "CourseSection"
                     @context.set.participating_students
                   when "Group"
                     @context.set.participants
                   else
                     []
                   end

        @context.assignment.submissions.active.where(
          workflow_state: "unsubmitted",
          user_id: students
        )
      else
        Submission.none
      end
    end
  end

  private_constant :StudentAwarenessAnalyzer
end
