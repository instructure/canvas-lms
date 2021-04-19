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
#

require 'switchman/r_spec_helper'
require_relative 'spec_helper'
require_relative 'support/onceler/sharding'

def has_sharding?
  User.instance_method(:associated_shards).owner != User
end

def specs_require_sharding
  if has_sharding?
    include Switchman::RSpecHelper
    include Onceler::Sharding
  else
    before(:once) do
      skip 'Sharding specs fail without additional support from a multi-tenancy plugin'
    end
  end
end
