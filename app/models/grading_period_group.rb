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

class GradingPeriodGroup < ActiveRecord::Base
  include Canvas::SoftDeletable

  belongs_to :root_account, inverse_of: :grading_period_groups, foreign_key: :account_id, class_name: "Account"
  belongs_to :course
  has_many :grading_periods, inverse_of: :grading_period_group
  has_many :enrollment_terms, inverse_of: :grading_period_group

  validate :associated_with_course_or_root_account, if: :active?

  before_save :set_root_account_id
  after_save :recompute_course_scores, if: :weighted_actually_changed?
  after_save :recache_grading_period, if: :saved_change_to_course_id?
  after_destroy :cleanup_associations_and_recompute_scores_later

  set_policy do
    given do |user|
      (course || root_account).grants_right?(user, :read)
    end
    can :read

    given do |user|
      root_account&.associated_user?(user)
    end
    can :read

    given do |user|
      (course || root_account).grants_right?(user, :manage)
    end
    can :update and can :delete

    given do |user|
      root_account&.grants_right?(user, :manage)
    end
    can :create
  end

  def self.for(account)
    raise ArgumentError, "argument is not an Account" unless account.is_a?(Account)

    root_account = account.root_account? ? account : account.root_account
    root_account.grading_period_groups.active
  end

  def self.for_course(context)
    course_group = GradingPeriodGroup.find_by(course_id: context, workflow_state: :active)
    return course_group if course_group.present?

    account_group = context.enrollment_term.grading_period_group
    (account_group.nil? || account_group.deleted?) ? nil : account_group
  end

  def recompute_scores_for_each_term(update_all_grading_period_scores, term_ids: nil)
    terms = term_ids ? EnrollmentTerm.where(id: term_ids) : enrollment_terms.active

    terms.find_each do |term|
      term.recompute_course_scores_later(
        update_all_grading_period_scores:,
        strand_identifier: "GradingPeriodGroup:#{global_id}"
      )
    end
  end

  private

  def recompute_course_scores
    return course.recompute_student_scores(update_all_grading_period_scores: false) if course_id.present?

    recompute_scores_for_each_term(false)
  end

  if Rails.env.production?
    handle_asynchronously :recompute_course_scores,
                          singleton: proc { |g| "grading_period_group:recompute:GradingPeriodGroup:#{g.global_id}" }
  end

  def weighted_actually_changed?
    !new_record? && saved_change_to_weighted?
  end

  def recache_grading_period
    SubmissionLifecycleManager.recompute_course(course) if course
    SubmissionLifecycleManager.recompute_course(course_id_before_last_save) if course_id_before_last_save
  end

  def associated_with_course_or_root_account
    if course_id.blank? && account_id.blank?
      errors.add(:course_id, t("cannot be nil when account_id is nil"))
      errors.add(:account_id, t("cannot be nil when course_id is nil"))
    elsif course_id.present? && account_id.present?
      errors.add(:course_id, t("cannot be present when account_id is present"))
      errors.add(:account_id, t("cannot be present when course_id is present"))
    elsif root_account && !root_account.root_account?
      errors.add(:account_id, t("must belong to a root account"))
    elsif root_account&.deleted?
      errors.add(:account_id, t("must belong to an active root account"))
    elsif course&.deleted?
      errors.add(:course_id, t("must belong to an active course"))
    end
  end

  def cleanup_associations_and_recompute_scores_later(updating_user: nil)
    root_account_id = course_id ? course.root_account.global_id : root_account.global_id
    delay_if_production(strand: "GradingPeriodGroup#cleanup_associations_and_recompute_scores:Account#{root_account_id}",
                        priority: Delayed::LOW_PRIORITY)
      .cleanup_associations_and_recompute_scores(updating_user:)
  end

  def cleanup_associations_and_recompute_scores(updating_user: nil)
    periods_to_destroy = grading_periods.active
    update_in_batches(periods_to_destroy, workflow_state: :deleted)

    scores_to_destroy = Score.active.where(grading_period_id: periods_to_destroy)
    update_in_batches(scores_to_destroy, workflow_state: :deleted)

    # Legacy Grading Period support. Grading Periods can no longer have a course_id.
    if course_id.present?
      course.recompute_student_scores(update_all_grading_period_scores: true, run_immediately: true)
      SubmissionLifecycleManager.recompute_course(course, run_immediately: true, executing_user: updating_user)
    else
      term_ids = enrollment_terms.pluck(:id)
      update_in_batches(enrollment_terms, grading_period_group_id: nil)
      recompute_scores_for_each_term(true, term_ids:)
    end
  end

  def update_in_batches(scope, updates)
    scope.find_ids_in_ranges(batch_size: 1000) do |min_id, max_id|
      scope.where(id: min_id..max_id).update_all(updates.reverse_merge({ updated_at: Time.zone.now }))
    end
  end

  def set_root_account_id
    self.root_account_id ||= account_id || course&.root_account_id
  end
end
