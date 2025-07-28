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

require_relative "../report_spec_helper"
require_relative "shared/shared_examples"
require_relative "shared/improved_outcome_reports_spec_helpers"
require_relative "shared/setup"

describe "StudentAssignmentOutcomeMapReport" do
  include ReportSpecHelper

  describe AccountReports::ImprovedOutcomeReports::StudentAssignmentOutcomeMapReport do
    before(:once) do
      @root_account = Account.create(name: "New Account", default_time_zone: "UTC")
      @user1 = user_with_managed_pseudonym(
        active_all: true,
        account: @root_account,
        name: "John St. Clair",
        sortable_name: "St. Clair, John",
        username: "john@stclair.com",
        sis_user_id: "user_sis_id_01"
      )
    end

    let(:account_report) { AccountReport.new(report_type: "outcome_export_csv", account: @root_account, user: @user1) }
    let(:report) { described_class.new(account_report) }

    describe "#post_process_record" do
      let(:account) { Account.create!(name: "Test Account") }
      let(:record_hash) { { "account id" => account.id } }
      let(:cache) { {} }

      context "when account id is nil" do
        it "raises ActiveRecord::RecordInvalid" do
          record_hash["account id"] = nil
          expect { report.send(:post_process_record, record_hash, cache) }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "when account is not found" do
        it "raises ActiveRecord::RecordInvalid" do
          record_hash["account id"] = -1
          expect { report.send(:post_process_record, record_hash, cache) }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context "when account is found" do
        it "adds account name to record_hash" do
          result = report.send(:post_process_record, record_hash, cache)
          expect(result["account name"]).to eq(account.name)
        end

        it "caches the account" do
          report.send(:post_process_record, record_hash, cache)
          expect(cache[account.id]).to eq(account)
        end
      end
    end
  end

  describe "Student Competency report" do
    include ImprovedOutcomeReportsSpecHelpers

    include_context "setup"

    let(:report_type) { "student_assignment_outcome_map_csv" }
    let(:expected_headers) { AccountReports::ImprovedOutcomeReports::StudentAssignmentOutcomeMapReport::HEADERS }
    let(:all_values) { [user2_values, user1_values] }
    let(:order) { [0, 2, 3, 15] }

    before do
      Account.site_admin.enable_feature!(:improved_outcome_report_generation)
    end

    include_examples "common outcomes report behavior"
  end
end
