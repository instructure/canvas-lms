#
# Copyright (C) 2012 - present Instructure, Inc.
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

class SubmissionCommentConversationFix < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    Submission.active.where(id: ConversationMessage.select(:asset_id).
                         where("asset_id IS NOT NULL").
                         where(body: '')).each do |submission|
      submission.create_or_update_conversations!(:destroy) if submission.visible_submission_comments.empty?
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
