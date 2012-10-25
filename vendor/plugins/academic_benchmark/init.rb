Rails.configuration.to_prepare do

  Canvas::Plugin.register :academic_benchmark_importer, :export_system, {
          :name => proc { t(:name, 'Academic Benchmark Importer') },
          :author => 'Instructure',
          :description => I18n.t('plugins.ab.description', 'This enables importing Academic Benchmark standards into Canvas.'),
          :version => '1.0.0',
          :settings_partial => 'plugins/academic_benchmark_settings',
          :settings => {
            :api_key => nil,
            :api_url => AcademicBenchmark::API_BASE_URL,
            :worker => 'CCWorker',
            :converter_class => AcademicBenchmark::Converter,
            :provides => {:academic_benchmark => AcademicBenchmark::Converter}
          }
  }
end
