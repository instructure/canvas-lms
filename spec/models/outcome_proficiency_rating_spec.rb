# frozen_string_literal: true

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

describe OutcomeProficiencyRating do
  describe "associations" do
    it { is_expected.to belong_to(:outcome_proficiency) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of :description }
    it { is_expected.to validate_presence_of :points }
    it { is_expected.to validate_numericality_of(:points).is_greater_than_or_equal_to(0) }
    it { is_expected.to allow_value("0F160a").for(:color) }
    it { is_expected.not_to allow_value("#0F160a").for(:color) }
    it { is_expected.not_to allow_value("").for(:color) }
    it { is_expected.not_to allow_value(nil).for(:color) }
  end

  describe "root_account_id" do
    let(:root_account) { account_model }
    let(:proficiency) { outcome_proficiency_model(root_account) }

    it "sets root_account_id using outcome proficiency" do
      rating = OutcomeProficiencyRating.create!(description: "A", points: 4, mastery: true, color: "00ff00", outcome_proficiency: proficiency)
      expect(rating.root_account_id).to be_present
      expect(rating.root_account_id).to eq(proficiency.root_account_id)
    end
  end

  it_behaves_like "soft deletion" do
    subject { OutcomeProficiencyRating }

    let(:proficiency) { outcome_proficiency_model(account_model) }

    let(:creation_arguments) { [{ description: "A", points: 4, mastery: true, color: "00ff00", outcome_proficiency: proficiency }] }
  end
end
