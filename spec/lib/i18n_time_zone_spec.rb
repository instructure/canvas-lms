# encoding: UTF-8
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe I18nTimeZone do
  context "::all" do
    it "should provide an array of i18n tz instances" do
      tzs = I18nTimeZone.all
      expect(tzs.first.class).to eq I18nTimeZone
      expect(tzs.count).to eq ActiveSupport::TimeZone::MAPPING.count
    end
  end

  context "#keyify" do
    it "should provide a translation key for valid time zone name" do
      t_key = I18nTimeZone['International Date Line West'].keyify
      expect(t_key).to eq "#time_zones.international_date_line_west"
    end
  end

  context "localization" do
    before { I18n.locale = I18n.default_locale }
    after  { I18n.locale = I18n.default_locale }

    it "should present a localized name with offset when responding to #to_s" do
      I18n.locale = :es
      I18n.backend.stub({es: { time_zones: { international_date_line_west: "Línea de fecha internacional del oeste" }}}) do
        tz = I18nTimeZone['International Date Line West']
        expect(tz.to_s).to eq "Línea de fecha internacional del oeste (-11:00)"
      end
    end
  end
end
