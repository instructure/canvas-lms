# frozen_string_literal: true

require 'shellwords'

module DrDiff
  class Change
    attr_reader :git_dir
    attr_reader :path
    attr_reader :status

    STATUS_MAP = {
      "A" => "added",
      "D" => "deleted",
      "M" => "modified"
    }.freeze

    def initialize(status, path, git_dir)
      @status = STATUS_MAP[status]
      @path = path
      @git_dir = git_dir
    end

    ROOT_DIR = File.expand_path("../../../../../", __FILE__)
    def path_from_root
      File.join(ROOT_DIR, git_dir || ".", path)
    end

    def to_s
      path
    end
  end

  class GitProxy
    attr_reader :git_dir
    private :git_dir

    attr_reader :sha
    private :sha

    attr_reader :run_on_outstanding
    private :run_on_outstanding

    def initialize(git_dir: nil, sha: nil)
      @git_dir = git_dir
      @run_on_outstanding = !sha && dirty?
      @sha = sha || "HEAD"
    end

    def files
      return outstanding_change_files if run_on_outstanding
      change_files
    end

    def diff
      return outstanding_change_diff if run_on_outstanding
      change_diff
    end

    def changes
      command = if run_on_outstanding
                  "git diff --name-status"
                else
                  "git diff-tree --no-commit-id --name-status -r #{sha}"
                end
      raw_changes = shell(command)
      raw_changes.split("\n").map do |raw_change|
        status, path = raw_change.split("\t")
        Change.new(status, path, git_dir)
      end
    end

    def wip?
      first_line =~ /\A(\(|\[)?wip\b/i ? true : false
    end

    private

    def first_line
      shell("git log --pretty=%s -1 #{sha}").strip
    end

    def dirty?
      !shell("git status --porcelain --untracked-files=no").empty?
    end

    def outstanding_change_files
      shell("git diff --name-only")
    end

    def change_files
      shell("git diff-tree --no-commit-id --name-only -r #{sha}")
    end

    def outstanding_change_diff
      shell("git diff")
    end

    def change_diff
      shell("git show #{sha}")
    end

    def shell(command)
      if git_dir
        Dir.chdir(git_dir) do
          Kernel.send(:`, command)
        end
      else
        Kernel.send(:`, command)
      end
    end
  end
end
