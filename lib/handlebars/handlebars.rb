require 'fileutils'

# Precompiles handlebars templates into JavaScript function strings
class Handlebars

  @@header = '!function() { var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};'
  @@footer = '}()'

  class << self

    # Recursively compiles a source directory of .handlebars templates into a 
    # destination directory. Immitates the node.js bin script at
    # https://github.com/wycats/handlebars.js/blob/master/bin/handlebars
    #
    # Arguments:
    #   root_path (string) - The root directory to find templates to compile
    #   compiled_path (string) - The destination directory in which to save the
    #     compiled templates.
    def compile(root_path, compiled_path)
      files = Dir["#{root_path}/**/**.handlebars"]
      files.each { |file| compile_file file, root_path, compiled_path }
    end

    # Compiles a single file into a destination directory.
    #
    # Arguments:
    #   file (string) - The file to compile.
    #   root_path - See `compile`
    #   compiled_path - See `compile`
    def compile_file(file, root_path, compiled_path)
      require 'execjs'
      id       = file.gsub(root_path, '').gsub(/.handlebars$/, '')
      path     = "#{compiled_path}/#{id}.js"
      dir      = File.dirname(path)
      template = context.call "Handlebars.precompile", File.read(file)
      js       = "#{@@header}\ntemplates['#{id}'] = template(#{template}); #{@@footer}"
      FileUtils.mkdir_p(dir) unless File.exists?(dir)
      File.open(path, 'w') { |file| file.write(js) }
    end

    protected

    # Returns the JavaScript context
    def context
      @context ||= self.set_context
    end

    # Compiles and caches the handlebars JavaScript
    def set_context
      handlebars_source = File.read(File.dirname(__FILE__) + '/vendor/handlebars.js')
      @context = ExecJS.compile handlebars_source
    end
  end
end