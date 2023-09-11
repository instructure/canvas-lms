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

describe I18nTimeZone do
  context "::all" do
    it "provides an array of i18n tz instances" do
      tzs = I18nTimeZone.all
      expect(tzs.first.class).to eq I18nTimeZone
      expect(tzs.count).to eq ActiveSupport::TimeZone.all.count # rubocop:disable Rails/RedundantActiveRecordAllMethod
    end
  end

  context "#keyify" do
    it "provides a translation key for valid time zone name" do
      t_key = I18nTimeZone["International Date Line West"].keyify
      expect(t_key).to eq "time_zones.international_date_line_west"
    end
  end

  context "localization" do
    it "presents a localized name with offset when responding to #to_s" do
      I18n.with_locale(:es) do
        I18n.backend.stub({ es: { time_zones: { international_date_line_west: "Línea de fecha internacional del oeste" } } }) do
          tz = I18nTimeZone["International Date Line West"]
          expect(tz.to_s).to include "Línea de fecha internacional del oeste"
        end
      end
    end

    it "has an entry in en locale for every time zone" do
      I18nTimeZone.all.each do |zone|
        expect(zone.to_s).to_not include("translation missing")
      end
    end
  end
end
