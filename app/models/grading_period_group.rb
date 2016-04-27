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

  attr_readonly :account_id

  attr_accessible :title
  belongs_to :course
  has_many :grading_periods, dependent: :destroy
  has_many :enrollment_terms, inverse_of: :grading_period_group

  validate :associated_with_course_or_account_or_enrollment_term?

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
    root_account = account.root_account? ? account : account.root_account
    grading_period_group_ids = root_account
      .active_enrollment_terms.select(:grading_period_group_id)
    active.where(id: grading_period_group_ids)
  end

  def multiple_grading_periods_enabled?
    (course || root_account).feature_enabled?(:multiple_grading_periods) ||
      account_grading_period_allowed?
  end

  private

  def root_account
    @root_account ||= begin
      if enrollment_terms.loaded?
        term_account_id = enrollment_terms.map(&:root_account_id).first
        Account.find(term_account_id)
      else
        Account.find_by(id: enrollment_terms.select(:root_account_id))
      end
    end
  end

  def associated_with_course_or_account_or_enrollment_term?
    if enrollment_terms?
      validate_with_enrollment_terms
    elsif active?
      validate_without_enrollment_terms
    end
  end

  def enrollment_terms?
    if enrollment_terms.loaded?
      enrollment_terms.any?(&:active?)
    else
      enrollment_terms.active.exists?
    end
  end

  def validate_without_enrollment_terms
    if course_id.blank? && account_id.blank?
      errors.add(:enrollment_terms, t("cannot be empty when course_id is nil and account_id is nil"))
    elsif course_id.present? && account_id.present?
      errors.add(:course_id, t("cannot be present when account_id is present"))
      errors.add(:account_id, t("cannot be present when course_id is present"))
    end
  end

  def validate_with_enrollment_terms
    if enrollment_terms.loaded?
      account_ids = enrollment_terms.map(&:root_account_id)
    else
      account_ids = enrollment_terms.pluck(:root_account_id)
    end
    account_ids << self.account_id if self.account_id.present?
    if account_ids.uniq.count > 1
      errors.add(:enrollment_terms, t("cannot be associated with different accounts"))
    end
  end

  def account_grading_period_allowed?
   root_account.present? && root_account.feature_allowed?(:multiple_grading_periods)
  end
end
