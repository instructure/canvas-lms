require 'net/http'
require 'cgi'

module AcademicBenchmark
  def self.config
    Canvas::Plugin.find('academic_benchmark_importer').settings || {}
  end

  class APIError < StandardError; end

end

require 'academic_benchmark/api'
require 'academic_benchmark/converter'
require 'academic_benchmark/standard'