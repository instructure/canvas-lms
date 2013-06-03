require 'guard'
require 'guard/guard'
require 'lib/canvas/require_js/plugin_extension'

module Guard
  class JsExtensions < Guard
    def initialize(watchers = [], options = {})
      pattern = %r{vendor/plugins/[^/]+/app/coffeescripts/extensions/(.+\.coffee)$}
      super [::Guard::Watcher.new(pattern)], options
    end

    def run_on_additions(paths)
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
