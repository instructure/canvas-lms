$LOAD_PATH << File.dirname(__FILE__)

guard 'coffeescript', :input => 'app/coffeescripts',  :output => 'public/javascripts/compiled'
guard 'coffeescript', :input => 'spec/coffeescripts', :output => 'spec/javascripts'
guard 'jst',          :input => 'app/views/jst',      :output => 'public/javascripts/jst'
guard :styleguide
guard :js_extensions

Dir[File.join(File.dirname(__FILE__),'vendor/plugins/*/Guardfile')].each do |g|
  eval(File.read(g))
end

