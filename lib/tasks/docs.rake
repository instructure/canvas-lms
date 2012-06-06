begin
  require 'yard'

namespace :doc do
  API_DOC_DIR = File.expand_path(Rails.root + "public/doc/api")

  YARD::Rake::YardocTask.new(:api) do |t|
    t.before = proc { FileUtils.rm_rf(API_DOC_DIR) }
    t.files = ["app/controllers/*.rb", "vendor/plugins/*/app/controllers/*.rb"]
    t.options = ["-e", "lib/api_routes.rb", "--title", "Canvas REST API", "-p", "doc", "-t", "api", "--readme", "doc/api/README.md", "-o", API_DOC_DIR]
  end

  task 'api' do |t|
    puts "API Documentation successfully generated in public/doc/api\nSee public/doc/api/index.html"
  end
end
rescue LoadError
  # tasks not enabled
end
