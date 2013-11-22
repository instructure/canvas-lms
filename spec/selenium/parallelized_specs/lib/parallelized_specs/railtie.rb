# add rake tasks if we are inside Rails
if defined?(Rails::Railtie)
  class ParallelizedSpecs
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load File.expand_path("../../tasks/parallelized_specs.rake", __FILE__)
      end
    end
  end
end
