# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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
#
require "nokogiri"

class SkippedSpecsManager
  FILENAME = "skipped_specs.json"
  COVERAGE_RUN_FREQUENCY = 1

  def initialize(mode = "ruby")
    @new_map = {}
    @existing_map = {}
    @updated_map = {}
    @mode = mode
    determine_settings
  end

  def determine_settings
    @path_to_specs = if @mode == "ruby"
                       "/tmp/*_rspec_results"
                     else
                       "/tmp/js-results"
                     end
    puts "Path to specs: #{@path_to_specs}"
  end

  def create_new_map
    Dir.glob("#{@path_to_specs}/**/*.xml") do |filename|
      puts "Looking at #{filename}"
      f = File.read(filename)
      parsed_info = Nokogiri::XML(f)
      skipped_specs = parsed_info.xpath("//testcase/skipped")
      # classname attr for both JS and Ruby reflects the file hierarchy
      # name is a description of the test
      skipped_specs.each do |spec|
        key = if spec.parent[:file]
                "#{spec.parent[:file]}__#{spec.parent[:name]}"
              else
                spec.parent[:name]
              end
        puts "Duplicate entry for '#{key}' found!" if @new_map[key]
        @new_map[key] = {
          file_indicator: spec.parent[:file],
          description: spec.parent[:name],
          duration: 0
        }
      end
    end
  end

  def read_existing_map
    f = File.read(FILENAME)
    @existing_map = JSON.parse(f)
  rescue Errno::ENOENT
    puts "No existing #{FILENAME} found"
  end

  def resolve_maps
    @new_map.each do |spec_key, attrs|
      if @existing_map[spec_key]
        duration = @existing_map[spec_key]["duration"].to_i
        attrs[:duration] = attrs[:duration].to_i + duration + COVERAGE_RUN_FREQUENCY
      end
      @updated_map[spec_key] = attrs
    end
  end

  def write_to_file
    path = (@mode == "ruby") ? "/usr/src/app/out/" : "/tmp/"
    full_path = "#{path}/#{FILENAME}"

    puts "writing #{@updated_map.keys.count} spec(s) to '#{full_path}'"
    File.write(full_path, @updated_map.sort_by { |_spec_key, attrs| -attrs[:duration] }.to_h.to_json)
  end
end

manager = SkippedSpecsManager.new(ARGV[0])
manager.read_existing_map
manager.create_new_map
manager.resolve_maps
manager.write_to_file
