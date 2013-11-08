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

  def query_args
    raw_arguments.map do |tag|
      ArgumentView.new(tag.text, route.verb, route.path_variables)
    end
  end

  def query_arg_names
    query_args.map{ |arg| arg.name }
  end

  def path_args
    (route.path_variables - query_arg_names).map do |path_variable|
      ArgumentView.new("#{path_variable} [String] ID", route.verb, route.path_variables)
    end
  end

  def arguments
    path_args + query_args
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

  def route
    @route ||= RouteView.new(@method)
  end

  def parameters
    arguments.map do |arg|
      arg.to_swagger
    end
  end

  def path
    route.swagger_path
  end

  def swagger_type
    returns.to_swagger
  end

  def operation
    {
      "method" => route.verb,
      "summary" => summary,
      "notes" => desc,
      "nickname" => nickname,
      "parameters" => parameters,
    }.merge(swagger_type)
  end

  def to_swagger
    {
      "path" => path,
      "description" => desc,
      "operations" => [operation]
    }
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
