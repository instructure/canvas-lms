#
# Copyright (C) 2013 Instructure, Inc.
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

class Progress < ActiveRecord::Base
  belongs_to :context, :polymorphic => true
  belongs_to :user
  attr_accessible :context, :tag, :completion, :message

  validates_presence_of :context_id
  validates_presence_of :context_type
  validates_presence_of :tag

  include Workflow
  workflow do
    state :queued do
      event :start, :transitions_to => :running
      event :fail, :transitions_to => :failed
    end
    state :running do
      event(:complete, :transitions_to => :completed) { update_completion! 100 }
      event :fail, :transitions_to => :failed
    end
    state :completed
    state :failed
  end

  def update_completion!(value)
    update_attribute(:completion, value)
  end

  def calculate_completion!(current_value, total)
    update_completion!(100.0 * current_value / total)
  end

  def pending?
    queued? || running?
  end
end
