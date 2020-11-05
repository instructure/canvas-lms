# frozen_string_literal: true

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

require 'spec_helper'

describe DataFixup::PopulateRootAccountIdsOnLearningOutcomes do

  def populate(lo)
    DataFixup::PopulateRootAccountIdsOnLearningOutcomes.populate(lo.id, lo.id)
  end

  context 'with context id' do
    it 'sets root_account_ids with Account context' do
      account = account_model
      lo = LearningOutcome.create!(context: account, short_description: 'test')
      lo.update_column(:root_account_ids, nil)
      populate(lo)
      expect(lo.reload.root_account_ids).to eq [account.id]
    end

    it 'sets root_account_ids with Course context' do
      course = course_model
      lo = LearningOutcome.create!(context: course, short_description: 'test')
      lo.update_column(:root_account_ids, nil)
      populate(lo)
      expect(lo.reload.root_account_ids).to eq [course.root_account_id]
    end

    it 'finds outcome with empty array of root_account_ids' do
      course = course_model
      lo = LearningOutcome.create!(context: course, short_description: 'test')
      lo.update_column(:root_account_ids, [])
      populate(lo)
      expect(lo.reload.root_account_ids).to eq [course.root_account_id]
    end
  end

  context 'no context id' do
    it 'sets root_account_ids when there is one root account on shard' do
      account_model
      lo = LearningOutcome.create!(context_id: nil, short_description: 'test')
      lo.update_column(:root_account_ids, nil)
      populate(lo)
      expect(lo.reload.root_account_ids).to eq [Account.root_accounts.first.id]
    end

    it 'sets root_account_ids when there are multiple root accounts on shard' do
      a1 = account_model
      a2 = account_model
      a3 = account_model(root_account: a2)
      lo = LearningOutcome.create!(context_id: nil, short_description: 'test')
      lo.update_column(:root_account_ids, nil)

      ContentTag.create!(content: lo, context: a1, tag_type: 'learning_outcome_association', associated_asset_type: 'LearningOutcomeGroup')
      ContentTag.create!(content: lo, context: a3, tag_type: 'learning_outcome_association', associated_asset_type: 'LearningOutcomeGroup')

      populate(lo)
      expect(lo.reload.root_account_ids).to eq [a1.id, a2.id]
    end
  end

end