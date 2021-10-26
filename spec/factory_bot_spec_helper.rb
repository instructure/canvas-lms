# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative 'spec_helper'

# NOTE/RANT: bringing this in should not be construed as an endorsement of FactoryBot
# i honestly have no idea how to use it
# but for whatever reason the conditional_release peeps liked it
# and bringing it into canvas seemed like the easiest solution
# since absorbing the code into the hivemind is going to be hard enough
# without having to rewrite all their specs into a canvas-y way

require 'factory_bot'
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    unless FactoryBot.definition_file_paths == %w{spec/factory_bot} # already loaded
      FactoryBot.definition_file_paths = %w{spec/factory_bot}
      FactoryBot.find_definitions
    end
  end
end
