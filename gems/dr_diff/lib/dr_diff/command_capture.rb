require 'gergich/capture'

module DrDiff
  class CommandCapture
    def self.run(format, command)
      captor = Gergich::Capture.load_captor(format)
      _, output = Gergich::Capture.run_command(command)
      captor.new.run(output.gsub(/\e\[\d+m/m, ""))
    end
  end
end
