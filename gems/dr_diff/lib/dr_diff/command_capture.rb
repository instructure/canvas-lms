require 'gergich/capture'

module DrDiff
  class CommandCapture
    def self.run(format, command)
      _, comments = Gergich::Capture.run(format, command, add_comments: false, suppress_output: true)
      comments
    end
  end
end
