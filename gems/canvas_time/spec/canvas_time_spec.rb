# frozen_string_literal: true

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
#

require "spec_helper"

# rubocop:disable Security/MarshalLoad
describe "Time Marshal override" do
  it "preserves the old marshalling for post-1900 dates" do
    raw_time = Time.zone.parse("2013-02-16 05:43:21.15Z").time
    dumped = Marshal.dump(raw_time)
    expect(dumped).to include(":\tTime\r\x05F\x1C#{0xc0.chr}#{0xf0.chr}IR#{0xad.chr}")
    reloaded = Marshal.load(dumped)
    expect(reloaded).to eq(raw_time)
  end

  it "does not fail for pre-1900 dates" do
    old_time = Time.zone.parse("0010-05-13 04:12:51Z")
    raw_time = old_time.time
    dumped = Marshal.dump(raw_time)
    # the last character differs between ruby 1.9 and ruby 2.1
    expect(dumped[0..-2]).to eq("\x04\bIu:\tTime!pre1900:0010-05-13T04:12:51Z\x06:\x06E")
    expect(%w[F T]).to include(dumped[-1])
    dumped[-1] = "F"
    reloaded = Marshal.load(dumped)
    expect(reloaded).to eq(raw_time)
    dumped[-1] = "T"
    reloaded = Marshal.load(dumped)
    expect(reloaded).to eq(raw_time)
    # confirm it works for TimeWithZone as well
    expect(Marshal.load(Marshal.dump(old_time))).to eq(old_time)
  end
end
# rubocop:enable Security/MarshalLoad

describe "utc_datetime" do
  it "returns a DateTime" do
    expect(Time.now.utc_datetime).to be_a(DateTime)
  end

  it "is initialized from the given time" do
    t = Time.utc(2000, "jan", 3, 20, 15, 1)
    utc_datetime = t.utc_datetime

    expect(utc_datetime.iso8601).to eq "2000-01-03T20:15:00+00:00"
  end
end

describe "fancy_midnight" do
  it "doesn't stomp on your Jenkins specs at midnight UTC" do
    time = Time.now.beginning_of_day + 4.seconds
    expect(CanvasTime.fancy_midnight(time)).to eq(time)
    expect(CanvasTime.fancy_midnight(time.beginning_of_day)).to eq time.end_of_day
  end
end
