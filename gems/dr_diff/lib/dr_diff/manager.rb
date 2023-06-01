# frozen_string_literal: true

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

require "forwardable"

module DrDiff
  class Manager
    attr_reader :git, :git_dir, :campsite, :heavy, :base_dir, :severe_anywhere

    private :git
    private :git_dir
    private :campsite
    private :heavy
    private :base_dir
    private :severe_anywhere

    # all levels: %w(error warn info)
    SEVERE_LEVELS = %w[error warn].freeze

    def initialize(git: nil, git_dir: nil, sha: nil, campsite: true, heavy: false, base_dir: nil, severe_anywhere: true)
      @git_dir = git_dir
      @git = git || GitProxy.new(git_dir:, sha:)
      @campsite = campsite
      @heavy = heavy
      @base_dir = base_dir || ""
      @severe_anywhere = severe_anywhere
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
      diff = DiffParser.new(git.diff, raw: true, campsite:)

      result = []

      command_comments.each do |comment|
        path = comment[:path]
        path = path[git_dir.length..] if git_dir
        severe = severe?(comment[:severity], severe_levels)
        next unless heavy ||
                    (severe && severe_anywhere) ||
                    diff.relevant?(path, comment[:position], severe:) ||
                    comment[:corrected]

        comment[:path] = path unless include_git_dir_in_output
        result << comment
      end

      result
    end

    private

    def severe?(level, severe_levels)
      severe_levels.include?(level)
    end
  end
end
