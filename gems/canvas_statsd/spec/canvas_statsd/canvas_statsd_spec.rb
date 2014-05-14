#
# Copyright (C) 2014 Instructure, Inc.
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

require 'spec_helper'

describe CanvasStatsd do
  before(:each) do
    CanvasStatsd.settings = {}
  end

  describe ".settings" do
    it "have default settings" do
      expect(CanvasStatsd.settings).to eq({})
    end

    it "can be assigned a new value" do
      settings = {foo: 'bar', baz: 'apple'}
      CanvasStatsd.settings = settings

      expect(CanvasStatsd.settings).to eq settings
    end
  end
end