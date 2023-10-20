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

require "active_support"
require "active_support/core_ext/object/blank"

module AdheresToPolicy
  require "adheres_to_policy/cache"
  require "adheres_to_policy/class_methods"
  require "adheres_to_policy/condition"
  require "adheres_to_policy/configuration"
  require "adheres_to_policy/instance_methods"
  require "adheres_to_policy/policy"
  require "adheres_to_policy/results"

  @configuration = Configuration.new
  class << self
    attr_reader :configuration

    def configure
      yield(configuration)
    end
  end
end
