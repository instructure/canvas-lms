def maintain_plugin_symlinks(relative_path)
  Dir.glob("vendor/plugins/*/#{relative_path}").each do |plugin_dir|
    Dir.mkdir("#{relative_path}/plugins") unless File.exists?("#{relative_path}/plugins")
    plugin = plugin_dir.gsub(%r{^vendor/plugins/(.*)/#{relative_path}$}, '\1')
    source = "#{relative_path}/plugins/#{plugin}"
    target = "#{relative_path.gsub(%r{[^/]+}, '..')}/../#{plugin_dir}"
    unless File.symlink?(source) && File.readlink(source) == target
      File.unlink(source) if File.exists?(source)
      File.symlink(target, source)
    end
  end
end

maintain_plugin_symlinks('public')
maintain_plugin_symlinks('app/coffeescripts')
maintain_plugin_symlinks('app/views/jst')
maintain_plugin_symlinks('app/stylesheets')
