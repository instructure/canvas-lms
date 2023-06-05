# frozen_string_literal: true

# Copyright (C) 2017 - present Instructure, Inc.
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
module CC
  module ToolProfiles
    def create_tool_profiles
      @course.tool_proxies.active.each do |tool_proxy|
        # This is grossness that I added until we have a proper
        # ToolProfile ActiveRecord class
        tool_proxy.define_singleton_method(:asset_string) do
          "tool_profile_#{id}"
        end
        next unless export_object?(tool_proxy, asset_type: "tool_profiles")

        migration_id = create_key(tool_proxy)

        file_name = "#{migration_id}.json"
        file_path = File.join(@export_dir, file_name)
        file = File.new(file_path, "w")

        data = serialize_tool_proxy(tool_proxy)
        file.write(data.to_json)
        file.close

        @resources.resource(identifier: migration_id, type: "tool_profile") do |res|
          res.file(href: file_name)
        end
      end
    end

    def serialize_tool_proxy(tool_proxy)
      {
        "tool_profile" => tool_proxy.raw_data["tool_profile"],
        "meta" => {
          "registration_url" => tool_proxy.registration_url || ""
        }
      }
    end
  end
end
