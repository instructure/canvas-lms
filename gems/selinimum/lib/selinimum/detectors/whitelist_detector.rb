require_relative "generic_detector"

module Selinimum
  module Detectors
    # stuff we ignore that should never affect a build
    # TODO: config file, maybe .gitignore style?
    class WhitelistDetector < GenericDetector
      def can_process?(file)
        return false if file =~ %r{\Aspec/fixtures/}
        return true if file =~ %r{\.(txt|md|png|jpg|gif|ico|svg|html|yml)\z}
        return true if file =~ %r{\A(spec/coffeescripts|doc|guard|bin|script|gems/rubocop-canvas\z)/}
        return true if file =~ %r{\Agems/selinimum/}
        return true if file == "spec/spec.opts"
        return true if file == "public/javascripts/translations/_core_en.js"
        return true if file == "Gemfile.d/test.rb" # TODO: this is :totes: temporary, just until https://gerrit.instructure.com/#/c/58088/ lands and we can remove testbot from canvas-lms proper
        false
      end
    end
  end
end
