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

# Canvas → SwaggerYard adapter for SwaggerYard 1.1.1
# - Registers Canvas-style YARD tags (@API, @argument, @returns, @model)
# - Patches SwaggerYard::Operation to handle Canvas tags
#
# This adapter allows SwaggerYard to parse Canvas's existing YARD documentation
# and generate OpenAPI 3.0 specifications from it.

require "swagger_yard"
require "yard"

module SwaggerYard
  module CanvasAdapter
    # Storage for examples to be added during OpenAPI post-processing
    @canvas_examples = {}

    # Storage for model schemas collected from @model tags
    @canvas_schemas = {}

    # Storage for tracking which operations return which models
    # Format: { operation_id => { response_status => model_name } }
    @operation_models = {}

    class << self
      attr_accessor :canvas_examples, :canvas_schemas, :operation_models
    end

    TAGS = {
      API: { name: "Canvas API summary", handler: :API },
      argument: { name: "Canvas argument", handler: :argument },
      returns: { name: "Canvas returns", handler: :returns },
      model: { name: "Canvas model", handler: :model },
      example_request: { name: "Example request", handler: :example_request },
      example_response: { name: "Example response", handler: :example_response },
    }.freeze

    # Public: call once before building the spec
    def self.install!
      define_canvas_tags
      load_canvas_routes!
      patch_api_group!
      patch_operation!
      collect_model_schemas!
    end

    # Load Canvas routes to map controller#action to actual route paths
    # Uses TokenScopes.api_routes_for_openapi_docs to extract routes
    def self.load_canvas_routes!
      @canvas_routes = {}
      @canvas_examples = {} # Reset examples storage
      @canvas_schemas = {} # Reset schemas storage
      @operation_models = {} # Reset operation model tracking
      load_routes_from_api_route_set!
    end

    # Load routes directly from TokenScopes (requires DB)
    def self.load_routes_from_api_route_set!
      # rubocop:disable Rails/Output
      puts "📍 Loading routes from TokenScopes API..."

      # This requires database access
      routes_by_action = TokenScopes.api_routes_for_openapi_docs

      process_routes_by_action(routes_by_action)
      log_routes_summary("TokenScopes")
      # rubocop:enable Rails/Output
    end

    def self.process_routes_by_action(routes_by_action)
      routes_by_action.each do |action_name, routes|
        routes.each do |route|
          process_single_route(action_name, route)
        end
      end
    end

    def self.process_single_route(action_name, route)
      path = normalize_route_path(route[:path])
      methods = extract_http_methods(route[:method])

      methods.each do |method|
        add_route_entry(action_name, path, method)
      end
    end

    def self.normalize_route_path(path)
      path = path.sub(%r{^/api/(v1|sis|quiz/v1|lti/v1|lti)}, "")
      path.gsub(/:(\w+)/, '{\1}')
    end

    def self.extract_http_methods(verb)
      methods = verb.to_s.split("|").map(&:strip).reject(&:empty?)
      methods.empty? ? ["GET"] : methods
    end

    def self.add_route_entry(action_name, path, method)
      @canvas_routes[action_name] ||= []
      route_entry = {
        method: method.upcase,
        path:,
        context: detect_context_from_path(path)
      }

      return if route_exists?(@canvas_routes[action_name], path, method)

      @canvas_routes[action_name] << route_entry
    end

    def self.route_exists?(routes, path, method)
      routes.any? { |r| r[:path] == path && r[:method] == method.upcase }
    end

    def self.log_routes_summary(source = "TokenScopes")
      # rubocop:disable Rails/Output
      total_routes = @canvas_routes.values.sum(&:size)
      puts "   Loaded #{total_routes} API routes from #{source} (#{@canvas_routes.size} controller#action pairs)"
      # rubocop:enable Rails/Output
    end

    def self.canvas_routes
      @canvas_routes ||= {}
    end

    # Collect all @model definitions from controller files
    def self.collect_model_schemas!
      # rubocop:disable Rails/Output
      puts "📦 Collecting @model schemas from controllers..."

      # Include subdirectories like app/controllers/lti/*
      root_path = (defined?(Rails) && Rails.respond_to?(:root)) ? Rails.root : Dir.pwd
      controller_files = Dir.glob(File.join(root_path, "app/controllers/**/*_controller.rb"))

      controller_files.each do |file_path|
        # Parse the file with YARD
        YARD::Registry.clear
        YARD.parse(file_path, [], YARD::Logger::ERROR)

        # Look through all documented objects
        # rubocop:disable Rails/FindEach
        YARD::Registry.all.each do |yard_object|
          # Process @model tags
          yard_object.docstring.tags(:model).each do |model_tag|
            extract_and_store_model_schema(model_tag)
          end
        end
        # rubocop:enable Rails/FindEach
      rescue
        # Silently skip files that can't be parsed
        next
      end

      puts "   Collected #{@canvas_schemas.size} model schemas from controllers"

      # Also load schemas from lib/schemas/docs/**/*.rb
      collect_schemas_from_lib(root_path)

      puts "   Total schemas: #{@canvas_schemas.size}"
      # rubocop:enable Rails/Output
    end

    # Load schemas from lib/schemas/docs/**/*.rb
    def self.collect_schemas_from_lib(root_path)
      # rubocop:disable Rails/Output
      puts "📦 Loading schemas from lib/schemas/docs/..."

      # First, ensure base schema is loaded
      base_schema_path = File.join(root_path, "lib/schemas/base.rb")
      require base_schema_path if File.exist?(base_schema_path)

      schema_files = Dir.glob(File.join(root_path, "lib/schemas/docs/**/*.rb"))
      loaded_count = 0

      schema_files.each do |file_path|
        schema_loaded = load_schema_from_file(file_path)
        loaded_count += 1 if schema_loaded
      rescue
        # Skip files that can't be loaded
        # Uncomment for debugging: puts "   Warning: Could not load schema from #{file_path}: #{e.message}"
      end

      puts "   Loaded #{loaded_count} schemas from lib/schemas/docs/"
      # rubocop:enable Rails/Output
    end

    def self.load_schema_from_file(file_path)
      # Infer class name from file path
      # e.g., lib/schemas/docs/user.rb -> User
      relative_path = file_path.split("lib/schemas/docs/").last
      class_name = relative_path.gsub("/", "::").gsub(".rb", "").split("::").map(&:camelize).join("::")

      # Require the file - we're in a rake task context so this is safe
      require file_path

      # Get the full class name with module
      full_class_name = "Schemas::Docs::#{class_name}"
      schema_class = Object.const_get(full_class_name)

      if schema_class.respond_to?(:schema)
        schema = schema_class.schema

        # Convert symbol keys to strings for JSON processing
        schema_hash = deep_stringify_keys(schema)

        # Extract schema name
        schema_name = schema_hash["id"] || class_name

        # Convert to OpenAPI format
        openapi_schema = convert_canvas_schema_to_openapi(schema_hash)

        # Store it
        @canvas_schemas[sanitize_schema_name(schema_name)] = openapi_schema

        return true
      end

      false
    rescue => e
      # Skip files with errors - might be missing dependencies
      # rubocop:disable Rails/Output
      puts "   Warning: Could not load #{file_path}: #{e.class} - #{e.message}"
      # rubocop:enable Rails/Output
      false
    end

    def self.deep_stringify_keys(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(key, value), result|
          result[key.to_s] = deep_stringify_keys(value)
        end
      when Array
        obj.map { |item| deep_stringify_keys(item) }
      else
        obj
      end
    end

    # Extract schema from @model tag and store it
    def self.extract_and_store_model_schema(model_tag)
      model_name = model_tag.name
      schema_text = model_tag.text.to_s.strip

      return if model_name.blank? || schema_text.blank?

      parse_and_store_schema(model_name, schema_text)
    end

    def self.parse_and_store_schema(model_name, schema_text)
      cleaned_text = clean_schema_text(schema_text)
      schema_json = JSON.parse(cleaned_text)

      openapi_schema = convert_canvas_schema_to_openapi(schema_json)
      sanitized_name = sanitize_schema_name(model_name)

      @canvas_schemas[sanitized_name] = openapi_schema
    rescue JSON::ParserError
      # If parsing fails, skip this model
      # puts "   Warning: Could not parse schema for model #{model_name}: #{e.message}"
    end

    def self.clean_schema_text(schema_text)
      cleaned = schema_text.gsub(/^#\s*/, "")
      cleaned.gsub("::", "_")
    end

    # Sanitize schema names to be OpenAPI compliant
    # Component names can only contain: A-Z a-z 0-9 - . _
    def self.sanitize_schema_name(name)
      # Replace :: with _ (namespace separator)
      name.to_s.gsub("::", "_")
    end

    # Clean up schema type conflicts (e.g., object with items field)
    def self.clean_schema_type_conflicts(schema)
      return unless schema.is_a?(Hash)

      # If this has both type and items, and type is not array, remove items
      if schema["type"] && schema["items"] && schema["type"] != "array"
        schema.delete("items")
      end

      # Recursively clean properties
      schema["properties"]&.each_value do |prop|
        clean_schema_type_conflicts(prop) if prop.is_a?(Hash)
      end

      # Recursively clean items
      if schema["items"]
        clean_schema_type_conflicts(schema["items"]) if schema["items"].is_a?(Hash)
      end

      # Clean allOf, anyOf, oneOf
      %w[allOf anyOf oneOf].each do |key|
        next unless schema[key].is_a?(Array)

        schema[key].each do |sub_schema|
          clean_schema_type_conflicts(sub_schema) if sub_schema.is_a?(Hash)
        end
      end
    end

    # Recursively fix all $ref values in a schema to ensure they have proper JSON pointer format
    def self.fix_refs_recursive(obj)
      case obj
      when Hash
        obj.transform_values do |value|
          # If this is a $ref key, ensure it has the proper prefix
          if obj.key?("$ref") && obj["$ref"].is_a?(String)
            ref_value = obj["$ref"]
            # Only fix if it doesn't already have the prefix
            unless ref_value.start_with?("#/components/schemas/")
              sanitized_name = sanitize_schema_name(ref_value)
              return { "$ref" => "#/components/schemas/#{sanitized_name}" }
            end
          end
          # Recursively process nested structures
          fix_refs_recursive(value)
        end
      when Array
        obj.map { |item| fix_refs_recursive(item) }
      else
        obj
      end
    end

    # Convert Canvas JSON schema format to OpenAPI 3.0 format
    def self.convert_canvas_schema_to_openapi(canvas_schema)
      openapi_schema = {
        "type" => "object"
      }

      # Copy properties
      if canvas_schema["properties"]
        openapi_schema["properties"] = convert_properties(canvas_schema["properties"])
      end

      # Copy required fields - ensure it's an array
      if canvas_schema["required"]
        required = canvas_schema["required"]
        openapi_schema["required"] = required.is_a?(String) ? [required] : required
      end

      # Copy description
      openapi_schema["description"] = canvas_schema["description"] if canvas_schema["description"]

      # Fix type/items conflicts (objects shouldn't have items)
      clean_schema_type_conflicts(openapi_schema)

      # Fix any malformed $ref values recursively
      fix_refs_recursive(openapi_schema)
    end

    # Convert properties from Canvas format to OpenAPI format
    def self.convert_properties(properties)
      properties.transform_values do |prop_def|
        convert_single_property(prop_def)
      end
    end

    def self.convert_single_property(prop_def)
      return { "$ref" => "#/components/schemas/#{sanitize_schema_name(prop_def["$ref"])}" } if prop_def["$ref"]

      converted_prop = {}
      convert_property_type(converted_prop, prop_def)
      copy_basic_property_fields(converted_prop, prop_def)

      # Handle enums and items carefully for arrays
      if converted_prop["type"] == "array"
        # For arrays, handle items first, then apply enum to items if present
        handle_property_items(converted_prop, prop_def)
        handle_array_enum(converted_prop, prop_def)
      else
        # For non-arrays, apply enum directly
        handle_property_enum(converted_prop, prop_def)
        handle_property_items(converted_prop, prop_def)
      end

      converted_prop
    end

    def self.convert_property_type(converted_prop, prop_def)
      prop_type = prop_def["type"]
      return unless prop_type

      if prop_type.is_a?(Array)
        handle_array_types(converted_prop, prop_type)
      else
        handle_single_type(converted_prop, prop_type)
      end
    end

    def self.handle_array_types(converted_prop, types)
      types = types.map { |t| t.to_s.downcase }

      if types.include?("null")
        handle_nullable_type(converted_prop, types)
      else
        converted_prop["type"] = convert_single_type(types.first)
      end
    end

    def self.handle_nullable_type(converted_prop, types)
      non_null_types = types.reject { |t| t == "null" }
      return unless non_null_types.any?

      first_type = non_null_types.first
      converted_prop["type"] = convert_single_type(first_type)
      converted_prop["nullable"] = true
      add_format_for_special_type(converted_prop, first_type)
    end

    def self.add_format_for_special_type(converted_prop, type)
      case type
      when "datetime", "date-time"
        converted_prop["format"] = "date-time"
      when "date"
        converted_prop["format"] = "date"
      when "uuid"
        converted_prop["format"] = "uuid"
      end
    end

    def self.handle_single_type(converted_prop, type)
      type = type.to_s.downcase
      case type
      when "datetime", "date-time"
        converted_prop["type"] = "string"
        converted_prop["format"] = "date-time"
      when "date"
        converted_prop["type"] = "string"
        converted_prop["format"] = "date"
      when "uuid"
        converted_prop["type"] = "string"
        converted_prop["format"] = "uuid"
      else
        converted_prop["type"] = type
      end
    end

    def self.copy_basic_property_fields(converted_prop, prop_def)
      converted_prop["description"] = prop_def["description"] if prop_def["description"]
      converted_prop["example"] = prop_def["example"] if prop_def["example"]
      converted_prop["format"] = prop_def["format"] if prop_def["format"] && !converted_prop["format"]
    end

    def self.handle_property_enum(converted_prop, prop_def)
      return unless prop_def["allowableValues"] && prop_def["allowableValues"]["values"]

      converted_prop["enum"] = prop_def["allowableValues"]["values"]
    end

    def self.handle_array_enum(converted_prop, prop_def)
      return unless prop_def["allowableValues"] && prop_def["allowableValues"]["values"]

      # For arrays, enum goes on items, not the array itself
      if converted_prop["items"]
        # If items already exist, add enum to them
        if converted_prop["items"].is_a?(Hash)
          converted_prop["items"]["enum"] = prop_def["allowableValues"]["values"]
        end
      else
        # If no items exist yet, create items with enum
        converted_prop["items"] = {
          "type" => "string",
          "enum" => prop_def["allowableValues"]["values"]
        }
      end
    end

    def self.handle_property_items(converted_prop, prop_def)
      if prop_def["items"]
        converted_prop["items"] = convert_array_items(prop_def["items"])
      elsif converted_prop["type"] == "array"
        converted_prop["items"] = { "type" => "object" }
      end
    end

    def self.convert_array_items(items)
      if items["$ref"]
        { "$ref" => "#/components/schemas/#{sanitize_schema_name(items["$ref"])}" }
      elsif items["type"]
        convert_item_type(items["type"], items)
      else
        items
      end
    end

    def self.convert_item_type(item_type, items)
      case item_type.to_s.downcase
      when "datetime", "date-time"
        { "type" => "string", "format" => "date-time" }
      when "date"
        { "type" => "string", "format" => "date" }
      else
        items
      end
    end

    # Helper to convert single type string to OpenAPI type
    def self.convert_single_type(type)
      case type.to_s.downcase
      when "datetime", "date-time", "date", "uuid"
        "string"
      else
        type
      end
    end

    # Detect context (courses, groups, accounts, users) from path
    def self.detect_context_from_path(path)
      case path
      when %r{^/courses/} then :courses
      when %r{^/groups/} then :groups
      when %r{^/accounts/} then :accounts
      when %r{^/users/} then :users
      else :other
      end
    end

    class << self
      private

      def define_canvas_tags
        # Register Canvas tags with YARD
        YARD::Tags::Library.define_tag(TAGS[:API][:name], :API)
        YARD::Tags::Library.define_tag(TAGS[:argument][:name], :argument, :with_types_and_name)
        YARD::Tags::Library.define_tag(TAGS[:returns][:name], :returns, :with_types)
        YARD::Tags::Library.define_tag(TAGS[:model][:name], :model, :with_types_and_name)
        YARD::Tags::Library.define_tag(TAGS[:example_request][:name], :example_request)
        YARD::Tags::Library.define_tag(TAGS[:example_response][:name], :example_response)
      end

      # Patch SwaggerYard::ApiGroup to auto-generate @resource from class name
      def patch_api_group!
        SwaggerYard::ApiGroup.prepend(Module.new do
          def add_info(yard_object)
            super

            # Canvas doesn't use @resource tags. Instead, the resource name is defined
            # in @API tags (e.g., "@API Users", "@API Courses"). SwaggerYard needs a
            # @resource for grouping operations, so we generate it from the class name.
            # Note: This typically matches the resource name used in @API tags within
            # the controller (e.g., UsersController uses "@API Users" → both become "Users")
            if yard_object.type == :class
              class_name = yard_object.name.to_s
              # Only remove 'Controller' suffix, keep 'Api' as it's meaningful
              # e.g., AssignmentsApiController → AssignmentsApi
              @resource = class_name.sub(/Controller$/, "")
            end
          end

          def add_path_item(yard_object)
            paths = paths_from_yard_object_canvas(yard_object)
            return if paths.blank?

            # Generate path items for ALL routes (e.g., both courses and groups)
            paths.each do |path_info|
              path = path_info[:path]
              http_method = path_info[:http_method]
              path_info[:context]

              path_item = (path_items[path] ||= SwaggerYard::PathItem.new(self))

              # Add @path tag to yard_object so SwaggerYard processes it
              yard_object.add_tag(YARD::Tags::Tag.new("path", path, [http_method]))

              path_item.add_operation(yard_object)
            end

            paths.first[:path] # Return first path for compatibility
          end

          private

          def paths_from_yard_object_canvas(yard_object)
            # Canvas methods use @API tags; infer path and method from routes
            api_tag = yard_object.docstring.tags(:API).first
            return nil unless api_tag # Skip methods without @API

            # Get method name and controller
            method_name = yard_object.name.to_s
            class_name_str = @class_name.to_s

            # Handle nested classes like UsersController::ServiceCredentials
            # For nested classes, use the parent controller name
            if class_name_str.include?("::")
              class_name_str = class_name_str.split("::").first
            end

            controller_name = underscore(class_name_str).sub(/_controller$/, "")

            # Find routes from Canvas routes.rb
            route_key = "#{controller_name}##{method_name}"
            route_infos = SwaggerYard::CanvasAdapter.canvas_routes[route_key]

            return nil unless route_infos.is_a?(Array) && !route_infos.empty?

            # Return ALL routes for this controller#action
            route_infos.map do |route_info|
              {
                path: route_info[:path],
                http_method: route_info[:method],
                context: route_info[:context]
              }
            end
          end

          def underscore(str)
            str.gsub("::", "/")
               .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
               .gsub(/([a-z\d])([A-Z])/, '\1_\2')
               .tr("-", "_")
               .downcase
          end
        end)
      end

      # Patch SwaggerYard::Operation.from_yard_object to handle Canvas tags
      def patch_operation!
        SwaggerYard::Operation.singleton_class.prepend(Module.new do
          def from_yard_object(yard_object, path_item)
            # Call original method
            operation = super

            # Process Canvas tags
            process_canvas_tags(yard_object, operation)

            operation
          end

          private

          def process_canvas_tags(yard_object, operation)
            ds = yard_object.docstring
            return unless ds

            process_api_tag(ds, operation)
            process_argument_tags(ds, operation)
            process_returns_tags(ds, operation)
            add_pagination_parameters_if_needed(ds, operation, yard_object)
            process_example_tags(ds, operation)
          end

          def process_api_tag(docstring, operation)
            api_tag = docstring.tags(:API).first
            return unless api_tag

            lines = api_tag.text.to_s.strip.split(/\r?\n/)
            summary = lines.shift&.strip
            desc = lines.join("\n").strip

            operation.summary = summary unless summary.blank?
            unless desc.empty?
              operation.description = [operation.description, desc].reject(&:empty?).join("\n\n")
            end
          end

          def process_argument_tags(docstring, operation)
            body_params = []

            docstring.tags(:argument).each do |tag|
              param_info = extract_param_info_from_tag(tag)
              add_parameter_to_operation(param_info, operation, body_params)
            end

            add_request_body_if_needed(body_params, operation)
          end

          def extract_param_info_from_tag(tag)
            name = tag.name
            types = (tag.types || ["String"]).map(&:to_s)
            desc = tag.text.to_s.strip

            name, types = normalize_nested_param_name(name, types, desc)
            is_array = name.end_with?("[]")
            clean_name = is_array ? name.chomp("[]") : name

            {
              name: clean_name,
              original_name: name,
              types:,
              description: desc,
              is_array:
            }
          end

          def normalize_nested_param_name(name, types, desc)
            first_type = types.first
            return [name, types] unless first_type
            return [name, types] if first_type.match?(/^(String|Integer|Float|Number|Boolean|Array|Hash|Object|DateTime|Date|Time|Numeric|nil|optional|required)$/i)

            # YARD parser treats brackets as type notation
            # @argument account_notification[subject] → name="account_notification", types=["subject", ...]
            # Reconstruct the full parameter name
            full_name = "#{name}[#{first_type}]"
            remaining_types = types[1..] || []

            # Parse actual types from description text
            if desc =~ /^\[([^\]]+)\]/
              type_str = $1
              remaining_types = type_str.split(",").map(&:strip).reject(&:empty?)
            end

            [full_name, remaining_types]
          end

          def add_parameter_to_operation(param_info, operation, body_params)
            location = infer_param_location(param_info[:name], operation)
            schema = build_param_schema(param_info)
            required = required_param?(param_info[:types], param_info[:description])

            case location
            when :path
              add_path_parameter(operation, param_info, schema)
            when :query
              add_query_parameter(operation, param_info, schema, required)
            when :body
              add_body_parameter(body_params, param_info, schema, required)
            end
          end

          def build_param_schema(param_info)
            base_schema = map_types_to_schema(param_info[:types])
            param_info[:is_array] ? "array<#{base_schema}>" : base_schema
          end

          def add_path_parameter(operation, param_info, schema)
            param = create_parameter(param_info[:name], "path", schema, param_info[:description], true)
            operation.add_or_update_parameter(param)
          end

          def add_query_parameter(operation, param_info, schema, required)
            param = create_parameter(param_info[:name], "query", schema, param_info[:description], required)
            operation.add_or_update_parameter(param)
          end

          def add_body_parameter(body_params, param_info, schema, required)
            body_params << {
              name: param_info[:name],
              original_name: param_info[:original_name],
              schema:,
              description: param_info[:description],
              required:
            }
          end

          def add_request_body_if_needed(body_params, operation)
            return if body_params.empty?

            body_schema = build_request_body_schema(body_params)
            body_param = create_body_parameter(body_schema)
            operation.add_or_update_parameter(body_param)
          end

          def process_returns_tags(docstring, operation)
            docstring.tags(:returns).each do |tag|
              types = tag.types || ["String"]
              desc = tag.text.to_s.strip

              # Extract model name from types before building schema
              model_name = extract_model_name_from_types(types)

              response_schema = build_response_schema(types, desc)
              response_type = SwaggerYard::Type.new(response_schema)
              operation.add_response_type(response_type, desc)

              # Track the model usage for this operation if we found one
              if model_name
                track_operation_model(operation.operation_id, model_name, response_schema)
              end
            end
          end

          def add_pagination_parameters_if_needed(_docstring, operation, yard_object)
            # Only add pagination to GET requests
            return unless operation.http_method.to_s.upcase == "GET"

            # Check if page/per_page parameters already exist (explicitly documented)
            existing_params = operation.parameters.map { |p| p.name.to_s }
            has_page = existing_params.include?("page")
            has_per_page = existing_params.include?("per_page")

            # If already documented, don't add
            return if has_page && has_per_page

            # Check if the controller method uses Api.paginate() by examining the method source
            should_paginate = method_uses_pagination?(yard_object)

            return unless should_paginate

            # Add page parameter if missing
            unless has_page
              page_param = create_parameter(
                "page",
                "query",
                "integer",
                "The page number to return. Defaults to 1.",
                false
              )
              operation.add_or_update_parameter(page_param)
            end

            # Add per_page parameter if missing
            unless has_per_page
              per_page_param = create_parameter(
                "per_page",
                "query",
                "integer",
                "The number of items to return per page. Defaults to #{Api::PER_PAGE}. Maximum is #{Api::MAX_PER_PAGE}.",
                false
              )
              operation.add_or_update_parameter(per_page_param)
            end
          end

          def method_uses_pagination?(yard_object, visited = Set.new)
            # Check if the method source contains Api.paginate or .paginate( calls
            # This is the definitive way to know if Canvas endpoint is paginated
            return false unless yard_object.respond_to?(:source)

            # Prevent infinite recursion
            return false if visited.include?(yard_object)

            visited.add(yard_object)

            source = yard_object.source.to_s

            # Look for Api.paginate, Api::paginate, or just .paginate(
            # (some methods use collection.paginate directly from WillPaginate)
            return true if source.match?(/Api\.paginate|Api::paginate|\.paginate\(/)

            # General solution: Check all method calls in the source
            # Extract method names being called (simple heuristic: word followed by parenthesis or space)
            # This will catch: method_name(...), method_name {...}, self.method_name, etc.
            controller_class = yard_object.parent
            return false unless controller_class

            # Find all potential method calls in the source
            # Match patterns like: word( or word { or word. or word\s
            method_calls = source.scan(/\b([a-z_][a-z0-9_]*)\s*[({]/).flatten.uniq

            # For each method call, try to find it in the same controller and check recursively
            method_calls.each do |method_name|
              next if method_name == yard_object.name.to_s # Skip recursive self-calls

              helper_method = controller_class.children.find { |m| m.name.to_s == method_name }
              return true if helper_method.respond_to?(:source) && method_uses_pagination?(helper_method, visited)
            end

            false
          rescue
            # If we can't get the source, fall back to conservative heuristic
            # Only add pagination to endpoints that end with _index or _list
            operation_id = yard_object.name.to_s
            %w[index list].include?(operation_id)
          end

          def extract_model_name_from_types(types)
            return nil if types.blank?

            type_str = types.first.to_s.strip

            # Extract model name from [Model], {Model}, Array<Model>, Hash<Model>
            # rubocop:disable Lint/DuplicateBranch
            if type_str =~ /^\[(.+)\]$/
              $1
            elsif type_str =~ /^\{(.+)\}$/
              $1
            elsif type_str =~ /^Array<(.+)>$/i
              $1
            elsif type_str =~ /^Hash<(.+)>$/i
              $1
            elsif !%w[string integer int float number numeric boolean bool array object hash].include?(type_str.downcase)
              # Assume it's a model name if it's not a primitive type
              type_str
            end
            # rubocop:enable Lint/DuplicateBranch
          end

          def track_operation_model(operation_id, model_name, response_schema)
            return unless model_schema_exists?(model_name)

            # Debug: log tracking attempts
            # puts "Tracking: #{operation_id} -> #{model_name} (array: #{response_schema.include?('array')})"

            SwaggerYard::CanvasAdapter.operation_models[operation_id] ||= {}
            SwaggerYard::CanvasAdapter.operation_models[operation_id]["200"] = {
              model: model_name,
              is_array: response_schema.include?("array")
            }
          end

          def process_example_tags(docstring, operation)
            process_example_request_tag(docstring, operation)
            process_example_response_tag(docstring, operation)
          end

          def process_example_request_tag(docstring, operation)
            example_req = docstring.tags(:example_request).first
            return unless example_req

            example_text = example_req.text.to_s.strip
            return if example_text.empty?

            op_id = operation.operation_id
            SwaggerYard::CanvasAdapter.canvas_examples[op_id] ||= {}
            SwaggerYard::CanvasAdapter.canvas_examples[op_id][:request] = example_text
          end

          def process_example_response_tag(docstring, operation)
            example_resp = docstring.tags(:example_response).first
            return unless example_resp

            example_text = example_resp.text.to_s.strip
            return if example_text.empty?

            parsed_example = parse_json_example(example_text)
            op_id = operation.operation_id
            SwaggerYard::CanvasAdapter.canvas_examples[op_id] ||= {}
            SwaggerYard::CanvasAdapter.canvas_examples[op_id][:response] = parsed_example
          end

          def parse_json_example(text)
            JSON.parse(text)
          rescue JSON::ParserError
            text
          end

          def infer_param_location(name, operation)
            path_tmpl = operation.path.to_s
            return :path if path_tmpl.include?("{#{name}}")

            method = operation.http_method.to_s.downcase
            return :query if %w[get delete head].include?(method)

            :body
          end

          def map_types_to_schema(types)
            cleaned_types = sanitize_type_list(types)
            type_str = cleaned_types.first
            enum_values = extract_enum_values(cleaned_types)

            base_type = map_to_openapi_type(type_str)

            build_schema_with_enum(base_type, enum_values)
          end

          def sanitize_type_list(types)
            tlist = types.map { |t| t.to_s.strip }.reject(&:empty?)

            # Remove Canvas modifiers that aren't actual types
            modifiers = ["optional", "required"]
            tlist = tlist.reject { |t| modifiers.include?(t.downcase) }

            # Remove nil types
            non_nil = tlist.reject { |t| t.casecmp("nil").zero? }
            non_nil.empty? ? ["String"] : non_nil
          end

          def extract_enum_values(types)
            # Canvas uses pattern like String, "val1"|"val2"|"val3"
            # Extract quoted strings as enum values
            types[1..]&.map { |t| t.scan(/"([^"]+)"/) }&.flatten&.compact || []
          end

          def map_to_openapi_type(type_str)
            # rubocop:disable Lint/DuplicateBranch
            case type_str.downcase
            when "string"
              "string"
            when "integer", "int"
              "integer"
            when "float", "number", "numeric"
              "number"
            when "boolean", "bool"
              "boolean"
            when /^array/i
              "array"
            else
              # Unknown types default to string for prototype
              "string"
            end
            # rubocop:enable Lint/DuplicateBranch
          end

          def build_schema_with_enum(base_type, enum_values)
            if enum_values.empty?
              base_type
            else
              { "type" => base_type, "enum" => enum_values }
            end
          end

          def create_parameter(name, location, schema, description, required)
            # Create a SwaggerYard::Parameter with correct signature
            # Parameter.new(name, type, description, options={})
            # type must be a SwaggerYard::Type object

            # If schema is a hash (e.g., with enum), we need to handle it specially
            type_obj = if schema.is_a?(Hash)
                         # Create a Type with the base type, then monkey-patch schema_with to add enum
                         type = SwaggerYard::Type.new(schema["type"])
                         schema_data = schema
                         type.define_singleton_method(:schema_with) do |**_options|
                           result = { "type" => schema_data["type"] }
                           result["enum"] = schema_data["enum"] if schema_data["enum"]
                           result
                         end
                         type
                       else
                         SwaggerYard::Type.new(schema)
                       end

            SwaggerYard::Parameter.new(
              name,
              type_obj,
              description,
              { param_type: location, required: }
            )
          end

          def required_param?(types, description)
            # Check if parameter is marked as required
            # Canvas uses "Required" or "required" in type list or description
            types_str = types.join(" ").downcase
            desc_str = description.to_s.downcase

            return false if types_str.include?("optional")
            return true if types_str.include?("required")
            return true if desc_str.match?(/\brequired\b/)

            false
          end

          def build_request_body_schema(body_params)
            flat_params, nested_params = group_params_by_nesting(body_params)

            properties = {}
            required_fields = []

            process_flat_params(flat_params, properties, required_fields)
            process_nested_params(nested_params, properties, required_fields)

            {
              properties:,
              required: required_fields.uniq
            }
          end

          def group_params_by_nesting(body_params)
            nested_params = {}
            flat_params = []

            body_params.each do |param|
              if nested_param?(param[:name])
                add_to_nested_params(param, nested_params)
              else
                flat_params << param
              end
            end

            [flat_params, nested_params]
          end

          def nested_param?(param_name)
            param_name =~ /^([^\[]+)\[([^\]]+)\]$/
          end

          def add_to_nested_params(param, nested_params)
            param[:name] =~ /^([^\[]+)\[([^\]]+)\]$/
            parent_name = $1
            child_name = $2

            nested_params[parent_name] ||= { properties: {}, required: [] }
            nested_params[parent_name][:properties][child_name] = param
            nested_params[parent_name][:required] << child_name if param[:required]
          end

          def process_flat_params(flat_params, properties, required_fields)
            flat_params.each do |param|
              properties[param[:name]] = build_property_schema(param)
              required_fields << param[:name] if param[:required]
            end
          end

          def build_property_schema(param)
            schema_info = param[:schema]

            if schema_info.is_a?(Hash)
              schema_info.merge(description: param[:description])
            elsif schema_info.is_a?(String) && schema_info.start_with?("array<")
              build_array_property_schema(schema_info, param[:description])
            else
              {
                type: schema_info,
                description: param[:description]
              }
            end
          end

          def build_array_property_schema(schema_info, description)
            item_type = schema_info.match(/array<(.+)>/)[1]

            # Convert datetime types to proper OpenAPI format
            items_schema = case item_type.downcase
                           when "datetime", "date-time"
                             { type: "string", format: "date-time" }
                           when "date"
                             { type: "string", format: "date" }
                           else
                             { type: item_type }
                           end

            {
              type: "array",
              items: items_schema,
              description:
            }
          end

          def process_nested_params(nested_params, properties, required_fields)
            nested_params.each do |parent_name, nested_data|
              nested_schema = build_nested_object_schema(nested_data)
              properties[parent_name] = nested_schema

              # If any nested property is required, mark the parent as required
              required_list = nested_data[:required].uniq
              required_fields << parent_name unless required_list.empty?
            end
          end

          def build_nested_object_schema(nested_data)
            nested_properties = {}

            nested_data[:properties].each do |child_name, param|
              nested_properties[child_name] = build_property_schema(param)
            end

            nested_schema = {
              type: "object",
              properties: nested_properties
            }

            # Only include required array if there are required properties (OpenAPI spec requires at least 1 item)
            required_list = nested_data[:required].uniq
            nested_schema[:required] = required_list unless required_list.empty?

            nested_schema
          end

          def create_body_parameter(body_schema_info)
            type = create_body_type_with_schema(body_schema_info)

            SwaggerYard::Parameter.new(
              "body",
              type,
              "Request body parameters",
              { param_type: "body", required: true }
            )
          end

          def create_body_type_with_schema(body_schema_info)
            type = SwaggerYard::Type.new("object")
            schema_info = body_schema_info

            # Monkey-patch the schema_with method on this specific instance
            # We need to inline the logic here since the singleton method doesn't have access
            # to the instance methods of the module
            type.define_singleton_method(:schema_with) do |**_options|
              schema = { "type" => "object" }

              if schema_info[:properties].present?
                props = {}
                schema_info[:properties].each do |name, prop_info|
                  props[name.to_s] = if prop_info.is_a?(Hash)
                                       result = prop_info.transform_keys(&:to_s)
                                       # Recursively transform nested properties if present
                                       if result["properties"].is_a?(Hash)
                                         result["properties"] = result["properties"].transform_keys(&:to_s)
                                       end
                                       # Clean up required array (OpenAPI requires at least 1 item)
                                       if result["required"].is_a?(Array)
                                         unique_required = result["required"].map(&:to_s).uniq
                                         if unique_required.empty?
                                           result.delete("required")
                                         else
                                           result["required"] = unique_required
                                         end
                                       end
                                       result
                                     else
                                       # Simple type string
                                       { "type" => prop_info, "description" => "" }
                                     end
                end
                schema["properties"] = props
              end

              unless schema_info[:required].empty?
                schema["required"] = schema_info[:required].map(&:to_s).uniq
              end

              schema
            end

            type
          end

          def build_response_schema(types, _description)
            tlist = types.map { |t| t.to_s.strip }.reject(&:empty?)
            return "object" if tlist.empty?

            type_str = tlist.first
            handle_response_type(type_str)
          end

          def handle_response_type(type_str)
            return handle_array_response(type_str) if array_type?(type_str)
            return handle_hash_response(type_str) if hash_type?(type_str)

            handle_primitive_or_model_response(type_str)
          end

          def array_type?(type_str)
            type_str =~ /^\[(.+)\]$/ || type_str =~ /^Array<(.+)>$/i
          end

          def hash_type?(type_str)
            type_str =~ /^\{(.+)\}$/ || type_str =~ /^Hash<(.+)>$/i
          end

          def handle_array_response(type_str)
            type_str =~ /^\[(.+)\]$/ || type_str =~ /^Array<(.+)>$/i
            model_name = $1
            track_model_usage(model_name) if model_schema_exists?(model_name)
            "array<object>"
          end

          def handle_hash_response(type_str)
            type_str =~ /^\{(.+)\}$/ || type_str =~ /^Hash<(.+)>$/i
            model_name = $1
            track_model_usage(model_name) if model_schema_exists?(model_name)
            "object"
          end

          def handle_primitive_or_model_response(type_str)
            case type_str.downcase
            when "string" then "string"
            when "integer", "int" then "integer"
            when "float", "number", "numeric" then "number"
            when "boolean", "bool" then "boolean"
            when "array" then "array<object>"
            when "object", "hash" then "object"
            else
              track_model_usage(type_str) if model_schema_exists?(type_str)
              "object"
            end
          end

          def model_schema_exists?(model_name)
            SwaggerYard::CanvasAdapter.canvas_schemas.key?(model_name)
          end

          # rubocop:disable Naming/PredicateMethod
          def track_model_usage(model_name)
            # For now, just verify it exists. The post-processing will use
            # the operation context to determine which responses use which models
            model_schema_exists?(model_name)
          end
          # rubocop:enable Naming/PredicateMethod

          def map_model_to_type(_model_name)
            # Deprecated: use build_response_schema instead
            "object"
          end
        end)
      end
    end
  end
end
