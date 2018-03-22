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

$LOAD_PATH.push File.expand_path("../../gems/dr_diff/lib", __FILE__)
require 'dr_diff'
require 'json'

class Linter
  DEFAULT_OPTIONS = {
    append_files_to_command: false,
    auto_correct: false,
    boyscout_mode: true,
    campsite_mode: true,
    comment_post_processing: proc { |comments| comments },
    custom_comment_generation: false,
    env_sha: ENV['SHA'] || ENV['GERRIT_PATCHSET_REVISION'],
    file_regex: /./,
    generate_comment_proc: proc { },
    gerrit_patchset: !!ENV['GERRIT_PATCHSET_REVISION'],
    heavy_mode: false,
    heavy_mode_proc: proc {},
    include_git_dir_in_output: !!!ENV['GERRIT_PATCHSET_REVISION'],
    plugin: ENV['GERRIT_PROJECT'],
    skip_file_size_check: false,
    skip_wips: false,
    base_dir: nil
  }.freeze

  def initialize(options = {})
    options = DEFAULT_OPTIONS.merge(options)

    if options[:plugin] == 'canvas-lms'
      options[:plugin] = nil
    end

    options.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def run
    if git_dir && !Dir.exist?(git_dir)
      puts "No plugin #{plugin} found"
      return
    end

    if skip_wips && wip?
      puts "WIP detected, #{linter_name} will not run."
      return
    end

    if !skip_file_size_check && files.size == 0
      puts "No #{file_regex} file changes found, skipping #{linter_name} check!"
      return
    end

    if heavy_mode
      heavy_mode_proc.call(files)
    else
      publish_comments
    end
  end

  private

  # TODO: generate from DEFAULT_OPTIONS
  attr_reader :append_files_to_command,
              :auto_correct,
              :boyscout_mode,
              :campsite_mode,
              :command,
              :comment_post_processing,
              :default_boyscout_mode,
              :custom_comment_generation,
              :env_sha,
              :file_regex,
              :format,
              :generate_comment_proc,
              :gergich_capture,
              :gerrit_patchset,
              :heavy_mode,
              :heavy_mode_proc,
              :include_git_dir_in_output,
              :linter_name,
              :plugin,
              :severe_levels,
              :skip_file_size_check,
              :skip_wips,
              :base_dir

  def git_dir
    @git_dir ||= plugin && "gems/plugins/#{plugin}/"
  end

  def severe_levels
    boyscout_mode ? %w(error warn info) : %w(error warn)
  end

  def dr_diff
    @dr_diff ||= ::DrDiff::Manager.new(git_dir: git_dir, sha: env_sha, campsite: campsite_mode, base_dir: base_dir)
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
      "#{command} #{files.join(' ')}"
    else
      command
    end
  end

  def comments
    @comments ||= dr_diff.comments(format: format,
                                   command: full_command,
                                   include_git_dir_in_output: include_git_dir_in_output,
                                   severe_levels: severe_levels)
  end

  def generate_comments
    if custom_comment_generation
      generate_comment_proc.call(changes: changes, auto_correct: auto_correct)
    else
      comments
    end
  end

  def publish_comments
    processed_comments = comment_post_processing.call(generate_comments)

    unless processed_comments.size > 0
      puts "-- -- -- -- -- -- -- -- -- -- --"
      puts "No relevant #{linter_name} errors found!"
      puts "-- -- -- -- -- -- -- -- -- -- --"
    end

    if gerrit_patchset
      publish_gergich_comments(processed_comments)
    else
      publish_local_comments(processed_comments)
      if auto_correct
        puts "Errors detected and possibly auto corrected."
        puts "Fix and/or git add the corrections and try to commit again."
      end
    end
  end

  def publish_gergich_comments(comments)
    require "gergich"
    draft = Gergich::Draft.new

    cover_comments, comments = comments.partition do |comment|
      comment[:cover_message]
    end

    comments.each do |comment|
      draft.add_comment comment[:path],
                        comment[:position],
                        comment[:message],
                        comment[:severity]
    end

    cover_comments.each do |cover_comment|
      draft.add_message(cover_comment[:message])
    end
  end

  def publish_local_comments(comments)
    require 'colorize'
    comments.each { |comment| pretty_comment(comment) }
  end

  def pretty_comment(comment)
    message = ""
    message += "[#{comment[:severity]}]".colorize(:yellow)
    unless comment[:cover_message]
      message += " #{comment[:path].colorize(:light_blue)}:#{comment[:position]}"
    end
    message += " => #{comment[:message].colorize(:green)}"
    puts message
  end
end
