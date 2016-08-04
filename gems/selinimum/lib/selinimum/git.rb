require "shellwords"

module Selinimum
  module Git
    class << self
      def change_list(sha)
        sha = recent_shas[1] if ignore_intermediate_commits?
        `git diff --name-only #{Shellwords.escape(sha)}`.split(/\n/)
      end

      def recent_shas
        `git log --oneline --first-parent --pretty=format:'%H'|head -n 100`.split(/\n/)
      end

      def head
        recent_shas.first || ENV["GERRIT_PATCHSET_REVISION"] || raise("no .git directory, and no revision specified!")
      end

      def normalize_sha(sha)
        sha = `git show #{Shellwords.escape(sha)} --pretty=format:'%H' --name-only 2>/dev/null|head -n 1`
        sha.strip unless sha.empty?
      end

      def ignore_intermediate_commits?
        commit_msg.include?("[selinimum:ignore_intermediate_commits]")
      end

      def commit_msg
        `git show --pretty=format:%B -s`
      end
    end
  end
end
