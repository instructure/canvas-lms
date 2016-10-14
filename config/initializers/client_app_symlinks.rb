require 'fileutils'
require 'pathname'
require 'set'

# stolen and adapted from ./plugin_symlinks.rb
def maintain_client_app_symlinks
  output_dir = Pathname.new "public/javascripts/client_apps"

  links = []
  # make a list of what should exist
  Pathname.glob("client_apps/*").select(&:directory?).each do |app_dir|
    app = app_dir.basename
    dist = app_dir.join('dist')
    next unless dist.exist?
    files = Dir.chdir(dist) do
     [Pathname.new("#{app}.js")] + Pathname.glob("#{app}/**/*").reject(&:directory?)
    end

    links.concat(files.map do |asset|
      original = dist.join(asset)
      target = output_dir.join(asset)
      FileUtils.mkdir_p(target.dirname)
      [original.relative_path_from(target.dirname), target]
    end)
  end

  valid_files = links.map(&:last).to_set
  valid_dirs = Set.new
  valid_files.each do |file|
    dir = file.dirname
    while dir != output_dir
      valid_dirs << dir
      dir = dir.dirname
    end
  end
  # compressing assets can generate .gz versions of files; don't remove them
  valid_files.merge(valid_files.map { |f| Pathname.new(f.to_s + '.gz') })

  # remove any unnecessary links
  Pathname.glob("public/javascripts/client_apps/**/*").each do |file|
    if file.directory?
      file.rmtree unless valid_dirs.include?(file)
    else
      unless valid_files.include?(file)
        # we might have already removed this file in an rmtree above,
        # so we need to check if it exists still before trying to unlink it
        File.unlink(file) if File.exist?(file)
      end
    end
  end

  # create links
  links.each do |(target, source)|
    unless File.symlink?(source) && File.readlink(source) == target.to_s
      File.unlink(source) if File.exist?(source)
      File.symlink(target, source)
    end
  end
end

File.open(__FILE__) do |f|
  f.flock(File::LOCK_EX)

  Dir.chdir(Rails.root) do
    maintain_client_app_symlinks
  end
end
