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

require "json_schemer"

module OpenApiSpecHelper
  class SchemaVerifier
    attr_accessor :errors

    def initialize(openapi_spec)
      @errors = {}
      @openapi_spec = openapi_spec
    end

    def verify(request, response)
      spec_for_path = @openapi_spec["paths"][request.path]
      unless spec_for_path
        @errors[request.path] = "This URL is not documented."
        return
      end

      method = request.method.downcase
      spec_for_method = spec_for_path[method]
      unless spec_for_method
        @errors[request.path] ||= {}
        @errors[request.path][method] = "This HTTP method is not documented."
        return
      end

      req_errors = request_errors(spec_for_method, request)
      unless req_errors.empty?
        @errors[request.path] ||= {}
        @errors[request.path][method] ||= {}
        @errors[request.path][method]["request"] ||= {}
        @errors[request.path][method]["request"].deep_merge!(req_errors)
      end

      spec_for_response = spec_for_method["responses"][response.code]
      unless spec_for_response
        @errors[request.path] ||= {}
        @errors[request.path][method] ||= {}
        @errors[request.path][method]["responses"] ||= {}
        @errors[request.path][method]["responses"][response.code] = "There are no documented respones for this status code."
        return
      end

      resp_errors = response_errors(spec_for_response, response)
      unless resp_errors.empty?
        @errors[request.path] ||= {}
        @errors[request.path][method] ||= {}
        @errors[request.path][method]["responses"] ||= {}
        @errors[request.path][method]["responses"][response.code] ||= []
        @errors[request.path][method]["responses"][response.code].concat(resp_errors)
      end
    end

    def request_errors(spec_at_method, request)
      errors = {}
      if spec_at_method["parameters"]
        parameter_schemas = parameter_schemas_by_name(spec_at_method["parameters"])
        query_param_errors = request_query_param_errors(parameter_schemas, request.query_parameters)
        if query_param_errors.any?
          errors["query params"] = query_param_errors
        end
      end

      if request.content_type
        body_param_schema = spec_at_method.dig("requestBody", "content", request.content_type)
        if body_param_schema
          request_body_errors = request_body_errors(body_param_schema["schema"], request.parameters)
          if request_body_errors.any?
            errors["body parameters"] = request_body_errors.pluck("error")
          end
        else
          errors["body parameters"] = "The content type #{request.content_type} is not in the schema"
        end
      end

      errors
    end

    def response_errors(spec_at_response_code, response)
      errors = []

      header_schema = spec_at_response_code["headers"]
      if header_schema
        errors << response_header_errors(spec_at_response_code["headers"], response.headers)
      end

      content_type = response.content_type
      if content_type.include?(";")
        content_type = content_type.slice(0..content_type.index(";") - 1)
      end
      body_schema = spec_at_response_code.dig("content", content_type, "schema")
      if body_schema
        errors.concat(response_body_errors(body_schema, response.body))
      else
        errors << "No body schema defined, and the response had a body" unless response.body.empty?
      end

      errors
    end

    def response_header_errors(header_schemas_by_name, headers)
      errors = []

      header_schemas_by_name.each_pair do |header_name, header_spec|
        value = headers[header_name]
        unless JSONSchemer.schema(header_spec["schema"]).valid?(value)
          errors << "#{header_name} does not match schema"
        end
      end

      errors
    end

    def response_body_errors(body_schema, body)
      JSONSchemer.schema(body_schema).validate(JSON.parse(body)).to_a
    end

    def request_query_param_errors(parameter_schemas, query_params)
      errors = []
      parameter_schemas.each_pair do |param_name, schema|
        value = query_params[param_name]
        unless JSONSchemer.schema(schema).valid?(value)
          errors << "#{param_name} does not match schema"
        end
      end

      errors
    end

    def request_body_errors(body_schema, body)
      JSONSchemer.schema(body_schema).validate(body).to_a
    end

    private

    # parameters array is an array like
    # [ { name: "paramName", schema: schemaObj } ]
    # which this returns as { "paramName" => schemaObj }
    def parameter_schemas_by_name(parameters_array)
      parameters_array.to_h do |parameter|
        [parameter["name"], parameter["schema"]]
      end
    end
  end
end
