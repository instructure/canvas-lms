# frozen_string_literal: true

# Copyright (C) 2026 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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

  def self.detect_environment
    if ApplicationController.test_cluster?
      ApplicationController.test_cluster_name
    else
      Canvas.environment
    end
  end

  def self.test_cluster?
    detect_environment == "test"
  end

  DOC_OPTIONS = {
    # turning this on will show all the appendixes of all
    # controllers in the All Resources page
    all_resource_appendixes: false
  }.freeze

  namespace :doc do
    desc "generate HTML redirect files for deprecated API docs"
    task generate_html_redirects: :environment do
      require "json"
      require "fileutils"

      mapping_script = Rails.root.join("doc/api/redirect_old_docs/map_urls.rb")
      redirect_script = Rails.root.join("doc/api/redirect_old_docs/generate_html_redirects.rb")
      output_dir = Rails.public_path.join("doc/api")
      markdown_dir = Rails.public_path.join("doc/api_md")
      mapping_file = markdown_dir.join("url_mappings.json")

      puts "\nGenerating HTML redirects instead of full documentation..."
      puts "Redirects will point to: https://developerdocs.instructure.com/services/canvas"
      puts ""

      # Run in separate process to avoid stale ApiRouteSet cache
      system({ "OUTPUT_FORMAT" => "markdown" }, "rake", "doc:api_yard") || raise("Failed to generate markdown documentation")

      system("ruby", mapping_script.to_s, mapping_file.to_s) || raise("Failed to generate URL mappings")

      # Clean old HTML files but keep url_mappings.json
      FileUtils.mkdir_p(output_dir)
      Dir.glob(output_dir.join("*.html")).each { |f| File.delete(f) }

      system("ruby", redirect_script.to_s, output_dir.to_s, mapping_file.to_s) || raise("Failed to generate redirect files")
    end

    YARD::Tags::Library.define_tag("A Data Model", :model)
    YARD::Tags::Library.define_tag("A schema to include with a controller's doc page", :include)
    YARD::Rake::YardocTask.new(:api_yard) do |t|
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
    task api: :environment do
      is_test_cluster = test_cluster?

      if DOC_FORMAT == "html" && is_test_cluster
        # For HTML format in test cluster, generate redirects instead of docs
        Rake::Task["doc:generate_html_redirects"].invoke
        puts "\n✓ HTML redirects generated in #{DOC_DIR}"
        puts "All old API doc URLs will redirect to https://developerdocs.instructure.com"
        puts "Note: Full HTML docs not generated (test cluster environment)"
      elsif DOC_FORMAT == "markdown"
        # Run doc generation in separate process to avoid stale ApiRouteSet cache
        system("rake", "doc:api_yard") || raise("Failed to generate markdown documentation")
        puts "API Documentation successfully generated in #{DOC_DIR}\n"
        puts "See #{DOC_DIR}/Readme.md"
      else
        # Run doc generation in separate process to avoid stale ApiRouteSet cache
        system("rake", "doc:api_yard") || raise("Failed to generate HTML documentation")
        puts "API Documentation successfully generated in #{DOC_DIR}\n"
        puts "See #{DOC_DIR}/index.html"
      end
    end
  end
rescue LoadError
  # tasks not enabled
  nil
end
