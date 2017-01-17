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

class GradebookUpload < ActiveRecord::Base
  belongs_to :course
  belongs_to :user
  belongs_to :progress
  has_many :attachments, as: :context, inverse_of: :context, dependent: :destroy

  serialize :gradebook, JSON

  def self.queue_from(course, user, attachment_data)
    progress = Progress.create!(context: course, tag: "gradebook_upload") do |p|
      p.user = user
    end
    gradebook_upload = GradebookUpload.create!(course: course, user: user, progress: progress)
    gradebook_upload_attachment = gradebook_upload.attachments.create!(attachment_data)
    progress.process_job(GradebookImporter, :create_from, {}, gradebook_upload, user, gradebook_upload_attachment)
    progress
  end

  def stale?
    created_at < 60.minutes.ago || progress.try(:workflow_state) == "failed"
  end
end
