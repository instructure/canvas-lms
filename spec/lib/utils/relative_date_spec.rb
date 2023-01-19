# frozen_string_literal: true

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
#
# Copyright (C) 2011 Instructure, Inc.
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

require_relative "../../spec_helper"

module Utils
  describe RelativeDate do
    let(:today) { Date.parse("2014-10-1") }

    around do |example|
      Timecop.freeze(today, &example)
    end

    it "can tell if its today" do
      expect(RelativeDate.new(today).today?).to be(true)
      expect(RelativeDate.new(today + 3).today?).to be(false)
    end

    it "can tell if its tomorrow" do
      expect(RelativeDate.new(today).tomorrow?).to be(false)
      expect(RelativeDate.new(today + 1).tomorrow?).to be(true)
    end

    it "can tell if its yesterday" do
      expect(RelativeDate.new(today).yesterday?).to be(false)
      expect(RelativeDate.new(today - 1).yesterday?).to be(true)
    end

    it "can tell if its this week" do
      expect(RelativeDate.new(today - 1).this_week?).to be(false)
      expect(RelativeDate.new(today + 4).this_week?).to be(true)
    end

    it "can tell if its this year" do
      expect(RelativeDate.new(today + 365).this_year?).to be(false)
      expect(RelativeDate.new(today + 30).this_year?).to be(true)
    end

    it "is resiliant against nil timezone override" do
      no_zone_date = RelativeDate.new(today, nil)
      expect(no_zone_date.today?).to be(true)
    end
  end
end
