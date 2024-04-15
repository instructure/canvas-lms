# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

# This config file is used for switching environment variables
# that need to be set before rails initialization even starts.
# That's why it is required directly from the Gemfile.

# You can set the Rails version to use by:
# 1. CANVAS_RAILS="<supported version>"
# 2. Create a file RAILS_VERSION with <supported version> as the contents
# 3. Create a Consul setting private/canvas/rails_version with <supported version> as the contents

# the default version (corresponding to the bare Gemfile.lock) must be listed first
SUPPORTED_RAILS_VERSIONS = %w[7.0 7.1].freeze

unless defined?($canvas_rails)
  file_path = File.expand_path("RAILS_VERSION", __dir__)

  if ENV["CANVAS_RAILS"]
    $canvas_rails = ENV["CANVAS_RAILS"]
  elsif File.exist?(file_path)
    $canvas_rails = File.read(file_path).strip
  else
    begin
      # have to do the consul communication without any gems, because
      # we're in the context of loading the gemfile
      require "base64"
      require "json"
      require "net/http"
      require "yaml"

      environment = YAML.safe_load_file(File.expand_path("consul.yml", __dir__)).dig(ENV["RAILS_ENV"] || "development", "environment")

      keys = ($canvas_clusters || []).map do |canvas_cluster| # rubocop:disable Style/GlobalVars
        "private/canvas/#{environment}/#{canvas_cluster}/rails_version"
      end

      keys.push(
        ["private/canvas", environment, "rails_version"].compact.join("/"),
        ["private/canvas", "rails_version"].compact.join("/"),
        ["global/private/canvas", environment, "rails_version"].compact.join("/"),
        ["global/private/canvas", "rails_version"].compact.join("/")
      )
      keys.uniq!

      result = nil
      Net::HTTP.start("localhost", 8500, connect_timeout: 1, read_timeout: 1) do |http|
        keys.each do |key|
          result = http.request_get("/v1/kv/#{key}?stale")
          result = nil unless result.is_a?(Net::HTTPSuccess)
          break if result
        end
      end
      $canvas_rails = result ? Base64.decode64(JSON.parse(result.body).first["Value"]).strip : SUPPORTED_RAILS_VERSIONS.first
    rescue
      $canvas_rails = SUPPORTED_RAILS_VERSIONS.first
    end
  end
end

unless SUPPORTED_RAILS_VERSIONS.any?($canvas_rails)
  raise "unsupported Rails version specified #{$canvas_rails}"
end
