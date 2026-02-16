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
# Generate static HTML redirect files for each documentation page
#

require "json"
require "fileutils"

CURRENT_DIR = File.dirname(__FILE__)
# Default input from public/doc/api_md
DEFAULT_URL_MAP = File.join(CURRENT_DIR, "..", "..", "..", "public", "doc", "api_md", "url_mappings.json")
# Default output to public/doc/api
DEFAULT_OUTPUT_DIR = File.join(CURRENT_DIR, "..", "..", "..", "public", "doc", "api")
# ARGV[0] = output directory (required for backwards compatibility)
# ARGV[1] = input mappings file (default: url_mappings.json)
OUTPUT_DIR = ARGV[0] || DEFAULT_OUTPUT_DIR
URL_MAP = ARGV[1] || DEFAULT_URL_MAP

puts "Generating HTML redirect files..."
puts "Input: #{URL_MAP}"
puts "Output: #{OUTPUT_DIR}"
puts ""

# Load mapping
mapping = JSON.parse(File.read(URL_MAP))

# Create output directory
FileUtils.mkdir_p(OUTPUT_DIR)

# Template for redirect HTML
def generate_redirect_html(new_url, title, old_url)
  <<~HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>Redirecting to Canvas Developer Portal</title>
      <meta http-equiv="refresh" content="0; url=#{new_url}">
      <link rel="canonical" href="#{new_url}">
      <meta name="robots" content="noindex">
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
          max-width: 600px;
          margin: 100px auto;
          padding: 20px;
          text-align: center;
        }
        .banner {
          background: #0084ff;
          color: white;
          padding: 20px;
          border-radius: 8px;
          margin-bottom: 20px;
        }
        a {
          color: #0084ff;
          text-decoration: none;
          font-weight: bold;
        }
        a:hover {
          text-decoration: underline;
        }
        .spinner {
          border: 3px solid #f3f3f3;
          border-top: 3px solid #0084ff;
          border-radius: 50%;
          width: 40px;
          height: 40px;
          animation: spin 1s linear infinite;
          margin: 20px auto;
        }
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      </style>
      <script>
        // Immediate redirect via JavaScript
        window.location.href = "#{new_url}";
      </script>
    </head>
    <body>
      <div class="banner">
        <h1>📢 Documentation Has Moved!</h1>
      </div>
      <div class="spinner"></div>
      <p>Redirecting to the new Canvas Developer Portal...</p>
      <p><strong>New location:</strong> <a href="#{new_url}">#{title}</a></p>
      <p>If you are not redirected automatically, <a href="#{new_url}">click here</a>.</p>
      <hr style="margin: 40px 0; border: none; border-top: 1px solid #ddd;">
      <p style="font-size: 12px; color: #666;">
        Old URL: <code>#{old_url}</code><br>
        New URL: <code>#{new_url}</code>
      </p>
    </body>
    </html>
  HTML
end

# Generate redirect files
mapping.each_with_index do |entry, index|
  # Get the filename from old URL
  filename = entry["old_url"].split("/").last

  # Skip if it's not an HTML file
  next unless filename.end_with?(".html")

  filepath = File.join(OUTPUT_DIR, filename)

  # Generate HTML redirect
  html = generate_redirect_html(
    entry["new_url"],
    entry["title"] || filename.gsub(".html", "").tr("_", " ").capitalize,
    entry["old_url"]
  )

  File.write(filepath, html)

  print "\r✓ Generated #{index + 1}/#{mapping.count} redirects" if (index + 1) % 10 == 0
end

puts "\r✓ Generated #{mapping.count} HTML redirect files"
puts ""
puts "Files created in: #{OUTPUT_DIR}"
puts ""
# rubocop:enable Rails/Output
