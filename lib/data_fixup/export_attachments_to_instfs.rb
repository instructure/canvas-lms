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

# this datafixup is not intended to have a corresponding migration. it will be
# manually applied to selected accounts, and then eventually run on the
# remainder
module DataFixup
  module ExportAttachmentsToInstfs
    def self.run(root_account, batch_size: 1000, sleep_interval_per_batch: nil)
      root_account.shard.activate do
        raise ArgumentError unless InstFS.enabled?
        importable_attachments = Attachment.where(instfs_uuid: nil).where("md5 IS NOT NULL")
        importable_attachments.find_ids_in_ranges(batch_size: batch_size) do |start_id, end_id|
          batch = importable_attachments.where(id: start_id..end_id)
          references = self.post_to_instfs({
            objectStore: self.object_store,
            references: batch.map{ |attachment| self.reference_from_attachment(attachment, root_account.global_id) }
          })
          batch.each_with_index{ |attachment, i| update_attachment(attachment, references[i]) }
          sleep(sleep_interval_per_batch) if sleep_interval_per_batch
        end
      end
    end

    def self.object_store
      if Attachment.s3_storage?
        region = Attachment.s3_config[:region]
        return {
          "type": "s3",
          "params": {
            "host": Aws::Partitions::EndpointProvider.resolve(region, 's3'),
            "bucket": Attachment.s3_config[:bucket_name]
          }
        }
      else
        raise NotImplementedError
      end
    end

    def self.reference_from_attachment(attachment, root_account_id)
      data = {
        "storeKey": attachment.full_filename,
        "timestamp": attachment.created_at.to_i,
        "md5":  attachment.md5,
        "filename": attachment.filename,
        "content_type": attachment.content_type,
        "size": attachment.size,
        "root_account_id": root_account_id.to_s,
      }
      # don't send nil fields
      if attachment.global_user_id
        data["user_id"] = attachment.global_user_id.to_s
      end
      if attachment.encoding
        data["encoding"] = attachment.encoding
      end

      # fallback for display_name
      if attachment.display_name
        data["displayName"] = attachment.display_name
      else
        data["displayName"] = attachment.filename
      end

      data
    end

    def self.post_to_instfs(payload)
      response = CanvasHttp.post(
        InstFS.export_references_url,
        body: payload.to_json,
        content_type: "application/json"
      )
      if response.is_a?(Net::HTTPSuccess)
        return JSON.parse(response.body)["success"]
      else
        raise "InstFS returned an error on Attachment import: #{JSON.parse(response.body)}"
      end
    end

    def self.update_attachment(attachment, reference)
      attachment.update(instfs_uuid: reference["id"])
    end
  end
end