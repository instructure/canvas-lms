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

class WebConferenceParticipant < ActiveRecord::Base
  belongs_to :web_conference
  belongs_to :user

  EXPORTABLE_ATTRIBUTES = [:id, :user_id, :web_conference_id, :participation_type, :workflow_state, :created_at, :updated_at]
  EXPORTABLE_ASSOCIATIONS = [:web_conference, :user]

  attr_accessible :web_conference, :user
end
