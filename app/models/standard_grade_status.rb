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
class StandardGradeStatus < ApplicationRecord
  STANDARD_GRADE_STATUSES = %w[late missing resubmitted dropped excused extended].freeze

  belongs_to :root_account, class_name: "Account", inverse_of: :standard_grade_statuses

  validates :color, presence: true, length: { maximum: 7 }, format: { with: /\A#([0-9a-fA-F]{3}){1,2}\z/ }
  validates :status_name, presence: true, uniqueness: { scope: :root_account }, inclusion: { in: STANDARD_GRADE_STATUSES, message: -> { t("%{value} is not a valid standard grade status") } }
  validates :hidden, inclusion: [true, false]
  validates :root_account, presence: true

  set_policy do
    given { |user, session| root_account&.grants_right?(user, session, :manage) }
    can :create and can :read and can :update
  end
end
