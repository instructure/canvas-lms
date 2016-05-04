require_relative "generic_detector"

module Selinimum
  module Detectors
    # stuff we ignore that should never affect a build
    # TODO: config file, maybe .gitignore style?
    class WhitelistDetector < GenericDetector
      def can_process?(file, _)
        return false if file =~ %r{\Aspec/fixtures/}
        return true if file =~ %r{\.(txt|md|png|jpg|gif|ico|svg|html|yml)\z}
        return true if file =~ %r{\A(spec/coffeescripts|doc|guard|bin|script|gems/rubocop-canvas\z)/}
        return true if file =~ %r{\Agems/selinimum/}
        return true if file == "spec/spec.opts"
        return true if file == "public/javascripts/translations/_core_en.js"
        false
      end
    end
  end
end
