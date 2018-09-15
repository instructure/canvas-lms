#
# Copyright (C) 2013 - present Instructure, Inc.
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

require 'hash_view'

class RouteView < HashView
  attr_reader :raw_route, :method_view

  def initialize(raw_route, method_view)
    @raw_route = raw_route
    @method_view = method_view
  end

  def route_name
    ActionController::Routing::Routes.named_routes.routes.index(raw_route).to_s.sub("api_v1_", "")
  end

  def file_path
    filepath = "app/controllers/#{@method_view.controller}_controller.rb"
    filepath = nil unless File.file?(File.join(Rails.root, filepath))
    filepath
  end

  def api_path
    path = remove_parentheticals(raw_route.path.spec.to_s)
    path.chop! if path.length > 1 && path[-1] == '/' # remove trailing slash
    path
  end

  def remove_parentheticals(str)
    str.gsub(/\([^\)]+\)/, '')
  end


  def path_variables
    api_path.scan(%r{:(\w+)}).map{ |v| v.first }
  end

  def swagger_path
    api_path.
      gsub(%r{^/api}, '').
      gsub(%r{:(\w+)}, '{\1}')
  end

  def verb
    raw_route.verb.upcase
  end

  def query_args
    method_view.raw_arguments.map do |tag|
      ArgumentView.new(tag.text, verb, path_variables, deprecated: tag.tag_name&.downcase == 'deprecated_argument')
    end
  end

  def query_arg_names
    query_args.map{ |arg| arg.name }
  end

  def path_args
    (path_variables - query_arg_names).map do |path_variable|
      ArgumentView.new("#{path_variable} [String] ID", verb, path_variables)
    end
  end

  def arguments
    path_args + query_args
  end

  def parameters
    arguments.map { |arg| arg.to_swagger }
  end

  def response_fields
    method_view.raw_response_fields.map { |tag| ResponseFieldView.new(tag).to_swagger }
  end

  def nickname
    method_view.nickname + method_view.unique_nickname_suffix(self)
  end

  def operation
    {
      "method" => verb,
      "summary" => method_view.summary,
      "notes" => method_view.desc,
      "nickname" => nickname,
      "parameters" => parameters,
      "response_fields" => response_fields,
      "deprecated" => method_view.deprecated?,
      "deprecation_description" => method_view.deprecation_description
    }.merge(method_view.swagger_type)
  end

  def to_swagger
    {
      "path" => swagger_path,
      "description" => method_view.desc,
      "operations" => [operation]
    }
  end

  def to_hash
    {
      "verb" => verb,
      "api_path" => api_path,
      "reqs" => raw_route.requirements,
      "name" => route_name,
      "file_path" => file_path,
    }
  end
end
