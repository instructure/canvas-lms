#!/usr/bin/env ruby
#
# Runs a .js file through Canvas's I18nExtraction gem and tests for errors.
# This script must be run using "bundle exec" inside the gem's directory at
#
#     /canvas-lms/gems/i18n_extraction/
#
# Use the helper task `grunt check_i18n` for testing the application's built
# JS assets.

$LOAD_PATH.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'i18n_tasks', 'lib')

require 'i18n_extraction'
require 'i18n_tasks/utils'
require 'active_support/core_ext'

source = ARGV[0] || begin
  puts "Usage: $0 path/to/javascript_file.js"
  Kernel.exit(1)
end

translations = {}
extractor = I18nExtraction::JsExtractor.new

process_script = lambda do |file_contents, file_name, arg_block|
  extractor.translations = {}

  begin
    extractor.process(file_contents, *arg_block.call(file_contents))
  rescue Exception => e
    puts e
    raise "Error reading #{file_contents}: #{$!}\nYou should probably run `rake i18n:check' first"
  end

  translations.deep_merge!(extractor.translations || {})
end

process_files = lambda do |files, arg_block|
  files.each do |filename|
    scripts = I18nTasks::Utils.extract_js_scripts(File.read(filename))
    scripts.each do |script|
      process_script.call(script, filename, arg_block)
    end
  end
end

process_files.call([ source ], lambda { |file| [{:filename => file}] })

puts JSON.pretty_generate(translations)