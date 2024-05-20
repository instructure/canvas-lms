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
#

$LOAD_PATH.push File.expand_path("../gems/dr_diff/lib", __dir__)
require "dr_diff"

class Linter
  DEFAULT_OPTIONS = {
    append_files_to_command: false,
    auto_correct: false,
    boyscout_mode: true,
    campsite_mode: true,
    command: nil,
    comment_post_processing: proc { |comments| comments },
    custom_comment_generation: false,
    env_sha: ENV["SHA"] || ENV["GERRIT_PATCHSET_REVISION"],
    format: nil,
    file_regex: /./,
    generate_comment_proc: proc {},
    gerrit_patchset: !!ENV["GERRIT_PATCHSET_REVISION"],
    heavy_mode: false,
    include_git_dir_in_output: !!!ENV["GERRIT_PATCHSET_REVISION"],
    linter_name: nil,
    plugin: ENV["GERRIT_PROJECT"],
    skip_file_size_check: false,
    skip_wips: false,
    base_dir: nil,
    severe_anywhere: true
  }.freeze

  def initialize(options = {})
    options = DEFAULT_OPTIONS.merge(options)

    if options[:plugin] == "canvas-lms"
      options[:plugin] = nil
    end

    if options[:plugin].nil?
      canvas_dir = File.expand_path("..", __dir__)
      plugins_dir = File.join(canvas_dir, "gems/plugins")
      if Dir.pwd.start_with?(plugins_dir)
        options[:plugin] = Dir.pwd[(plugins_dir.length + 1)..]
        Dir.chdir(canvas_dir)
      end
    end

    options.each do |key, value|
      instance_variable_set(:"@#{key}", value)
    end
  end

  def run
    if git_dir && !Dir.exist?(git_dir)
      puts "No plugin #{plugin} found"
      return false
    end

    if skip_wips && wip?
      puts "WIP detected, #{linter_name} will not run."
      return true
    end

    if !skip_file_size_check && files.empty?
      puts "No #{file_regex} file changes found, skipping #{linter_name} check!"
      return true
    end

    publish_comments
  end

  def severe_levels
    return @severe_levels if @severe_levels

    boyscout_mode ? %w[info warn error fatal] : %w[warn error fatal]
  end

  private

  attr_reader(*DEFAULT_OPTIONS.keys)

  def git_dir
    @git_dir ||= plugin && "gems/plugins/#{plugin}/"
  end

  def dr_diff
    @dr_diff ||= ::DrDiff::Manager.new(git_dir:, sha: env_sha, campsite: campsite_mode, heavy: heavy_mode, base_dir:, severe_anywhere:)
  end

  def wip?
    dr_diff.wip?
  end

  def changes
    dr_diff.changes
  end

  def files
    @files ||= dr_diff.files(file_regex)
  end

  def full_command
    if append_files_to_command
      "#{command} #{files.join(" ")}"
    else
      command
    end
  end

  def comments
    @comments ||= dr_diff.comments(format:,
                                   command: full_command,
                                   include_git_dir_in_output:,
                                   severe_levels:)
  end

  def generate_comments
    if custom_comment_generation
      generate_comment_proc.call(changes:, auto_correct:)
    else
      comments
    end
  end

  def publish_comments
    processed_comments = comment_post_processing.call(generate_comments)

    if processed_comments.empty?
      puts "-- -- -- -- -- -- -- -- -- -- --"
      puts "No relevant #{linter_name} errors found!"
      puts "-- -- -- -- -- -- -- -- -- -- --"
      return true
    end

    if gerrit_patchset
      if boyscout_mode
        processed_comments.each do |comment|
          comment[:severity] = "error"
        end
      end
      publish_gergich_comments(processed_comments)
    else
      publish_local_comments(processed_comments)
      if auto_correct
        puts "Errors detected and possibly auto corrected."
        puts "Fix and/or git add the corrections and try to commit again."
      end
    end
    boyscout_mode ? false : processed_comments.any? { |c| severe_levels.include?(c[:severity]) }
  end

  def publish_gergich_comments(comments)
    require "gergich"
    draft = Gergich::Draft.new

    cover_comments, comments = comments.partition do |comment|
      comment[:cover_message]
    end

    comments.each do |comment|
      message = +"[#{comment[:source]}] "
      message << "#{comment[:rule]}: " if comment[:rule]
      message << comment[:message]

      draft.add_comment comment[:path],
                        comment[:position],
                        message,
                        comment[:severity]
    end

    cover_comments.each do |cover_comment|
      draft.add_message(cover_comment[:message])
    end
  end

  def publish_local_comments(comments)
    require "colorize"
    comments.each { |comment| pretty_comment(comment) }
  end

  def pretty_comment(comment)
    message = +""
    severity_color = severe_levels.include?(comment[:severity]) ? :red : :yellow
    severity_color = :green if comment[:corrected]
    message << "[#{comment[:severity]}]".colorize(severity_color)
    unless comment[:cover_message]
      message << " #{comment[:path].colorize(:light_blue)}:#{comment[:position]}"
    end
    message << " => "
    message << "[Correctable] ".colorize(:yellow) if comment[:correctable]
    message << "[Corrected] ".colorize(:green) if comment[:corrected]
    message << "#{comment[:rule]}: " if comment[:rule]
    message << comment[:message].colorize(:green)
    puts message
  end
end
