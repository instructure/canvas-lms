module RuboCop::Canvas
  class FileSieve
    attr_reader :git

    def initialize(git: nil, git_dir: nil)
      @git_dir = git_dir
      @git = git || RuboCop::Canvas::GitProxy.new(@git_dir)
    end

    def files(sha=nil)
      if sha.nil?
        if git.dirty?
          changes = git.changes(true)
          return sieved(changes)
        else
          sha = git.head_sha
        end
      end
      diff = git.diff_files(sha)
      sieved(diff)
    end

    private
    def sieved(output)
      output.split("\n").map do |f|
        f = f.strip.split(/\s/).last
        f = @git_dir + f if @git_dir
        f
      end.select { |f| f =~ /\.rb$/ && File.exist?(f) }
    end
  end
end
