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

require File.expand_path(File.dirname(__FILE__) + '/report_spec_helper')

describe "Outcome Reports" do
  include ReportSpecHelper

  RATING_INDEX = AccountReports::OutcomeExport::OUTCOME_EXPORT_HEADERS.find_index('ratings')

  describe 'outcome export' do
    def match_row(attrs)
      satisfy("match row #{attrs}") { |row| include(attrs).matches?(row.to_h) }
    end

    def match_outcome(outcome)
      match_row('canvas_id' => outcome.id.to_s)
    end

    def include_outcome(outcome)
      include(match_outcome(outcome))
    end

    def row_index(outcome)
      report.find_index { |row| match_outcome(outcome).matches?(row) }
    end

    def have_n_ratings(n)
      satisfy("have #{n} ratings") do |row|
        row.length - RATING_INDEX == 2 * n
      end
    end

    let_once(:account) { account_model }
    let(:report_options) { {} }
    let(:report) do
      read_report(
        'outcome_export_csv',
        parse_header: true,
        account: account,
        order: [2,0],
        **report_options
      )
    end

    it 'includes the correct headers' do
      report_options[:header] = true
        expect(report[0].headers).to eq AccountReports::OutcomeExport::OUTCOME_EXPORT_HEADERS
    end

    context 'with outcome groups' do
      before(:once) do
        @root_group_1 = outcome_group_model(context: account, vendor_guid: 'monkey')
        @root_group_2 = outcome_group_model(context: account)
        @child_group_1_1 = outcome_group_model(context: account, outcome_group_id: @root_group_1.id)
        @child_group_2_1 = outcome_group_model(context: account, outcome_group_id: @root_group_2.id)
      end

      it 'includes outcome groups' do
        expect(report.length).to eq 4
        expect(report).to all(match_row('object_type' => 'group'))
        expect(report[0]).to match_outcome(@root_group_1)
        expect(report[3]).to match_outcome(@child_group_2_1)
      end

      it 'includes only outcome groups in current account' do
        other_account = account_model(parent_account: account)
        other_account_group = outcome_group_model(context: other_account)
        expect(report).not_to include_outcome(other_account_group)
      end

      it 'includes relevant fields' do
        expect(report[0]['canvas_id']).to eq @root_group_1.id.to_s
        expect(report[0]['object_type']).to eq 'group'
        expect(report[0]['title']).to eq 'new outcome group'
        expect(report[0]['description']).to match(/outcome group description/)
        expect(report[0]['workflow_state']).to eq 'active'
      end

      it 'does not include deleted outcome groups' do
        @child_group_2_1.destroy!
        expect(report.length).to eq 3
        expect(report).not_to include_outcome(@child_group_2_1)
      end

      context 'with vendor guids' do
        before(:once) do
          @root_group_1.update! vendor_guid: 'lion', vendor_guid_2: 'tiger'
          @root_group_2.update! vendor_guid: 'bear'
          @child_group_1_1.update! vendor_guid_2: 'monkey'
        end

        it 'defaults to vendor_guid field when AcademicBenchmark.use_new_guid_columns? not set' do
          allow(AcademicBenchmark).to receive(:use_new_guid_columns?).and_return false
          expect(report[0]['vendor_guid']).to eq 'lion'
          expect(report[1]['vendor_guid']).to eq 'bear'
          expect(report[2]['vendor_guid']).to eq 'monkey'
        end

        it 'defaults to vendor_guid_2 field when AcademicBenchmark.use_new_guid_columns? set' do
          allow(AcademicBenchmark).to receive(:use_new_guid_columns?).and_return true
          expect(report[0]['vendor_guid']).to eq 'tiger'
          expect(report[1]['vendor_guid']).to eq 'bear'
          expect(report[2]['vendor_guid']).to eq 'monkey'
        end

        it 'uses canvas id for vendor_guid if and only if vendor_guid is not present' do
          expect(report[3]['vendor_guid']).to eq "canvas_outcome_group:#{@child_group_2_1.id}"
        end
      end

      it 'has empty parent_guids if parent is root outcome group' do
        expect(report[0]['parent_guids']).to eq nil
        expect(report[1]['parent_guids']).to eq nil
      end

      it 'includes parent of outcome groups' do
        expect(report[2]['parent_guids']).to eq 'monkey'
        expect(report[3]['parent_guids']).to eq "canvas_outcome_group:#{@root_group_2.id}"
      end

      it 'includes parent before children' do
        report_options[:order] = 'skip'
        expect(row_index(@root_group_1)).to be < row_index(@child_group_1_1)
        expect(row_index(@root_group_2)).to be < row_index(@child_group_2_1)
      end

      it 'does not include root outcome group' do
        expect(report).not_to include_outcome(account.root_outcome_group)
      end
    end

    context 'with outcomes' do
      before(:once) do
        @root_outcome_1 = outcome_model(
          context: account,
          vendor_guid: 'giraffe',
          calculation_method: 'highest'
        )
        @root_outcome_2 = outcome_model(
          context: account,
          calculation_method: 'n_mastery',
          calculation_int: 5
        )
        @root_outcome_3 = outcome_model(
          context: account
        )
        @root_outcome_4 = outcome_model(
          context: account
        )
      end

      it 'includes outcomes' do
        expect(report.length).to eq 4
        expect(report).to all(match_row('object_type' => 'outcome'))
        expect(report[0]).to match_outcome(@root_outcome_1)
        expect(report[1]).to match_outcome(@root_outcome_2)
      end

      it 'includes only outcomes linked in current account' do
        other_account = account_model(parent_account: @account)
        other_outcome = outcome_model(context: other_account)
        expect(report).not_to include_outcome(other_outcome)
      end

      it 'includes outcomes from another context linked in current account' do
        other_account = account_model
        other_outcome = outcome_model(context: other_account)
        account.root_outcome_group.add_outcome(other_outcome)
        expect(report.length).to eq 5
        expect(report).to include_outcome(other_outcome)
      end

      it 'includes global outcomes' do
        @root_outcome_1.update! context: nil
        expect(report).to include_outcome(@root_outcome_1)
      end

      it 'includes relevant fields' do
        expect(report[0]['canvas_id']).to eq @root_outcome_1.id.to_s
        expect(report[0]['object_type']).to eq 'outcome'
        expect(report[0]['title']).to eq @root_outcome_1.title
        expect(report[0]['description']).to eq @root_outcome_1.description
        expect(report[0]['display_name']).to eq @root_outcome_1.display_name
        expect(report[0]['calculation_method']).to eq 'highest'
        expect(report[0]['calculation_int']).to eq nil
        expect(report[0]['workflow_state']).to eq @root_outcome_1.workflow_state
        expect(report[0]['mastery_points']).to eq '3.0'

        expect(report[1]['calculation_method']).to eq 'n_mastery'
        expect(report[1]['calculation_int']).to eq '5'
      end

      it 'does not include deleted outcomes' do
        @root_outcome_2.destroy!
        expect(report.length).to eq 3
        expect(report).not_to include_outcome(@root_outcome_2)
      end

      context 'with vendor guids' do
        before(:once) do
          @root_outcome_1.update! vendor_guid: 'lion', vendor_guid_2: 'tiger'
          @root_outcome_2.update! vendor_guid: 'bear'
          @root_outcome_3.update! vendor_guid: 'llama'
        end

        it 'defaults to vendor_guid field when AcademicBenchmark.use_new_guid_columns? not set' do
          allow(AcademicBenchmark).to receive(:use_new_guid_columns?).and_return false
          expect(report[0]['vendor_guid']).to eq 'lion'
          expect(report[1]['vendor_guid']).to eq 'bear'
          expect(report[2]['vendor_guid']).to eq 'llama'
        end

        it 'defaults to vendor_guid_2 field when AcademicBenchmark.use_new_guid_columns? set' do
          allow(AcademicBenchmark).to receive(:use_new_guid_columns?).and_return true
          expect(report[0]['vendor_guid']).to eq 'tiger'
          expect(report[1]['vendor_guid']).to eq 'bear'
          expect(report[2]['vendor_guid']).to eq 'llama'
        end

        it 'uses canvas id for vendor_guid if vendor_guid is not present' do
          expect(report[3]['vendor_guid']).to eq "canvas_outcome:#{@root_outcome_4.id}"
        end
      end

      it 'does not contain parent guids for the root outcome group' do
        expect(report[0]['parent_guids']).to be_blank
      end

      context 'and groups' do
        before do
          @root_group_1 = outcome_group_model(context: account)
          @group_1_1 = outcome_group_model(context: account, outcome_group_id: @root_group_1.id)
          @group_1_1_1 = outcome_group_model(context: account, outcome_group_id: @group_1_1.id)
          @nested_outcome = outcome_model(context: account, outcome_group: @group_1_1_1)
        end

        it 'includes groups before outcomes' do
          report_options[:order] = 'skip'
          LearningOutcomeGroup.where.not(learning_outcome_group_id: nil).to_a.
            product(LearningOutcome.all).
            each do |group, outcome|
              expect(row_index(group)).to be < row_index(outcome)
            end
        end

        it 'includes parents for outcome group links' do
          expect(report[row_index(@nested_outcome)]['parent_guids']).to eq "canvas_outcome_group:#{@group_1_1_1.id}"
        end

        it 'includes multiple parents if group is linked to multiple outcome groups' do
          @root_group_1.add_outcome(@nested_outcome)
          expect(report[7]['parent_guids']).
            to eq "canvas_outcome_group:#{@root_group_1.id} canvas_outcome_group:#{@group_1_1_1.id}"
        end
      end

      context 'with ratings' do
        it 'includes all ratings' do
          expect(report[0]).to have_n_ratings(2)
          expect(report[0][RATING_INDEX]).to eq '3.0'
          expect(report[0][RATING_INDEX + 1]).to eq 'Rockin'
          expect(report[0][RATING_INDEX + 2]).to eq '0.0'
          expect(report[0][RATING_INDEX + 3]).to eq 'Lame'
        end

        it 'includes different number of fields depending on how many ratings are present' do
          @root_outcome_1.rubric_criterion = {
            ratings: [
              { points: 0, description: 'I know' },
              { points: 1, description: 'an old' },
              { points: 2, description: 'woman' },
              { points: 3, description: 'who' },
              { points: 4, description: 'swallowed' },
              { points: 10, description: 'a fly' }
            ]
          }
          @root_outcome_1.save!
          expect(report[0]).to have_n_ratings(6)
          expect(report[0][RATING_INDEX]).to eq '10.0'
          expect(report[0][RATING_INDEX + 1]).to eq 'a fly'
          expect(report[0][RATING_INDEX + 10]).to eq '0.0'
          expect(report[0][RATING_INDEX + 11]).to eq 'I know'
          expect(report[0][RATING_INDEX + 12]).to be_nil
          expect(report[0][RATING_INDEX + 13]).to be_nil
        end
      end
    end
  end
end
