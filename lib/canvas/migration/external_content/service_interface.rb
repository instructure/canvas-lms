module Canvas::Migration::ExternalContent
  class ServiceInterface
    class << self
      def validate_service!(service)
        # an external content service should respond to the following methods:
        #
        # applies_to_course?(course)
        #   is the service on for this course?
        #
        # begin_export(course, opts)
        #   tell the service to begin an export
        #   data sent back here will be sent to retrieve_export
        #
        #   if the export is selective, opts[:selective] will be true
        #   and opts[:exported_assets] will be a set of exported asset strings
        #
        # retrieve_export(export_data)
        #   return the data that we need to save in the package
        #
        # send_imported_content(course, imported_content)
        #   give back the translated data for importing
        methods = {
          :applies_to_course? => 1,
          :begin_export => 2,
          :retrieve_export => 1,
          :send_imported_content => 2
        }
        methods.each do |method_name, arity|
          raise "external content service needs to implement #{method_name}" unless service.respond_to?(method_name)
          m = service.method(method_name)
          raise "method #{method_name} should accept #{arity} argument(s)" unless m.arity == arity
        end
      end
    end
  end
end