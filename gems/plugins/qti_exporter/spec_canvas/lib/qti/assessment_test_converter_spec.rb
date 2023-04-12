# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../../qti_helper"

describe Qti::AssessmentTestConverter do
  it "interprets duration strings that include units" do
    assess = Qti::AssessmentTestConverter

    minutes_in_hour = 60
    minutes_in_day = 24 * minutes_in_hour

    expect(assess.parse_time_limit("D1")).to eq minutes_in_day
    expect(assess.parse_time_limit("d2")).to eq 2 * minutes_in_day
    expect(assess.parse_time_limit("H4")).to eq 4 * minutes_in_hour
    expect(assess.parse_time_limit("h1")).to eq minutes_in_hour
    expect(assess.parse_time_limit("M120")).to eq 120
    expect(assess.parse_time_limit("m14")).to eq 14

    # Canvas uses minutes, QTI uses seconds
    expect(assess.parse_time_limit("60")).to eq 1
    expect(assess.parse_time_limit("3600")).to eq 60
  end

  def test_section(select)
    Nokogiri::XML(<<~XML).at_css("testPart")
      <testPart identifier="BaseTestPart">
      #{select && %(<selection select="#{select}">)}
      </testPart>
    XML
  end

  it "accepts a numeric pick count even if it's zero" do
    assess = Qti::AssessmentTestConverter
    expect(assess.parse_pick_count(test_section(" 1"))).to eq 1
    expect(assess.parse_pick_count(test_section("0"))).to eq 0
    expect(assess.parse_pick_count(test_section("-5"))).to be_nil
    expect(assess.parse_pick_count(test_section(""))).to be_nil
    expect(assess.parse_pick_count(test_section("puppies"))).to be_nil
    expect(assess.parse_pick_count(test_section(nil))).to be_nil
  end
end
