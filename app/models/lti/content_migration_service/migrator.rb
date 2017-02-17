# Copyright (C) 2016 Instructure, Inc.
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

module Lti
  module ContentMigrationService
    class Migrator
      FAILED_STATUS = 'failed'.freeze
      JWT_LIFETIME = 30.seconds
      SUCCESSFUL_STATUS = 'completed'.freeze
      private_constant :FAILED_STATUS, :JWT_LIFETIME, :SUCCESSFUL_STATUS

      private

      def expanded_variables
        return @expanded_variabled if @expanded_variables
        variable_expander = Lti::VariableExpander.new(root_account, @course, nil, tool: @tool)
        @expanded_variables = variable_expander.expand_variables!(
          @tool.set_custom_fields('content_migration')
        )
      end

      def generate_jwt
        key = JSON::JWK.new({k: @tool.shared_secret, kid: @tool.consumer_key, kty: 'oct'})
        Canvas::Security.create_jwt({}, JWT_LIFETIME.from_now, key)
      end

      def base_request_headers
        {'Authorization' => "Bearer #{generate_jwt}"}
      end

      def root_account
        @course.root_account
      end
    end
  end
end

