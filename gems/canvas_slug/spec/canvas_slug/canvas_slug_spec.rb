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
#

require 'spec_helper'

describe CanvasSlug do
  let(:subject) {CanvasSlug}

  describe ".generate_securish_uuid" do
    it "returns a securish uuid" do
      expect(subject.generate_securish_uuid).to be_a(String)
    end

    it "works with length 0" do
      expect(subject.generate_securish_uuid(0)).to eq ""
    end
  end

  describe ".generate" do
    it "returns a string" do
      expect(subject.generate).to be_a(String)
    end

    it "prepends a provided purpose" do
      expect(subject.generate("foobar")).to match /\Afoobar-\w{4}\z/
    end
  end
end
