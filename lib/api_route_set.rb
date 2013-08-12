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

  def self.route(mapper, prefix = self.prefix)
    route_set = self.new(prefix)
    route_set.mapper = mapper
    yield route_set
  ensure
    route_set.mapper = nil
  end

  def self.draw(router, prefix = self.prefix, &block)
    route_set = self.new(prefix)
    route_set.mapper = router
    route_set.instance_eval(&block)
  ensure
    route_set.mapper = nil
  end

  def self.prefix
    raise ArgumentError, "prefix required"
  end

  def self.routes_for(prefix)
    builder = ActionController::Routing::RouteBuilder.new
    segments = builder.segments_for_route_path(prefix)
    ActionController::Routing::Routes.routes.select { |r| segments_match(r.segments[0,segments.size], segments) }
  end

  def self.segments_match(seg1, seg2)
    seg1.size == seg2.size && seg1.each_with_index { |s,i| return false unless s.respond_to?(:value) && s.value == seg2[i].value }
  end

  def self.api_methods_for_controller_and_action(controller, action)
    self.routes_for(prefix).find_all { |r| r.matches_controller_and_action?(controller, action) }
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

  def resources(resource_name, opts = {}, &block)
    resource_name = resource_name.to_s
    path_prefix = opts.delete :path_prefix
    path_prefix << "/" if path_prefix

    name_prefix = opts.delete :name_prefix

    only, except = opts.delete(:only), opts.delete(:except)
    def maybe_action(only, except, action)
      if (!only || only.include?(action)) && (!except || !except.include?(action))
        yield
      end
    end

    maybe_action(only, except, :index) { get "#{path_prefix}#{resource_name}", opts.merge(:action => :index, :path_name => "#{name_prefix}#{resource_name}") }
    maybe_action(only, except, :show) { get "#{path_prefix}#{resource_name}/:#{resource_name.singularize}_id", opts.merge(:action => :show, :path_name => "#{name_prefix}#{resource_name.singularize}") }
    maybe_action(only, except, :create) { post "#{path_prefix}#{resource_name}", opts.merge(:action => :create, :path_name => "#{name_prefix}#{resource_name}") }
    maybe_action(only, except, :update) { put "#{path_prefix}#{resource_name}/:#{resource_name.singularize}_id", opts.merge(:action => :update) }
    maybe_action(only, except, :destroy) { delete "#{path_prefix}#{resource_name}/:#{resource_name.singularize}_id", opts.merge(:action => :destroy) }
  end

  def mapper_prefix
    ""
  end

  def mapper_method(opts)
    if opts[:path_name]
      path_name = "#{mapper_prefix}#{opts.delete(:path_name)}"
    else
      path_name = :connect
    end
  end

  def route(method, path, opts)
    opts ||= {}
    if defined?(ActionController::Routing::RouteSet::Mapper) && mapper.is_a?(ActionController::Routing::RouteSet::Mapper)
      # backwards compat until plugins are all updated
      mapper.__send__ mapper_method(opts), "#{prefix}/#{path}", (opts || {}).merge(:conditions => { :method => method }, :format => 'json')
      mapper.__send__ mapper_method(opts), "#{prefix}/#{path}.json", (opts || {}).merge(:conditions => { :method => method }, :format => 'json')
      return
    end

    if opts[:path_name]
      opts[:as] = "#{mapper_prefix}#{opts.delete(:path_name)}"
    end
    opts[:constraints] ||= {}
    opts[:constraints][:format] = 'json'
    if CANVAS_RAILS3
      opts[:format] = 'json'
      mapper.send(method, "#{prefix}/#{path}(.json)", opts)
    else
      # Our fake rails3 router isn't clever enough to translate (.json) to
      # something that rails 2 routing understands, so we help it out here for
      # api routes.
      opts[:format] = false
      mapper.send(method, "#{prefix}/#{path}.json", opts)
      mapper.send(method, "#{prefix}/#{path}", opts)
    end
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
      if defined?(ActionController::Routing::RouteSet::Mapper) && mapper.is_a?(ActionController::Routing::RouteSet::Mapper)
        # backwards compat until plugins are all updated
        path.split('/').each { |segment| opts[segment[1..-1].to_sym] = ID_REGEX if segment.match(ID_PARAM) }
      else
        opts[:constraints] ||= {}
        path.split('/').each { |segment| opts[:constraints][segment[1..-1].to_sym] = ID_REGEX if segment.match(ID_PARAM) }
      end
      super(method, path, opts)
    end
  end
end
