require 'active_support/inflector'

class EmberBundle
  attr_accessor :app_name, :paths, :objects, :assigns

  ASSIGNABLE = %w(components controllers models routes views)

  def initialize(app_name, opts={})
    @app_name = app_name
    @root = "app/coffeescripts/ember/#{@app_name}"
    files = assignable_paths(opts[:files] || Dir.glob("#{@root}/**/*.coffee"))
    templates = opts[:templates] || Dir.glob("#{@root}/**/*.hbs")
    @paths = files.map { |file| parse_require_path(file) }
    @objects = files.map { |file| parse_object_name(file) }
    @assigns = @objects.map { |object| "App.#{object} = #{object}" }.join(";\n  ")
    include_config_files
    templates.each { |file| @paths << parse_require_path(file) }
  end

  def include_config_files
    @paths.unshift(parse_require_path("#{@root}/config/app.coffee"))
    @objects.unshift("App")
    @paths.push(parse_require_path("#{@root}/config/routes.coffee"))
  end

  def build
    path = "public/javascripts/compiled/bundles/#{@app_name}.js"
    File.open(path, 'w') { |f| f.write build_output }
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
    <<-END
require(#{@paths.inspect}, function(#{@objects.join(', ')}) {
  window.App = App;
  #{@assigns}
});
    END
  end

  def self.build_from_file(path)
    # TODO: don't build if its not assignable
    EmberBundle.new(EmberBundle::parse_app_from_file(path)).build
  end

  def self.parse_app_from_file(path)
    path.gsub(/^app\/coffeescripts\/ember\//, '').split('/')[0]
  end
end
