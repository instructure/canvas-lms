# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
class CustomGradeStatus < ApplicationRecord
  include Canvas::SoftDeletable

  belongs_to :root_account, class_name: "Account", inverse_of: :custom_grade_statuses
  belongs_to :created_by, class_name: "User"
  belongs_to :deleted_by, class_name: "User"

  has_many :submissions, inverse_of: :custom_grade_status, dependent: :nullify
  has_many :scores, inverse_of: :custom_grade_status, dependent: :nullify

  validates :color, presence: true, length: { maximum: 7 }, format: { with: /\A#([0-9a-fA-F]{3}){1,2}\z/ }
  validates :name, presence: true, length: { maximum: 14 }
  validates :root_account, :created_by, presence: true

  validate :validate_custom_grade_status_limit
  validate :deleted_by_validation
  validate :owned_by_root_account

  set_policy do
    given { |user, session| root_account&.grants_right?(user, session, :manage) }
    can :create and can :read and can :update and can :delete
  end

  private

  def validate_custom_grade_status_limit
    return unless root_account_id

    limit = new_record? ? 2 : 3
    if root_account.custom_grade_statuses.active.count > limit
      errors.add(:base, "Custom grade status limit reached for root account with id #{root_account_id}, only 3 custom grade statuses are allowed")
    end
  end

  def deleted_by_validation
    if deleted? && deleted_by_id.nil?
      errors.add(:deleted_by, "can't be blank")
    elsif active? && deleted_by_id.present?
      errors.add(:deleted_by, "must be blank")
    end
  end

  def owned_by_root_account
    return unless root_account_id

    unless root_account.root_account?
      errors.add(:root_account_id, "must reference a root account")
    end
  end
end
