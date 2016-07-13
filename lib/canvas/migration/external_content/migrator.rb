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
        self.registered_services.each do |key, service|
          if service.applies_to_course?(course)
            begin
              pending_exports[key] = service.begin_export(course, opts)
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
      def retrieve_exported_content(pending_exports)
        exported_content = {}

        retry_block_for_each(pending_exports.keys) do |key|
          pending_export = pending_exports[key]
          service = self.registered_services[key]

          if service.export_completed?(pending_export)
            service_data = service.retrieve_export(pending_export)
            exported_content[key] = Canvas::Migration::ExternalContent::Translator.new.translate_data(service_data, :export) if service_data
            true
          end
        end

        exported_content
      end

      # sends back the imported content to the external services
      def send_imported_content(migration, imported_content)
        imported_content = Canvas::Migration::ExternalContent::Translator.new(migration).translate_data(imported_content, :import)

        pending_imports = {}
        imported_content.each do |key, content|
          service = self.registered_services[key]
          if service
            begin
              if import = service.send_imported_content(migration.context, content)
                pending_imports[key] = import
              end
            rescue => e
              Canvas::Errors.capture_exception(:external_content_migration, e)
            end
          end
        end
        ensure_imports_completed(pending_imports)
      end

      def ensure_imports_completed(pending_imports)
        # keep pinging until they're all finished
        retry_block_for_each(pending_imports.keys) do |key|
          self.registered_services[key].import_completed?(pending_imports[key])
        end
      end
    end
  end
end