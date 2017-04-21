module TatlTael
  module Linters
    module Regex
      # shared regexes
      COFFEE_REGEX = /app\/coffeescripts\/.*\.coffee$/
      COFFEE_REGEX_EXCLUDE = /bundles\//
      COFFEE_SPEC_REGEX = /spec\/coffeescripts\//
      JSX_REGEX = /app\/jsx\/.*\.js/ # (no longer .jsx ending)
      JSX_SPEC_REGEX = /spec\/(coffeescripts|javascripts)\/jsx\//
      PUBLIC_JS_REGEX = /public\/javascripts\/.*\.js$/
      PUBLIC_JS_REGEX_EXCLUDE = /(bower|mediaelement|shims|vendor|symlink_to_node_modules)\//
      PUBLIC_JS_SPEC_REGEX = /spec\/(coffeescripts|javascripts)\//
    end
  end
end