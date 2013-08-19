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

  def arguments
    raw_arguments.map do |tag|
      ArgumentView.new(tag.text, route.verb, route.path_variables)
    end
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

  def operation
    {
      "httpMethod" => route.verb,
      "nickname" => nickname,
      "responseClass" => returns.to_swagger,
      "parameters" => parameters,
      "summary" => summary,
      "notes" => desc
    }
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