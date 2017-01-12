require_relative 'change'

module TatlTael
  class GitProxy
    attr_reader :git_dir
    private :git_dir

    def initialize(git_dir = nil)
      @git_dir = git_dir
    end

    def changes
      command = "git diff-tree --no-commit-id --name-status -r HEAD"
      raw_changes = shell(command)
      raw_changes.split("\n").map do |raw_change|
        status, path = raw_change.split("\t")
        TatlTael::Change.new(status, path)
      end
    end

    def wip?
      first_line =~ /\A(\(|\[)?wip\b/i ? true : false
    end

    private

    def first_line
      `git log --pretty=%s -1 HEAD`.strip
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
