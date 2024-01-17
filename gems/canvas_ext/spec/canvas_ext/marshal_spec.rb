# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require "spec_helper"

class MarshalTesting
  def self.const_missing(class_name)
    class_eval "class #{class_name}; end; #{class_name}", __FILE__, __LINE__
  end
end

describe Marshal do
  it "retries .load() when an 'undefined class/module ...' error is raised" do
    str = Marshal.dump(MarshalTesting::BlankClass.new)
    MarshalTesting.send :remove_const, "BlankClass" # rubocop:disable RSpec/RemoveConst
    expect(Marshal.load(str)).to be_instance_of(MarshalTesting::BlankClass) # rubocop:disable Security/MarshalLoad
  end
end
