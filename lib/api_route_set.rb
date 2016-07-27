#
# Copyright (C) 2011 Instructure, Inc.
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

# wrapping your API routes in an ApiRouteSet adds structure to the routes file
# and lets us auto-discover the route for a given API method in the docs.
class ApiRouteSet
  attr_reader :prefix

  def initialize(prefix)
    @prefix = prefix
  end
  attr_accessor :mapper

  def self.draw(router, prefix = self.prefix, &block)
    @@prefixes ||= Set.new
    @@prefixes << prefix
    route_set = self.new(prefix)
    route_set.mapper = router
    route_set.instance_eval(&block)
  ensure
    route_set.mapper = nil
  end

  def self.prefixes
    @@prefixes
  end

  def self.prefix
    raise ArgumentError, "prefix required"
  end

  def self.routes_for(prefix)
    CanvasRails::Application.routes.set.select{|r| r.path.spec.to_s.start_with?(prefix)}
  end

  def self.segments_match(seg1, seg2)
    seg1.size == seg2.size && seg1.each_with_index { |s,i| return false unless s.respond_to?(:value) && s.value == seg2[i].value }
  end

  def self.api_methods_for_controller_and_action(controller, action)
    @routes ||= self.prefixes.map{|pfx| self.routes_for(pfx)}.flatten
    @routes.find_all { |r| matches_controller_and_action?(r, controller, action) }
  end

  def self.matches_controller_and_action?(route, controller, action)
    route.requirements[:controller] == controller && route.requirements[:action] == action
  end

  def method_missing(m, *a, &b)
    mapper.__send__(m, *a) {
      self.instance_eval(&b) if b
    }
  end

  def get(path, opts = {})
    route(:get, path, opts)
  end

  def put(path, opts = {})
    route(:put, path, opts)
  end

  def post(path, opts = {})
    route(:post, path, opts)
  end

  def delete(path, opts = {})
    route(:delete, path, opts)
  end

  def patch(path, opts = {})
    route(:patch, path, opts)
  end

  def resources(resource_name, opts = {}, &block)
    resource_name = resource_name.to_s

    path = opts.delete(:path) || resource_name
    name_prefix = opts.delete :name_prefix

    only, except = opts.delete(:only), opts.delete(:except)
    maybe_action = ->(action) { (!only || Array(only).include?(action)) && (!except || !Array(except).include?(action)) }

    get("#{path}", opts.merge(:action => :index, :as => "#{name_prefix}#{resource_name}")) if maybe_action[:index]
    get("#{path}/:#{resource_name.singularize}_id", opts.merge(:action => :show, :as => "#{name_prefix}#{resource_name.singularize}")) if maybe_action[:show]
    post( "#{path}", opts.merge(:action => :create, :as => (maybe_action[:index] ? nil : "#{name_prefix}#{resource_name}"))) if maybe_action[:create]
    put("#{path}/:#{resource_name.singularize}_id", opts.merge(:action => :update)) if maybe_action[:update]
    delete("#{path}/:#{resource_name.singularize}_id", opts.merge(:action => :destroy)) if maybe_action[:destroy]
  end

  def mapper_prefix
    ""
  end

  def route(method, path, opts)
    opts ||= {}
    opts[:as] ||= opts.delete(:path_name)
    opts[:as] = "#{mapper_prefix}#{opts[:as]}" if opts[:as]
    opts[:constraints] ||= {}
    opts[:constraints][:format] = 'json' if opts[:constraints].is_a? Hash
    opts[:format] = 'json'
    mapper.send(method, "#{prefix}/#{path}", opts)
  end

  class V1 < ::ApiRouteSet
    # match a path component, including periods, but excluding the string ".json" for backwards compat
    # for api v2, we'll just drop the .json completely
    # unfortunately, this means that api v1 can't match a sis id that ends with
    # .json -- but see the api docs for info on sending hex-encoded sis ids,
    # which allows any string.
    ID_REGEX = %r{(?:[^/?.]|\.(?!json(?:\z|[/?])))+}
    ID_PARAM = %r{^:(id|[\w]+_id)$}

    def self.prefix
      "/api/v1"
    end

    def mapper_prefix
      "api_v1_"
    end

    def route(method, path, opts)
      opts[:constraints] ||= {}
      path.split('/').each { |segment| opts[:constraints][segment[1..-1].to_sym] = ID_REGEX if segment.match(ID_PARAM) }
      super(method, path, opts)
    end
  end
end
