#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Outcomes::ResultAnalytics do

  # import some stuff so we don't have to spell it out all the time
  let(:ra) { Outcomes::ResultAnalytics }
  let(:time) { Time.now }
  Rollup = Outcomes::ResultAnalytics::Rollup
  RollupScore = Outcomes::ResultAnalytics::RollupScore

  # ResultAnalytics only uses a few fields, so use some mock stuff to avoid all
  # the surrounding database logic
  MockUser = Struct.new(:id, :name)
  MockOutcome = Struct.new(:id, :calculation_method, :calculation_int)
  class MockOutcomeResult < Struct.new(:user, :learning_outcome, :score, :title, :submitted_at)
    def learning_outcome_id
      learning_outcome.id
    end

    def user_id
      user.id
    end
  end

  describe '#rollup_user_results' do
    it 'returns a rollup score for each distinct outcome_id' do
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 2.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81], 3.0],
      ]
      expect(ra.rollup_user_results(results)).to eq [
        RollupScore.new(MockOutcome[80], 2.0, 1),
        RollupScore.new(MockOutcome[81], 3.0, 1),
      ]
    end
  end

  describe '#mastery calculation' do
    it 'returns maximum score when no method is set' do
      # this is to ensure we don't change behavior on outcomes that predate
      # the calculations feature. decaying avg will be default for new outcomes
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 3.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 1.0],
      ]
      expect(ra.rollup_user_results(results)).to eq [
        RollupScore.new(MockOutcome[80], 3.0, 2)
      ]
    end

    it 'returns maximum score when highest score method is selected' do
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'highest'], 3.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'highest'], 1.0],
      ]
      expect(ra.rollup_user_results(results)).to eq [
        RollupScore.new(MockOutcome[80, 'highest'], 3.0, 2)
      ]
    end

    it 'returns correct score when latest score method is selected' do
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'latest'], 4.0, "name, o1", nil],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'latest'], 3.0, "name, o1", time],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'latest'], 1.0, "name, o1", time - 1.day]
      ]
      expect(ra.rollup_user_results(results)).to eq [
        RollupScore.new(MockOutcome[80, 'latest'], 3.0, 3, "o1", time)
      ]
    end

    it 'properly calculates results when method is n# of scores for mastery' do
      results = [
        #first outcome
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'n_mastery', 3], 3.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'n_mastery', 3], 1.0],
        #second outcome
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'n_mastery', 5], 3.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'n_mastery', 5], 1.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'n_mastery', 5], 3.0],
        #third outcome
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[82, 'n_mastery', 4], 4.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[82, 'n_mastery', 4], 5.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[82, 'n_mastery', 4], 1.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[82, 'n_mastery', 4], 3.0],
      ]
      expect(ra.rollup_user_results(results)).to eq [
        RollupScore.new(MockOutcome[80, 'n_mastery', 3], nil, 2),
        RollupScore.new(MockOutcome[81, 'n_mastery', 5], nil, 3),
        RollupScore.new(MockOutcome[82, 'n_mastery', 4], 3.25, 4),
      ]
    end

    it 'properly calculates results when method is decaying average' do
      results = [
        #first outcome
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80, 'decaying_average', 75], 3.0, "name, o1", time],
        #second outcome
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'decaying_average', 75], 4.0, "name, o2", time],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'decaying_average', 75], 5.0, "name, o2", time - 1.day],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'decaying_average', 75], 1.0, "name, o2", time - 2.days],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81, 'decaying_average', 75], 3.0, "name, o2", time - 3.days],
      ]
      expect(ra.rollup_user_results(results)).to eq [
        RollupScore.new(MockOutcome[80, 'decaying_average', 75], nil, 1, "o1", time),
        RollupScore.new(MockOutcome[81, 'decaying_average', 75], 3.75, 4, "o2", time),
      ]
    end
  end

  describe '#outcome_results_rollups' do
    it 'returns a rollup for each distinct user_id' do
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 4.0],
        MockOutcomeResult[MockUser[20, 'b'], MockOutcome[80], 5.0],
      ]
      users = [MockUser[10, 'a'], MockUser[30, 'c']]
      expect(ra.outcome_results_rollups(results, users)).to eq [
        Rollup.new(MockUser[10, 'a'], [ RollupScore.new(MockOutcome[80], 4.0, 1) ]),
        Rollup.new(MockUser[20, 'b'], [ RollupScore.new(MockOutcome[80], 5.0, 1) ]),
        Rollup.new(MockUser[30, 'c'], []),
      ]
    end
  end

  describe '#aggregate_outcome_results_rollup' do
    it 'returns one rollup with the rollup averages' do
      fake_context = MockUser.new(42, 'fake')
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 0.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 1.0],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81], 5.0],
        MockOutcomeResult[MockUser[20, 'b'], MockOutcome[80], 2.0],
        MockOutcomeResult[MockUser[20, 'b'], MockOutcome[81], 6.0],
        MockOutcomeResult[MockUser[30, 'c'], MockOutcome[80], 3.0],
        MockOutcomeResult[MockUser[40, 'd'], MockOutcome[80], 4.0],
        MockOutcomeResult[MockUser[40, 'd'], MockOutcome[81], 7.0],
      ]
      aggregate_result = ra.aggregate_outcome_results_rollup(results, fake_context)
      expect(aggregate_result).to eq Rollup.new(
        fake_context,
        [
          RollupScore.new(MockOutcome[80], 2.5, 4),
          RollupScore.new(MockOutcome[81], 6.0, 3),
        ]
      )
    end
  end

end
