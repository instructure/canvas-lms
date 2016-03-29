$LOAD_PATH << File.dirname(__FILE__)
require 'guard-gulp'

ignore! Listen::DirectoryRecord::DEFAULT_IGNORED_DIRECTORIES - ['vendor'] + [%r{vendor/(?!plugins)}]

guard :shell, all_on_start: true do
  watch('package.json') do
    `npm install`
  end
end

guard :brandable_css
guard 'coffeescript', :input => 'app/coffeescripts',  :output => 'public/javascripts/compiled'
guard 'coffeescript', :input => 'spec/coffeescripts', :output => 'spec/javascripts/compiled'
guard 'coffeescript', :input => 'spec_canvas/coffeescripts', :output => 'spec_canvas/javascripts'
guard 'jst',          :input => 'app/views/jst',      :output => 'public/javascripts/jst'
guard 'jstcss',       :input => 'app/stylesheets/jst'
guard :ember_templates
guard :ember_bundles
guard :styleguide
guard :js_extensions
guard :jsx

guard 'gulp' do
  watch(%r{^gulpfile.babel.js$})
end
