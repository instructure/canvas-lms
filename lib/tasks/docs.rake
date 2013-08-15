begin
  require 'yard'
  require 'yard-appendix'

namespace :doc do
  DOC_DIR     = File.join(%w[public doc api])
  API_DOC_DIR = File.expand_path(Rails.root + DOC_DIR)
  DOC_OPTIONS = {
    # turning this on will show all the appendixes of all
    # controllers in the All Resources page
    :all_resource_appendixes => false
  }

  YARD::Rake::YardocTask.new(:api) do |t|
    t.before = proc { FileUtils.rm_rf(API_DOC_DIR) }
    t.files = %w[
      app/controllers/*.rb
      vendor/plugins/*/app/controllers/*.rb
      vendor/plugins/*/lib/*.rb
    ]

    t.options = %W[
      -e lib/api_routes.rb
      --title "Canvas REST API"
      -p doc
      -t api
      --readme doc/api/README.md
      -o #{API_DOC_DIR}
      --asset doc/images:images
      --asset doc/examples:examples
    ]

    # t.options << '--verbose'
    # t.options << '--debug'
  end

  task 'api' do |t|
    puts "API Documentation successfully generated in #{DOC_DIR}\n" <<
         "See #{DOC_DIR}/index.html"
  end

  namespace(:api) do
    # Produces api.json file as output (in the current dir). The api.json file is
    # an API description in JSON format that follows the 'swagger' API description
    # standard.
    YARD::Rake::YardocTask.new(:swagger) do |t|
      t.before = proc { FileUtils.rm_rf(API_DOC_DIR) }
      t.files = %w[
        app/controllers/*.rb
        vendor/plugins/*/app/controllers/*.rb
        vendor/plugins/*/lib/*.rb
      ]

      t.options = %W[
        -e lib/api_routes.rb
        -p doc
        -t api
        -o #{API_DOC_DIR}
      ]

      t.options << '-f' << 'text'
    end
  end
end

rescue LoadError
  # tasks not enabled
end
