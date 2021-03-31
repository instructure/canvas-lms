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
  let!(:global_group_subgroup) { global_group.child_outcome_groups.build(title: 'global subgroup') }
  let!(:global_outcome1) { outcome_model(outcome_group: global_group, title: 'G Outcome 1') }
  let!(:global_outcome2) { outcome_model(outcome_group: global_group, title: 'G Outcome 2') }
  let!(:g0) { context.root_outcome_group }
  let!(:g1) { outcome_group_model(context: context, outcome_group_id: g0, title: 'Group 1.1') }
  let!(:g2) { outcome_group_model(context: context, outcome_group_id: g0, title: 'Group 1.2') }
  let!(:g3) { outcome_group_model(context: context, outcome_group_id: g1, title: 'Group 2.1') }
  let!(:g4) { outcome_group_model(context: context, outcome_group_id: g1, title: 'Group 2.2') }
  let!(:g5) { outcome_group_model(context: context, outcome_group_id: g2, title: 'Group 3') }
  let!(:g6) { outcome_group_model(context: context, outcome_group_id: g3, title: 'Group 4') }
  let!(:o0) { outcome_model(context: context, outcome_group: g0, title:'Outcome 1', short_description: 'Outcome 1') }
  let!(:o1) { outcome_model(context: context, outcome_group: g1, title:'Outcome 2.1', short_description: 'Outcome 2.1') }
  let!(:o2) { outcome_model(context: context, outcome_group: g1, title:'Outcome 2.2', short_description: 'Outcome 2.2') }
  let!(:o3) { outcome_model(context: context, outcome_group: g2, title:'Outcome 3', short_description: 'Outcome 3') }
  let!(:o4) { outcome_model(context: context, outcome_group: g3, title:'Outcome 4.1', short_description: 'Outcome 4.1') }
  let!(:o5) { outcome_model(context: context, outcome_group: g3, title:'Outcome 4.2', short_description: 'Outcome 4.2') }
  let!(:o6) { outcome_model(context: context, outcome_group: g3, title:'Outcome 4.3', short_description: 'Outcome 4.3') }
  let!(:o7) { outcome_model(context: context, outcome_group: g4, title:'Outcome 5', short_description: 'Outcome 5') }
  let!(:o8) { outcome_model(context: context, outcome_group: g5, title:'Outcome 6', short_description: 'Outcome 6') }
  let!(:o9) { outcome_model(context: context, outcome_group: g6, title:'Outcome 7.1', short_description: 'Outcome 7.1') }
  let!(:o10) { outcome_model(context: context, outcome_group: g6, title:'Outcome 7.2', short_description: 'Outcome 7.2') }
  let!(:o11) { outcome_model(context: context, outcome_group: g6, title:'Outcome 7.3', short_description: 'Outcome 7.3') }
  # rubocop:enable RSpec/LetSetup

  # Outcome Structure for visual reference
  # Global
  # global_group: global
  #   global_outcome1: G Outcome 1
  #   global_outcome2: G Outcome 2
  # Root
  # g0: Root/Content Name
  #   o0: Outcome 1
  #   g1: Group 1.1
  #      o1: Outcome 2.1
  #      o2: Outcome 2.2
  #      g3: Group 2.1
  #         o4: Outcome 4.1
  #         o5: Outcome 4.2
  #         o6: outcome 4.3
  #         g6: Group 4
  #            o9:  Outcome 7.1
  #            o10: Outcome 7.2
  #            o11: Outcome 7.3
  #      g4: Group 2.2
  #         o7: Outcome 5
  #   g2: Group 1.2
  #      o3: Outcome 2
  #      g5: Group 3
  #         o8: Outcome 6

  before do
    Rails.cache.clear
    context.root_account.enable_feature! :improved_outcomes_management
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
      subject { described_class.new }

      it 'returns global outcome groups' do
        expect(subject.total_subgroups(global_group.id)).to eq 1
      end
    end

    it 'caches the total subgroups' do
      enable_cache do
        expect(LearningOutcomeGroup.connection).to receive(:execute).and_call_original.once
        expect(subject.total_subgroups(g0.id)).to eq 6
        expect(subject.total_subgroups(g0.id)).to eq 6
        expect(described_class.new(context).total_subgroups(g0.id)).to eq 6
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

    it 'caches the total outcomes' do
      enable_cache do
        expect(ContentTag).to receive(:active).and_call_original.once
        expect(subject.total_outcomes(g0.id)).to eq 12
        expect(subject.total_outcomes(g0.id)).to eq 12
        expect(described_class.new(context).total_outcomes(g0.id)).to eq 12
      end
    end

    context 'when outcome is deleted' do
      before { o4.destroy }

      it 'returns the total outcomes for a learning outcome group without the deleted outcomes' do
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
      subject { described_class.new }

      it 'returns global outcomes' do
        expect(subject.total_outcomes(global_group.id)).to eq 2
      end
    end
  end

  describe '#suboutcomes_by_group_id' do
    it 'returns the outcomes ordered by parent group title then outcome short_description' do
      g_outcomes = subject.suboutcomes_by_group_id(global_group.id).map(&:learning_outcome_content).map(&:short_description)
      expect(g_outcomes).to match_array(['G Outcome 1', 'G Outcome 2'])
      r_outcomes = subject.suboutcomes_by_group_id(g0.id).map(&:learning_outcome_content).map(&:short_description)
      expect(r_outcomes).to match_array(
        [
          'Outcome 1', 'Outcome 2.1', 'Outcome 2.2', 'Outcome 3', 'Outcome 4.1',
          'Outcome 4.2', 'Outcome 4.3', 'Outcome 5', 'Outcome 6', 'Outcome 7.1',
          'Outcome 7.2', 'Outcome 7.3'
        ]
      )
    end

    context 'when g2 title is updated with a letter that will proceed others' do
      before {g2.update!(title: 'A Group 3')}

      it 'should return the g2s outcome (o3) first' do
        outcomes = subject.suboutcomes_by_group_id(g0.id).map(&:learning_outcome_content).map(&:short_description)
        expect(outcomes).to match_array(
          [
            'Outcome 3', 'Outcome 1', 'Outcome 2.1', 'Outcome 2.2', 'Outcome 4.1',
            'Outcome 4.2', 'Outcome 4.3', 'Outcome 5', 'Outcome 6', 'Outcome 7.1',
            'Outcome 7.2', 'Outcome 7.3'
          ]
        )
      end
    end

    context 'when o5 short_description is updated with a letter that will proceed others' do
      # NOTE: when you update the short_description of a LearningOutcome it does NOT update the
      # content tag title.
      before {o5.update!(short_description: 'A Outcome 4.2')}

      it 'o5 should be returned before o4 but not o2 and o3' do
        outcomes = subject.suboutcomes_by_group_id(g1.id).map(&:learning_outcome_content).map(&:short_description)
        expect(outcomes).to match_array(
          [
            'Outcome 2.1', 'Outcome 2.2', 'A Outcome 4.2', 'Outcome 4.1', 'Outcome 4.3',
            'Outcome 5', 'Outcome 7.1', 'Outcome 7.2', 'Outcome 7.3'
          ]
        )
      end
    end

    context 'when g4 title and o6 short_description is updated with a letter that will proceed others' do
      before {
        g4.update!(title: 'A Group 2.2')
        o6.update!(short_description: 'A Outcome 4.3')
      }

      it 'should return the g4s outcomes first and o6 should be first before other Outcomes 4.x' do
        outcomes = subject.suboutcomes_by_group_id(g1.id).map(&:learning_outcome_content).map(&:short_description)
        expect(outcomes).to match_array(
          [
            'Outcome 5', 'Outcome 2.1', 'Outcome 2.2', 'A Outcome 4.3', 'Outcome 4.1',
            'Outcome 4.2', 'Outcome 7.1', 'Outcome 7.2', 'Outcome 7.3'
          ]
        )
      end
    end

    context 'when context is nil' do
      subject { described_class.new }

      it 'returns global outcomes' do
        outcomes = subject.suboutcomes_by_group_id(global_group.id).map(&:learning_outcome_content).map(&:short_description)
        expect(outcomes).to match_array(['G Outcome 1', 'G Outcome 2'])
      end
    end
  end

  describe '#clear_descendants_cache' do
    it 'clears the cache' do
      enable_cache do
        expect(LearningOutcomeGroup.connection).to receive(:execute).and_call_original.twice
        expect(ContentTag).to receive(:active).and_call_original.exactly(4).times
        expect(subject.total_subgroups(g0.id)).to eq 6
        expect(subject.total_outcomes(g0.id)).to eq 12
        expect(subject.total_outcomes(g1.id)).to eq 9
        subject.clear_descendants_cache
        instance = described_class.new(context)
        expect(instance.total_subgroups(g0.id)).to eq 6
        expect(instance.total_outcomes(g0.id)).to eq 12
        expect(instance.total_outcomes(g1.id)).to eq 9
      end
    end
  end

  describe '#clear_total_outcomes_cache' do
    it 'clears the cache' do
      enable_cache do
        expect(ContentTag).to receive(:active).and_call_original.twice
        expect(subject.total_outcomes(g0.id)).to eq 12
        subject.clear_total_outcomes_cache
        instance = described_class.new(context)
        expect(instance.total_outcomes(g0.id)).to eq 12
      end
    end
  end

  context 'learning outcome groups and learning outcomes events' do
    context 'when a group is destroyed' do
      it 'clears the cache' do
        enable_cache do
          expect(subject.total_subgroups(g0.id)).to eq 6
          g6.destroy
          expect(described_class.new(context).total_subgroups(g0.id)).to eq 5
        end
      end
    end

    context 'when a group is added' do
      it 'clears the cache' do
        enable_cache do
          expect(subject.total_subgroups(g0.id)).to eq 6
          outcome_group_model(context: context, outcome_group_id: g0)
          expect(described_class.new(context).total_subgroups(g0.id)).to eq 7
        end
      end

      context 'when a global group is added' do
        it 'clears the cache for total_subgroups and total_outcomes' do
          enable_cache do
            expect(subject.total_subgroups(g0.id)).to eq 6
            expect(subject.total_outcomes(g0.id)).to eq 12
            g0.add_outcome_group(global_group)
            expect(described_class.new(context).total_subgroups(g0.id)).to eq 8
            expect(described_class.new(context).total_outcomes(g0.id)).to eq 14
          end
        end
      end
    end

    context 'when a group is adopted' do
      it 'clears the cache' do
        enable_cache do
          expect(subject.total_subgroups(g0.id)).to eq 6
          outcome_group = outcome_group_model(context: context)
          g1.adopt_outcome_group(outcome_group)
          expect(described_class.new(context).total_subgroups(g0.id)).to eq 7
        end
      end
    end

    context 'when a group is edited' do
      it 'does not clear the cache' do
        enable_cache do
          # rubocop:disable RSpec/AnyInstance
          expect_any_instance_of(Outcomes::LearningOutcomeGroupChildren).not_to receive(:clear_descendants_cache)
          # rubocop:enable RSpec/AnyInstance
          expect(subject.total_subgroups(g0.id)).to eq 6
          g1.update(title: 'title edited')
          expect(described_class.new(context).total_subgroups(g0.id)).to eq 6
        end
      end
    end

    context 'when an outcome is added' do
      it 'clears the cache' do
        enable_cache do
          expect(subject.total_outcomes(g1.id)).to eq 9
          outcome = LearningOutcome.create!(title: 'test outcome', context: context)
          g1.add_outcome(outcome)
          expect(described_class.new(context).total_outcomes(g1.id)).to eq 10
        end
      end
    end

    context 'when an outcome is destroyed' do
      it 'clears the cache' do
        enable_cache do
          outcome = LearningOutcome.create!(title: 'test outcome', context: context)
          g1.add_outcome(outcome)
          expect(described_class.new(context).total_outcomes(g1.id)).to eq 10
          outcome.destroy
          expect(described_class.new(context).total_outcomes(g1.id)).to eq 9
        end
      end

      context 'when the outcome belongs to a global group' do
        it 'clears the cache' do
          enable_cache do
            expect(described_class.new.total_outcomes(global_group.id)).to eq 2
            global_outcome1.destroy
            expect(described_class.new.total_outcomes(global_group.id)).to eq 1
          end
        end
      end

      context 'when the outcome belongs to different contexts' do
        it 'clears the cache on each context' do
          enable_cache do
            g1.add_outcome(global_outcome1)
            expect(described_class.new(context).total_outcomes(g1.id)).to eq 10
            expect(described_class.new.total_outcomes(global_group.id)).to eq 2
            global_outcome1.destroy
            expect(described_class.new(context).total_outcomes(g1.id)).to eq 9
            expect(described_class.new.total_outcomes(global_group.id)).to eq 1
          end
        end
      end
    end

    context 'when a child_outcome_link is destroyed' do
      it 'clears the cache' do
        enable_cache do
          outcome = LearningOutcome.create!(title: 'test outcome', context: context)
          child_outcome_link = g1.add_outcome(outcome)
          expect(described_class.new(context).total_outcomes(g1.id)).to eq 10
          child_outcome_link.destroy
          expect(described_class.new(context).total_outcomes(g1.id)).to eq 9
        end
      end

      context 'when the child_outcome_link belongs to global learning outcome group' do
        it 'clears the cache' do
          enable_cache do
            outcome = LearningOutcome.create!(title: 'test outcome')
            child_outcome_link = global_group.add_outcome(outcome)
            expect(described_class.new.total_outcomes(global_group.id)).to eq 3
            child_outcome_link.destroy
            expect(described_class.new.total_outcomes(global_group.id)).to eq 2
          end
        end
      end
    end
  end
end
