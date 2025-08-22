# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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
class Lti::RegistrationHistoryEntry < ApplicationRecord
  extend RootAccountResolver

  VALID_UPDATE_TYPES = %w[manual_edit registration_update].freeze

  belongs_to :root_account, class_name: "Account", inverse_of: :lti_registration_history_entries
  belongs_to :lti_registration, class_name: "Lti::Registration", inverse_of: :lti_registration_history_entries
  belongs_to :created_by, class_name: "User", inverse_of: :lti_registration_history_entries

  validates :lti_registration, :created_by, :diff, presence: true

  validates :update_type, presence: true, inclusion: { in: VALID_UPDATE_TYPES }

  validates :comment, if: -> { comment.present? }, length: { maximum: 2000 }

  resolves_root_account through: :lti_registration
end
