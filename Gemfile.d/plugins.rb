Dir[File.join(File.dirname(__FILE__), '../gems/plugins/*')].each do |plugin_dir|
  gem(File.basename(plugin_dir), path: plugin_dir)
end
