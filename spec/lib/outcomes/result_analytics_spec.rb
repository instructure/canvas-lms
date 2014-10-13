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
  Rollup = Outcomes::ResultAnalytics::Rollup
  RollupScore = Outcomes::ResultAnalytics::RollupScore

  # ResultAnalytics only uses a few fields, so use some mock stuff to avoid all
  # the surrounding database logic
  MockUser = Struct.new(:id, :name)
  MockOutcome = Struct.new(:id)
  class MockOutcomeResult < Struct.new(:user, :learning_outcome, :score)
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
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 20],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81], 30],
      ]
      expect(ra.rollup_user_results(results)).to eq [
        RollupScore.new(MockOutcome[80], 20, 1),
        RollupScore.new(MockOutcome[81], 30, 1),
      ]
    end

    it 'returns the maximum score for each outcome_id' do
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 20],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 30],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81], 40],
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[81], 50],
      ]
      expect(ra.rollup_user_results(results)).to eq [
        RollupScore.new(MockOutcome[80], 30, 2),
        RollupScore.new(MockOutcome[81], 50, 2),
      ]
    end
  end

  describe '#outcome_results_rollups' do
    it 'returns a rollup for each distinct user_id' do
      results = [
        MockOutcomeResult[MockUser[10, 'a'], MockOutcome[80], 40],
        MockOutcomeResult[MockUser[20, 'b'], MockOutcome[80], 50],
      ]
      users = [MockUser[10, 'a'], MockUser[30, 'c']]
      expect(ra.outcome_results_rollups(results, users)).to eq [
        Rollup.new(MockUser[10, 'a'], [ RollupScore.new(MockOutcome[80], 40, 1) ]),
        Rollup.new(MockUser[20, 'b'], [ RollupScore.new(MockOutcome[80], 50, 1) ]),
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
