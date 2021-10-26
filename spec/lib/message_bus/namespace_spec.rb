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

describe MessageBus::Namespace do
  describe "suffix expansion" do
    it "adds no suffix when region code absent" do
      expect(Canvas.region_code).to be_nil
      ns = MessageBus::Namespace.build("ns-name")
      expect(ns.to_s).to eq("ns-name")
    end

    it "appends a cluster suffix when region present" do
      allow(Canvas).to receive(:region_code).and_return("abc")
      ns = MessageBus::Namespace.build("ns-name")
      expect(ns.to_s).to eq("ns-name-abc")
    end

    it "will not repeatedly extend a namespace name" do
      allow(Canvas).to receive(:region_code).and_return("abc")
      ns = MessageBus::Namespace.build("ns-name-abc")
      expect(ns.to_s).to eq("ns-name-abc")
    end

    it "returns the same namespace object if already built" do
      ns = MessageBus::Namespace.build("ns-name")
      ns2 = MessageBus::Namespace.build(ns)
      expect(ns.to_s).to eq(ns2.to_s)
    end
  end
end
