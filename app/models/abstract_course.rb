#
# Copyright (C) 2011 Instructure, Inc.
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

class AbstractCourse < ActiveRecord::Base

  include Workflow

  strong_params

  belongs_to :root_account, :class_name => 'Account'
  belongs_to :account
  belongs_to :enrollment_term
  has_many :courses

  validates_presence_of :account_id, :root_account_id, :enrollment_term_id, :workflow_state

  workflow do
    state :active
    state :deleted
  end

  alias_method :destroy_permanently!, :destroy
  def destroy
    self.workflow_state = 'deleted'
    save!
  end

  scope :active, -> { where("abstract_courses.workflow_state<>'deleted'") }

  include StickySisFields
  are_sis_sticky :name, :short_name, :enrollment_term_id

end
