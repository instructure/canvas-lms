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

class TemporaryEnrollmentPairing < ActiveRecord::Base
  include Canvas::SoftDeletable

  belongs_to :root_account, class_name: "Account", inverse_of: :temporary_enrollment_pairings
  belongs_to :created_by, class_name: "User"
  belongs_to :deleted_by, class_name: "User"

  has_many :enrollments, inverse_of: :temporary_enrollment_pairing, dependent: :nullify

  validates :root_account_id, :created_by, presence: true

  scope :active, -> { where.not(workflow_state: "deleted") }
end
