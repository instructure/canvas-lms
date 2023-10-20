# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Canvas::Plugins::Validators::GoogleDriveValidator
  def self.validate(settings, plugin_setting)
    if settings.map(&:last).all?(&:blank?)
      {
        client_id: "",
        client_secret: "",
        redirect_uri: "",
        client_secret_json: ""
      }
    elsif (res = check_json(settings))
      plugin_setting.errors.add(:base, res)
      false
    else
      if settings["client_secret_json"].present?
        parsed = JSON.parse(settings["client_secret_json"])["web"]
        to_return = {
          client_id: parsed["client_id"],
          client_secret: parsed["client_secret"],
          redirect_uri: parsed["redirect_uris"][0], # we only care about the first one
          client_secret_json: ""
        }
      else
        to_return = settings.to_hash.with_indifferent_access
      end
      to_return
    end
  end

  def self.check_json(settings)
    return nil if settings["client_secret_json"].blank?

    begin
      jayson = JSON.parse(settings["client_secret_json"])
      if !!jayson # if is valid json
        return "Missing application type (Needs `web` somewhere in there)" unless jayson["web"]
        return "Missing `client_id`" unless jayson["web"]["client_id"]
        return "Missing `client_secret`" unless jayson["web"]["client_secret"]

        "Missing `redirect_uris` (need at least one)" unless jayson["web"]["redirect_uris"]
      end
    rescue TypeError, JSON::JSONError => e
      "Is not valid JSON \n (#{e.message}) \n (#{e.backtrace.inspect})"
    end
  end
end
