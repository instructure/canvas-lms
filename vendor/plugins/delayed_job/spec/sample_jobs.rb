class SimpleJob
  cattr_accessor :runs; self.runs = 0
  def perform; @@runs += 1; end
end

class ErrorJob
  cattr_accessor :runs; self.runs = 0
  def perform; raise 'did not work'; end
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