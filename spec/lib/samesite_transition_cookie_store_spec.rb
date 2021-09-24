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

require_relative '../spec_helper'

describe "SamesiteTransitionCookieStore" do
  describe "#unmarshal" do
    it "doesn't explode with malformed data" do
      app = double("SomeAppThing")
      options = {secret: "038c3fa7b8f07362f0a79db7e717eada"} #<- fake secret
      store = SamesiteTransitionCookieStore.new(app, options)
      expect(Canvas::Errors).to receive(:capture_exception) do |type, e, level|
        expect(level).to eq(:info)
        expect(e.class).to be(ArgumentError)
        expect(type).to eq(:cookie_store)
      end
      output = store.unmarshal("asdfasdfasdfasdf.asdfasdfasdfasdf.asdfasdfasdfasdf.asdfasdfasdfasdf")
      expect(output).to be_nil
    end
  end
end
