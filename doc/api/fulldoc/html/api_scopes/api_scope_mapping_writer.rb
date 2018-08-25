#
# Copyright (C) 2018 - present Instructure, Inc.
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
class ApiScopeMappingWriter

  attr_reader :resource_lookup

  def initialize(resources)
    @resources = resources
    dir = File.dirname(__FILE__)
    @template = File.read(File.join(dir, '/scope_mapper_template.erb'))
    @output_file = Rails.root.join("lib", "api_scope_mapper.rb")
    @resource_lookup = {}
  end

  def generate_scope_mapper
    mapping = generate_scopes_mapping(@resources)
    out = ERB.new(@template, nil, '-').result(binding)
    File.open(@output_file, 'w') {|file| file.write(out)}
  end

  private

  def generate_scopes_mapping(resources)
    resources.each_with_object({}) do |(name, controllers), hash|
      process_controllers(controllers, name, hash)
    end
  end

  def process_controllers(controllers, name, resource_hash)
    controllers.each_with_object(resource_hash) do |controller, hash|
      scope_resource = controller.name.to_s.underscore.gsub('_controller', '')
      children = process_children(controller.children, name)
      hash[scope_resource] = hash[scope_resource].nil? ? children : hash[scope_resource].merge(children)
    end
  end

  def process_children(children, name)
    children.each_with_object({}) do |child, hash|
      next unless api_method?(child)
      resource = name.parameterize.underscore.to_sym
      hash[child.name] = resource
      add_resource_lookup(resource, name)
    end
  end

  def add_resource_lookup(resource, name)
    @resource_lookup[resource] = name
  end

  def api_method?(child)
    child.tags.any? {|t| t.tag_name == "API"} && child.tags.none? {|t| t.tag_name.casecmp?("internal")}
  end

end
