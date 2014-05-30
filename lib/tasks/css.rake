namespace :css do
  desc "Generate styleguide"
  task :styleguide do
    puts "--> creating styleguide"
    puts `dress_code config/styleguide.yml`
  end

  desc "Compile css assets."
  task :generate do
    require 'lib/multi_variant_compass_compiler'
    include MultiVariantCompassCompiler
    compile_all quiet: true, force: true, environment: :production
  end

end
