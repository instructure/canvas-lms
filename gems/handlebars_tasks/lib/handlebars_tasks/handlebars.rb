require 'fileutils'
require 'handlebars_tasks/template_precompiler'

# Precompiles handlebars templates into JavaScript function strings
module HandlebarsTasks
  class Handlebars

    class << self
      include HandlebarsTasks::TemplatePrecompiler

      # Recursively compiles a source directory of .handlebars templates into a
      # destination directory. Immitates the node.js bin script at
      # https://github.com/wycats/handlebars.js/blob/master/bin/handlebars
      #
      # Arguments:
      #   root_path (string) - The root directory to find templates to compile
      #   compiled_path (string) - The destination directory in which to save the
      #     compiled templates.
      #   plugin (string) - Optional plugin to which the files belong. Will be
      #     used in scoping the generated module names. If absent, but a file is
      #     visibly under a plugin, the plugin for that file will be inferred.
      #
      # OR an array of such
      def compile(*args)
        unless args.first.is_a? Array
          args = [args]
        end
        files = []
        args.each do |(root_path, compiled_path, plugin)|
          files.concat(Dir["#{root_path}/**/**.handlebars"].map { |file| [file, root_path, compiled_path, plugin] })
        end
        require 'parallel'
        Parallel.each(files, :in_threads => Parallel.processor_count) do |file|
          compile_file *file
        end
      end

      # Compiles a single file into a destination directory.
      #
      # Arguments:
      #   file (string) - The file to compile.
      #   root_path - See `compile`
      #   compiled_path - See `compile`
      #   plugin - See `compile`
      def compile_file(file, root_path, compiled_path, plugin=nil)
        id       = file.gsub(root_path + '/', '').gsub(/.handlebars$/, '')
        path     = "#{compiled_path}/#{id}.js"
        dir      = File.dirname(path)
        source   = File.read(file)
        plugin ||= compiled_path =~ /vendor\/plugins\/([^\/]*)\// ? $1 : nil
        js       = compile_template(source, file, id, plugin)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        File.open(path, 'w') { |file| file.write(js) }
      end

      def compile_template(source, path, id, plugin=nil)
        # if the first letter of the template name is "_", register it as a partial
        # ex: _foobar.handlebars or subfolder/_something.handlebars
        filename = File.basename(id)
        if filename.match(/^_/)
          partial_name = filename.sub(/^_/, "")
          partial_path = id.sub(filename, partial_name)
          partial_registration = "\nHandlebars.registerPartial('#{partial_path}', templates['#{id}']);\n"
        end

        dependencies = ['compiled/handlebars_helpers']

        # if a scss file named exactly like this exists, load it when this is loaded
        if Dir.glob("app/stylesheets/jst/#{id}.scss").first
          bundle = "jst/#{id}"
          require 'lib/brandable_css'

          # arguments[1] will be brandableCss
          dependencies << "compiled/util/brandableCss"

          cached = BrandableCSS.all_fingerprints_for(bundle)
          if cached.values.first[:includesNoVariables]
            options = MultiJson.dump(cached.values.first)
          else
            options = "#{MultiJson.dump(cached)}[arguments[1].getCssVariant()]"
          end
          css_registration = "
            var options = #{options};
            arguments[1].loadStylesheet('#{bundle}', options);
          "
        end

        # take care of `require`ing partials
        partials = find_partial_deps(source)
        partials.each do |partial|
          split = partial.split /\//
          split[-1] = "_#{split[-1]}"
          require_path = split.join '/'
          dependencies << "jst/#{require_path}"
        end

        data = precompile_template(path, source)
        dependencies << "i18n!#{data["scope"]}" if data["translationCount"] > 0

        <<-JS
define('#{plugin ? plugin + "/" : ""}jst/#{id}', #{MultiJson.dump dependencies}, function (Handlebars) {
  var template = Handlebars.template, templates = Handlebars.templates = Handlebars.templates || {};
  templates['#{id}'] = template(#{data["template"]});
  #{partial_registration}
  #{css_registration}
  return templates['#{id}'];
});
        JS
      end

      protected

      def find_partial_deps(template)
        # finds partials like: {{>foo bar}} and {{>[foo/bar] baz}}
        template.scan(/\{\{>\s?\[?(.+?)\]?( .*?)?}}/).map {|m| m[0].strip }.uniq
      end
    end
  end
end
