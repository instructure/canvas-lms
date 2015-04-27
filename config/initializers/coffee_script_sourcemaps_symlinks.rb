if Rails.env.development? && ENV["CANVAS_SOURCE_MAPS"] != "0"
  app_dir = File.expand_path "#{Rails.root}/public/app"
  FileUtils.makedirs(app_dir) unless File.exist?(app_dir)
  symlink = File.expand_path "#{Rails.root}/public/app/coffeescripts"
  target = File.expand_path "#{Rails.root}/app/coffeescripts"
  unless File.symlink?(symlink) && File.readlink(symlink) == target
    File.unlink(symlink) if File.exist?(symlink)
    File.symlink(target,symlink)
  end
end

