# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

Dir[File.join(File.dirname(__FILE__), "../gems/plugins/*")].each do |plugin_dir|
  gem(File.basename(plugin_dir), path: plugin_dir)
end

# Private Plugin Alignment
gem "activeresource", "6.0.0"
gem "colorize", "0.8.1", require: false
gem "crypt", ">= 2.2.0"
gem "dynect4r", "0.2.4"
gem "maxminddb", "0.1.22"
gem "mechanize", "2.7.7"
gem "restforce", "5.0.3"
gem "sshkey", "2.0.0"
gem "xml-simple", "1.1.5"
gem "zendesk_api", "1.28.0"

group :test do
  gem "vcr", "6.1.0"
end

# Private Dependency Sub-Dependencies
gem "typhoeus", "~> 1.3"
