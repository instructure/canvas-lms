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

require "google_drive"
require "debug"
require "timecop"
require "webmock/rspec"

DRIVE_FIXTURES_PATH = File.dirname(__FILE__) + "/fixtures/google_drive/"

def load_fixture(filename)
  File.read(DRIVE_FIXTURES_PATH + filename)
end

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.color = true

  config.order = "random"

  config.before do
    WebMock.disable_net_connect!(allow_localhost: true)
  end
  config.after do
    WebMock.allow_net_connect!
  end
end
