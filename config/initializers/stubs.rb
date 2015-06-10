# stubs go at the bottom of the autoload path so that a plugin's version will
# be found first
ActiveSupport::Dependencies.autoload_paths.push(Rails.root + 'lib/stubs')
