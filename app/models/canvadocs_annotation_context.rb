# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class CanvadocsAnnotationContext < ApplicationRecord
  belongs_to :attachment
  belongs_to :root_account, class_name: "Account"
  belongs_to :submission

  validates :attachment_id, presence: true
  validates :launch_id, presence: true
  validates :root_account_id, presence: true
  validates :submission_id, presence: true

  validates_uniqueness_of :submission_attempt, scope: [:attachment_id, :submission_id]

  before_validation :set_launch_id, if: :new_record?
  before_validation :set_root_account_id, if: :new_record?

  set_policy do
    given do |user|
      user && (
        submission.grants_right?(user, :grade) ||
        (submission.assignment.moderated_grading? && submission.assignment.can_be_moderated_grader?(user)) ||
        (draft? && user == submission.user)
      )
    end

    can :readwrite
  end

  def draft?
    self.submission_attempt.nil?
  end

  def set_launch_id
    self.launch_id ||= SecureRandom.hex(20)
  end

  def set_root_account_id
    self.root_account_id ||= self.submission&.root_account_id
  end
end
