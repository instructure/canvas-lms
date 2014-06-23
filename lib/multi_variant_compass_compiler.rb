##########################################################################
# See the docs at the top of assets.yml for more info on what this is for.
##########################################################################

module MultiVariantCompassCompiler

  VARIANTS = %w{legacy_normal_contrast legacy_high_contrast new_styles_normal_contrast new_styles_high_contrast}.freeze

  def all_sass_files
    require 'config/initializers/plugin_symlinks'
    # build the list of files ourselves so that we get it to follow symlinks
    sass_path = File.expand_path('app/stylesheets')
    sass_files = Dir.glob("#{sass_path}/{,plugins/*/}**/[^_]*.s[ac]ss")
  end

  def self.make_variants_from_real_assets_yml
    require 'erb'
    require 'yaml'
    require 'jammit'
    original_yml = ERB.new(File.read(File.expand_path('../../config/assets_real.yml',  __FILE__))).result(binding)
    parsed = YAML.load(original_yml)
    stylesheets_with_variants = {}
    VARIANTS.each do |variant|
      parsed['stylesheets'].each do |bundle_name, file_paths|
        paths = file_paths.map{ |p| p.gsub(%r{/compiled/}, '_compiled/' + variant + '/')}
        stylesheets_with_variants[bundle_name + '_' + variant] = paths
      end
    end
    parsed['stylesheets'] = stylesheets_with_variants
    YAML.dump(parsed)
  end

  def compile_all(opts={})
    require 'compass'
    require 'compass/commands'
    require 'parallel'

    sass_files = all_sass_files
    Parallel.each(VARIANTS) do |variant|
      command = Compass::Commands::UpdateProject.new('./', opts.merge(
        :css_dir => "public/stylesheets_compiled/#{variant}",
        :additional_import_paths => ["app/stylesheets/variants/#{variant}"],
        :cache_dir => "/tmp/sassc_#{variant}",
        :sass_files => sass_files))
      command.perform
    end
  end
end
