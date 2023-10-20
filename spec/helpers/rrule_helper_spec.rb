# frozen_string_literal: true

# Copyright (C) 2011 - present Instructure, Inc.
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

describe RruleHelper do
  include RruleHelper

  shared_examples "rrule variants" do |rrule, expected_result|
    let(:rrule) { rrule }
    let(:expected_result) { expected_result }

    it "converts an rrule to natural language" do
      result = rrule_to_natural_language(rrule)
      expect(result).to eql(expected_result)
    end
  end

  describe "rruleToNaturalLanguage" do
    @rrule_to_natural_lang = {
      "FREQ=DAILY;INTERVAL=1;COUNT=3" => "Daily, 3 times",
      "FREQ=DAILY;INTERVAL=3;COUNT=3" => "Every 3 days, 3 times",
      "FREQ=DAILY;INTERVAL=1;UNTIL=20220708T000000Z" => "Daily until Jul 8, 2022",
      "FREQ=DAILY;INTERVAL=3;UNTIL=20220708T000000Z" => "Every 3 days until Jul 8, 2022",
      "FREQ=WEEKLY;INTERVAL=1;COUNT=3" => "Weekly, 3 times",
      "FREQ=WEEKLY;INTERVAL=1;UNTIL=20220729T000000Z" => "Weekly until Jul 29, 2022",
      "FREQ=WEEKLY;INTERVAL=1;BYDAY=TU,TH;COUNT=3" => "Weekly on Tue, Thu, 3 times",
      "FREQ=WEEKLY;INTERVAL=1;BYDAY=TU,TH;UNTIL=20220729T000000Z" => "Weekly on Tue, Thu until Jul 29, 2022",
      "FREQ=WEEKLY;INTERVAL=2;COUNT=3" => "Every 2 weeks, 3 times",
      "FREQ=WEEKLY;INTERVAL=2;UNTIL=20220729T000000Z" => "Every 2 weeks until Jul 29, 2022",
      "FREQ=WEEKLY;INTERVAL=3;BYDAY=TU,TH;COUNT=3" => "Every 3 weeks on Tue, Thu, 3 times",
      "FREQ=WEEKLY;INTERVAL=3;BYDAY=TU,TH;UNTIL=20220729T000000Z" => "Every 3 weeks on Tue, Thu until Jul 29, 2022",
      "FREQ=MONTHLY;INTERVAL=1;COUNT=3" => "Monthly, 3 times",
      "FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=15;COUNT=3" => "Monthly on day 15, 3 times",
      "FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=3,5;COUNT=3" => "Monthly on days 3,5, 3 times",
      "FREQ=MONTHLY;INTERVAL=2;BYMONTHDAY=15;COUNT=3" => "Every 2 months on day 15, 3 times",
      "FREQ=MONTHLY;INTERVAL=2;BYMONTHDAY=3,5;COUNT=3" => "Every 2 months on days 3,5, 3 times",
      "FREQ=MONTHLY;INTERVAL=1;UNTIL=20220729T000000Z" => "Monthly until Jul 29, 2022",
      "FREQ=MONTHLY;INTERVAL=2;UNTIL=20220729T000000Z" => "Every 2 months until Jul 29, 2022",
      "FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=5;UNTIL=20220729T000000Z" => "Monthly on day 5 until Jul 29, 2022",
      "FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=3,5;UNTIL=20220729T000000Z" => "Monthly on days 3,5 until Jul 29, 2022",
      "FREQ=MONTHLY;INTERVAL=2;BYMONTHDAY=5;UNTIL=20220729T000000Z" => "Every 2 months on day 5 until Jul 29, 2022",
      "FREQ=MONTHLY;INTERVAL=2;BYMONTHDAY=3,5;UNTIL=20220729T000000Z" => "Every 2 months on days 3,5 until Jul 29, 2022",
      "FREQ=MONTHLY;INTERVAL=1;BYDAY=TU,TH;COUNT=3" => "Monthly every Tue, Thu, 3 times",
      "FREQ=MONTHLY;INTERVAL=2;BYDAY=TU,TH;COUNT=3" => "Every 2 months on Tue, Thu, 3 times",
      "FREQ=MONTHLY;INTERVAL=1;BYDAY=1TU;COUNT=3" => "Monthly on the 1st Tue, 3 times",
      "FREQ=MONTHLY;INTERVAL=2;BYDAY=1TU,1TH;COUNT=3" => "Every 2 months on the 1st Tue, Thu, 3 times",
      "FREQ=MONTHLY;INTERVAL=1;BYDAY=TU,TH;UNTIL=20220729T000000Z" => "Monthly every Tue, Thu until Jul 29, 2022",
      "FREQ=MONTHLY;INTERVAL=2;BYDAY=TU,TH;UNTIL=20220729T000000Z" => "Every 2 months on Tue, Thu until Jul 29, 2022",
      "FREQ=MONTHLY;INTERVAL=1;BYDAY=2TU;UNTIL=20220729T000000Z" => "Monthly on the 2nd Tue until Jul 29, 2022",
      "FREQ=MONTHLY;INTERVAL=2;BYDAY=2TU,2TH;UNTIL=20220729T000000Z" => "Every 2 months on the 2nd Tue, Thu until Jul 29, 2022",
      "FREQ=YEARLY;INTERVAL=1;BYMONTH=07;BYDAY=TU;COUNT=3" => "Annually on the first Tue of July, 3 times",
      "FREQ=YEARLY;INTERVAL=2;BYMONTH=07;BYDAY=2TU;COUNT=3" => "Every 2 years on the 2nd Tue of July, 3 times",
      "FREQ=YEARLY;INTERVAL=1;BYMONTH=07;BYDAY=TU;UNTIL=20220729T000000Z" => "Annually on the first Tue of July until Jul 29, 2022",
      "FREQ=YEARLY;INTERVAL=2;BYMONTH=07;BYDAY=2TU,2TH;UNTIL=20220729T000000Z" => "Every 2 years on the 2nd Tue, Thu of July until Jul 29, 2022",
      "FREQ=YEARLY;INTERVAL=1;BYMONTH=07;BYMONTHDAY=5;COUNT=3" => "Annually on Jul 5, 3 times",
      "FREQ=YEARLY;INTERVAL=2;BYMONTH=07;BYMONTHDAY=5;COUNT=3" => "Every 2 years on Jul 5, 3 times",
      "FREQ=YEARLY;INTERVAL=1;BYMONTH=07;BYMONTHDAY=5;UNTIL=20220729T000000Z" => "Annually on Jul 5 until Jul 29, 2022",
      "FREQ=YEARLY;INTERVAL=2;BYMONTH=07;BYMONTHDAY=5;UNTIL=20220729T000000Z" => "Every 2 years on Jul 5 until Jul 29, 2022",
      "FREQ=YEARLY;BYMONTH=2;BYMONTHDAY=29;INTERVAL=1;COUNT=3" => "Annually on Feb 29, 3 times",
      "FREQ=BOGUS;INTERVAL=1;COUNT=3" => nil # bogus frequency
    }

    @rrule_to_natural_lang.each_key do |rrule|
      include_examples "rrule variants", rrule, @rrule_to_natural_lang[rrule]
    end
  end

  describe "rrule_parse" do
    # just a rudimentary spec, since it gets thoroughly exercised in the specs above
    it "parses an RRULE into a hash" do
      rrule = rrule_parse("FREQ=DAILY;INTERVAL=1;COUNT=3")
      expect(rrule["FREQ"]).to eql("DAILY")
      expect(rrule["INTERVAL"]).to eql("1")
      expect(rrule["COUNT"]).to eql("3")
    end
  end

  describe "rrule_validate_common_opts" do
    it "catches missing INTERVAL" do
      expect { rrule_validate_common_opts(rrule_parse("FREQ=DAILY;COUNT=3")) }.to raise_error(RruleValidationError, "Missing INTERVAL")
    end

    it "catches an invalid INTERVAL" do
      expect { rrule_validate_common_opts(rrule_parse("FREQ=DAILY;INTERVAL=0;COUNT=3")) }.to raise_error(RruleValidationError, "INTERVAL must be > 0")
      expect { rrule_validate_common_opts(rrule_parse("FREQ=DAILY;INTERVAL=X;COUNT=3")) }.to raise_error(RruleValidationError, "INTERVAL must be > 0")
    end

    it "catches missing COUNT and UNTIl" do
      expect { rrule_validate_common_opts(rrule_parse("FREQ=DAILY;INTERVAL=1")) }.to raise_error(RruleValidationError, "Missing COUNT or UNTIL")
    end

    it "catches invalid COUNT" do
      max_count = RruleHelper::RECURRING_EVENT_LIMIT
      expect { rrule_validate_common_opts(rrule_parse("FREQ=DAILY;INTERVAL=1;COUNT=0")) }.to raise_error(RruleValidationError, "COUNT must be > 0")
      expect { rrule_validate_common_opts(rrule_parse("FREQ=DAILY;INTERVAL=1;COUNT=X")) }.to raise_error(RruleValidationError, "COUNT must be > 0")
      expect { rrule_validate_common_opts(rrule_parse("FREQ=DAILY;INTERVAL=1;COUNT=#{max_count + 1}")) }.to raise_error(RruleValidationError, "COUNT must be <= #{max_count}")
    end

    it "catches invalid UNTIL" do
      expect { rrule_validate_common_opts(rrule_parse("FREQ=DAILY;INTERVAL=1;UNTIL=20220931")) }.to raise_error(RruleValidationError, "Invalid UNTIL '20220931'")
      expect { rrule_validate_common_opts(rrule_parse("FREQ=DAILY;INTERVAL=1;UNTIL=X")) }.to raise_error(RruleValidationError, "Invalid UNTIL 'X'")
    end
  end
end
