# Non-standard Canvas extension to Bundler behavior -- load the Gemfiles from
# plugins.
Dir[File.join(File.dirname(__FILE__), '../gems/plugins/*/Gemfile.d/*')].each do |g|
  eval(File.read(g), nil, g)
end
