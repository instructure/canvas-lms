begin
  require 'yard'

namespace :doc do
  API_DOC_DIR = File.expand_path(File.join(RAILS_ROOT, "doc", "api"))

  YARD::Rake::YardocTask.new(:api) do |t|
    FileUtils.rm_rf(API_DOC_DIR)
    t.files = ["app/controllers/*.rb"]
    t.options = ["-e", "vendor/plugins/api_routes/lib/api_routes.rb", "--title", "Canvas REST API", "-t", "rest", "-o", API_DOC_DIR]
  end
end
rescue LoadError
  # tasks not enabled
end
