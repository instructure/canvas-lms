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

class SubmissionCommentParticipant < ActiveRecord::Base
  belongs_to :user
  belongs_to :submission_comment

  attr_accessible :user_id, :participation_type

  EXPORTABLE_ATTRIBUTES = [:id, :submission_comment_id, :user_id, :participation_type, :created_at, :updated_at]
  EXPORTABLE_ASSOCIATIONS = [:user, :submission_comment]
end
