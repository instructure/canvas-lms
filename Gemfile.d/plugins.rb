Dir["gems/plugins/*"].each do |plugin_dir|
  gem(File.basename(plugin_dir), path: plugin_dir)
end
