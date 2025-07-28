# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class Lti::AssetProcessorEulaAcceptance < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable

  resolves_root_account through: :context_external_tool

  belongs_to :user, optional: false
  belongs_to :context_external_tool, optional: false

  validates :workflow_state, length: { maximum: 255 }
  validates :accepted, inclusion: { in: [true, false] }
  validates :user_id, uniqueness: { scope: :context_external_tool_id, conditions: -> { active } }
end
