namespace :css do
  desc "Compile css assets."
  task :generate do
    require 'config/initializers/plugin_symlinks'
    require 'action_controller'
    require 'compass-rails'
    require 'compass/commands'

    # build the list of files ourselves so that we get it to follow symlinks
    sass_path = File.expand_path(Compass.configuration.sass_path)
    sass_files = Dir.glob("#{sass_path}/{,plugins/*/}**/[^_]*.s[ac]ss")

    # build and execute the compass command
    compass = Compass::Commands::UpdateProject.new(Rails.root.to_s,
      :environment => :production,
      :sass_files => sass_files,
      :quiet => true,
      :force => true)
    compass.perform
    raise "Error running compass\nABORTING" unless compass.successful?
  end
end
