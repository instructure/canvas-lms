# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require "nokogiri"
require "shellwords"

module Qti
  PYTHON_MIGRATION_EXECUTABLE = "migrate.py"
  EXPECTED_LOCATION = Rails.root.join("vendor/QTIMigrationTool", PYTHON_MIGRATION_EXECUTABLE).to_s rescue nil
  EXPECTED_LOCATION_ALT = Rails.root.join("vendor/qti_migration_tool", PYTHON_MIGRATION_EXECUTABLE).to_s rescue nil
  @migration_executable = nil

  if File.exist?(EXPECTED_LOCATION)
    @migration_executable = EXPECTED_LOCATION
  elsif File.exist?(EXPECTED_LOCATION_ALT)
    @migration_executable = EXPECTED_LOCATION_ALT
  elsif /qti/i.match?(`#{PYTHON_MIGRATION_EXECUTABLE} --version 2>&1`)
    @migration_executable = PYTHON_MIGRATION_EXECUTABLE
  end

  def self.migration_executable
    @migration_executable
  end

  def self.qti_enabled?
    if (plugin = Canvas::Plugin.find(:qti_converter))
      return plugin.settings[:enabled].to_s == "true"
    end

    false
  end

  # Does a JSON export of the courses
  def self.save_to_file(hash, file_name = nil)
    file_name ||= File.join("log", "qti_export.json")
    File.open(file_name, "w") { |file| file << hash.to_json }
    file_name
  end

  def self.convert_questions(manifest_path, opts = {})
    sorted_paths = if (path_map = opts[:file_path_map])
                     # used when searching for matching file paths to help find the best matching path
                     path_map.keys.sort_by(&:length)
                   else
                     []
                   end
    questions = []
    doc = Nokogiri::XML(File.open(manifest_path))
    doc.css("manifest resources resource[type^=imsqti_item_xmlv2p]").each do |item|
      q = AssessmentItemConverter.create_instructure_question(opts.merge(manifest_node: item, base_dir: File.dirname(manifest_path), sorted_file_paths: sorted_paths))
      questions << q if q
    end
    questions
  end

  def self.convert_assessments(manifest_path, opts = {})
    assessments = []
    doc = Nokogiri::XML(File.open(manifest_path))
    doc.css("manifest resources resource[type=imsqti_assessment_xmlv2p1], manifest resources resource[type=imsqti_test_xmlv2p1]").each do |item|
      a = AssessmentTestConverter.new(item, File.dirname(manifest_path), opts).create_instructure_quiz
      assessments << a if a
    end
    assessments
  end

  def self.convert_xml(xml, opts = {})
    assessments = nil
    questions = nil
    Dir.mktmpdir do |dirname|
      xml_file = File.join(dirname, opts[:file_name] || "qti.xml")
      File.open(xml_file, "w") { |f| f << xml }

      # convert to 2.1
      dest_dir_2_1 = File.join(dirname, "qti_2_1")
      command = Qti.get_conversion_command(dest_dir_2_1, dirname)
      output = `#{command}`

      if $?.exitstatus == 0
        manifest = File.join(dest_dir_2_1, "imsmanifest.xml")
        questions = convert_questions(manifest, opts)
        assessments = convert_assessments(manifest, opts)
      else
        raise "Error running python qti converter: #{output}"
      end
    end
    [questions, assessments]
  end

  def self.convert_files(manifest_path)
    attachments = []
    doc = Nokogiri::XML(File.open(manifest_path))
    resource_nodes = doc.css("resource")
    doc.css("file").each do |file|
      # skip resource nodes, which are things like xml metadata and other sorts
      next if resource_nodes.any? { |node| node["href"] == file["href"] }

      # anything left is a file that needs to become an attachment on the context
      attachments << CGI.unescape(file["href"])
    end
    attachments
  end

  def self.get_conversion_command(out_dir, manifest_file, file_path_prepend = nil)
    if @migration_executable.nil?
      raise "Couldn't find QTI Migration Tool. See https://github.com/instructure/QTIMigrationTool/wiki for installation instructions."
    else
      prepend = file_path_prepend ? "--pathprepend=\"#{file_path_prepend}\" " : ""
      "\"#{@migration_executable}\" #{prepend}--ucvars --nogui --overwrite --cpout=#{Shellwords.escape(out_dir)} #{Shellwords.escape(manifest_file)} 2>&1"
    end
  end
end
