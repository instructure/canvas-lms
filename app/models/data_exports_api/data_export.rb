#
# Copyright (C) 2014 Instructure, Inc.
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

module DataExportsApi
  class DataExport < ActiveRecord::Base
    include Workflow
    include ContextModuleItem

    has_one :job_progress, :class_name => 'Progress', :as => :context
    belongs_to :context, :polymorphic => true
    validates_inclusion_of :context_type, :allow_nil => true, :in => ['EnrollmentTerm', 'Account', 'Course', 'User']
    belongs_to :user

    attr_accessible :user, :context
    validates_presence_of :workflow_state

    scope :for, lambda { |c|
      where(context_id: c.id, context_type: c.class.name)
    }

    workflow do
      state :created
      state :processing
      state :completed
      state :failed
      state :cancelled
    end

    def cancel
      if %w(processing created).include?(self.workflow_state)
        #TODO kill or unqueue process
        self.workflow_state = "cancelled"
        self.save!
      end
    end

  end
end
