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

require 'yaml'

module DrDiff
  class UserConfig
    USER_CONFIG_FILE = File.expand_path("../../../config/gergich_user_config.yml", __FILE__)

    def self.user_config
      @user_config ||= begin
        if File.exist?(USER_CONFIG_FILE)
          YAML.load_file(USER_CONFIG_FILE)
        else
          {}
        end
      end
    end

    def self.only_report_errors?
      user_list = user_config["only_report_errors"] || []
      user_list.include?(ENV['GERRIT_EVENT_ACCOUNT_EMAIL'])
    end
  end
end
