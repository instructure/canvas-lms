namespace :css do
  desc "Generate styleguide"
  task :styleguide do
    puts "--> creating styleguide"
    puts `dress_code config/styleguide.yml`
  end

  def to_bool(val)
    return true if val == true or val =~ (/^(true|t|yes|y|1)$/i)
    return false
  end

  desc "Compile css assets."
  task :generate, :force, :quiet, :environment do |t, args|
    args.with_defaults :force => false, :quiet => false, :environment => :development
    require 'lib/multi_variant_compass_compiler'
    include MultiVariantCompassCompiler
    compile_args = { quiet: to_bool(args[:quiet]), force: to_bool(args[:force]), environment: args[:environment] }
    puts "Compiling Compass with args: #{compile_args}" unless compile_args[:quiet]
    compile_all(compile_args)
  end

end
