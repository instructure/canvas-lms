# Non-standard Canvas extension to Bundler behavior -- load the Gemfiles from
# plugins.
Dir[File.join(File.dirname(__FILE__), '../vendor/plugins/*/Gemfile')].each do |g|
  unless Dir[File.join(File.dirname(g), "*.gemspec")].empty?
    raise "#{File.dirname(g)} has a gemspec, and probably needs to be moved to gems/plugins"
  end
  eval_gemfile(g)
end

# Non-standard Canvas extension to Bundler behavior -- load the Gemfiles from
# plugins.
Dir[File.join(File.dirname(__FILE__), '../gems/plugins/*/Gemfile.d/*')].each do |g|
  eval_gemfile(g)
end
