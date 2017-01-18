require_relative "generic_detector"
require "globby"

module Selinimum
  module Detectors
    # stuff we ignore that should never affect a build
    class WhitelistDetector < GenericDetector
      def commit_files=(files)
        # rather than glob **/* (which can be slow), just give globby the
        # files and dirs that actually changed
        dirs = Set.new
        files.each do |file|
          path = file.dup
          dirs << path + "/" while path.sub!(%r{/[^/]+\z}, '') && !dirs.include?(path)
        end

        @whitelisted_files = Set.new(
          Globby.select(
            Selinimum.whitelist,
            Globby::GlObject.new(files, dirs)
          )
        )
      end

      def can_process?(file, _)
        @whitelisted_files.include?(file)
      end
    end
  end
end
