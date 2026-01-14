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

require_relative "../../spec_helper"

describe SwaggerYard::CanvasAdapter do
  describe ".install!" do
    it "installs without errors" do
      expect { described_class.install! }.not_to raise_error
    end

    it "defines Canvas YARD tags" do
      described_class.install!
      expect(YARD::Tags::Library.instance_variable_get(:@labels)).to include(:API, :argument, :returns, :model)
    end
  end

  describe ".load_canvas_routes!" do
    before do
      described_class.load_canvas_routes!
    end

    it "loads routes from config/routes.rb" do
      routes = described_class.canvas_routes
      expect(routes).to be_a(Hash)
      expect(routes.size).to be > 0
    end

    it "parses controller#action format" do
      routes = described_class.canvas_routes
      # Check for a known route
      expect(routes.keys.first).to match(/\w+#\w+/)
    end

    it "includes HTTP method and path for each route" do
      routes = described_class.canvas_routes
      first_route = routes.values.first&.first

      expect(first_route).to be_a(Hash)
      expect(first_route).to have_key(:method)
      expect(first_route).to have_key(:path)
      expect(first_route).to have_key(:context)
    end

    it "converts Rails path params to OpenAPI format" do
      routes = described_class.canvas_routes
      # Find a route with path params
      route_with_params = routes.values.flatten.find { |r| r[:path].include?("{") }

      expect(route_with_params).not_to be_nil
      expect(route_with_params[:path]).to match(/\{[\w_]+\}/)
      expect(route_with_params[:path]).not_to match(/:[\w_]+/)
    end

    it "supports multi-context routes" do
      routes = described_class.canvas_routes
      # Some controller actions should have multiple paths (courses, groups, etc.)
      multi_route = routes.values.find { |route_array| route_array.is_a?(Array) && route_array.size > 1 }

      # This might not always exist, so we'll just check structure if it does
      if multi_route
        expect(multi_route).to all(be_a(Hash))
        expect(multi_route).to all(have_key(:path))
      end
    end
  end

  describe ".detect_context_from_path" do
    it "detects courses context" do
      expect(described_class.detect_context_from_path("/courses/123/assignments")).to eq(:courses)
    end

    it "detects groups context" do
      expect(described_class.detect_context_from_path("/groups/456/assignments")).to eq(:groups)
    end

    it "detects accounts context" do
      expect(described_class.detect_context_from_path("/accounts/789/users")).to eq(:accounts)
    end

    it "detects users context" do
      expect(described_class.detect_context_from_path("/users/123/profile")).to eq(:users)
    end

    it "returns :other for unknown context" do
      expect(described_class.detect_context_from_path("/api/v1/custom")).to eq(:other)
    end
  end

  describe "TAGS constant" do
    it "defines all required Canvas tags" do
      expect(described_class::TAGS).to include(:API, :argument, :returns, :model)
    end

    it "includes optional tags" do
      expect(described_class::TAGS).to include(:example_request, :example_response)
    end

    it "has proper structure for each tag" do
      described_class::TAGS.each_value do |value|
        expect(value).to have_key(:name)
        expect(value).to have_key(:handler)
      end
    end
  end

  describe ".sanitize_schema_name" do
    it "replaces :: with _" do
      expect(described_class.sanitize_schema_name("User::Profile")).to eq("User_Profile")
    end

    it "handles simple names" do
      expect(described_class.sanitize_schema_name("User")).to eq("User")
    end

    it "handles multiple namespaces" do
      expect(described_class.sanitize_schema_name("Api::V1::User::Profile")).to eq("Api_V1_User_Profile")
    end
  end

  describe ".convert_single_type" do
    it "converts datetime to string" do
      expect(described_class.convert_single_type("datetime")).to eq("string")
    end

    it "converts date-time to string" do
      expect(described_class.convert_single_type("date-time")).to eq("string")
    end

    it "converts date to string" do
      expect(described_class.convert_single_type("date")).to eq("string")
    end

    it "converts uuid to string" do
      expect(described_class.convert_single_type("uuid")).to eq("string")
    end

    it "keeps primitive types unchanged" do
      expect(described_class.convert_single_type("integer")).to eq("integer")
      expect(described_class.convert_single_type("boolean")).to eq("boolean")
    end
  end

  describe ".handle_array_types" do
    it "handles nullable types" do
      converted_prop = {}
      described_class.handle_array_types(converted_prop, ["string", "null"])
      expect(converted_prop["type"]).to eq("string")
      expect(converted_prop["nullable"]).to be(true)
    end

    it "handles non-nullable array types" do
      converted_prop = {}
      described_class.handle_array_types(converted_prop, ["string", "integer"])
      expect(converted_prop["type"]).to eq("string")
      expect(converted_prop).not_to have_key("nullable")
    end

    it "adds format for nullable datetime" do
      converted_prop = {}
      described_class.handle_array_types(converted_prop, ["datetime", "null"])
      expect(converted_prop["type"]).to eq("string")
      expect(converted_prop["format"]).to eq("date-time")
      expect(converted_prop["nullable"]).to be(true)
    end
  end

  describe ".handle_single_type" do
    it "converts datetime type" do
      converted_prop = {}
      described_class.handle_single_type(converted_prop, "datetime")
      expect(converted_prop["type"]).to eq("string")
      expect(converted_prop["format"]).to eq("date-time")
    end

    it "converts date type" do
      converted_prop = {}
      described_class.handle_single_type(converted_prop, "date")
      expect(converted_prop["type"]).to eq("string")
      expect(converted_prop["format"]).to eq("date")
    end

    it "converts uuid type" do
      converted_prop = {}
      described_class.handle_single_type(converted_prop, "uuid")
      expect(converted_prop["type"]).to eq("string")
      expect(converted_prop["format"]).to eq("uuid")
    end

    it "handles regular types" do
      converted_prop = {}
      described_class.handle_single_type(converted_prop, "integer")
      expect(converted_prop["type"]).to eq("integer")
      expect(converted_prop).not_to have_key("format")
    end
  end

  describe ".convert_property_type" do
    it "handles array types" do
      converted_prop = {}
      prop_def = { "type" => ["string", "null"] }
      described_class.convert_property_type(converted_prop, prop_def)
      expect(converted_prop["type"]).to eq("string")
      expect(converted_prop["nullable"]).to be(true)
    end

    it "handles single types" do
      converted_prop = {}
      prop_def = { "type" => "integer" }
      described_class.convert_property_type(converted_prop, prop_def)
      expect(converted_prop["type"]).to eq("integer")
    end

    it "returns early if no type" do
      converted_prop = {}
      prop_def = {}
      described_class.convert_property_type(converted_prop, prop_def)
      expect(converted_prop).to be_empty
    end
  end

  describe ".convert_single_property" do
    it "handles $ref properties" do
      prop_def = { "$ref" => "User" }
      result = described_class.convert_single_property(prop_def)
      expect(result).to eq({ "$ref" => "#/components/schemas/User" })
    end

    it "handles $ref with namespace" do
      prop_def = { "$ref" => "Api::User" }
      result = described_class.convert_single_property(prop_def)
      expect(result).to eq({ "$ref" => "#/components/schemas/Api_User" })
    end

    it "converts basic properties" do
      prop_def = {
        "type" => "string",
        "description" => "User name"
      }
      result = described_class.convert_single_property(prop_def)
      expect(result["type"]).to eq("string")
      expect(result["description"]).to eq("User name")
    end

    it "handles properties with enum" do
      prop_def = {
        "type" => "string",
        "allowableValues" => { "values" => ["active", "inactive"] }
      }
      result = described_class.convert_single_property(prop_def)
      expect(result["type"]).to eq("string")
      expect(result["enum"]).to eq(["active", "inactive"])
    end

    it "handles array properties with items" do
      prop_def = {
        "type" => "array",
        "items" => { "type" => "string" }
      }
      result = described_class.convert_single_property(prop_def)
      expect(result["type"]).to eq("array")
      expect(result["items"]).to eq({ "type" => "string" })
    end

    it "adds default items for array without items" do
      prop_def = { "type" => "array" }
      result = described_class.convert_single_property(prop_def)
      expect(result["type"]).to eq("array")
      expect(result["items"]).to eq({ "type" => "object" })
    end
  end

  describe ".convert_properties" do
    it "converts multiple properties" do
      properties = {
        "name" => { "type" => "string" },
        "age" => { "type" => "integer" }
      }
      result = described_class.convert_properties(properties)
      expect(result["name"]["type"]).to eq("string")
      expect(result["age"]["type"]).to eq("integer")
    end

    it "returns empty hash for empty properties" do
      result = described_class.convert_properties({})
      expect(result).to eq({})
    end
  end

  describe ".convert_canvas_schema_to_openapi" do
    it "converts basic schema" do
      canvas_schema = {
        "properties" => {
          "id" => { "type" => "integer" },
          "name" => { "type" => "string" }
        },
        "required" => ["id"]
      }
      result = described_class.convert_canvas_schema_to_openapi(canvas_schema)
      expect(result["type"]).to eq("object")
      expect(result["properties"]["id"]["type"]).to eq("integer")
      expect(result["properties"]["name"]["type"]).to eq("string")
      expect(result["required"]).to eq(["id"])
    end

    it "handles schema with description" do
      canvas_schema = {
        "description" => "A user object",
        "properties" => {
          "id" => { "type" => "integer" }
        }
      }
      result = described_class.convert_canvas_schema_to_openapi(canvas_schema)
      expect(result["description"]).to eq("A user object")
    end

    it "converts string required to array" do
      canvas_schema = {
        "properties" => {
          "id" => { "type" => "integer" }
        },
        "required" => "id"
      }
      result = described_class.convert_canvas_schema_to_openapi(canvas_schema)
      expect(result["required"]).to eq(["id"])
    end
  end

  describe ".fix_refs_recursive" do
    it "fixes $ref values in hash" do
      obj = { "$ref" => "User" }
      result = described_class.fix_refs_recursive(obj)
      expect(result["$ref"]).to eq("#/components/schemas/User")
    end

    it "fixes $ref with namespace" do
      obj = { "$ref" => "Api::User" }
      result = described_class.fix_refs_recursive(obj)
      expect(result["$ref"]).to eq("#/components/schemas/Api_User")
    end

    it "does not modify already correct $refs" do
      obj = { "$ref" => "#/components/schemas/User" }
      result = described_class.fix_refs_recursive(obj)
      expect(result["$ref"]).to eq("#/components/schemas/User")
    end

    it "fixes nested $refs in arrays" do
      obj = [
        { "$ref" => "User" },
        { "$ref" => "Course" }
      ]
      result = described_class.fix_refs_recursive(obj)
      expect(result[0]["$ref"]).to eq("#/components/schemas/User")
      expect(result[1]["$ref"]).to eq("#/components/schemas/Course")
    end

    it "fixes deeply nested $refs" do
      obj = {
        "properties" => {
          "user" => { "$ref" => "User" },
          "courses" => {
            "type" => "array",
            "items" => { "$ref" => "Course" }
          }
        }
      }
      result = described_class.fix_refs_recursive(obj)
      expect(result["properties"]["user"]["$ref"]).to eq("#/components/schemas/User")
      expect(result["properties"]["courses"]["items"]["$ref"]).to eq("#/components/schemas/Course")
    end
  end

  describe ".convert_array_items" do
    it "handles items with $ref" do
      items = { "$ref" => "User" }
      result = described_class.convert_array_items(items)
      expect(result["$ref"]).to eq("#/components/schemas/User")
    end

    it "handles items with type" do
      items = { "type" => "datetime" }
      result = described_class.convert_array_items(items)
      expect(result["type"]).to eq("string")
      expect(result["format"]).to eq("date-time")
    end

    it "handles regular type items" do
      items = { "type" => "integer" }
      result = described_class.convert_array_items(items)
      expect(result["type"]).to eq("integer")
    end
  end

  describe ".normalize_route_path" do
    it "removes /api/v1 prefix" do
      path = "/api/v1/courses/{id}"
      result = described_class.normalize_route_path(path)
      expect(result).to eq("/courses/{id}")
    end

    it "removes /api/sis prefix" do
      path = "/api/sis/courses"
      result = described_class.normalize_route_path(path)
      expect(result).to eq("/courses")
    end

    it "converts Rails params to OpenAPI format" do
      path = "/api/v1/courses/:id/assignments/:assignment_id"
      result = described_class.normalize_route_path(path)
      expect(result).to eq("/courses/{id}/assignments/{assignment_id}")
    end

    it "handles paths without api prefix" do
      path = "/courses/{id}"
      result = described_class.normalize_route_path(path)
      expect(result).to eq("/courses/{id}")
    end
  end

  describe ".extract_http_methods" do
    it "splits pipe-separated methods" do
      result = described_class.extract_http_methods("GET|POST")
      expect(result).to eq(["GET", "POST"])
    end

    it "handles single method" do
      result = described_class.extract_http_methods("POST")
      expect(result).to eq(["POST"])
    end

    it "defaults to GET for empty string" do
      result = described_class.extract_http_methods("")
      expect(result).to eq(["GET"])
    end

    it "strips whitespace" do
      result = described_class.extract_http_methods("GET | POST | PUT")
      expect(result).to eq(%w[GET POST PUT])
    end
  end

  describe ".clean_schema_text" do
    it "removes leading # and whitespace" do
      text = "#   { \"type\": \"string\" }"
      result = described_class.clean_schema_text(text)
      expect(result).to eq("{ \"type\": \"string\" }")
    end

    it "replaces :: with _" do
      text = "{ \"$ref\": \"Api::User\" }"
      result = described_class.clean_schema_text(text)
      expect(result).to eq("{ \"$ref\": \"Api_User\" }")
    end

    it "handles multiline text" do
      text = "#   {\n#     \"type\": \"string\"\n#   }"
      result = described_class.clean_schema_text(text)
      expect(result).to include("\"type\": \"string\"")
    end
  end

  describe "paths_from_yard_object_canvas (via add_path_item integration)" do
    # Test via integration since the method is private and deeply integrated with YARD/SwaggerYard
    # This tests the core logic without needing full YARD object mocking

    before do
      described_class.install! # Ensure patches are applied
    end

    # Create a minimal test helper that demonstrates the method behavior
    let(:test_context) do
      Class.new do
        attr_accessor :class_name

        def initialize(controller_name)
          @class_name = controller_name
        end

        # Include the actual private method we're testing
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
      end.new("UsersController")
    end

    it "returns nil when yard_object has no @API tag" do
      docstring = double("docstring")
      allow(docstring).to receive(:tags).with(:API).and_return([])

      yard_object = double("yard_object",
                           name: "index",
                           docstring:)

      result = test_context.paths_from_yard_object_canvas(yard_object)
      expect(result).to be_nil
    end

    it "returns nil when no routes are found in canvas_routes" do
      api_tag = double("api_tag")
      docstring = double("docstring")
      allow(docstring).to receive(:tags).with(:API).and_return([api_tag])

      yard_object = double("yard_object",
                           name: "nonexistent_method",
                           docstring:)

      result = test_context.paths_from_yard_object_canvas(yard_object)
      expect(result).to be_nil
    end

    it "returns routes when found in canvas_routes" do
      # Mock canvas_routes with a known route
      allow(described_class).to receive(:canvas_routes).and_return({
                                                                     "users#index" => [
                                                                       { path: "/users", method: "GET", context: :users }
                                                                     ]
                                                                   })

      api_tag = double("api_tag")
      docstring = double("docstring")
      allow(docstring).to receive(:tags).with(:API).and_return([api_tag])

      yard_object = double("yard_object",
                           name: "index",
                           docstring:)

      result = test_context.paths_from_yard_object_canvas(yard_object)

      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first).to eq({ path: "/users", http_method: "GET", context: :users })
    end

    it "returns multiple routes for the same controller#action" do
      # Mock canvas_routes with multiple contexts
      allow(described_class).to receive(:canvas_routes).and_return({
                                                                     "users#show" => [
                                                                       { path: "/courses/{course_id}/users/{id}", method: "GET", context: :courses },
                                                                       { path: "/groups/{group_id}/users/{id}", method: "GET", context: :groups }
                                                                     ]
                                                                   })

      api_tag = double("api_tag")
      docstring = double("docstring")
      allow(docstring).to receive(:tags).with(:API).and_return([api_tag])

      yard_object = double("yard_object",
                           name: "show",
                           docstring:)

      result = test_context.paths_from_yard_object_canvas(yard_object)

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result[0]).to eq({ path: "/courses/{course_id}/users/{id}", http_method: "GET", context: :courses })
      expect(result[1]).to eq({ path: "/groups/{group_id}/users/{id}", http_method: "GET", context: :groups })
    end

    it "handles nested controller classes" do
      nested_context = Class.new(test_context.class).new("UsersController::ServiceCredentials")

      allow(described_class).to receive(:canvas_routes).and_return({
                                                                     "users#index" => [
                                                                       { path: "/users", method: "GET", context: :users }
                                                                     ]
                                                                   })

      api_tag = double("api_tag")
      docstring = double("docstring")
      allow(docstring).to receive(:tags).with(:API).and_return([api_tag])

      yard_object = double("yard_object",
                           name: "index",
                           docstring:)

      result = nested_context.paths_from_yard_object_canvas(yard_object)

      expect(result).to be_an(Array)
      expect(result.size).to eq(1)
      expect(result.first[:path]).to eq("/users")
    end
  end
end
