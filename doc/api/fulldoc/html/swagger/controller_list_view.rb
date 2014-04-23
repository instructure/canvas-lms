require 'hash_view'
require 'controller_view'

class ControllerListView < HashView
  def initialize(name, controllers)
    @controllers = controllers.map do |ctrl|
      ControllerView.new(ctrl)
    end
    @name = name
  end

  def symbolic_name
    @name.underscore.gsub(/\s+/, '_')
  end

  def domain
    ENV["SWAGGER_DOMAIN"] || "http://canvas.instructure.com"
  end

  def swagger_file
    "#{symbolic_name}.json"
  end

  def swagger_reference
    {
      "path" => '/' + swagger_file,
      "description" => @name,
    }
  end

  def swagger_api_listing
    {
      "apiVersion" => "1.0",
      "swaggerVersion" => "1.2",
      "basePath" => "#{domain}/api",
      "resourcePath" => "/#{symbolic_name}",
      "produces" => ["application/json"],
      "apis" => apis,
      "models" => models
    }
  end

  def apis
    [].tap do |list|
      @controllers.each do |controller|
        controller.methods.each do |method|
          method.routes.each do |route|
            list << route.to_swagger
          end
        end
      end
    end
  end

  def models
    {}.tap do |m|
      merge = lambda do |name, hash|
        begin
          m.merge! hash
        rescue JSON::ParserError
          puts "Unable to parse model: #{name} (#{ctrl.raw_name})"
        end
      end

      # If @object tags are available to describe a class of object, we'll
      # use it if we must. From the examples given by the JSON that follows
      # the @object tag, we generate a best-guess JSON-schema (draft 4).
      #
      # If a @model tag is present, this is the preferred way to describe
      # API classes, and it will be merged last.
      #
      # See https://github.com/wordnik/swagger-core/wiki/Datatypes for a
      # description of the models schema we are trying to generate here.
      @controllers.each do |ctrl|
        ctrl.objects.each{ |object| merge[object.name, object.to_model.json_schema] }
        ctrl.models.each{ |model| merge[model.name, model.json_schema] }
      end
    end
  end
end
