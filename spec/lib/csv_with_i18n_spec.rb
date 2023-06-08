# frozen_string_literal: true

#
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

require_relative "../../gems/plugins/account_reports/spec_canvas/report_spec_helper"

# These tests and a subset of tests in gradebook_exporter_spec collectively cover csv_i18n_settings
describe CSVWithI18n do
  before(:once) do
    @account = account_model
    @admin = account_admin_user(account: @account)
  end

  describe "csv_i18n_settings" do
    describe "byte_order mark" do
      it "is included when the user has it enabled" do
        @admin.enable_feature!(:include_byte_order_mark_in_gradebook_exports)
        expect(CSVWithI18n.csv_i18n_settings(@admin)).to include(include_bom: true)
      end

      it "is excluded when the user has it disabled" do
        @admin.disable_feature!(:include_byte_order_mark_in_gradebook_exports)
        expect(CSVWithI18n.csv_i18n_settings(@admin)).to include(include_bom: false)
      end
    end

    describe "column_separator" do
      it "respects the semicolon feature flag" do
        @admin.enable_feature!(:use_semi_colon_field_separators_in_gradebook_exports)
        expect(CSVWithI18n.csv_i18n_settings(@admin)).to include(col_sep: ";")
      end

      it "can automatically determine the column separator to use when asked to autodetect" do
        @admin.enable_feature!(:autodetect_field_separators_for_gradebook_exports)
        I18n.with_locale(:is) do
          expect(CSVWithI18n.csv_i18n_settings(@admin)).to include(col_sep: ";")
        end
      end

      it "uses comma as the column separator when not asked to autodetect" do
        @admin.disable_feature!(:autodetect_field_separators_for_gradebook_exports)
        I18n.with_locale(:is) do
          expect(CSVWithI18n.csv_i18n_settings(@admin)).to include(col_sep: ",")
        end
      end
    end

    it "passes through other options" do
      expect(CSVWithI18n.csv_i18n_settings(@admin, foo: "bar")).to include(foo: "bar")
    end

    it "works alongside CSVWithI18n" do
      @admin.enable_feature!(:use_semi_colon_field_separators_in_gradebook_exports)
      @admin.enable_feature!(:include_byte_order_mark_in_gradebook_exports)
      options = CSVWithI18n.csv_i18n_settings(@admin)
      output = CSVWithI18n.generate(**options) do |csv|
        csv << [1, 2]
        csv << [3, 4]
      end
      expect(output.bytes).to eq "\xEF\xBB\xBF1;2\n3;4\n".bytes
    end
  end

  describe "CSVWithI18n" do
    it "does not add a bom if not set as an option" do
      output = CSVWithI18n.generate do |csv|
        csv << [1, 2]
        csv << [3, 4]
      end
      expect(output).to eq "1,2\n3,4\n"
    end

    it "does add a bom if set as an option" do
      output = CSVWithI18n.generate(include_bom: true) do |csv|
        csv << [1, 2]
        csv << [3, 4]
      end
      expect(output.bytes).to eq "\xEF\xBB\xBF1,2\n3,4\n".bytes
    end
  end
end
