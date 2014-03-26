# Non-standard Canvas extension to Bundler behavior -- load the Gemfiles from
# plugins.
Dir[File.join(File.dirname(__FILE__), '../vendor/plugins/*/Gemfile')].each do |g|
  eval(File.read(g))
end
