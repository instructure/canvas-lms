# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require 'spec_helper'

describe Outcomes::LearningOutcomeGroupChildren do
  subject { described_class.new(context) }

  # rubocop:disable RSpec/LetSetup
  let!(:context) { Account.default }
  let!(:global_group) { LearningOutcomeGroup.create(title: 'global') }
  let!(:global_outcome1) { outcome_model(outcome_group: global_group) }
  let!(:global_outcome2) { outcome_model(outcome_group: global_group) }
  let!(:g0) { context.root_outcome_group }
  let!(:g1) { outcome_group_model(context: context, outcome_group_id: g0) }
  let!(:g2) { outcome_group_model(context: context, outcome_group_id: g0) }
  let!(:g3) { outcome_group_model(context: context, outcome_group_id: g1) }
  let!(:g4) { outcome_group_model(context: context, outcome_group_id: g1) }
  let!(:g5) { outcome_group_model(context: context, outcome_group_id: g2) }
  let!(:g6) { outcome_group_model(context: context, outcome_group_id: g3) }
  let!(:o0) { outcome_model(context: context, outcome_group: g0) }
  let!(:o1) { outcome_model(context: context, outcome_group: g1) }
  let!(:o2) { outcome_model(context: context, outcome_group: g1) }
  let!(:o3) { outcome_model(context: context, outcome_group: g2) }
  let!(:o4) { outcome_model(context: context, outcome_group: g3) }
  let!(:o5) { outcome_model(context: context, outcome_group: g3) }
  let!(:o6) { outcome_model(context: context, outcome_group: g3) }
  let!(:o7) { outcome_model(context: context, outcome_group: g4) }
  let!(:o8) { outcome_model(context: context, outcome_group: g5) }
  let!(:o9) { outcome_model(context: context, outcome_group: g6) }
  let!(:o10) { outcome_model(context: context, outcome_group: g6) }
  let!(:o11) { outcome_model(context: context, outcome_group: g6) }
  # rubocop:enable RSpec/LetSetup


  before do
    Rails.cache.clear
  end

  describe '#total_subgroups' do
    it 'returns the total sugroups for a learning outcome group' do
      expect(subject.total_subgroups(g0.id)).to eq 6
      expect(subject.total_subgroups(g1.id)).to eq 3
      expect(subject.total_subgroups(g2.id)).to eq 1
      expect(subject.total_subgroups(g3.id)).to eq 1
      expect(subject.total_subgroups(g4.id)).to eq 0
      expect(subject.total_subgroups(g5.id)).to eq 0
      expect(subject.total_subgroups(g6.id)).to eq 0
    end

    context 'when outcome group is deleted' do
      before { g4.update(workflow_state: 'deleted') }

      it 'returns the total sugroups for a learning outcome group without the deleted groups' do
        expect(subject.total_subgroups(g0.id)).to eq 5
        expect(subject.total_subgroups(g1.id)).to eq 2
        expect(subject.total_subgroups(g2.id)).to eq 1
        expect(subject.total_subgroups(g3.id)).to eq 1
        expect(subject.total_subgroups(g4.id)).to eq 0
        expect(subject.total_subgroups(g5.id)).to eq 0
        expect(subject.total_subgroups(g6.id)).to eq 0
      end
    end

    context 'when context is nil' do
      subject { described_class.new(nil) }

      it 'returns global outcome groups' do
        expect(subject.total_subgroups(global_group.id)).to eq 0
      end
    end
  end

  describe '#total_outcomes' do
    it 'returns the total nested outcomes at each group' do
      expect(subject.total_outcomes(g0.id)).to eq 12
      expect(subject.total_outcomes(g1.id)).to eq 9
      expect(subject.total_outcomes(g2.id)).to eq 2
      expect(subject.total_outcomes(g3.id)).to eq 6
      expect(subject.total_outcomes(g4.id)).to eq 1
      expect(subject.total_outcomes(g5.id)).to eq 1
      expect(subject.total_outcomes(g6.id)).to eq 3
    end

    context 'when outcome is deleted' do
      before { o4.destroy }

      it 'returns the total sugroups for a learning outcome group without the deleted groups' do
        expect(subject.total_outcomes(g0.id)).to eq 11
        expect(subject.total_outcomes(g1.id)).to eq 8
        expect(subject.total_outcomes(g2.id)).to eq 2
        expect(subject.total_outcomes(g3.id)).to eq 5
        expect(subject.total_outcomes(g4.id)).to eq 1
        expect(subject.total_outcomes(g5.id)).to eq 1
        expect(subject.total_outcomes(g6.id)).to eq 3
      end
    end

    context 'when context is nil' do
      subject { described_class.new(nil) }

      it 'returns global outcomes' do
        expect(subject.total_outcomes(global_group.id)).to eq 2
      end
    end
  end
end
