require 'shellwords'

module DrDiff
  class GitProxy
    attr_reader :git_dir
    private :git_dir

    attr_reader :sha
    private :sha

    attr_reader :run_on_outstanding
    private :run_on_outstanding

    def initialize(git_dir: nil, sha: nil)
      @git_dir = git_dir
      @run_on_outstanding = !sha
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

    private

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
