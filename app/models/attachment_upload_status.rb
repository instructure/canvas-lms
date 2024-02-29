# frozen_string_literal: true

# Copyright (C) 2019 - present Instructure, Inc.
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
class AttachmentUploadStatus < ApplicationRecord
  belongs_to :attachment

  validates :attachment, :error, presence: true

  def self.cache_key(attachment)
    "attachment_upload:#{attachment.global_id}:status"
  end

  def self.pending!(attachment)
    Rails.cache.write(cache_key(attachment), "pending", expires_in: 1.day)
  end

  def self.success!(attachment)
    Rails.cache.delete(cache_key(attachment))
  end

  def self.failed!(attachment, error)
    attachment.shard.activate do
      create!(
        attachment:,
        error:
      ).tap { Rails.cache.delete(cache_key(attachment)) }
    end
  end

  # If Rails.cache has a status, use that. Otherwise check for AttachmentUploadStatus in db.
  # If everything is empty, means the upload was a success.
  def self.upload_status(attachment)
    if attachment.created_at > 1.day.ago # seems like we can skip the cache check if it's old enough
      status = Rails.cache.read(cache_key(attachment))
      return status if status
    end

    failed = if attachment.attachment_upload_statuses.loaded?
               attachment.attachment_upload_statuses.any?
             else
               attachment.attachment_upload_statuses.exists?
             end
    return "failed" if failed

    "success"
  end
end
