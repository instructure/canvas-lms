#
# Copyright (C) 2015 - present Instructure, Inc.
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

require 'active_support/concern'

module Canvas::SoftDeletable
  extend ActiveSupport::Concern

  included do
    include Workflow

    workflow do
      state :active
      state :deleted
    end

    scope :active, -> { where workflow_state: "active" }

    # save the previous definition of `destroy` and alias it to `destroy_permanently!`
    # Note: `destroy_permanently!` now does NOT throw errors while the newly defined
    # `destroy` DOES throw errors due to `save!`
    alias_method :destroy_permanently!, :destroy
    def destroy
      return true if deleted?
      self.workflow_state = 'deleted'
      run_callbacks(:destroy) { save! }
    end

    # `restore` was taken by too many other methods...
    def undestroy(active_state: 'active')
      self.workflow_state = active_state
      save!
      true
    end
  end
end
