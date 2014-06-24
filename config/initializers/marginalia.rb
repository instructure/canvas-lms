require_dependency 'setting'

config = ConfigFile.load('marginalia') || {}

if config[:components].present?
  require 'marginalia'
  Marginalia::Railtie.insert

  module Marginalia
    module Comment
      def self.context_id
        RequestContextGenerator.request_id
      end

      def self.job_tag
        Delayed::Worker.current_job.try(:tag)
      end
    end
  end

  Marginalia::Comment.components = config[:components].map(&:to_sym)
end
