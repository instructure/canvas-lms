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
#

begin
  require "swagger_yard"
  require_relative "../swagger_yard/open_api_generator"

  namespace :doc do
    desc "Generate OpenAPI 3.0 specification (requires DB) - Usage: rake doc:openapi[output_path]"
    task :openapi, [:output_path] => :environment do |_t, args|
      # This task loads routes from TokenScopes (requires DB)
      # and generates the OpenAPI spec in one step

      # Use custom output path if provided, otherwise use default
      if args[:output_path]
        output_path = File.expand_path(args[:output_path])
      else
        output_dir = File.join(Dir.pwd, "public/doc/openapi")
        output_path = File.join(output_dir, "canvas.openapi.yaml")
      end

      SwaggerYard::OpenApiGenerator.generate(
        output_path:,
        canvas_root: Dir.pwd
      )
    end
  end
rescue LoadError
  # swagger_yard not available
  nil
end
