module AcademicBenchmark
  class Engine < ::Rails::Engine
    initializer "academic_benchmark.canvas_plugin" do
      require_dependency 'academic_benchmark/converter'

      Canvas::Plugin.register :academic_benchmark_importer, :export_system, {
              :name => proc { I18n.t(:name, 'Academic Benchmark Importer') },
              :author => 'Instructure',
              :description => proc { t(:description, 'This enables importing Academic Benchmark standards into Canvas.') },
              :version => AcademicBenchmark::VERSION,
              :settings_partial => 'academic_benchmark/plugin_settings',
              :hide_from_users => true,
              :settings => {
                :api_key => nil,
                :api_url => AcademicBenchmark::Api::API_BASE_URL,
                :common_core_guid => AcademicBenchmark::Converter::COMMON_CORE_GUID,
                :worker => 'CCWorker',
                :converter_class => AcademicBenchmark::Converter,
                :provides => {:academic_benchmark => AcademicBenchmark::Converter},
                :valid_contexts => %w{Account}
              }
      }
    end
  end
end
