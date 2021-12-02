# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "turnitin_api"
require "webmock/rspec"

RSpec.configure do |config|
  config.before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end
  config.after do
    WebMock.allow_net_connect!
  end
end

def fixture(*file)
  File.new(File.join(File.expand_path("fixtures", __dir__), *file))
end

def json_fixture(*file)
  JSON.parse(fixture(*file).read)
end
