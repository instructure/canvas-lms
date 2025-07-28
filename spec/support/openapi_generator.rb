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
#

module OpenApiGenerator
  def self.generate(running_context, example)
    # remove when INTEROP-8721 is done
    return unless running_context.response.code == "200"

    # This looks at the "request" variable that is available
    # inside of the test ("running_context"). It will throw an exception
    # if the test has a request variable defined that is not actually
    # an HTTP request object.
    # rubocop:disable Style/RedundantBegin
    begin
      # rubocop:enable Style/RedundantBegin
      CanvasRails::Application.routes.router.recognize(running_context.request) do |route|
        controller_name = route.defaults[:controller]
        openapi_doc_file_location = "spec/openapi/#{controller_name}.yaml"
        record = RSpec::OpenAPI::RecordBuilder.build(running_context, example:)
        RSpec::OpenAPI.path_records[openapi_doc_file_location] << record if record
      end
    rescue NoMethodError
      # If we are here, a request variable was defined in the test but
      # it wasn't readable as an HTTP request, or for some reason didn't
      # map to a route. This is fine; we won't document this one.
    end
  end
end
