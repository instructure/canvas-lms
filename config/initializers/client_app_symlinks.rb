require 'fileutils'
require 'pathname'

# stolen and adapted from ./plugin_symlinks.rb
def maintain_client_app_symlinks
  output_dir = Pathname.new "public/javascripts/client_apps"
  # remove anything that was there first
  output_dir.rmtree if output_dir.exist?

  # create new ones
  Pathname.glob("client_apps/*").select(&:directory?).each do |app_dir|
    app = app_dir.basename
    dist = app_dir.join('dist')
    next unless dist.exist?
    files = Dir.chdir(dist) do
     [Pathname.new("#{app}.js")] + Pathname.glob("#{app}/**/*").reject(&:directory?)
    end

    files.each do |asset|
      original = dist.join(asset)
      target = output_dir.join(asset)
      FileUtils.mkdir_p(target.dirname)
      File.symlink(original.relative_path_from(target.dirname), target)
    end
  end
end

File.open(__FILE__) do |f|
  f.flock(File::LOCK_EX)
  maintain_client_app_symlinks
end
