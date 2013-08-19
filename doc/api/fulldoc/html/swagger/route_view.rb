require 'hash_view'

class RouteView < HashView
  def initialize(yard_method_object)
    @object = yard_method_object
    @controller = @object.parent.path.underscore.sub("_controller", '')
    @action = @object.path.sub(/^.*#/, '').sub(/_with_.*$/, '')
  end

  def route
    @route ||= begin
      routes = ApiRouteSet::V1.api_methods_for_controller_and_action(@controller, @action)
      # Choose shortest route (preferrably without .json suffix)
      routes.sort_by { |r| r.segments.join.size }.first
    end
  end

  def route_name
    ActionController::Routing::Routes.named_routes.routes.index(route).to_s.sub("api_v1_", "")
  end

  def file_path
    filepath = "app/controllers/#{@controller}_controller.rb"
    filepath = nil unless File.file?(File.join(Rails.root, filepath))
    filepath
  end

  def api_path
    path = route.segments.inject("") { |str,s| str << s.to_s }
    path.chop! if path.length > 1 # remove trailing slash
    path
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
    route.conditions[:method].to_s.upcase
  end

  def reqs
    route.requirements
  end

  def to_hash
    {
      "verb" => verb,
      "api_path" => api_path,
      "reqs" => reqs,
      "name" => route_name,
      "file_path" => file_path,
    }
  end
end
