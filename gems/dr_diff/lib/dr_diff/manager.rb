module DrDiff
  class Manager
    attr_reader :git
    private :git

    attr_reader :git_dir
    private :git_dir

    attr_reader :campsite
    private :campsite

    # all levels: %w(error warn info)
    SEVERE_LEVELS = %w(error warn).freeze

    def initialize(git: nil, git_dir: nil, sha: nil, campsite: true)
      @git_dir = git_dir
      @git = git || GitProxy.new(git_dir: git_dir, sha: sha)
      @campsite = campsite
    end

    def files(regex = /./)
      all_files = git.files.split("\n")

      if git_dir
        all_files = all_files.map { |file_path| git_dir + file_path }
      end

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
