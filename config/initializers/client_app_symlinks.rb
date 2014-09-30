# stolen and adapted from ./plugin_symlinks.rb
def maintain_client_app_symlinks(local_path)
  # remove bad symlinks first
  Dir.glob("#{local_path}/client_apps/*.js").each do |app_symlink|
    if File.symlink?(app_symlink) && !File.exists?(app_symlink)
      File.unlink(app_symlink)
    end
  end

  # create new ones
  Dir.glob("client_apps/*").select { |f| File.directory?(f) }.each do |app_dir|
    unless File.exists?("#{local_path}/client_apps")
      FileUtils.makedirs("#{local_path}/client_apps")
    end

    app = File.basename(app_dir)
    source = "#{local_path}/client_apps/#{app}.js"
    target = "#{local_path.gsub(%r{[^/]+}, '..')}/../#{app_dir}/dist/#{app}.js"

    unless File.symlink?(source) && File.readlink(source) == target
      File.unlink(source) if File.exists?(source)
      File.symlink(target, source)
    end
  end
end

File.open(__FILE__) do |f|
  f.flock(File::LOCK_EX)

  maintain_client_app_symlinks('public/javascripts')
end
