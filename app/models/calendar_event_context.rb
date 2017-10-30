#
# Copyright (C) 2017 - present Instructure, Inc.
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
class CalendarEventContext < ActiveRecord::Base
  include Workflow

  belongs_to :calendar_event
  belongs_to :context,
    polymorphic: %i{course user group appointment_group course_section},
    polymorphic_prefix: true

  validates :calendar_event, presence: true

  validates :context, presence: true # Ensure that the record exists too
  validates :context_id, uniqueness: {scope: %i{calendar_event context_type}}

  class << self
    def active
      where(workflow_state: 'active')
    end

    def for_context(context)
      where(context: context)
    end
    alias_method :for_contexts, :for_context
  end

  workflow do
    state :active
    state :deleted
  end
end
