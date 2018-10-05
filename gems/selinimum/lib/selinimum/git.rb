#
# Copyright (C) 2015 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require "shellwords"

module Selinimum
  module Git
    class << self
      def change_list(sha)
        sha = recent_shas[1] if ignore_intermediate_commits?
        # all changes except deletions
        `git diff --diff-filter=d --name-only #{Shellwords.escape(sha)}`.split(/\n/)
      end

      def recent_shas
        `git log --oneline --first-parent --pretty=format:'%H'|head -n 500`.split(/\n/)
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
