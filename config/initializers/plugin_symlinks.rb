def maintain_plugin_symlinks(local_path, plugin_path=nil)
  plugin_path ||= local_path

  # remove bad symlinks first
  Dir.glob("#{local_path}/plugins/*").each do |plugin_dir|
    if File.symlink?(plugin_dir) && !File.exist?(plugin_dir)
      File.unlink(plugin_dir)
    end
  end

  # create new ones
  Dir.glob("{gems,vendor}/plugins/*/#{plugin_path}").each do |plugin_dir|
    FileUtils.makedirs("#{local_path}/plugins") unless File.exist?("#{local_path}/plugins")
    plugin = plugin_dir.gsub(%r{^(?:gems|vendor)/plugins/(.*)/#{plugin_path}$}, '\1')
    source = "#{local_path}/plugins/#{plugin}"
    target = "#{local_path.gsub(%r{[^/]+}, '..')}/../#{plugin_dir}"
    unless File.symlink?(source) && File.readlink(source) == target
      File.unlink(source) if File.exist?(source)
      File.symlink(target, source)
    end
  end
end

File.open(__FILE__) do |f|
  f.flock(File::LOCK_EX)

  Dir.chdir(Rails.root) do
    maintain_plugin_symlinks('public')
    # our new unified build.js and friends require these two symlinks
    maintain_plugin_symlinks('public/javascripts')
    maintain_plugin_symlinks('app/coffeescripts')
    maintain_plugin_symlinks('app/views/jst')
    maintain_plugin_symlinks('app/stylesheets')
    maintain_plugin_symlinks('spec/coffeescripts', 'spec_canvas/coffeescripts')
  end
end
