#!/usr/bin/env ruby
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
#
# rubocop:disable Rails/Output
# Auto-generate URL mappings from markdown documentation structure
#

require "json"

CURRENT_DIR = File.dirname(__FILE__)
TOC_FILE = File.join(CURRENT_DIR, "..", "..", "..", "public", "doc", "api_md", "toc.md")
# Default output to public/doc/api_md (alongside markdown docs, for deployment to Developer Portal)
DEFAULT_OUTPUT = File.join(CURRENT_DIR, "..", "..", "..", "public", "doc", "api_md", "url_mappings.json")
OUTPUT_FILE = ARGV[0] || DEFAULT_OUTPUT

OLD_BASE_URL = "https://canvas.instructure.com/doc/api"
NEW_BASE_URL = "https://developerdocs.instructure.com/services/canvas"

unless File.exist?(TOC_FILE)
  puts "ERROR: #{TOC_FILE} does not exist!"
  puts "Please run 'OUTPUT_FORMAT=markdown rake doc:api' first to generate markdown documentation."
  raise "TOC file not found"
end

# Parse the toc.md file and extract mappings
def parse_toc(file_path)
  mappings = []
  lines = File.readlines(file_path)
  section_stack = [] # Track current section path (excluding root)

  lines.each do |line|
    next if line.strip.empty?

    # Calculate indentation level
    indent_level = (line[/^\s*/].length / 2)
    next if indent_level == 0

    # Match markdown links: * [Title](filename.md)
    if line =~ /\*\s+\[([^\]]+)\]\(([^\s]+\.md)\)/
      title = Regexp.last_match(1)
      filename = Regexp.last_match(2)

      # Generate URLs
      old_url = generate_old_url(filename)
      new_url = generate_new_url(filename, section_stack)

      # Add mapping entries
      mappings.concat(create_mapping_entries(old_url, new_url, title, filename))
    # Match section headers: * SectionName (no link)
    elsif line =~ /\*\s+([^\[]+)$/ && line.strip != "*"
      section_name = Regexp.last_match(1).strip
      section_depth = indent_level - 1

      # Adjust section stack to match the current depth, then add new section
      section_stack = section_stack[0...section_depth]
      section_stack << section_name
    end
  end

  mappings
end

def generate_old_url(filename)
  html_filename = filename.gsub(/\.md$/, ".html")
  "#{OLD_BASE_URL}/#{html_filename}"
end

# Generate new URL format based on section hierarchy
def generate_new_url(filename, section_stack)
  # Special case: README maps to root
  return NEW_BASE_URL if filename == "README.md"

  # Build path from section stack
  path_segments = section_stack.map { |section| slugify(section) }
  file_segment = filename.gsub(/\.md$/, "")
  file_segment = slugify_filename(file_segment)
  full_path = (path_segments + [file_segment]).join("/")

  "#{NEW_BASE_URL}/#{full_path}"
end

def slugify(text)
  text.downcase
      .gsub(/\s+/, "-")        # spaces to hyphens
      .gsub(/[^\w.-]/, "-")    # non-word chars to hyphens (preserve dots for version numbers)
      .squeeze("-")            # collapse multiple hyphens
      .gsub(/^-|-$/, "")       # remove leading/trailing hyphens
end

# Convert filename to URL-friendly slug (preserve file. prefix)
def slugify_filename(filename)
  if filename.start_with?("file.")
    prefix = "file."
    rest = filename[5..]
  else
    prefix = ""
    rest = filename
  end

  prefix + slugify(rest)
end

# Create mapping entries (handling file.* prefix variants)
def create_mapping_entries(old_url, new_url, title, filename)
  entries = []

  entries << {
    "old_url" => old_url,
    "new_url" => new_url,
    "title" => title
  }

  # Handle file.* prefix variants
  if filename.start_with?("file.")
    without_prefix = filename.sub(/^file\./, "")
    alt_old_url = generate_old_url(without_prefix)

    entries << {
      "old_url" => alt_old_url,
      "new_url" => new_url,
      "title" => title
    }
  end

  entries
end

# Add special case redirects
def add_special_cases(mappings)
  special_cases = [
    {
      "old_url" => "#{OLD_BASE_URL}/index.html",
      "new_url" => NEW_BASE_URL,
      "title" => "Canvas LMS API Documentation"
    },
    {
      "old_url" => "#{OLD_BASE_URL}/all_resources.html",
      "new_url" => NEW_BASE_URL,
      "title" => "All Resources"
    }
  ]

  mappings + special_cases
end

begin
  mappings = parse_toc(TOC_FILE)

  mappings = add_special_cases(mappings)

  # Sort by old_url for consistency
  mappings.sort_by! { |m| m["old_url"] }

  # Remove duplicates
  mappings = mappings.uniq { |m| m["old_url"] }

  File.write(OUTPUT_FILE, JSON.pretty_generate(mappings))

  puts "✓ Generated #{mappings.count} URL mappings"
  puts "✓ Saved to: #{OUTPUT_FILE}"
  puts ""
rescue => e
  puts "ERROR: #{e.message}"
  puts e.backtrace
  raise
end
# rubocop:enable Rails/Output
