#
# Copyright (C) 2016 - present Instructure, Inc.
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

module DrDiff
  class Manager
    attr_reader :git
    private :git

    attr_reader :git_dir
    private :git_dir

    attr_reader :campsite
    private :campsite

    attr_reader :base_dir
    private :base_dir

    # all levels: %w(error warn info)
    SEVERE_LEVELS = %w(error warn).freeze

    def initialize(git: nil, git_dir: nil, sha: nil, campsite: true, base_dir: nil)
      @git_dir = git_dir
      @git = git || GitProxy.new(git_dir: git_dir, sha: sha)
      @campsite = campsite
      @base_dir = base_dir || ""
    end

    extend Forwardable
    def_delegators :@git, :wip?, :changes

    def files(regex = /./)
      all_files = git.files.split("\n")

      dir = git_dir || base_dir
      all_files = all_files.map { |file_path| dir + file_path }

      all_files.select do |file_path|
        file_path =~ regex && File.exist?(file_path)
      end
    end

    def comments(format:,
                 command:,
                 include_git_dir_in_output: false,
                 severe_levels: SEVERE_LEVELS)

      command_comments = CommandCapture.run(format, command)
      diff = DiffParser.new(git.diff, true, campsite)

      result = []

      command_comments.each do |comment|
        path = comment[:path]
        path = path[git_dir.length..-1] if git_dir
        if diff.relevant?(path, comment[:position], severe?(comment[:severity], severe_levels))
          comment[:path] = path unless include_git_dir_in_output
          result << comment
        end
      end

      result
    end

    private

    def severe?(level, severe_levels)
      if UserConfig.only_report_errors?
        level == 'error'
      else
        severe_levels.include?(level)
      end
    end
  end
end
