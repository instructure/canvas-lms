module RuboCop::Canvas
  class GitProxy

    def self.head_sha
      (`git log --oneline -n 1 | cut -d " " -f 1`).strip
    end

    def self.diff_files(sha)
      `git diff-tree --no-commit-id --name-only -r #{sha}`
    end

    def self.changes(include_untracked=false)
      if include_untracked
        `git status --porcelain`
      else
        `git status --porcelain -uno`
      end
    end

    def self.dirty?(change_set=self.changes)
      !change_set.strip.empty?
    end


  end
end
