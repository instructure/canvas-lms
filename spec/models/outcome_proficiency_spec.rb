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
    it { is_expected.to belong_to(:account).inverse_of(:outcome_proficiency) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :account }
    it { is_expected.to validate_presence_of :outcome_proficiency_ratings }

    describe 'uniqueness' do
      subject { outcome_proficiency_model(account_model) }

      it { is_expected.to validate_uniqueness_of(:account) }
    end

    describe 'strictly descending points' do
      it 'valid proficiency' do
        proficiency = outcome_proficiency_model(account_model)
        expect(proficiency.valid?).to be(true)
      end

      it 'invalid proficiency' do
        proficiency = outcome_proficiency_model(account_model)
        rating1 = OutcomeProficiencyRating.new(description: 'A', points: 4, mastery: false, color: '00ff00')
        rating2 = OutcomeProficiencyRating.new(description: 'B', points: 3, mastery: false, color: '0000ff')
        rating3 = OutcomeProficiencyRating.new(description: 'B', points: 3, mastery: false, color: '0000ff')
        rating4 = OutcomeProficiencyRating.new(description: 'C', points: 2, mastery: true, color: 'ff0000')
        proficiency.outcome_proficiency_ratings = [rating1, rating2, rating3, rating4]
        expect(proficiency.valid?).to be(false)
      end
    end
  end
end
