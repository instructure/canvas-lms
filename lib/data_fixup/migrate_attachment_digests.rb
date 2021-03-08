# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# this datafixup is not intended to have a corresponding migration. it will be
# manually applied
module DataFixup::MigrateAttachmentDigests
  # run this to migrate all local md5 attachment hashes to sha512. this only
  # works for local file storage
  def self.run
    # for s3 storage we use the md5 provided in the etag, so we don't want to change those
    raise 'Cannot migrate attachment digests when configured for s3 storage' if Attachment.s3_storage?

    Attachment.find_ids_in_ranges do |min_id, max_id|
      delay_if_production(n_strand: ["DataFixup:MigrateAttachmentDigests", Shard.current.database_server.id],
          priority: Delayed::LOWER_PRIORITY).
        run_for_attachment_range(min_id, max_id)
    end
  end

  def self.run_for_attachment_range(min_id, max_id)
    update_count = 0
    max_seconds = Setting.get("max_seconds_per_migrate_attachment_batch", nil).presence&.to_f

    start = Time.now
    Attachment.where(id: min_id..max_id, instfs_uuid: nil, root_attachment_id: nil).where("length(md5) = 32").order(:id).find_each do |attachment|
      recompute_attachment_digest(attachment)
      update_count += 1
      if max_seconds && Time.now >= start + max_seconds
        self.requeue(attachment.id + 1, max_id)
        break
      end
    end

    sleep_interval_per_batch = Setting.get("sleep_interval_per_migrate_attachment_batch", nil)&.to_f || 0
    sleep(sleep_interval_per_batch) if update_count > 0
  end

  def self.recompute_attachment_digest(attachment)
    digest = Digest::SHA512.new
    read_bytes = false
    attachment.open do |chunk|
      digest.update(chunk)
      read_bytes ||= chunk.length > 0
    end

    if read_bytes
      attachment.children_and_self.update(md5: digest)
    else
      Rails.logger.warn("unable to read attachment #{attachment.global_id}: #{attachment.errors.inspect}")
    end
  rescue StandardError => e
    Rails.logger.warn("unable to read attachment #{attachment.global_id}: #{e}")
  end

  def self.requeue(*args)
    delay(n_strand: ["DataFixup:MigrateAttachmentDigests", Shard.current.database_server.id],
        priority: Delayed::LOWER_PRIORITY).
      run_for_attachment_range(*args)
  end
end
