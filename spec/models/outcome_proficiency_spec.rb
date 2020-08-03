#
# Copyright (C) 2018 - present Instructure, Inc.
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

describe OutcomeProficiency, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:outcome_proficiency_ratings).dependent(:destroy).order('points DESC, id ASC').inverse_of(:outcome_proficiency) }
    it { is_expected.to belong_to(:context).required }
  end

  describe 'validations' do
    subject { outcome_proficiency_model(account_model) }

    it { is_expected.to validate_presence_of :outcome_proficiency_ratings }
    it { is_expected.to validate_presence_of :context }
    it { is_expected.to validate_uniqueness_of(:context_id).scoped_to(:context_type) }

    describe 'strictly descending points' do
      it 'valid proficiency' do
        expect(subject.valid?).to be(true)
      end

      it 'invalid proficiency' do
        rating1 = OutcomeProficiencyRating.new(description: 'A', points: 4, mastery: false, color: '00ff00')
        rating2 = OutcomeProficiencyRating.new(description: 'B', points: 3, mastery: false, color: '0000ff')
        rating3 = OutcomeProficiencyRating.new(description: 'B', points: 3, mastery: false, color: '0000ff')
        rating4 = OutcomeProficiencyRating.new(description: 'C', points: 2, mastery: true, color: 'ff0000')
        subject.outcome_proficiency_ratings = [rating1, rating2, rating3, rating4]
        expect(subject.valid?).to be(false)
      end
    end

    it 'sets the context from account' do
      account = account_model
      proficiency = outcome_proficiency_model(account)
      expect(proficiency.context_type).to eq 'Account'
      expect(proficiency.context).to eq account
    end
  end

  describe 'before save' do
    it 'sets root account id' do
      root_account = account_model
      proficiency = outcome_proficiency_model(root_account)
      expect(proficiency.root_account_id).to be(root_account.resolved_root_account_id)
    end

    it 'sets root account id with passed in id' do
      root_account_1 = account_model
      root_account_2 = account_model
      rating1 = OutcomeProficiencyRating.new(description: 'best', points: 10, mastery: true, color: '00ff00')
      rating2 = OutcomeProficiencyRating.new(description: 'worst', points: 0, mastery: false, color: 'ff0000')
      proficiency = OutcomeProficiency.create!(outcome_proficiency_ratings: [rating1, rating2], context: root_account_1,
        root_account_id: root_account_2.resolved_root_account_id)
      expect(proficiency.root_account_id).to be(root_account_2.resolved_root_account_id)
    end
  end

  describe 'undestroy' do
    before do
      rating1 = OutcomeProficiencyRating.new(description: 'best', points: 10, mastery: true, color: '00ff00')
      rating2 = OutcomeProficiencyRating.new(description: 'worst', points: 0, mastery: false, color: 'ff0000')
      @proficiency = OutcomeProficiency.create!(outcome_proficiency_ratings: [rating1, rating2], account: account_model)
      @proficiency.destroy
      @proficiency.undestroy
    end

    it 'restores soft deleted ratings' do
      expect(OutcomeProficiencyRating.active.count).to eq 2
    end

    it 'should set workflow_state to active upon undestroying' do
      expect(@proficiency.workflow_state).to eq 'active'
    end
  end

  it_behaves_like "soft deletion" do
    subject { OutcomeProficiency }

    let(:first_account) { account_model }
    let(:second_account) { account_model }
    let(:rating1) { OutcomeProficiencyRating.new(description: 'best', points: 10, mastery: true, color: '00ff00') }
    let(:params) { { outcome_proficiency_ratings: [rating1] } }
    let(:creation_arguments) { [ params.merge(context: first_account), params.merge(context: second_account) ] }
  end
end
