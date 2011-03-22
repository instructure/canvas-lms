begin
  require 'yard'

namespace :doc do
  API_DOC_DIR = File.expand_path(Rails.root + "doc/api")

  YARD::Rake::YardocTask.new(:api) do |t|
    FileUtils.rm_rf(API_DOC_DIR)
    t.files = ["app/controllers/*.rb"]
    t.options = ["-e", "config/environment.rb", "-e", "lib/api_routes.rb", "--title", "Canvas REST API", "-p", "doc/templates", "-t", "rest", "--readme", "doc/templates/rest/README.md", "-o", API_DOC_DIR]
  end

  task 'api' do |t|
    puts "API Documentation successfully generated in doc/api\nSee doc/api/index.html"
  end
end
rescue LoadError
  # tasks not enabled
end
