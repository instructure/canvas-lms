require "shellwords"

module Selinimum
  module Git
    class << self
      def change_list(sha)
        `git diff --name-only #{Shellwords.escape(sha)}`.split(/\n/)
      end

      def recent_shas
        `git log --oneline --first-parent --pretty=format:'%H'|head -n 100`.split(/\n/)
      end

      def head
        recent_shas.first
      end

      def normalize_sha(sha)
        sha = `git show #{Shellwords.escape(sha)} --pretty=format:'%H' --name-only 2>/dev/null|head -n 1`
        sha.strip unless sha.empty?
      end
    end
  end
end
