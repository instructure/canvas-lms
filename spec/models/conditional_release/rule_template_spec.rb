#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative '../../conditional_release_spec_helper'
require_dependency "conditional_release/rule_template"

module ConditionalRelease
  describe RuleTemplate, :type => :model do
    it_behaves_like 'a soft-deletable model'

    describe 'rule template definition' do
      before do
        @rule_template = build :rule_template
      end

      it 'cannot have null context_type' do
        @rule_template.context_type = nil
        expect(@rule_template.valid?).to be false
      end

      it 'must have a context' do
        [Account, Course].each do |valid_klass|
          @rule_template.context = valid_klass.create!
          expect(@rule_template.valid?).to be true
        end
        expect {
          @rule_template.context = User.create!
        }.to raise_error(ActiveRecord::AssociationTypeMismatch)
      end

      it 'cannot have a null context id' do
        @rule_template.context_id = nil
        expect(@rule_template.valid?).to be false
      end

      it 'cannot have a null name' do
        @rule_template.name = nil
        expect(@rule_template.valid?).to be false
      end

      it 'cannot have a null root account id' do
        @rule_template.root_account_id = nil
        expect(@rule_template.valid?).to be false
      end
    end

    describe 'build_rule' do
      it 'has the same account id' do
        root_account = Account.create!
        template = create :rule_template, :root_account_id => root_account.id
        rule = template.build_rule
        expect(rule.root_account_id).to eq root_account.id
      end

      it 'has the same number of ranges' do
        template = create :rule_template_with_scoring_ranges, scoring_range_template_count: 5
        rule = template.build_rule
        expect(rule.scoring_ranges.length).to eq 5
      end

      it 'has the same values for ranges' do
        template = create :rule_template_with_scoring_ranges, scoring_range_template_count: 9
        rule = template.build_rule
        template.scoring_range_templates.each_with_index do |sr_template, i|
          range = rule.scoring_ranges[i]
          expect(range.upper_bound).to eq sr_template.upper_bound
          expect(range.lower_bound).to eq sr_template.lower_bound
        end
      end

      it 'does not save rules or ranges' do
        template = create :rule_template_with_scoring_ranges, scoring_range_template_count: 1
        rule = template.build_rule
        expect(rule.new_record?).to be true
        expect(rule.scoring_ranges.first.new_record?).to be true
      end
    end
  end
end
