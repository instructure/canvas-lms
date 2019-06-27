
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

require_relative '../../gems/plugins/account_reports/spec_canvas/report_spec_helper'
require 'csv'

# These tests and a subset of tests in gradebook_exporter_spec collectively cover csv_i18n_settings
describe CsvI18nHelpers do
  include ReportSpecHelper

  before(:once) do
    @account = account_model
    @account.enable_feature!(:enable_i18n_features_in_outcomes_exports)
    @admin = account_admin_user(account: @account)
  end

  let(:report_options) {
    {
      parse_header: true,
      account: @account,
      order: 'skip',
      header: true
    }
  }

  let(:report) do
    run_report(
      'outcome_export_csv',
      report_options
    )
  end

  describe "byte_order mark" do
    it "is included when the user has it enabled" do
      @admin.enable_feature!(:include_byte_order_mark_in_gradebook_exports)
      actual_headers = parse_report(report, report_options)[0].headers
      expect(actual_headers[0].bytes).to eq("\xEF\xBB\xBFvendor_guid".bytes)
    end

    it "is excluded when the user has it disabled" do
      @admin.disable_feature!(:include_byte_order_mark_in_gradebook_exports)
      actual_headers = parse_report(report, report_options)[0].headers
      expect(actual_headers[0].bytes).to eq("vendor_guid".bytes)
    end
  end

  describe "column_separator" do
    it "respects the semicolon feature flag" do
      @admin.enable_feature!(:use_semi_colon_field_separators_in_gradebook_exports)
      actual_headers = parse_report(report, report_options.merge('col_sep': ';'))[0].headers
      expected_headers = ['vendor_guid', 'object_type', 'title']
      expect(actual_headers[0..2]).to eq(expected_headers)
    end

    it "can automatically determine the column separator to use when asked to autodetect" do
      @admin.enable_feature!(:autodetect_field_separators_for_gradebook_exports)
      I18n.locale = :is
      actual_headers = parse_report(report, report_options.merge('col_sep': ';'))[0].headers
      expected_headers = ['vendor_guid', 'object_type', 'title']
      expect(actual_headers[0..2]).to eq(expected_headers)
    end

    it "uses comma as the column separator when not asked to autodetect" do
      @admin.disable_feature!(:autodetect_field_separators_for_gradebook_exports)
      I18n.locale = :is
      actual_headers = parse_report(report, report_options.merge('col_sep': ','))[0].headers
      expected_headers = ['vendor_guid', 'object_type', 'title']
      expect(actual_headers[0..2]).to eq(expected_headers)
    end
  end
end
