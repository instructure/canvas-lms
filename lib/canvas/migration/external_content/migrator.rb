#
# Copyright (C) 2016 - present Instructure, Inc.
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

module Canvas::Migration::ExternalContent
  class Migrator
    class << self

      def registered_services
        @@registered_services ||= {}
      end

      def register_service(key, service)
        raise "service with the key #{key} is already registered" if self.registered_services[key] && self.registered_services[key] != service
        Canvas::Migration::ExternalContent::ServiceInterface.validate_service!(service)
        self.registered_services[key] = service
      end

      # tells the services to begin exporting
      # should return the info we need to go retrieve the exported data later (e.g. a status url)
      def begin_exports(course, opts={})
        pending_exports = {}
        pending_exports.merge!(Lti::ContentMigrationService.begin_exports(course, opts)) if Lti::ContentMigrationService.enabled?
        self.registered_services.each do |key, service|
          if service.applies_to_course?(course)
            begin
              if export = service.begin_export(course, opts)
                pending_exports[key] = export
              end
            rescue => e
              Canvas::Errors.capture_exception(:external_content_migration, e)
            end
          end
        end
        pending_exports
      end

      def retry_delay
        Setting.get('external_content_retry_delay_seconds', '20').to_i.seconds
      end

      def retry_limit
        Setting.get('external_content_retry_limit', '5').to_i
      end

      def retry_block_for_each(pending_keys)
        retry_count = 0

        while pending_keys.any? && retry_count <= retry_limit
          sleep(retry_delay) if retry_count > 0

          pending_keys.each do |service_key|
            begin
              pending_keys.delete(service_key) if yield(service_key)
            rescue => e
              pending_keys.delete(service_key) # don't retry if failed
              Canvas::Errors.capture_exception(:external_content_migration, e)
            end
          end
          retry_count += 1
        end
        if pending_keys.any?
          Canvas::Errors.capture_exception(:external_content_migration,
            "External content migrations timed out for #{pending_keys.join(', ')}")
        end
      end

      # retrieves data from each service to be saved as JSON in the exported package
      def retrieve_exported_content(content_export, pending_exports)
        exported_content = {}

        retry_block_for_each(pending_exports.keys) do |key|
          pending_export = pending_exports[key]

          if export_completed?(pending_export, key)
            service_data = retrieve_export_data(pending_export, key)
            exported_content[key] = Canvas::Migration::ExternalContent::Translator.new(content_export: content_export).translate_data(service_data, :export) if service_data
            true
          end
        end

        exported_content
      end

      # check if the export is completed, will send the message directly to the
      # export object if it can answer the question, otherwise has the source
      # service answer the question.
      def export_completed?(pending_export, key)
        if pending_export.respond_to?(:export_completed?)
          pending_export.export_completed?
        else
          self.registered_services[key].export_completed?(pending_export)
        end
      end

      def retrieve_export_data(pending_export, key)
        if pending_export.respond_to?(:retrieve_export)
          pending_export.retrieve_export
        else
          self.registered_services[key].retrieve_export(pending_export)
        end
      end

      # sends back the imported content to the external services
      def send_imported_content(migration, imported_content)
        imported_content = Canvas::Migration::ExternalContent::Translator.new(content_migration: migration).translate_data(imported_content, :import)

        pending_imports = {}
        imported_content.each do |key, content|
          service = import_service_for(key)
          if service
            begin
              if import = service.send_imported_content(migration.context, migration, content)
                pending_imports[key] = import
              end
            rescue => e
              Canvas::Errors.capture_exception(:external_content_migration, e)
            end
          end
        end
        ensure_imports_completed(pending_imports)
      end

      private def import_service_for(key)
        if Lti::ContentMigrationService::KEY_REGEX  =~ key
          Lti::ContentMigrationService.importer_for(key)
        else
          self.registered_services[key]
        end
      end

      def ensure_imports_completed(pending_imports)
        # keep pinging until they're all finished
        retry_block_for_each(pending_imports.keys) do |key|
          import_data = pending_imports[key]
          if import_data.respond_to?(:import_completed?)
            import_data.import_completed?
          else
            self.registered_services[key].import_completed?(import_data)
          end
        end
      end
    end
  end
end
