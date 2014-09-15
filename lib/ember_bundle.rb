require 'active_support/inflector'
require 'fileutils'

class EmberBundle
  attr_accessor :app_name, :paths, :objects, :assigns

  ASSIGNABLE = %w(components controllers models routes views adapters serializers)

  def initialize(app_name, opts={})
    @app_name = app_name
    @root = "app/coffeescripts/ember/#{@app_name}"
    files = assignable_paths(opts[:files] || Dir.glob("#{@root}/**/*.coffee"))
    helpers = Dir.glob("#{@root}/helpers/**/*.coffee")
    templates = opts[:templates] || Dir.glob("#{@root}/**/*.hbs")
    @paths = files.map { |file| parse_require_path(file) }
    @objects = files.map { |file| parse_object_name(file) }
    @assigns = @objects.map { |object| "#{object}: #{object}" }.join("\n    ")
    if File.exists?("#{@root}/config/routes.coffee")
      @routes = "
  App.initializer
    name: 'routes'
    initialize: (container, application) ->
      application.Router.map(routes)
"
    else
      @routes = ''
    end
    include_config_files
    (templates+helpers).each { |file| @paths << parse_require_path(file) }
  end

  def include_config_files
    if @routes
      @paths.unshift(parse_require_path("#{@root}/config/routes.coffee"))
      @objects.unshift("routes")
    end
    @paths.unshift(parse_require_path("#{@root}/config/app.coffee"))
    @objects.unshift("App")
    @paths.unshift('ember')
    @objects.unshift('Ember')
  end

  def build
    bundle_path = "public/javascripts/compiled/bundles/#{@app_name}.js"

    # if there is nothing in our app besides auto-generated
    # .gitignor'ed stuff, clean up and continue
    return FileUtils::rm_rf([@root, bundle_path], verbose: true) if @assigns.empty?

    main_path = "#{@root}/main.coffee"
    File.open(main_path, 'w') { |f| f.write build_output }
    FileUtils.mkdir_p 'public/javascripts/compiled/bundles'
    File.open(bundle_path, 'w') do |f|
      f.write "require(['compiled/ember/#{@app_name}/main'], function(App) { window.App = App.create(); });"
    end
  end

  def assignable_paths(files)
    files.select { |file|
      parent_dir = file.gsub(@root, '').split('/')[1]
      ASSIGNABLE.include?(parent_dir)
    }
  end

  def parse_object_name(path)
    path.gsub(/^app\/coffeescripts\/ember\/.+?\/.+?\//, '')
        .gsub(/\.coffee$/, '')
        .gsub(/\//, '_')
        .camelize
  end

  def parse_require_path(path)
    path.gsub(/^app\/coffeescripts/, 'compiled').gsub(/\.(coffee|hbs)$/, '')
  end

  def build_output
    "# this is auto-generated\ndefine #{@paths.inspect}, (#{@objects.join(', ')}) ->
#{@routes}
  App.reopen({
    #{@assigns}
  })
"
  end

  def self.build_from_file(path)
    # TODO: don't build if its not assignable
    app_name = EmberBundle::parse_app_from_file(path)
    return false if !app_name
    EmberBundle.new(app_name).build
  end

  def self.parse_app_from_file(path)
    path.gsub(/^app\/coffeescripts\/ember\//, '').split('/')[0]
  end
end
