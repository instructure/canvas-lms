module AcademicBenchmark::OutcomeData
  class Base
    def initialize(options={})
      @options = OpenStruct.new(options)
    end
  end
end
