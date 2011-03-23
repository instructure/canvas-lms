module Canvas
  module LockdownBrowser
    def self.plugin
      # TODO: support multiple enabled lockdown browser plugins? Right now we
      # always just use the first enabled one.
      Canvas::Plugin.all_for_tag(:lockdown_browser).first
    end
  end
end
