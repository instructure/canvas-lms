require 'fileutils'
require 'lib/i18n_extraction/handlebars_extractor'

# Precompiles handlebars templates into JavaScript function strings
class Handlebars

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
      id       = file.gsub(root_path + '/', '').gsub(/.handlebars$/, '')
      path     = "#{compiled_path}/#{id}.js"
      dir      = File.dirname(path)
      source   = File.read(file)
      js       = compile_template(source, id)
      FileUtils.mkdir_p(dir) unless File.exists?(dir)
      File.open(path, 'w') { |file| file.write(js) }
    end

    def compile_template(source, id)
      require 'execjs'
      # if the first letter of the template name is "_", register it as a partial
      # ex: _foobar.handlebars or subfolder/_something.handlebars
      filename = File.basename(id)
      if filename.match(/^_/)
        partial_name = filename.sub(/^_/, "")
        partial_path = id.sub(filename, partial_name)
        partial_registration = "\nHandlebars.registerPartial('#{partial_path}', templates['#{id}']);\n"
      end
      template = context.call "Handlebars.precompile", prepare_i18n(source, id)

      <<-JS
!define('jst/#{id}', ['compiled/handlebars_helpers'], function (Handlebars) {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
  templates['#{id}'] = template(#{template});#{partial_registration}
  return templates['#{id}'];
});
JS
    end

    def prepare_i18n(source, scope)
      @extractor ||= I18nExtraction::HandlebarsExtractor.new
      scope = scope.sub(/\A_/, '').gsub(/\/_?/, '.')
      @extractor.scan(source, :method => :gsub) do |data|
        wrappers = data[:wrappers].map{ |value, delimiter| " w#{delimiter.size-1}=#{value.inspect}" }.join
        "{{{t #{data[:key].inspect} #{data[:value].inspect} scope=#{scope.inspect}#{wrappers}#{data[:options]}}}}"
      end
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
