# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require "set"

path = ARGV[0] || "/tmp/crystalball"
map_header = nil
map_body = {}
Dir.glob("#{path}/**/*_map.yml") do |filename|
  puts "Looking through #{filename}"
  doc = File.read(filename)
  (header, body) = doc.split("---").reject(&:empty?)
  map_header ||= header.gsub(":timestamp:", ":timestamp: #{Time.now.utc}")
  puts "#{filename} Invalid! Likely contains spec failures" unless body
  next unless body

  body.split("\n").slice_when { |_before, after| after.include?(":") }.each do |group|
    spec = group.shift
    changed_files = group

    if spec.empty? || changed_files.count.zero?
      next
    else
      "'#{spec}' empty or Has 0 changed files!"
    end

    # JS files will be added to the map based on the parent directory of the file only
    # TODO: we should have a flag to filter JS at this level
    changed_files.map! do |file|
      if /(\.js|\.jsx|\.ts|\.tsx)/.match?(file)
        # Wrap in File.dirname if we want to filter by directories
        file.gsub(%r{("|/usr/src/app/)}, "")
      else
        file
      end
    end

    puts "Adding onto duplicate key! #{spec}" if map_body[spec]

    map_body[spec] ||= Set.new
    map_body[spec] << changed_files.uniq
  end
end

map_header = map_header.gsub(":version:", ":version: #{map_body.keys.count} Tests Present in Map")

File.open("crystalball_map.yml", "w") do |file|
  file << "---"
  file << map_header
  file << "---"
  file << "\n"
  map_body.each do |spec, app_files|
    file.puts spec
    file.puts app_files.to_a.join("\n")
  end
end

map_files = map_body.keys.map { |spec_file| spec_file.split("[").first.gsub(%r{^"./}, "") }.uniq

puts "Crystalball Map Created for #{map_body.keys.count} tests in #{map_files.count} files"
