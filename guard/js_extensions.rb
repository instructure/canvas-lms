require 'guard'
require 'guard/plugin'
require 'lib/canvas/require_js/plugin_extension'

module Guard
  class JsExtensions < Plugin
    def initialize(options = {})
      pattern = %r{gems/plugins/[^/]+/app/coffeescripts/extensions/(.+\.coffee)$}
      options[:watchers] = [::Guard::Watcher.new(pattern)]
      super(options)
    end

    def run_on_modifications(paths)
      UI.info "Generating plugin extensions for #{paths.join(", ")}"
      paths.each do |path|
        path = path.gsub(%r{.*?/extensions/}, '')
        Canvas::RequireJs::PluginExtension.generate(path)
      end
      UI.info "Successfully generated plugin extensions for #{paths.join(", ")}"
    end

    def run_all
      UI.info "Generating all plugin extensions"
      Canvas::RequireJs::PluginExtension.generate_all
      UI.info "Successfully generated all plugin extensions"
    end
  end
end
