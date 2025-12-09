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

require_relative "canvas_adapter"

module SwaggerYard
  # Generates OpenAPI 3.0 specification from Canvas YARD documentation
  #
  # Used by: rake doc:openapi
  module OpenApiGenerator
    class << self
      # Main entry point for OpenAPI generation
      #
      # @param output_path [String, Pathname] Where to write the YAML file
      # @param canvas_root [String, Pathname] Path to Canvas root directory
      # @param logger [#puts, nil] Optional logger (defaults to stdout)
      def generate(output_path:, canvas_root:, logger: nil)
        logger ||= StdoutLogger.new

        initialize_generation(canvas_root, logger)
        spec = parse_documentation(canvas_root, logger)
        openapi_spec = build_openapi_spec(spec, logger)
        write_and_summarize(openapi_spec, output_path, logger)

        output_path
      rescue => e
        handle_generation_error(e, logger)
      end

      def initialize_generation(canvas_root, logger)
        logger.puts "🔍 Parsing Canvas YARD documentation..."
        logger.puts "🔌 Installing Canvas SwaggerYard Adapter..."
        SwaggerYard::CanvasAdapter.install!
        configure_swagger_yard(canvas_root)
      end

      def parse_documentation(_canvas_root, logger)
        logger.puts "📖 Parsing YARD documentation with Canvas adapter..."
        SwaggerYard::Specification.new(
          SwaggerYard.config.controller_path,
          SwaggerYard.config.model_path
        )
      end

      def write_and_summarize(openapi_spec, output_path, logger)
        logger.puts "💾 Writing OpenAPI spec to: #{output_path}"
        write_spec(openapi_spec, output_path)
        show_summary(openapi_spec, output_path, logger)
      end

      def handle_generation_error(error, logger)
        logger.puts "❌ Error generating OpenAPI spec: #{error.message}"
        logger.puts error.backtrace.first(10).join("\n")
        raise
      end

      private

      def configure_swagger_yard(canvas_root)
        SwaggerYard.configure do |config|
          config.swagger_version = "3.0.0"
          config.api_version = "1.0.0"
          config.api_base_path = "/api/v1"
          config.title = "Canvas LMS API"
          config.description = "Canvas LMS REST API - Generated from YARD documentation"

          # Point to Canvas controllers
          config.controller_path = File.join(canvas_root, "app/controllers/*_controller.rb")
        end
      end

      def build_openapi_spec(spec, logger)
        openapi_spec = initialize_openapi_spec(spec)
        apply_path_transformations!(openapi_spec, logger)
        apply_schema_fixes!(openapi_spec, logger)
        apply_canvas_enhancements!(openapi_spec, spec, logger)
        openapi_spec
      end

      def initialize_openapi_spec(spec)
        openapi_spec = SwaggerYard::OpenAPI.new(spec).to_h
        JSON.parse(JSON.generate(openapi_spec))
      end

      def apply_path_transformations!(openapi_spec, logger)
        apply_path_cleanup(openapi_spec, logger)
        apply_parameter_fixes(openapi_spec, logger)
      end

      def apply_path_cleanup(openapi_spec, logger)
        logger.puts "🔧 Making operation IDs unique for multi-context routes..."
        make_operation_ids_unique!(openapi_spec)

        logger.puts "🔧 Resolving duplicate paths..."
        resolve_duplicate_paths!(openapi_spec)

        logger.puts "🔧 Removing paths with unresolved template variables..."
        remove_invalid_paths!(openapi_spec)
      end

      def apply_parameter_fixes(openapi_spec, logger)
        logger.puts "🔧 Cleaning up invalid path parameters..."
        cleanup_invalid_path_parameters!(openapi_spec)

        logger.puts "🔧 Ensuring all path parameters are defined..."
        ensure_path_parameters!(openapi_spec)

        logger.puts "🔧 Final verification of path parameters..."
        ensure_path_parameters!(openapi_spec)

        logger.puts "🔧 Applying targeted fixes for specific endpoints..."
        fix_problematic_endpoints!(openapi_spec)
      end

      def apply_schema_fixes!(openapi_spec, logger)
        logger.puts "🔧 Fixing enum type mismatches..."
        fix_enum_types!(openapi_spec)

        logger.puts "🔧 Fixing array schemas without items..."
        fix_array_schemas!(openapi_spec)
      end

      def apply_canvas_enhancements!(openapi_spec, spec, logger)
        enhance_with_canvas_specifics!(openapi_spec)

        logger.puts "🔧 Adding Canvas model schemas to components..."
        add_canvas_schemas!(openapi_spec)

        logger.puts "🔧 Replacing response objects with schema references..."
        replace_responses_with_schema_refs!(openapi_spec)

        logger.puts "🔧 Adding Canvas examples to operations..."
        add_canvas_examples!(openapi_spec, spec)

        logger.puts "🔧 Deduplicating tags..."
        deduplicate_tags!(openapi_spec)
      end

      def make_operation_ids_unique!(openapi_spec)
        operation_id_counts = Hash.new(0)

        # First pass: count occurrences
        openapi_spec["paths"]&.each_value do |methods|
          methods.each_value do |operation|
            next unless operation.is_a?(Hash) && operation["operationId"]

            operation_id_counts[operation["operationId"]] += 1
          end
        end

        # Second pass: add context suffix to duplicates
        seen_operation_ids = {}

        openapi_spec["paths"]&.each do |path, methods|
          methods.each_value do |operation|
            next unless operation.is_a?(Hash) && operation["operationId"]

            operation_id = operation["operationId"]
            if operation_id_counts[operation_id] > 1
              context = detect_path_context(path)
              new_operation_id = "#{operation_id}#{context}"

              # Handle edge case of still-duplicate IDs
              counter = 1
              base_new_operation_id = new_operation_id
              while seen_operation_ids[new_operation_id]
                counter += 1
                new_operation_id = "#{base_new_operation_id}_#{counter}"
              end

              operation["operationId"] = new_operation_id
              seen_operation_ids[new_operation_id] = true
            else
              seen_operation_ids[operation_id] = true
            end
          end
        end
      end

      def detect_path_context(path)
        if %r{^/courses/[^/]+/assignment_groups/}.match?(path)
          "_for_assignment_groups"
        elsif %r{^/courses/[^/]+/}.match?(path)
          "_for_courses"
        elsif %r{^/groups/[^/]+/}.match?(path)
          "_for_groups"
        elsif %r{^/accounts/[^/]+/}.match?(path)
          "_for_accounts"
        elsif %r{^/users/[^/]+/}.match?(path)
          "_for_users"
        else
          "_other"
        end
      end

      def ensure_path_parameters!(openapi_spec)
        openapi_spec["paths"]&.each do |path, methods|
          path_params = extract_path_parameters(path)
          next if path_params.empty?

          ensure_parameters_in_methods(methods, path_params)
        end
      end

      def extract_path_parameters(path)
        path.scan(/\{([^}]+)\}/).flatten
      end

      def ensure_parameters_in_methods(methods, path_params)
        methods.each do |method, operation|
          next unless valid_http_method_operation?(method, operation)
          next if method == "parameters"

          operation["parameters"] ||= []
          add_missing_path_parameters(operation, path_params)
        end
      end

      def add_missing_path_parameters(operation, path_params)
        existing_names = extract_existing_path_param_names(operation)

        path_params.each do |param_name|
          next if existing_names.include?(param_name)

          operation["parameters"].unshift(build_path_parameter(param_name))
        end
      end

      def extract_existing_path_param_names(operation)
        operation["parameters"]
          .select { |p| p.is_a?(Hash) && p["in"] == "path" }
          .filter_map { |p| p["name"] }
      end

      def build_path_parameter(param_name)
        {
          "name" => param_name,
          "in" => "path",
          "required" => true,
          "schema" => { "type" => "string" },
          "description" => "ID of the #{param_name.gsub("_id", "").tr("_", " ")}"
        }
      end

      def resolve_duplicate_paths!(openapi_spec)
        paths_to_merge = {}

        # Group paths that differ only by parameter names
        openapi_spec["paths"]&.each_key do |path|
          # Normalize path by replacing all parameters with a placeholder
          normalized_path = path.gsub(/\{[^}]+\}/, "{param}")

          paths_to_merge[normalized_path] ||= []
          paths_to_merge[normalized_path] << path
        end

        # For each group of duplicate paths, merge them
        paths_to_merge.each_value do |paths|
          next if paths.size <= 1 # No duplicates

          # Keep the first path, merge others into it
          primary_path = paths.first
          paths[1..].each do |duplicate_path|
            # Merge methods from duplicate into primary
            duplicate_methods = openapi_spec["paths"][duplicate_path]

            duplicate_methods&.each do |method, operation|
              # Only merge if the method doesn't already exist in primary
              unless openapi_spec["paths"][primary_path].key?(method)
                openapi_spec["paths"][primary_path][method] = operation
              end
            end

            # Remove the duplicate path
            openapi_spec["paths"].delete(duplicate_path)
          end

          # Standardize parameter names in the primary path
          # Use the most common parameter name pattern
          standardize_path_parameter_names!(openapi_spec, primary_path)
        end
      end

      def standardize_path_parameter_names!(openapi_spec, path)
        methods = openapi_spec["paths"][path]
        return unless methods

        path_params = extract_path_parameters(path)
        return if path_params.empty?

        path_params.each do |param_name|
          next unless param_name == "id"

          better_name = infer_better_parameter_name(path, param_name)
          next unless better_name

          update_path_with_better_name(openapi_spec, path, param_name, better_name)
          return
        end
      end

      def infer_better_parameter_name(path, param_name)
        segments = path.split("/")
        param_segment_index = segments.find_index { |s| s == "{#{param_name}}" }

        return nil unless param_segment_index && param_segment_index > 0

        resource = segments[param_segment_index - 1]
        "#{resource.gsub(/s$/, "")}_id"
      end

      def update_path_with_better_name(openapi_spec, old_path, old_name, new_name)
        new_path = old_path.gsub("{#{old_name}}", "{#{new_name}}")
        return unless new_path != old_path

        openapi_spec["paths"][new_path] = openapi_spec["paths"].delete(old_path)
        update_operation_parameter_names(openapi_spec["paths"][new_path], old_name, new_name)
      end

      def update_operation_parameter_names(methods, old_name, new_name)
        methods.each_value do |operation|
          next unless operation.is_a?(Hash) && operation["parameters"]

          operation["parameters"].each do |param|
            param["name"] = new_name if param["name"] == old_name
          end
        end
      end

      def remove_invalid_paths!(openapi_spec)
        return unless openapi_spec["paths"]

        invalid_paths = []

        openapi_spec["paths"].each_key do |path|
          # Check for unresolved Ruby template variables (#{...})
          if path.include?('#{')
            invalid_paths << path
          end
        end

        # Remove invalid paths
        invalid_paths.each do |path|
          openapi_spec["paths"].delete(path)
        end
      end

      def fix_enum_types!(openapi_spec)
        return unless openapi_spec["paths"]

        openapi_spec["paths"].each_value do |methods|
          methods.each_value do |operation|
            next unless operation.is_a?(Hash)

            # Fix enum types in parameters
            operation["parameters"]&.each do |param|
              fix_enum_in_schema(param["schema"]) if param["schema"]
            end

            # Fix enum types in request body
            if operation["requestBody"]
              operation["requestBody"]["content"]&.each_value do |content|
                fix_enum_in_schema(content["schema"]) if content["schema"]
              end
            end

            # Fix enum types in responses
            operation["responses"]&.each_value do |response|
              next unless response.is_a?(Hash)

              response["content"]&.each_value do |content|
                fix_enum_in_schema(content["schema"]) if content["schema"]
              end
            end
          end
        end
      end

      def fix_enum_in_schema(schema)
        return unless schema.is_a?(Hash)

        # If enum exists and type is array, but enum values are strings
        if schema["enum"] && schema["type"] == "array"
          enum_values = schema["enum"]
          if enum_values.is_a?(Array) && enum_values.all?(String)
            # Convert to proper array enum format or change type to string
            # Most likely this should be a string enum, not array
            schema["type"] = "string"
          end
        end

        # Recursively fix nested schemas
        schema["properties"]&.each_value do |prop_schema|
          fix_enum_in_schema(prop_schema) if prop_schema.is_a?(Hash)
        end

        schema["items"]&.then do |items|
          fix_enum_in_schema(items) if items.is_a?(Hash)
        end

        schema["allOf"]&.each { |s| fix_enum_in_schema(s) if s.is_a?(Hash) }
        schema["anyOf"]&.each { |s| fix_enum_in_schema(s) if s.is_a?(Hash) }
        schema["oneOf"]&.each { |s| fix_enum_in_schema(s) if s.is_a?(Hash) }
      end

      def fix_array_schemas!(openapi_spec)
        return unless openapi_spec["paths"]

        openapi_spec["paths"].each_value do |methods|
          methods.each_value do |operation|
            next unless operation.is_a?(Hash)

            # Fix array schemas in parameters
            operation["parameters"]&.each do |param|
              fix_array_schema_recursive(param["schema"]) if param["schema"]
            end

            # Fix array schemas in request body
            if operation["requestBody"]
              operation["requestBody"]["content"]&.each_value do |content|
                fix_array_schema_recursive(content["schema"]) if content["schema"]
              end
            end

            # Fix array schemas in responses
            operation["responses"]&.each_value do |response|
              next unless response.is_a?(Hash)

              response["content"]&.each_value do |content|
                fix_array_schema_recursive(content["schema"]) if content["schema"]
              end
            end
          end
        end
      end

      def fix_array_schema_recursive(schema)
        return unless schema.is_a?(Hash)

        # If type is array but items is missing, add a generic items definition
        if schema["type"] == "array" && !schema["items"]
          schema["items"] = { "type" => "string" }
        end

        # Recursively fix nested schemas
        schema["properties"]&.each_value do |prop_schema|
          fix_array_schema_recursive(prop_schema) if prop_schema.is_a?(Hash)
        end

        schema["items"]&.then do |items|
          fix_array_schema_recursive(items) if items.is_a?(Hash)
        end

        schema["allOf"]&.each { |s| fix_array_schema_recursive(s) if s.is_a?(Hash) }
        schema["anyOf"]&.each { |s| fix_array_schema_recursive(s) if s.is_a?(Hash) }
        schema["oneOf"]&.each { |s| fix_array_schema_recursive(s) if s.is_a?(Hash) }
      end

      def cleanup_invalid_path_parameters!(openapi_spec)
        return unless openapi_spec["paths"]

        openapi_spec["paths"].each do |path, methods|
          # Extract valid path parameters from the path
          valid_path_params = path.scan(/\{([^}]+)\}/).flatten

          methods.each do |method, operation|
            next unless operation.is_a?(Hash)
            next unless %w[get post put patch delete].include?(method)
            next unless operation["parameters"]

            # Remove path parameters that don't exist in the actual path
            operation["parameters"] = operation["parameters"].reject do |param|
              param["in"] == "path" && !valid_path_params.include?(param["name"])
            end
          end
        end
      end

      def fix_problematic_endpoints!(openapi_spec)
        # Manually fix the enrollments endpoint that keeps losing its user_id parameter
        if openapi_spec["paths"] && openapi_spec["paths"]["/users/{user_id}/enrollments"]
          operation = openapi_spec["paths"]["/users/{user_id}/enrollments"]["get"]
          if operation.is_a?(Hash)
            operation["parameters"] ||= []
            # Check if user_id already exists
            has_user_id = operation["parameters"].any? { |p| p.is_a?(Hash) && p["name"] == "user_id" }

            unless has_user_id
              # Add user_id at the beginning
              operation["parameters"].unshift({
                                                "name" => "user_id",
                                                "in" => "path",
                                                "required" => true,
                                                "schema" => { "type" => "string" },
                                                "description" => "ID of the user"
                                              })
            end
          end
        end
      end

      def add_canvas_examples!(openapi_spec, _spec)
        examples = SwaggerYard::CanvasAdapter.canvas_examples
        return if examples.empty?

        request_added = 0
        response_added = 0

        openapi_spec["paths"]&.each_value do |methods|
          methods.each do |method, operation|
            next unless valid_http_method_operation?(method, operation)

            op_id = operation["operationId"]
            next unless op_id && examples[op_id]

            request_added += 1 if add_request_example(operation, examples[op_id])
            response_added += 1 if add_response_example(operation, examples[op_id])
          end
        end

        request_added + response_added
      end

      def add_request_example(operation, op_examples)
        return 0 unless op_examples[:request] && operation["requestBody"]

        operation["requestBody"]["content"] ||= {}
        operation["requestBody"]["content"]["application/json"] ||= {}
        operation["requestBody"]["description"] ||= ""
        operation["requestBody"]["description"] += "\n\n**Example Request:**\n```\n#{op_examples[:request]}\n```"
        1
      end

      def add_response_example(operation, op_examples)
        return 0 unless op_examples[:response] && operation["responses"]

        response_key = find_success_response_key(operation["responses"])
        return 0 unless response_key && operation["responses"][response_key]

        operation["responses"][response_key]["content"] ||= {}
        operation["responses"][response_key]["content"]["application/json"] ||= {}
        operation["responses"][response_key]["content"]["application/json"]["example"] = op_examples[:response]
        1
      end

      def find_success_response_key(responses)
        responses.keys.find { |k| k.to_s.start_with?("2") } ||
          (responses["default"] ? "default" : nil)
      end

      def deduplicate_tags!(openapi_spec)
        return unless openapi_spec["tags"]

        # Deduplicate tags by name, keeping the first occurrence
        seen_names = Set.new
        openapi_spec["tags"] = openapi_spec["tags"].select do |tag|
          tag_name = tag["name"]
          if seen_names.include?(tag_name)
            false # Skip duplicate
          else
            seen_names.add(tag_name)
            true # Keep first occurrence
          end
        end
      end

      def enhance_with_canvas_specifics!(openapi_spec)
        add_server_config(openapi_spec)
        add_security_config(openapi_spec)
      end

      def add_server_config(openapi_spec)
        openapi_spec["servers"] = [
          {
            "url" => "https://{instance}.instructure.com/api/v1",
            "description" => "Canvas LMS Instance",
            "variables" => {
              "instance" => {
                "default" => "canvas",
                "description" => "Your Canvas instance subdomain"
              }
            }
          }
        ]
      end

      def add_security_config(openapi_spec)
        openapi_spec["components"] ||= {}
        openapi_spec["components"]["securitySchemes"] = {
          "bearer" => {
            "type" => "http",
            "scheme" => "bearer",
            "bearerFormat" => "token",
            "description" => "Canvas API access token"
          }
        }
        openapi_spec["security"] = [{ "bearer" => [] }]
      end

      def add_canvas_schemas!(openapi_spec)
        # Get collected schemas from CanvasAdapter
        schemas = SwaggerYard::CanvasAdapter.canvas_schemas
        return if schemas.empty?

        openapi_spec["components"] ||= {}
        openapi_spec["components"]["schemas"] ||= {}

        # Add each schema to components/schemas
        schemas.each do |schema_name, schema_def|
          openapi_spec["components"]["schemas"][schema_name] = schema_def
        end

        schemas.size
      end

      def replace_responses_with_schema_refs!(openapi_spec)
        operation_models = SwaggerYard::CanvasAdapter.operation_models
        return if operation_models.empty?

        replaced_count = 0
        openapi_spec["paths"]&.each_value do |methods|
          replaced_count += replace_responses_in_methods(methods, operation_models)
        end
        replaced_count
      end

      def replace_responses_in_methods(methods, operation_models)
        replaced_count = 0
        methods.each do |method, operation|
          next unless valid_http_method_operation?(method, operation)

          op_id = operation["operationId"]
          next unless op_id && operation_models[op_id]

          replaced_count += replace_responses_in_operation(operation, operation_models[op_id])
        end
        replaced_count
      end

      def replace_responses_in_operation(operation, op_models)
        replaced_count = 0
        operation["responses"]&.each do |status, response|
          next unless response.is_a?(Hash)

          model_info = find_model_info_for_status(op_models, status)
          next unless model_info && json_content?(response)

          response["content"]["application/json"]["schema"] = build_schema_ref(model_info)
          replaced_count += 1
        end
        replaced_count
      end

      def find_model_info_for_status(op_models, status)
        op_models[status] ||
          ((status == "default") ? op_models["200"] : nil) ||
          ((status == "200") ? op_models["default"] : nil)
      end

      def json_content?(response)
        response["content"] &&
          response["content"]["application/json"] &&
          response["content"]["application/json"]["schema"]
      end

      def build_schema_ref(model_info)
        if model_info[:is_array]
          {
            "type" => "array",
            "items" => { "$ref" => "#/components/schemas/#{model_info[:model]}" }
          }
        else
          { "$ref" => "#/components/schemas/#{model_info[:model]}" }
        end
      end

      def valid_http_method_operation?(method, operation)
        operation.is_a?(Hash) && %w[get post put patch delete].include?(method)
      end

      def write_spec(openapi_spec, output_path)
        FileUtils.mkdir_p(File.dirname(output_path))
        File.write(output_path, YAML.dump(openapi_spec))
      end

      def show_summary(openapi_spec, output_path, logger)
        paths_count = openapi_spec["paths"]&.size || 0
        schemas_count = openapi_spec.dig("components", "schemas")&.size || 0

        logger.puts ""
        logger.puts "=" * 60
        logger.puts "✅ Successfully generated OpenAPI spec!"
        logger.puts "=" * 60
        logger.puts "📊 Endpoints: #{paths_count}"
        logger.puts "📦 Schemas: #{schemas_count}"
        logger.puts "📁 Output: #{output_path}"
        logger.puts "=" * 60
      end

      # Simple logger that writes to stdout
      class StdoutLogger
        def puts(*)
          $stdout.puts(*)
        end
      end
    end
  end
end
