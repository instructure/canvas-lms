# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Importers
  class MediaTrackImporter < Importer
    self.item_class = MediaTrack

    def self.process_migration(data, migration)
      return unless data.present?

      media_attachments = migration.context.attachments.where.not(media_entry_id: nil).preload(:media_object_by_media_id)
      data.each do |file_id, track_list|
        media_attachment = media_attachments.find { |ma| ma.migration_id == file_id }
        next unless (media_object = media_attachment&.media_object_by_media_id)

        media_attachment.mark_as_importing!(migration)
        track_list.each do |track|
          import_from_migration(media_attachment, media_object, track, migration)
        end

        if media_attachment.editing_restricted?(:content)
          media_attachment.media_tracks.where.not(locale: track_list.pluck("locale")).destroy_all
        end
      end
    end

    def self.import_from_migration(attachment, media_object, track, migration)
      content = track["content"]
      if content.blank?
        file = migration.context.attachments.where(migration_id: track[:migration_id]).first
        return unless file

        content = +""
        file.open { |data| content << data }
      end

      mt = attachment.media_tracks.find_or_initialize_by(locale: track["locale"])
      mt.mark_as_importing!(migration)
      return if attachment.downstream_changes?(migration, "media_tracks_content") && !attachment.editing_restricted?(:content)

      mt.kind = track["kind"]
      mt.media_object = media_object
      mt.content = content
      begin
        mt.save!
      rescue => e
        er = Canvas::Errors.capture_exception(:import_media_tracks, e)[:error_report]
        error_message = t("Subtitles (%{lang}) could not be imported for %{file}", lang: track["locale"], file: attachment.display_name)
        migration.add_warning(error_message, error_report_id: er)
      end
      # remove temporary file
      file.destroy if file&.full_path&.starts_with?(File.join(Folder::ROOT_FOLDER_NAME, CC::CCHelper::MEDIA_OBJECTS_FOLDER) + "/")
    end
  end
end
