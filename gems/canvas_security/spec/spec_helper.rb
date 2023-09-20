# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "debug"
require "canvas_security"
require "rails"
Rails.env = "test"
Time.zone = "UTC"

# Right now Canvas injects the Setting class as the store.
# It would be great to pull that one out to something we can
# depend on as an adapter that Canvas can submit Setting itself
# as a strategy for...anyway, use this for now for specs
class MemorySettings
  def initialize(data = {})
    @settings = data || {}
  end

  def get(key, default)
    @settings.fetch(key, default)
  end

  def set(key, value)
    @settings[key] = value
  end

  def skip_cache
    yield
  end
end
CanvasSecurity.settings_store = MemorySettings.new

require "canvas_security/spec/jwt_env"

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = "random"

  config.before do
    # load config from local spec/fixtures/config/redis.yml
    # so that we have something for ConfigFile to parse.
    target_location = Pathname.new(File.join(File.dirname(__FILE__), "fixtures"))
    allow(Rails).to receive(:root).and_return(target_location)
  end
end
