$LOAD_PATH.push File.expand_path("../../gems/dr_diff/lib", __FILE__)
require 'dr_diff'
require 'json'

class Linter
  DEFAULT_OPTIONS = {
    append_files_to_command: false,
    boyscout_mode: true,
    campsite_mode: true,
    comment_post_processing: proc { |comments| comments },
    env_sha: ENV['SHA'] || ENV['GERRIT_PATCHSET_REVISION'],
    file_regex: /./,
    gerrit_patchset: !!ENV['GERRIT_PATCHSET_REVISION'],
    heavy_mode: false,
    heavy_mode_proc: proc {},
    include_git_dir_in_output: !!!ENV['GERRIT_PATCHSET_REVISION'],
    plugin: ENV['GERRIT_PROJECT'],
    skip_file_size_check: false,
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
      exit 0
    end

    if !skip_file_size_check && files.size == 0
      puts "No #{file_regex} file changes found, skipping #{linter_name} check!"
      exit 0
    end

    if heavy_mode
      heavy_mode_proc.call(files)
    else
      publish_comments
    end
  end

  private

  attr_reader :append_files_to_command,
              :boyscout_mode,
              :campsite_mode,
              :command,
              :comment_post_processing,
              :default_boyscout_mode,
              :env_sha,
              :file_regex,
              :format,
              :gerrit_patchset,
              :heavy_mode,
              :heavy_mode_proc,
              :include_git_dir_in_output,
              :linter_name,
              :plugin,
              :severe_levels,
              :skip_file_size_check

  def git_dir
    @git_dir ||= plugin && "gems/plugins/#{plugin}/"
  end

  def severe_levels
    boyscout_mode ? %w(error warn info) : %w(error warn)
  end

  def dr_diff
    @dr_diff ||= ::DrDiff::Manager.new(git_dir: git_dir, sha: env_sha, campsite: campsite_mode)
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

  def publish_comments
    processed_comments = comment_post_processing.call(comments)

    unless processed_comments.size > 0
      puts "-- -- -- -- -- -- -- -- -- -- --"
      puts "No relevant #{linter_name} errors found!"
      puts "-- -- -- -- -- -- -- -- -- -- --"
      exit(0)
    end

    if gerrit_patchset
      publish_gergich_comments(processed_comments)
    else
      publish_local_comments(processed_comments)
    end
  end

  def publish_gergich_comments(comments)
    require "gergich"
    draft = Gergich::Draft.new
    comments.each do |comment|
      draft.add_comment comment[:path],
                        comment[:position],
                        comment[:message],
                        comment[:severity]
    end
  end

  def publish_local_comments(comments)
    require 'colorize'
    comments.each { |comment| pretty_comment(comment) }
  end

  def pretty_comment(comment)
    message = ""
    message += "[#{comment[:severity]}]".colorize(:yellow)
    message += " #{comment[:path].colorize(:light_blue)}:#{comment[:position]}"
    message += " => #{comment[:message].colorize(:green)}"
    puts message
  end
end
