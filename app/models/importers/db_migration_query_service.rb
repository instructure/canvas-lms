# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module Importers
  # This class encapsulates the logic to retrieve metadata (for various types of assets)
  # given a migration id. This particular implementation relies on db queries in Canvas
  # but future implementations may rely on a static asset_migration_map
  #
  # Each function returns exactly one id (if available), and nil if an id
  # cannot be resolved
  class DbMigrationQueryService
    def initialize(migration)
      @context = migration.context
      @migration = migration
    end

    def attachment_path_id_lookup
      @migration.attachment_path_id_lookup
    end

    # Returns the path for the context, for a course, it should return something like
    # "courses/1"
    def context_path
      "/#{@context.class.to_s.underscore.pluralize}/#{@context.id}"
    end

    # Looks up a wiki page slug for a migration id
    def convert_wiki_page_migration_id_to_slug(migration_id)
      @context.wiki_pages.where(migration_id:).pick(:url)
    end

    # looks up a discussion topic
    def convert_discussion_topic_migration_id(migration_id)
      @context.discussion_topics.where(migration_id:).pick(:id)
    end

    def convert_context_module_tag_migration_id(migration_id)
      @context.context_module_tags.where(migration_id:).pick(:id)
    end

    def convert_attachment_migration_id(migration_id)
      @context.attachments.where(migration_id:).pick(:id)
    end

    def convert_migration_id(type, migration_id)
      if CanvasLinkMigrator::LinkParser::KNOWN_REFERENCE_TYPES.include? type
        @context.send(type).scope.where(migration_id:).pick(:id)
      end
    end

    def lookup_attachment_by_migration_id(migration_id)
      @context.attachments.find_by(migration_id:)
    end

    def lookup_attachment_by_media_id(media_entry_id)
      @context.attachments.find_by(media_entry_id:)
    end

    def root_folder_name
      Folder.root_folders(@context).first.name
    end

    def process_domain_substitutions(url)
      @migration.process_domain_substitutions(url)
    end

    def context_hosts
      if (account = @migration&.context&.root_account)
        HostUrl.context_hosts(account)
      else
        []
      end
    end

    def report_link_parse_warning(ref_type)
      Sentry.with_scope do |scope|
        scope.set_tags(type: ref_type)
        scope.set_tags(url:)
        Sentry.capture_message("Link Parser failed to validate type", level: :warning)
      end
    end

    def supports_embedded_images
      true
    end

    # Returns a link with a boolean "resolved" property indicating whether the link
    # was actually resolved, or if needs further processing.
    def link_embedded_image(info_match)
      extension = MIME::Types[info_match[:mime_type]]&.first&.extensions&.first
      image_data = Base64.decode64(info_match[:image])
      md5 = Digest::MD5.hexdigest image_data
      folder_name = I18n.t("embedded_images")
      @folder ||= Folder.root_folders(@context).first.sub_folders
                        .where(name: folder_name, workflow_state: "hidden", context: @context).first_or_create!
      filename = "#{md5}.#{extension}"
      file = Tempfile.new([md5, ".#{extension}"])
      file.binmode
      file.write(image_data)
      file.close
      attachment = FileInContext.attach(@context, file.path, display_name: filename, folder: @folder, explicit_filename: filename, md5:)
      {
        resolved: true,
        url: "#{context_path}/files/#{attachment.id}/preview",
      }
    rescue
      {
        resolved: false,
        url: "#{folder_name}/#{filename}"
      }
    end

    def fix_relative_urls?
      # For course copies don't try to fix relative urls. Any url we can
      # correctly alter was changed during the 'export' step
      !@migration&.for_course_copy?
    end
  end
end
