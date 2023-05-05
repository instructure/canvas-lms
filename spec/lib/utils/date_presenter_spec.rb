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
  describe DatePresenter do
    describe "#as_string" do
      it "uses the medium date in long format" do
        date = Date.parse("2010-10-1")
        string = DatePresenter.new(date).as_string(:long)
        expect(string).to eq("Oct 1, 2010")
      end

      it "can use the short format" do
        date = Date.parse("2010-10-1")
        string = DatePresenter.new(date).as_string(:short)
        expect(string).to eq("Oct 1")
      end

      it "can use the full format" do
        date = Date.parse("2010-10-1")
        string = DatePresenter.new(date).as_string(:full)
        expect(string).to eq("Oct 1, 2010 12:00am")
      end

      describe "on relative dates" do
        let(:today) { Date.parse("2014-10-1") }

        around do |example|
          Timecop.freeze(today, &example)
        end

        it "returns Today for today" do
          expect(DatePresenter.new(today).as_string).to eq("Today")
        end

        it "returns Tomorrow for tomorrow" do
          expect(DatePresenter.new(today + 1).as_string).to eq("Tomorrow")
        end

        it "returns Yesterday for yesterday" do
          expect(DatePresenter.new(today - 1).as_string).to eq("Yesterday")
        end

        it "provides weekday names for this week" do
          expect(DatePresenter.new(today + 2).as_string).to eq("Friday")
        end
      end
    end
  end
end
