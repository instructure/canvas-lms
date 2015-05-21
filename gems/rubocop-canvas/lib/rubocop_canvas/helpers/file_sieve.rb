module RuboCop::Canvas
  class FileSieve
    attr_reader :git
    def initialize(input_git=RuboCop::Canvas::GitProxy)
      @git = input_git
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
      output.split("\n").map{|f| f.strip.split(/\s/).last }.
        select{|f| f =~ /\.rb$/ && File.exist?(f) }
    end
  end
end
