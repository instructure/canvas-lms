# frozen_string_literal: true

begin
  require "yard"
  require "yard-appendix"
  require_relative "../../config/initializers/json"

  DOC_FORMAT = ENV["OUTPUT_FORMAT"] || "html"
  DOC_DIR = if DOC_FORMAT == "markdown"
              File.join(%w[public doc api_md])
            else
              File.join(%w[public doc api])
            end

  API_DOC_DIR = Rails.root.join(DOC_DIR).expand_path
  DOC_OPTIONS = {
    # turning this on will show all the appendixes of all
    # controllers in the All Resources page
    all_resource_appendixes: false
  }.freeze

  namespace :doc do
    YARD::Tags::Library.define_tag("A Data Model", :model)
    YARD::Tags::Library.define_tag("A schema to include with a controller's doc page", :include)
    YARD::Rake::YardocTask.new(:api) do |t|
      # If the above fails, that would mean we're in
      # a limited environment like when we're building a release image.
      # In that case, we'll need to manually load Zeitwerk and tell it where
      # to find the schemas namespace.

      # There are times during the build process where the entire
      # codebase is is not available, but this file still gets parsed.
      # So we should check if the lib/schemas dir exists first.
      schemas_path = Rails.root.join("lib/schemas").to_s

      lib_dir_is_loaded = CanvasRails::Application.autoloaders.any? do |autoloader|
        lib_path = Rails.root.join("lib").to_s
        autoloader.dirs.include?(lib_path)
      end

      t.before = proc { FileUtils.rm_rf(API_DOC_DIR) }
      t.before = proc { `script/generate_lti_variable_substitution_markdown` }
      t.before = proc do
        lib_dir_is_loaded = CanvasRails::Application.autoloaders.any? do |autoloader|
          lib_path = Rails.root.join("lib").to_s
          autoloader.dirs.include?(lib_path)
        end

        if Dir.exist?(schemas_path) && !lib_dir_is_loaded
          # Make sure schemas module exists so that it can be set as the
          # namespace for lib/schemas
          module Schemas
          end

          loader = Zeitwerk::Loader.new
          loader.push_dir(schemas_path, namespace: Schemas)
          loader.setup
        end
      end
      t.files = %w[
        app/controllers/**/*.rb
        {gems,vendor}/plugins/*/app/controllers/**/*.rb
        {gems,vendor}/plugins/*/lib/*.rb
      ]

      t.options = %W[
        -e
        doc/api/api_routes.rb
        --title
        "Canvas
        REST
        API"
        -p
        doc
        -t
        api
        --readme
        doc/api/README.md
        -o
        #{API_DOC_DIR}
        --asset
        doc/images:images
        --asset
        doc/examples:examples
        --format
        #{DOC_FORMAT}
      ]

      # t.options << '--verbose'
      # t.options << '--debug'
    end

    desc "generate API docs"
    task "api" do # rubocop:disable Rails/RakeEnvironment
      puts "API Documentation successfully generated in #{DOC_DIR}\n"
      if DOC_FORMAT == "html"
        puts "See #{DOC_DIR}/index.html"
      elsif DOC_FORMAT == "markdown"
        puts "See #{DOC_DIR}/Readme.md"
      end
    end
  end
rescue LoadError
  # tasks not enabled
  nil
end
