require_relative "generic_detector"

module Selinimum
  module Detectors
    # we try to map out dependents of any ruby files when we generate the
    # spec dependency graph. because ruby and rails are so crazy/magical,
    # currently this is only possible for:
    #  * _spec.rb files
    #  * views
    #  * controllers
    class RubyDetector < GenericDetector
      def can_process?(file)
        file =~ %r{\A(
          app/views/.*\.erb |
          app/controllers/.*\.rb |
          spec/.*_spec\.rb
        )\z}x && file !~ GLOBAL_FILES
      end

      # we don't find dependents at this point; we do that during the
      # capture phase. so here we just return the file itself
      def dependents_for(file)
        ["file:#{file}"]
      end

      # stuff not worth tracking, since they are literally used everywhere.
      # so if they change, we test all the things
      GLOBAL_FILES = %r{\A(
        app/views/(layouts|shared)/.*\.erb |
        app/controllers/application_controller.rb
      )\z}x
    end
  end
end

