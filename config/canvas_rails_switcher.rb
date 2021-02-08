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

# You can enable the Rails 6.0 support by either defining a
# CANVAS_RAILS6_0=1 env var, creating an empty RAILS6_0 file in the canvas config dir,
# or setting `private/canvas/rails6.0` to `true` in a locally accessible consul
unless defined?(CANVAS_RAILS5_2)
  if ENV['CANVAS_RAILS6_0']
    CANVAS_RAILS5_2 = ENV['CANVAS_RAILS6_0'] == '0'
  elsif File.exist?(File.expand_path("../RAILS6_0", __FILE__))
    CANVAS_RAILS5_2 = false
  else
    begin
      # have to do the consul communication without any gems, because
      # we're in the context of loading the gemfile
      require 'base64'
      require 'json'
      require 'net/http'
      require 'yaml'

      environment = YAML.load(File.read(File.expand_path("../consul.yml", __FILE__))).dig(ENV['RAILS_ENV'] || 'development', 'environment')

      keys = [
        ["private/canvas", environment, $canvas_cluster, "rails6.0"].compact.join("/"),
        ["private/canvas", environment, "rails6.0"].compact.join("/"),
        ["private/canvas", "rails6.0"].compact.join("/"),
        ["global/private/canvas", environment, "rails6.0"].compact.join("/"),
        ["global/private/canvas", "rails6.0"].compact.join("/")
      ].uniq

      result = nil
      keys.each do |key|
        result = Net::HTTP.get_response(URI("http://localhost:8500/v1/kv/#{key}?stale"))
        result = nil unless result.is_a?(Net::HTTPSuccess)
        break if result
      end
      CANVAS_RAILS5_2 = !(result && Base64.decode64(JSON.load(result.body).first['Value']) == 'true')
    rescue
      CANVAS_RAILS5_2 = true
    end
  end
end
