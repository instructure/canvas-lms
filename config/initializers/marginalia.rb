require_dependency 'setting'

config = ConfigFile.load('marginalia') || {}

if config[:components].present?
  require 'marginalia'
  Marginalia::Railtie.insert

  module Marginalia
    module Comment
      class << self
        attr_accessor :migration, :rake_task

        def context_id
          RequestContextGenerator.request_id
        end

        def job_tag
          Delayed::Worker.current_job.try(:tag)
        end
      end
    end
  end

  Marginalia::Comment.components = config[:components].map(&:to_sym)

  module Marginalia::RakeTask
    def execute(args = nil)
      previous, Marginalia::Comment.rake_task = Marginalia::Comment.rake_task, self.name
      super
    ensure
      Marginalia::Comment.rake_task = previous
    end
  end

  Rake::Task.prepend(Marginalia::RakeTask)
end
