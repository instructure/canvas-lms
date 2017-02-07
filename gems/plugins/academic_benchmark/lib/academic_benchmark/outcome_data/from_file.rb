module AcademicBenchmark
  module OutcomeData
    class FromFile < Data
      delegate :archive_file, to: :@options

      def data
        @_data ||= AcademicBenchmarks::Standards::StandardsForest.new(
          JSON.parse(archive_file.read)
        )
      end

      def error_message
        "The provided Academic Benchmark file has an error"
      end
    end
  end
end
