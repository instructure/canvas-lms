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
        # export_completed?(export_data)
        #   check to see if the export is ready to be downloaded
        #
        # retrieve_export(export_data)
        #   return the data that we need to save in the package
        #
        # send_imported_content(course, content_migration, imported_content)
        #   gives back the translated data for importing to the service
        #   return information needed to verify import is complete
        #
        # import_completed?(import_data)
        #   verifies that the import completed
        methods = {
          :applies_to_course? => 1,
          :begin_export => 2,
          :export_completed? => 1,
          :retrieve_export => 1,
          :send_imported_content => 3,
          :import_completed? => 1
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
