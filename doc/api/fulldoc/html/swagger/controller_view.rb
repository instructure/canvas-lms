require 'hash_view'
require 'method_view'

class ControllerView < HashView
  def initialize(controller)
    @controller = controller
  end

  def name
    format(@controller.name)
  end

  def raw_methods
    @controller.children.select do |method|
      method.tags.find do |tag|
        tag.tag_name.downcase == "api"
      end
    end
  end

  def methods
    raw_methods.map do |method|
      MethodView.new(method)
    end
  end

  def to_hash
    {
      "name" => name,
      "methods" => methods.map{ |m| m.to_hash },
    }
  end
end