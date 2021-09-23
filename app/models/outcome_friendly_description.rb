# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class OutcomeFriendlyDescription < ApplicationRecord
  include Canvas::SoftDeletable
  extend RootAccountResolver

  belongs_to :learning_outcome
  belongs_to :context, polymorphic: [:account, :course]
  resolves_root_account through: :context

  validates :context, presence: true
  validates :learning_outcome_id, uniqueness: { scope: [:context_type, :context_id]}
  validates :description, length: { maximum: maximum_string_length, allow_blank: false}
end
