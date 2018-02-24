#
# Copyright (C) 2018 - present Instructure, Inc.
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

class OutcomeImport < ApplicationRecord
  include Workflow
  belongs_to :context, polymorphic: %i[account course]
  belongs_to :attachment
  belongs_to :user
  has_many :outcome_import_errors

  validates :context_type, presence: true
  validates :context_id, presence: true
  validates :workflow_state, presence: true

  workflow do
    state :initializing
    state :created
    state :importing
    state :imported
    state :imported_with_messages
    state :aborted
    state :failed
    state :failed_with_messages
  end
end
