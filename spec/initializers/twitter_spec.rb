# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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
require_relative '../../config/initializers/twitter'

describe CanvasTwitterConfig do

  describe "#call" do
    it "returns a config with indifference access" do
      plugin = double(settings: {consumer_key: "abcdefg", consumer_secret_dec: "12345"})
      allow(Canvas::Plugin).to receive(:find).with(:twitter).and_return(plugin)
      output = described_class.call
      expect(output['api_key']).to eq("abcdefg")
      expect(output[:api_key]).to eq("abcdefg")
    end
  end
end
