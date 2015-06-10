require 'fileutils'
require 'handlebars_tasks/template_precompiler'

# Precompiles handlebars templates into JavaScript function strings
module HandlebarsTasks
  class EmberHbs
    class << self
      include HandlebarsTasks::TemplatePrecompiler

      def compile_file(path)
        dest = parse_dest(path)
        precompiled = compile_template(path)
        dir = File.dirname(dest)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        File.open(dest, 'w') { |f| f.write precompiled }
      end

      def parse_dest(path)
        path.gsub(/^app\/coffeescripts\/ember/, 'public/javascripts/compiled/ember').gsub(/hbs$/, 'js')
      end

      def parse_name(path)
        path.gsub(/^.+?\/templates\//, '').gsub(/\.hbs$/, '')
      end

      def compile_template(path)
        source = File.read(path)
        name = parse_name(path)
        dependencies = ['ember', 'compiled/ember/shared/helpers/common']
        data = precompile_template(path, source, ember: true)
        dependencies << "i18n!#{data["scope"]}" if data["translationCount"] > 0

        template_module = <<-END
define(#{MultiJson.dump dependencies}, function(Ember) {
  Ember.TEMPLATES['#{name}'] = Ember.Handlebars.template(#{data["template"]});
});
        END
        template_module
      end
    end
  end
end
