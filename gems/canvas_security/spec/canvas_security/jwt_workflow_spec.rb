# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

describe CanvasSecurity::JWTWorkflow do
  before do
    @c = "a_course"
    @a = "an_account"
  end

  describe "register/state_for" do
    it "uses block registerd with workflow to build state" do
      CanvasSecurity::JWTWorkflow.register(:foo) { |c, u| { c:, u: } }
      state = CanvasSecurity::JWTWorkflow.state_for(%i[foo], @c, @u)
      expect(state[:c]).to be(@c)
      expect(state[:u]).to be(@u)
    end

    it "returns an empty hash if if workflow is not registered" do
      state = CanvasSecurity::JWTWorkflow.state_for(%i[not_defined], @c, @u)
      expect(state).to be_empty
    end

    it "merges state of muliple workflows in order of array" do
      CanvasSecurity::JWTWorkflow.register(:foo) { { a: 1, b: 2 } }
      CanvasSecurity::JWTWorkflow.register(:bar) { { b: 3, c: 4 } }
      expect(CanvasSecurity::JWTWorkflow.state_for(%i[foo bar], nil, nil)).to include({ a: 1, b: 3, c: 4 })
      expect(CanvasSecurity::JWTWorkflow.state_for(%i[bar foo], nil, nil)).to include({ a: 1, b: 2, c: 4 })
    end
  end
end
