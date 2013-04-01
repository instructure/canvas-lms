class SimpleJob
  cattr_accessor :runs; self.runs = 0
  def perform; @@runs += 1; end
end

class ErrorJob
  cattr_accessor :runs; self.runs = 0
  def perform; raise 'did not work'; end

  cattr_accessor :failure_runs; self.failure_runs = 0
  def on_failure(error); @@failure_runs += 1; end

  cattr_accessor :permanent_failure_runs; self.permanent_failure_runs = 0
  def on_permanent_failure(error); @@permanent_failure_runs += 1; end
end

class LongRunningJob
  def perform; sleep 250; end
end

module M
  class ModuleJob
    cattr_accessor :runs; self.runs = 0
    def perform; @@runs += 1; end
  end
end
