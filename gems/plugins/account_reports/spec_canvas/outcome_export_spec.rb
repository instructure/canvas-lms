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

require_relative "report_spec_helper"

describe "Outcome Reports" do
  include ReportSpecHelper

  let(:rating_index) { AccountReports::OutcomeExport::OUTCOME_EXPORT_HEADERS.find_index("ratings") }

  describe "outcome export" do
    def match_row(attrs)
      satisfy("match row #{attrs}") { |row| include(attrs).matches?(row.to_h) }
    end

    def match_outcome(outcome)
      object_type = outcome.instance_of?(LearningOutcome) ? "canvas_outcome" : "canvas_outcome_group"
      vendor_guid = outcome.vendor_guid || "#{object_type}:#{outcome.id}"
      match_row("vendor_guid" => vendor_guid)
    end

    def include_outcome(outcome)
      include(match_outcome(outcome))
    end

    def row_index(outcome)
      report.find_index { |row| match_outcome(outcome).matches?(row) }
    end

    def find_object(object)
      report.find { |row| match_outcome(object).matches?(row) }
    end

    def n_ratings?(n)
      satisfy("have #{n} ratings") do |row|
        row.length - rating_index == 2 * n
      end
    end

    let_once(:account) { account_model }
    let(:report_options) { {} }
    let(:report) do
      read_report(
        "outcome_export_csv",
        parse_header: true,
        account:,
        order: "skip",
        **report_options
      )
    end

    it "includes the correct headers" do
      report_options[:header] = true
      expect(report[0].headers).to eq AccountReports::OutcomeExport::OUTCOME_EXPORT_HEADERS
    end

    it "respects csv i18n settings" do
      preparsed_report_options = {
        parse_header: true,
        account:,
        order: "skip",
        header: true
      }
      admin = account_admin_user(account:)
      expected_headers = %w[vendor_guid object_type title]
      admin.enable_feature!(:use_semi_colon_field_separators_in_gradebook_exports)

      preparsed_report = run_report("outcome_export_csv", preparsed_report_options)
      actual_headers = parse_report(preparsed_report, preparsed_report_options.merge(col_sep: ";"))[0].headers
      expect(actual_headers[0..2]).to eq(expected_headers)
    end

    context "with outcome groups" do
      before(:once) do
        @root_group_1 = outcome_group_model(context: account, vendor_guid: "monkey")
        @root_group_2 = outcome_group_model(context: account)
        @child_group_1_1 = outcome_group_model(context: account, outcome_group_id: @root_group_1.id)
        @child_group_2_1 = outcome_group_model(context: account, outcome_group_id: @root_group_2.id)
      end

      it "includes outcome groups" do
        expect(report.length).to eq 4
        expect(report).to all(match_row("object_type" => "group"))
        expect(find_object(@root_group_1)).to match_outcome(@root_group_1)
        expect(find_object(@child_group_2_1)).to match_outcome(@child_group_2_1)
      end

      it "includes only outcome groups in current account" do
        other_account = account_model(parent_account: account)
        other_account_group = outcome_group_model(context: other_account)
        expect(report).not_to include_outcome(other_account_group)
      end

      it "includes relevant fields" do
        group = find_object(@root_group_1)
        expect(group["object_type"]).to eq "group"
        expect(group["title"]).to eq "new outcome group"
        expect(group["description"]).to match(/outcome group description/)
        expect(group["workflow_state"]).to eq "active"
      end

      it "does not include deleted outcome groups" do
        @child_group_2_1.destroy!
        expect(report.length).to eq 3
        expect(report).not_to include_outcome(@child_group_2_1)
      end

      context "with vendor guids" do
        before(:once) do
          @root_group_1.update! vendor_guid: "lion"
        end

        let(:guids) { report.pluck("vendor_guid") }

        it "defaults to vendor_guid" do
          expect(guids).to include("lion")
        end

        it "uses canvas id for vendor_guid if and only if vendor_guid is not present" do
          expect(guids).to include("canvas_outcome_group:#{@child_group_1_1.id}")
        end
      end

      it "has empty parent_guids if parent is root outcome group" do
        expect(report[0]["parent_guids"]).to be_nil
        expect(report[1]["parent_guids"]).to be_nil
      end

      it "includes parent of outcome groups" do
        expect(find_object(@child_group_1_1)["parent_guids"]).to eq "monkey"
        guid = "canvas_outcome_group:#{@root_group_2.id}"
        expect(find_object(@child_group_2_1)["parent_guids"]).to eq guid
      end

      it "includes parent before children" do
        expect(row_index(@root_group_1)).to be < row_index(@child_group_1_1)
        expect(row_index(@root_group_2)).to be < row_index(@child_group_2_1)
      end

      it "does not include root outcome group" do
        expect(report).not_to include_outcome(account.root_outcome_group)
      end
    end

    context "with outcomes" do
      before(:once) do
        @root_outcome_1 = outcome_model(
          context: account,
          vendor_guid: "giraffe",
          calculation_method: "highest"
        )
        @root_outcome_2 = outcome_model(
          context: account,
          calculation_method: "n_mastery",
          calculation_int: 5
        )
        @root_outcome_3 = outcome_model(
          context: account
        )
        @root_outcome_4 = outcome_model(
          context: account
        )
        @outcome_2_fd = OutcomeFriendlyDescription.create!({
                                                             learning_outcome: @root_outcome_2,
                                                             context: account,
                                                             description: "A friendly description"
                                                           })
      end

      it "includes outcomes" do
        expect(report.length).to eq 4
        expect(report).to all(match_row("object_type" => "outcome"))
        expect(find_object(@root_outcome_1)).to match_outcome(@root_outcome_1)
        expect(find_object(@root_outcome_2)).to match_outcome(@root_outcome_2)
      end

      it "includes only outcomes linked in current account" do
        other_account = account_model(parent_account: @account)
        other_outcome = outcome_model(context: other_account)
        expect(report).not_to include_outcome(other_outcome)
      end

      it "includes outcomes from another context linked in current account" do
        other_account = account_model
        other_outcome = outcome_model(context: other_account)
        account.root_outcome_group.add_outcome(other_outcome)
        expect(report.length).to eq 5
        expect(report).to include_outcome(other_outcome)
      end

      it "includes global outcomes" do
        @root_outcome_1.update! context: nil
        expect(report).to include_outcome(@root_outcome_1)
      end

      it "includes relevant fields" do
        outcome = find_object(@root_outcome_1)
        expect(outcome["object_type"]).to eq "outcome"
        expect(outcome["title"]).to eq @root_outcome_1.title
        expect(outcome["description"]).to eq @root_outcome_1.description
        expect(outcome["friendly_description"]).to be_nil
        expect(outcome["display_name"]).to eq @root_outcome_1.display_name
        expect(outcome["calculation_method"]).to eq "highest"
        expect(outcome["calculation_int"]).to be_nil
        expect(outcome["workflow_state"]).to eq @root_outcome_1.workflow_state
        expect(outcome["mastery_points"]).to eq "3.0"

        other = find_object(@root_outcome_2)
        expect(other["calculation_method"]).to eq "n_mastery"
        expect(other["calculation_int"]).to eq "5"
        expect(other["friendly_description"]).to eq "A friendly description"
      end

      it "ignores fields when account level mastery scales are enabled" do
        @account.set_feature_flag!(:account_level_mastery_scales, "on")
        expect(report.length).to eq 4
        report.each do |r|
          expect(r).to_not have_key("mastery_points")
          expect(r).to_not have_key("calculation_method")
          expect(r).to_not have_key("calculation_int")
          expect(r).to_not have_key("ratings")
        end
      end

      it "does not include deleted outcomes" do
        @root_outcome_2.destroy!
        expect(report.length).to eq 3
        expect(report).not_to include_outcome(@root_outcome_2)
      end

      it "includes friendly description from account-level when exporting from sub-account" do
        subaccount = Account.create!(parent_account_id: @account.id)
        group = outcome_group_model(context: subaccount)
        group.add_outcome(@root_outcome_2)
        report_options[:account] = subaccount
        expect(find_object(@root_outcome_2)["friendly_description"]).to eq @outcome_2_fd.description
      end

      context "with vendor guids" do
        before(:once) do
          @root_outcome_1.update! vendor_guid: "lion"
        end

        it "defaults to vendor_guid" do
          expect(find_object(@root_outcome_1)["vendor_guid"]).to eq "lion"
        end

        it "uses canvas id for vendor_guid if vendor_guid is not present" do
          guid = "canvas_outcome:#{@root_outcome_2.id}"
          expect(find_object(@root_outcome_2)["vendor_guid"]).to eq guid
        end
      end

      it "does not contain parent guids for the root outcome group" do
        expect(report[0]["parent_guids"]).to be_blank
      end

      context "and groups" do
        before do
          @root_group_1 = outcome_group_model(context: account)
          @group_1_1 = outcome_group_model(context: account, outcome_group_id: @root_group_1.id)
          @group_1_1_1 = outcome_group_model(context: account, outcome_group_id: @group_1_1.id)
          @nested_outcome = outcome_model(context: account, outcome_group: @group_1_1_1)
        end

        it "includes groups before outcomes" do
          LearningOutcomeGroup.where.not(learning_outcome_group_id: nil).to_a
                              .product(LearningOutcome.all)
                              .each do |group, outcome|
            expect(row_index(group)).to be < row_index(outcome)
          end
        end

        it "includes parents for outcome group links" do
          expect(report[row_index(@nested_outcome)]["parent_guids"]).to eq "canvas_outcome_group:#{@group_1_1_1.id}"
        end

        it "includes multiple parents if group is linked to multiple outcome groups" do
          @root_group_1.add_outcome(@nested_outcome)
          expect(find_object(@nested_outcome)["parent_guids"])
            .to eq "canvas_outcome_group:#{@root_group_1.id} canvas_outcome_group:#{@group_1_1_1.id}"
        end
      end

      context "with ratings" do
        let(:first_outcome) { find_object(@root_outcome_1) }

        it "includes all ratings" do
          expect(first_outcome).to n_ratings?(2)
          expect(first_outcome[rating_index]).to eq "3.0"
          expect(first_outcome[rating_index + 1]).to eq "Rockin"
          expect(first_outcome[rating_index + 2]).to eq "0.0"
          expect(first_outcome[rating_index + 3]).to eq "Lame"
        end

        it "includes different number of fields depending on how many ratings are present" do
          @root_outcome_1.rubric_criterion = {
            ratings: [
              { points: 0, description: "I know" },
              { points: 1, description: "an old" },
              { points: 2, description: "woman" },
              { points: 3, description: "who" },
              { points: 4, description: "swallowed" },
              { points: 10, description: "a fly" }
            ]
          }
          @root_outcome_1.save!
          expect(first_outcome).to n_ratings?(6)
          expect(first_outcome[rating_index]).to eq "10.0"
          expect(first_outcome[rating_index + 1]).to eq "a fly"
          expect(first_outcome[rating_index + 10]).to eq "0.0"
          expect(first_outcome[rating_index + 11]).to eq "I know"
          expect(first_outcome[rating_index + 12]).to be_nil
          expect(first_outcome[rating_index + 13]).to be_nil
        end

        it "exports successfully with no ratings" do
          @root_outcome_1.data = nil
          @root_outcome_1.save!
          default_count = LearningOutcome.default_rubric_criterion[:ratings].length
          expect(first_outcome.length).to eq rating_index + (default_count * 2)
        end
      end

      context "in a different locale" do
        before do
          account.update(default_locale: :de)
        end

        it "formats mastery points" do
          expect(report[0]["mastery_points"]).to eq "3,0"
        end

        it "formats rating points" do
          expect(report[0][rating_index]).to eq "3,0"
        end
      end
    end
  end
end
