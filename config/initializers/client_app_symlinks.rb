# stolen and adapted from ./plugin_symlinks.rb
def maintain_client_app_symlinks
  # remove bad symlinks first
  Dir.glob("public/javascripts/client_apps/*").each do |app_symlink|
    if File.symlink?(app_symlink) && !File.exists?(app_symlink)
      File.unlink(app_symlink)
    end
  end

  # remove stale apps that were migrated/rewritten and have left build artifacts
  # and such after being removed from git (stuff was gitignored)
  #
  # needed since https://gerrit.instructure.com/#/c/44576
  Dir.glob("client_apps/*/.delete_me").each do |file|
    app = file.split('/')[1]

    FileUtils.rm_rf(File.dirname(file))

    [ "#{app}", "#{app}.js" ].each do |asset|
      asset_symlink = "public/javascripts/client_apps/#{asset}"
      FileUtils.rm(asset_symlink) if File.exists?(asset_symlink)
    end
  end

  # create new ones
  Dir.glob("client_apps/*").select { |f| File.directory?(f) }.each do |app_dir|
    unless File.exists?("public/javascripts/client_apps")
      FileUtils.makedirs("public/javascripts/client_apps")
    end

    app = File.basename(app_dir)

    [ "#{app}", "#{app}.js" ].each do |asset|
      source = "public/javascripts/client_apps/#{asset}"
      target = "../../../#{app_dir}/dist/#{asset}"

      unless File.symlink?(source) && File.readlink(source) == target
        File.unlink(source) if File.exists?(source)
        File.symlink(target, source)
      end
    end
  end
end

File.open(__FILE__) do |f|
  f.flock(File::LOCK_EX)

  maintain_client_app_symlinks
end
