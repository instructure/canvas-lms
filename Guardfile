$LOAD_PATH << File.dirname(__FILE__)

# whitelist what directories to watch
directories %w(app spec gems/plugins)
# this means that we can't watch files in the root directory
# (like Gemfile, package.json, gulpfile.js, etc).  See:
# https://github.com/guard/listen/wiki/Duplicate-directory-errors
# for why we've chosen to whitelist directories

guard :coffeescript, input: 'app/coffeescripts', output: 'public/javascripts/compiled'
guard :coffeescript, input: 'spec/coffeescripts', output: 'spec/javascripts/compiled'
guard :coffeescript, input: 'spec_canvas/coffeescripts', output: 'spec_canvas/javascripts'
guard :ember_bundles
guard :ember_templates
guard :js_extensions
guard :jst, input: 'app/views/jst', output: 'public/javascripts/jst'
guard :jstcss, input: 'app/stylesheets/jst'
guard :jsx
guard :styleguide

# these just kick off other watcher processes
guard :brandable_css
guard :gulp
