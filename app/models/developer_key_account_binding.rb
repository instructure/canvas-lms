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

class DeveloperKeyAccountBinding < ApplicationRecord
  DEFAULT_STATE = 'allow'.freeze

  belongs_to :account
  belongs_to :developer_key

  validates :account, :developer_key, presence: true
  validates :workflow_state, inclusion: { in: ['off', 'allow', 'on'] }

  before_validation :infer_workflow_state

  private

  def infer_workflow_state
    self.workflow_state ||= DEFAULT_STATE
  end
end
