require 'fileutils'
require 'i18n_extraction'

# Precompiles handlebars templates into JavaScript function strings
class EmberHbs
  class << self
    def compile_file(path)
      name = parse_name(path)
      dest = parse_dest(path)
      template_string = prepare_with_i18n(File.read(path), scopify(path))
      precompiled = compile_template(name, template_string)
      dir = File.dirname(dest)
      FileUtils.mkdir_p(dir) unless File.exists?(dir)
      File.open(dest, 'w') { |f| f.write precompiled }
    end

    def scopify(path)
      path.gsub(/^app\/coffeescripts\/ember\//, '').sub(/^_/, '').gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').gsub(/([a-z\d])([A-Z])/,'\1_\2').tr("-", "_").downcase.gsub(/\/_?/, '.')
    end

    def parse_dest(path)
      path.gsub(/^app\/coffeescripts\/ember/, 'public/javascripts/compiled/ember').gsub(/hbs$/, 'js')
    end

    def parse_name(path)
      path.gsub(/^.+?\/templates\//, '').gsub(/\.hbs$/, '')
    end

    def prepare_with_i18n(source, scope)
      @extractor = I18nExtraction::HandlebarsExtractor.new
      @extractor.scan(source, :method => :gsub) do |data|
        wrappers = data[:wrappers].map{ |value, delimiter| " w#{delimiter.size-1}=#{value.inspect}" }.join
        "{{{t #{data[:key].inspect} #{data[:value].inspect} scope=#{scope.inspect}#{wrappers}#{data[:options]}}}}"
      end
    end

    def compile_template(name, template_string)
      require "execjs"
      handlebars_source = File.read('./public/javascripts/bower/handlebars/handlebars.js')
      # execjs has no "exports" and global "var foo" does not land on "this.foo"
      shims = "; this.Handlebars = Handlebars; exports = {};"
      precompiler_source = File.read('./public/javascripts/bower/ember/ember-template-compiler.js')
      context = ExecJS.compile(handlebars_source + shims + precompiler_source)
      precompiled = context.eval "exports.precompile(#{template_string.inspect}).toString()", template_string
      template_module = <<-END
define(['ember', 'compiled/ember/shared/helpers/common'], function(Ember) {
  Ember.TEMPLATES['#{name}'] = Ember.Handlebars.template(#{precompiled});
});
      END
      template_module
    end

    def extract_i18n

    end
  end
end

