require 'hash_view'
require 'argument_view'
require 'route_view'
require 'return_view'

class MethodView < HashView
  def initialize(method)
    @method = method
  end

  def name
    format(@method.name)
  end

  def api_tag
    @api_tag ||= select_tags("api").first
  end

  def summary
    if api_tag
      format(api_tag.text)
    end
  end

  def nickname
    summary.downcase.
      gsub(/ an? /, ' ').
      gsub(/[^a-z]+/, '_').
      gsub(/^_+|_+$/, '')
  end

  def desc
    format(@method.docstring)
  end

  def raw_arguments
    select_tags("argument")
  end

  def return_tag
    select_tags("returns").first
  end

  def returns
    if return_tag
      ReturnView.new(return_tag.text)
    else
      ReturnViewNull.new
    end
  end

  def controller
    @method.parent.path.underscore.sub("_controller", '')
  end

  def action
    @method.path.sub(/^.*#/, '').sub(/_with_.*$/, '')
  end

  def raw_routes
    ApiRouteSet::V1.api_methods_for_controller_and_action(controller, action)
  end

  def routes
    @routes ||= raw_routes.map do |raw_route|
      RouteView.new(raw_route, self)
    end.select do |route|
      route.api_path !~ /json$/
    end
  end

  def swagger_type
    returns.to_swagger
  end

  def to_hash
    {
      "name" => name,
      "summary" => summary,
      "desc" => desc,
      "arguments" => arguments.map{ |a| a.to_hash },
      "returns" => returns.to_hash,
      "route" => route.to_hash,
    }
  end

protected
  def select_tags(tag_name)
    @method.tags.select do |tag|
      tag.tag_name.downcase == tag_name
    end
  end
end
