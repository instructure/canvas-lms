#
# Copyright (C) 2014-2016 Instructure, Inc.
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

  attr_accessible :title
  belongs_to :root_account, inverse_of: :grading_period_groups, foreign_key: :account_id, class_name: "Account"
  belongs_to :course
  has_many :grading_periods, dependent: :destroy
  has_many :enrollment_terms, inverse_of: :grading_period_group

  validate :associated_with_course_or_root_account, if: :active?

  after_destroy :dissociate_enrollment_terms

  set_policy do
    given do |user|
      multiple_grading_periods_enabled? &&
      (course || root_account).grants_right?(user, :read)
    end
    can :read

    given do |user|
      root_account &&
      multiple_grading_periods_enabled? &&
      root_account.associated_user?(user)
    end
    can :read

    given do |user|
      multiple_grading_periods_enabled? &&
      (course || root_account).grants_right?(user, :manage)
    end
    can :update and can :delete

    given do |user|
      root_account &&
      multiple_grading_periods_enabled? &&
      root_account.grants_right?(user, :manage)
    end
    can :create
  end

  def self.for(account)
    raise ArgumentError.new("account is not an Account") unless account.is_a?(Account)
    root_account = account.root_account? ? account : account.root_account
    root_account.grading_period_groups.active
  end

  def multiple_grading_periods_enabled?
    multiple_grading_periods_on_course? || multiple_grading_periods_on_account?
  end

  private

  def associated_with_course_or_root_account
    if course_id.blank? && account_id.blank?
      errors.add(:course_id, t("cannot be nil when account_id is nil"))
      errors.add(:account_id, t("cannot be nil when course_id is nil"))
    elsif course_id.present? && account_id.present?
      errors.add(:course_id, t("cannot be present when account_id is present"))
      errors.add(:account_id, t("cannot be present when course_id is present"))
    elsif root_account && !root_account.root_account?
      errors.add(:account_id, t("must belong to a root account"))
    elsif root_account && root_account.deleted?
      errors.add(:account_id, t("must belong to an active root account"))
    elsif course && course.deleted?
      errors.add(:course_id, t("must belong to an active course"))
    end
  end

  def multiple_grading_periods_on_account?
    root_account.present? && (
      root_account.feature_enabled?(:multiple_grading_periods) ||
      root_account.feature_allowed?(:multiple_grading_periods)
    )
  end

  def multiple_grading_periods_on_course?
    course.present? && course.feature_enabled?(:multiple_grading_periods)
  end

  def dissociate_enrollment_terms
    enrollment_terms.update_all(grading_period_group_id: nil)
  end
end
