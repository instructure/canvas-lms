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

# You can enable the Rails 5.1 support by either defining a
# CANVAS_RAILS5_1=1 env var, creating an empty RAILS5_1 file in the canvas config dir,
# or setting `private/canvas/rails5.1` to `true` in a locally accessible consul
unless defined?(CANVAS_RAILS5_1)
  if ENV['CANVAS_RAILS5_2']
    CANVAS_RAILS5_1 = ENV['CANVAS_RAILS5_2'] == '0'
  elsif File.exist?(File.expand_path("../RAILS5_2", __FILE__))
    CANVAS_RAILS5_1 = false
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
        ["private/canvas", environment, $canvas_cluster, "rails5.2"].compact.join("/"),
        ["private/canvas", environment, "rails5.2"].compact.join("/"),
        ["global/private/canvas", environment, "rails5.2"].compact.join("/")
      ].uniq

      result = nil
      keys.each do |key|
        result = Net::HTTP.get_response(URI("http://localhost:8500/v1/kv/#{key}"))
        result = nil unless result.is_a?(Net::HTTPSuccess)
        break if result
      end
      CANVAS_RAILS5_1 = !(result && Base64.decode64(JSON.load(result.body).first['Value']) == 'false')
    rescue
      CANVAS_RAILS5_1 = true
    end
  end
end
