module Canvas::Migration::ExternalContent
  class Migrator
    class << self

      def registered_services
        @@registered_services ||= {}
      end

      def register_service(key, service)
        key = key.to_url
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

      # retrieves data from each service to be saved as JSON in the exported package
      def retrieve_exported_content(pending_exports)
        exported_content = {}
        pending_exports.each do |key, pending_export|
          service_data = self.registered_services[key].retrieve_export(pending_export)
          exported_content[key] = Canvas::Migration::ExternalContent::Translator.new.translate_data(service_data, :export) if service_data
        end
        exported_content
      end

      # sends back the imported content to the external services
      def send_imported_content(migration, imported_content)
        imported_content = Canvas::Migration::ExternalContent::Translator.new(migration).translate_data(imported_content, :import)
        imported_content.each do |key, content|
          service = self.registered_services[key]
          if service
            begin
              service.send_imported_content(migration.context, content)
            rescue => e
              Canvas::Errors.capture_exception(:external_content_migration, e)
            end
          end
        end
      end
    end
  end
end