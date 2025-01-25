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

  MODEL_REGEX = ENV["MODEL_REGEX"] || ".+"

  namespace :doc do
    YARD::Tags::Library.define_tag("A Data Model", :model)
    YARD::Tags::Library.define_tag("A schema to include with a controller's doc page", :include)
    YARD::Rake::YardocTask.new(:api) do |t|
      t.before = proc { FileUtils.rm_rf(API_DOC_DIR) }
      t.before = proc { `script/generate_lti_variable_substitution_markdown` }
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
    task api: [:environment] do
      puts "API Documentation successfully generated in #{DOC_DIR}\n"
      if DOC_FORMAT == "html"
        puts "See #{DOC_DIR}/index.html"
      elsif DOC_FORMAT == "markdown"
        puts "See #{DOC_DIR}/Readme.md"
      end
    end
  end

  namespace :schemas do
    $generated_schemas = []

    YARD::Rake::YardocTask.new(:generate) do |t|
      t.files = %w[
        app/controllers/**/*.rb
        {gems,vendor}/plugins/*/app/controllers/**/*.rb
        {gems,vendor}/plugins/*/lib/*.rb
      ]

      t.options = %W[
        -e
        doc/api/api_routes.rb
        -o
        #{File.join(%w[lib schemas docs])}
        -p
        doc
        -t
        api
        --format
        schemas
      ]
    end

    desc "copy @model comments into their own ruby classes and delete original comments"
    task :generate do
      # grep for each thing in $generated_schemas,
      # looking for `@model GeneratedSchemaName`
      # then delete from that point until the next
      # blank comment line. (@model annotations
      # have a blank line after the last line
      # of their JSON schema.)
      $generated_schemas.each do |schema|
        res = `grep -Rn "\@model #{schema}$" app/controllers`.split(":")
        filename = res[0]
        start_line = res[1].to_i
        file_lines = File.readlines(filename)
        # starting at start_line - 1 (because the grep's line numbers start at 1),
        # search through the lines of the file until we reach a blank one.
        current_index = start_line - 1
        while current_index < file_lines.count
          break if /#( )*$/.match?(file_lines[current_index]) # exit the loop if we've found an empty line commment
          break unless /^( *)#/.match?(file_lines[current_index]) # also exit if we're not in a comment anymore

          current_index += 1
        end
        last_line = current_index + 1
        if last_line - start_line > 1
          # We found a comment block to delete
          file_lines = file_lines[0..start_line - 2] + file_lines[last_line..]
        end

        # Find instances of "@returns ModelName" and replace with
        # "@returns Schemas::Docs::ModelName"
        file_lines = file_lines.map do |line|
          # if line matches "@returns ModelName"
          # this regex finds "any number of spaces followed by @model followed by the schema name
          match = line.match(/ *# *@returns (#{schema})$/)
          if match
            line.sub!(schema, "Schemas::Docs::#{schema}")
          end
          line
        end

        f = File.open(filename, "w")
        f.write(file_lines.join)
      end
    end
  end
rescue LoadError
  # tasks not enabled
  nil
end
