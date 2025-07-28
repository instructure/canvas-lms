# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require "nokogiri"

module DataFixup::GetMediaFromNotoriousIntoInstfs
  def self.get_it_to_intfs(media_id)
    client = CanvasKaltura::ClientV3.new
    client.startSession(CanvasKaltura::SessionType::ADMIN)
    assets = client.flavorAssetGetByEntryId(media_id)
    media_file_url = client.flavorAssetGetDownloadUrl(assets.last[:id])
    filename = "#{assets.last[:id]}.#{assets.last[:fileExt]}"

    begin
      body = CanvasHttp.get(media_file_url).body
    rescue ArgumentError
      Rails.logger.info "GetMediaFromNotoriousIntoInstfs : failed fetching media at: #{media_file_url}"
    end

    return nil unless body

    File.open(filename, "wb") { |file| file << body }

    res = InstFS.direct_upload(
      file_name: filename,
      file_object: File.open("./#{filename}")
    )

    File.unlink filename

    [res, media_id, File.mime_type(filename)]
  end

  def self.fix_these(ids)
    Attachment.where(id: ids).find_each(strategy: :pluck_ids) do |att|
      media_id = (att.media_entry_id && att.media_entry_id != "maybe") ? att.media_entry_id : MediaObject.where(attachment_id: att.id).where.not(media_id: "maybe").last&.media_id
      if !media_id && att.root_attachment_id
        media_id = MediaObject.where(attachment_id: att.root_attachment_id).where.not(media_id: "maybe").last&.media_id
        media_id ||= att.root_attachment&.media_entry_id if att.root_attachment&.media_entry_id != "maybe"
      end

      unless media_id
        Rails.logger.info "GetMediaFromNotoriousIntoInstfs : No media id for attachment #{att.id}"
        next
      end

      begin
        instfs_uuid, media_entry_id, content_type = get_it_to_intfs(media_id)
        next unless instfs_uuid

        att.update_columns(instfs_uuid:, media_entry_id:, content_type:, updated_at: Time.now.utc)
      rescue NoMethodError
        Rails.logger.info "GetMediaFromNotoriousIntoInstfs : Failed for attachment #{att.id} (#{media_id})"
      end
    end
  end

  def self.run
    Attachment.where(created_at: Date.new(2023, 11, 28)..).where("content_type LIKE ? OR content_type LIKE ?", "%video%", "%audio%").where(instfs_uuid: nil).find_ids_in_batches do |id_batch|
      delay_if_production(
        priority: Delayed::LOW_PRIORITY,
        n_strand: ["DataFixup::GetMediaFromNotoriousIntoInstfs", Shard.current.database_server.id]
      ).fix_these(id_batch)
    end
  end
end
