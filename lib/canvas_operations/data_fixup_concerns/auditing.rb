# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../errors"

module CanvasOperations
  module DataFixupConcerns
    module Auditing
      MAX_CHUNK_SIZE = 5.megabytes
      FIXUP_PREFIX = "instructure_data_fixup"
      RETENTION_WINDOW = 90.days

      def self.extended(base)
        base.include InstanceMethods
      end

      # Whether to record changes made by this datafixup in an Attachment log associated wit the context.
      #
      # Defaults to false and is always false in the test environment.
      def record_changes?
        (@record_changes || false) && auditable_environment?
      end

      # Set whether to record changes made by this datafixup in an Attachment log associated with the context.
      # Defaults to false.
      #
      # @param value [Boolean] true to record changes, false otherwise
      def record_changes=(value)
        raise CanvasOperations::Errors::InvalidPropertyValue, "record_changes must be a boolean" unless [true, false].include?(value)

        @record_changes = value
      end

      def auditable_environment?
        !Rails.env.test?
      end

      module InstanceMethods
        delegate :record_changes?, to: :class

        # Yields a `report_changes` lambda that can be called to record changes
        # that should be tracked during the data fixup operation.
        #
        # This is often useful to create a auditable files that we can use to quickly
        # recover in the event of a bug or unexpected outcome.
        #
        # Results are chunked into 5MB pieces and stored in Attachments associated with
        # the operation's current context.
        def with_attachment_audits(&)
          result = nil
          Tempfile.open do |tempfile|
            # Yield a lambda to record the changes in the audit Attachment.
            yield(lambda do |changes|
              tempfile.write("#{changes}\n")
              tempfile.flush
            end)
          ensure
            result = write_report(tempfile)
          end
          result
        end

        def write_report(tempfile)
          GuardRail.activate(:primary) do
            tempfile.rewind

            index = 0
            file_name = name.underscore.tr("/", "_")
            attachment_ids = Set.new

            return attachment_ids unless tempfile.size.positive?

            while (chunk = tempfile.read(MAX_CHUNK_SIZE))
              chunk_file_name = "#{FIXUP_PREFIX}/#{file_name}/shards/#{switchman_shard.id}.part#{index}"

              attachment = Attachment.new(
                context:,
                filename: chunk_file_name,
                content_type: "text/plain"
              )

              Attachments::Storage.store_for_attachment(attachment, StringIO.new(chunk))

              attachment.save!

              # Cleanup the attachment after the retention window has passed
              delay(
                run_at: RETENTION_WINDOW.from_now,
                n_strand: "data_fixup_audit_cleanup",
                singleton: "data_fixup_audit_cleanup/#{attachment.global_id}"
              ).delete_audit_attachment(attachment)

              attachment_ids << attachment.id
              index += 1
            end

            attachment_ids
          end
        end

        def delete_audit_attachment(attachment)
          attachment.destroy_content
          attachment.destroy_permanently!
        end
      end
    end
  end
end
