module AcademicBenchmark
  class Data
    def self.load_data(options={})
      if options.key?(:archive_file)
        OutcomeData::FromFile.new(options.slice(:archive_file))
      elsif options.key?(:authority) || options.key?(:document)
        OutcomeData::FromApi.new(options)
      else
        raise Canvas::Migration::Error, "No outcome file or guid given"
      end
    end

    def initialize(options={})
      @options = OpenStruct.new(options)
    end
  end
end
