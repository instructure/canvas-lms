require 'shellwords'

module RuboCop::Canvas
  class GitProxy
    attr_reader :git_dir

    def initialize(git_dir = nil)
      @git_dir = git_dir
    end

    def head_sha
      shell("git log --oneline -n 1 | cut -d ' ' -f 1").strip
    end

    def diff_files(sha)
      shell("git diff-tree --no-commit-id --name-only -r #{sha}")
    end

    def changes(include_untracked=false)
      if include_untracked
        shell("git status --porcelain")
      else
        shell("git status --porcelain -uno")
      end
    end

    def diff
      shell("git diff")
    end

    def show(sha)
      shell("git show #{sha}")
    end

    def dirty?(change_set=self.changes)
      !change_set.strip.empty?
    end

    private

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
